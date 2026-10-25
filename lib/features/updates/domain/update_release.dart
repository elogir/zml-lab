import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// This build's version, stamped in by the release workflow
/// (`--dart-define=ZML_LAB_VERSION=1.2.3`, from the `v1.2.3` tag). Empty in
/// local builds, which never update themselves.
const appVersion = String.fromEnvironment('ZML_LAB_VERSION');

/// Where new releases are looked up: GitHub's latest release, which skips
/// drafts and pre-releases. Overridable to test against a local feed.
const updateFeedUrl = String.fromEnvironment(
  'ZML_LAB_UPDATE_FEED',
  defaultValue: 'https://api.github.com/repos/elogir/zml-lab/releases/latest',
);

/// The public half of the key release archives are signed with (the private
/// half is the repository's `ZML_LAB_UPDATE_KEY` secret). From
/// `dart run tool/update_signing.dart generate`.
const updatePublicKey = 'tB/rnTWxbzvPSgcviAa/LoShK2dSy9LgxQW15ZOhI5U=';

/// The release asset an OS installs from (`Platform.operatingSystem`), or null
/// when there are no release builds for it.
String? updateAssetFor(String os) => switch (os) {
  'macos' => 'zml-lab-macos.tar.gz',
  'linux' => 'zml-lab-linux-x64.tar.gz',
  _ => null,
};

/// Why an update couldn't be checked, downloaded or installed, worded for the
/// Settings status line.
class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A `major.minor.patch` version; a leading `v` (as in tags) is dropped.
final class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static AppVersion? tryParse(String text) {
    final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(text.trim());
    if (m == null) return null;
    return AppVersion(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  @override
  int compareTo(AppVersion other) => major != other.major
      ? major.compareTo(other.major)
      : minor != other.minor
      ? minor.compareTo(other.minor)
      : patch.compareTo(other.patch);

  bool operator >(AppVersion other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// A published release with a build for this platform: its archive and the
/// archive's signature (`<asset>.sig`).
final class UpdateRelease {
  const UpdateRelease({
    required this.version,
    required this.asset,
    required this.archiveUrl,
    required this.signatureUrl,
  });

  final AppVersion version;
  final String asset;
  final Uri archiveUrl;
  final Uri signatureUrl;

  /// Reads GitHub's release JSON. Null when the tag isn't a version or the
  /// release lacks [asset] or its signature.
  static UpdateRelease? fromGitHub(Map<String, dynamic> json, String asset) {
    final version = AppVersion.tryParse('${json['tag_name']}');
    final assets = json['assets'];
    if (version == null || assets is! List) return null;
    Uri? url(String name) {
      for (final a in assets) {
        if (a is Map && a['name'] == name) {
          return Uri.tryParse('${a['browser_download_url']}');
        }
      }
      return null;
    }

    final archive = url(asset);
    final signature = url('$asset.sig');
    if (archive == null || signature == null) return null;
    return UpdateRelease(
      version: version,
      asset: asset,
      archiveUrl: archive,
      signatureUrl: signature,
    );
  }
}

/// What a release signature covers: the version, the asset's name and the
/// archive's SHA-256 — so a signed archive can't be passed off as another
/// version or another platform's build.
List<int> updateSignedMessage(String version, String asset, String sha256) =>
    utf8.encode('zml-lab $version $asset $sha256');

/// Whether [signature] (base64 Ed25519) signs this archive, by [publicKey]
/// (base64; defaults to the release key).
Future<bool> verifyUpdateSignature({
  required String version,
  required String asset,
  required String sha256,
  required String signature,
  String publicKey = updatePublicKey,
}) async {
  try {
    return await Ed25519().verify(
      updateSignedMessage(version, asset, sha256),
      signature: Signature(
        base64.decode(signature.trim()),
        publicKey: SimplePublicKey(
          base64.decode(publicKey),
          type: KeyPairType.ed25519,
        ),
      ),
    );
  } on FormatException {
    return false;
  }
}
