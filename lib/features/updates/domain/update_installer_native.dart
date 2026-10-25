import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'update_release.dart';

/// This install's self-update plumbing. A release is downloaded, checked
/// against its signature and unpacked into a staging folder beside the app
/// (same file system, so the swap is two renames). A small shell script then
/// waits for the app to exit and swaps the staged build in: the app can't
/// replace itself while it runs, since assets and the perf library are read
/// from the bundle when first needed.
class UpdateInstaller {
  UpdateInstaller._(this._app, this._asset);

  /// The installed app: the `.app` bundle on macOS, the bundle folder on Linux.
  final Directory _app;

  /// The release asset this platform installs from.
  final String _asset;

  /// Null when this build doesn't update itself: a local build (no stamped
  /// version) or an OS without release builds.
  static UpdateInstaller? forThisApp() {
    final asset = updateAssetFor(Platform.operatingSystem);
    if (AppVersion.tryParse(appVersion) == null || asset == null) return null;
    final exe = File(Platform.resolvedExecutable);
    // macOS: <name>.app/Contents/MacOS/<exe>. Linux: <bundle>/<exe>.
    final app = Platform.isMacOS ? exe.parent.parent.parent : exe.parent;
    return UpdateInstaller._(app, asset);
  }

  Directory get _staging => Directory('${_app.parent.path}/.zml-lab-update');
  Directory get _stagedApp => Directory('${_staging.path}/app');
  File get _stagedVersionFile => File('${_staging.path}/version');

  /// The version unpacked and waiting to be swapped in, if any.
  AppVersion? get stagedVersion {
    try {
      if (!_stagedApp.existsSync()) return null;
      return AppVersion.tryParse(_stagedVersionFile.readAsStringSync());
    } on FileSystemException {
      return null;
    }
  }

  /// The latest release with a build for this platform; null when there is
  /// none yet.
  Future<UpdateRelease?> fetchLatest() async {
    final client = _client();
    try {
      final req = await client.getUrl(Uri.parse(updateFeedUrl));
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode == HttpStatus.notFound) return null;
      if (res.statusCode != HttpStatus.ok) {
        throw UpdateException('GitHub answered HTTP ${res.statusCode}.');
      }
      final json = jsonDecode(body);
      return json is Map<String, dynamic>
          ? UpdateRelease.fromGitHub(json, _asset)
          : null;
    } on IOException {
      throw const UpdateException("Couldn't reach GitHub.");
    } on FormatException {
      throw const UpdateException("GitHub's answer wasn't JSON.");
    } finally {
      client.close(force: true);
    }
  }

  /// Downloads [release], checks its signature and unpacks it into the
  /// staging folder, replacing whatever was staged before.
  Future<void> stage(
    UpdateRelease release, {
    void Function(double fraction)? onProgress,
  }) async {
    try {
      await discard();
      await _staging.create(recursive: true);
    } on FileSystemException {
      throw UpdateException(
        "Can't write to ${_app.parent.path}, so the app can't update itself "
        'there.',
      );
    }
    try {
      await _stage(release, onProgress);
    } catch (_) {
      await discard().catchError((_) {});
      rethrow;
    }
  }

  Future<void> _stage(
    UpdateRelease release,
    void Function(double fraction)? onProgress,
  ) async {
    final archive = File('${_staging.path}/${release.asset}');
    final client = _client();
    try {
      await _download(client, release.archiveUrl, archive, onProgress);
      final signature = await _fetchText(client, release.signatureUrl);
      final digest = await sha256.bind(archive.openRead()).first;
      final signed = await verifyUpdateSignature(
        version: '${release.version}',
        asset: release.asset,
        sha256: '$digest',
        signature: signature,
      );
      if (!signed) {
        throw const UpdateException(
          "The download's signature doesn't match, so it isn't installed.",
        );
      }
    } on IOException {
      throw const UpdateException("Couldn't download the update.");
    } finally {
      client.close(force: true);
    }

    // The system tar, not package:archive: it recreates the bundle's
    // framework links as they are, where package:archive drops a link that
    // runs through another one (Foo.framework/Foo -> Versions/Current/Foo).
    final unpacked = Directory('${_staging.path}/unpacked');
    await unpacked.create();
    final tar = await Process.run('tar', [
      '-xzf',
      archive.path,
      '-C',
      unpacked.path,
    ]);
    if (tar.exitCode != 0) {
      throw UpdateException(
        "Couldn't unpack the update: ${'${tar.stderr}'.trim()}",
      );
    }
    final roots = unpacked.listSync().whereType<Directory>().toList();
    if (roots.length != 1) {
      throw const UpdateException('The update archive should hold one folder.');
    }
    if (Platform.isMacOS && !await isCodeSigned(roots.single.path)) {
      throw const UpdateException(
        "The update isn't signed with ZML-Lab's certificate, so it isn't "
        'installed.',
      );
    }
    await roots.single.rename(_stagedApp.path);
    await unpacked.delete(recursive: true);
    await archive.delete();
    await _stagedVersionFile.writeAsString('${release.version}');
  }

  /// Removes the staged build, if any.
  Future<void> discard() async {
    if (await _staging.exists()) await _staging.delete(recursive: true);
  }

  /// Starts the swap script, which waits for this app to exit (however it
  /// exits) and then moves the staged build into place. Returns its pid, for
  /// [disarm].
  Future<int> armSwap() => _arm(const []);

  /// Stops a swap [armSwap] started.
  void disarm(int waiter) {
    // Never 0 or -1, which would signal a whole process group.
    if (waiter > 0) Process.killPid(waiter);
  }

  /// Swaps the staged build in now: arms the swap to relaunch the app once it
  /// is in place, then quits.
  Future<Never> restartInto() async {
    final exe = File(Platform.resolvedExecutable).uri.pathSegments.last;
    await _arm(
      Platform.isMacOS
          ? ['/usr/bin/open', '-n', _app.path]
          : ['${_app.path}/$exe'],
    );
    exit(0);
  }

  Future<int> _arm(List<String> relaunch) async {
    final script = File('${_staging.path}/swap.sh');
    await script.writeAsString(_swapScript);
    // Detached: its own session, so it outlives the app and its SIGHUP.
    final process = await Process.start('/bin/sh', [
      script.path,
      '$pid',
      _app.path,
      _stagedApp.path,
      ...relaunch,
    ], mode: ProcessStartMode.detached);
    return process.pid;
  }

  static HttpClient _client() => HttpClient()
    ..userAgent = 'zml-lab'
    ..connectionTimeout = const Duration(seconds: 20);

  static Future<void> _download(
    HttpClient client,
    Uri url,
    File to,
    void Function(double fraction)? onProgress,
  ) async {
    final res = await (await client.getUrl(url)).close();
    if (res.statusCode != HttpStatus.ok) {
      throw UpdateException(
        'Downloading the update failed (HTTP ${res.statusCode}).',
      );
    }
    final total = res.contentLength;
    var received = 0;
    final sink = to.openWrite();
    try {
      await for (final chunk in res) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
    } finally {
      await sink.close();
    }
  }

  static Future<String> _fetchText(HttpClient client, Uri url) async {
    final res = await (await client.getUrl(url)).close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != HttpStatus.ok) {
      throw UpdateException(
        'Downloading the signature failed (HTTP ${res.statusCode}).',
      );
    }
    return body;
  }
}

/// Whether the macOS app at [path] has a valid code signature, nested code
/// included, that satisfies [requirement].
Future<bool> isCodeSigned(
  String path, {
  String requirement = updateCodeRequirement,
}) async {
  final r = await Process.run('/usr/bin/codesign', [
    '--verify',
    '--deep',
    '--strict',
    // A leading '=' makes it the requirement's text, not a file.
    '-R=$requirement',
    path,
  ]);
  return r.exitCode == 0;
}

/// Waits for the app to exit, then puts the staged build in its place —
/// putting the old one back if that fails — and runs the relaunch command, if
/// given. Only ever touches the paths the updater passes it.
const _swapScript = r'''
# usage: swap.sh <app pid> <app> <staged app> [relaunch command...]
pid=$1 app=$2 new=$3
shift 3
case $new in */.zml-lab-update/app) ;; *) exit 1 ;; esac
[ -n "$pid" ] && [ -d "$app" ] && [ -d "$new" ] || exit 1
while kill -0 "$pid" 2>/dev/null; do sleep 1; done
rm -rf "$app.old"
if mv "$app" "$app.old"; then
  if mv "$new" "$app"; then
    rm -rf "$app.old" "${new%/app}"
  else
    mv "$app.old" "$app"
  fi
fi
[ $# -gt 0 ] && exec "$@"
''';
