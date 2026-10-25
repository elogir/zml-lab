import 'dart:convert';
import 'dart:io';

import '../core/logging/app_log.dart';
import 'endpoint_repository.dart';

/// `api-keys.json` in the user's config folder: `$XDG_CONFIG_HOME/zml-lab`
/// (by default `~/.config/zml-lab`) on macOS and Linux, `%APPDATA%\zml-lab`
/// on Windows.
String defaultApiKeysPath() {
  final env = Platform.environment;
  if (Platform.isWindows) return '${env['APPDATA']}\\zml-lab\\api-keys.json';
  final config = env['XDG_CONFIG_HOME'] ?? '${env['HOME']}/.config';
  return '$config/zml-lab/api-keys.json';
}

ApiKeyStore createApiKeyStore() => FileApiKeyStore(defaultApiKeysPath());

/// API keys as a JSON map (endpoint id → key) in a file only this user can
/// read: mode 0600 on macOS and Linux, and under the user's own profile on
/// Windows. Plain text, like gh's hosts.yml or Hugging Face's token file.
/// Not an OS keychain: macOS ties a Keychain item to the signature of the app
/// that wrote it, which changes with every ad-hoc-signed build (so updates
/// re-prompt, and deleting fails), and Linux's needs a running desktop keyring.
class FileApiKeyStore implements ApiKeyStore {
  FileApiKeyStore(this.path);

  final String path;

  /// The keys as last read or written; loaded on first use.
  Map<String, String>? _keys;

  /// Chains writes, so quick successive edits (the custom host's key is saved
  /// per keystroke) can't interleave and drop one.
  Future<void> _pending = Future.value();

  Future<Map<String, String>> _load() async {
    if (_keys case final keys?) return keys;
    final file = File(path);
    var keys = <String, String>{};
    if (await file.exists()) {
      try {
        final json = jsonDecode(await file.readAsString()) as Map;
        keys = json.map((k, v) => MapEntry(k as String, v as String));
      } catch (e) {
        AppLog.write('api keys: unreadable $path, starting empty ($e)');
      }
    }
    return _keys ??= keys;
  }

  @override
  Future<String?> read(String endpointId) async => (await _load())[endpointId];

  @override
  Future<void> write(String endpointId, String key) =>
      _update((keys) => keys[endpointId] = key);

  @override
  Future<void> delete(String endpointId) =>
      _update((keys) => keys.remove(endpointId));

  Future<void> _update(void Function(Map<String, String> keys) change) {
    final done = _pending.then((_) async {
      final keys = {...await _load()};
      change(keys);
      await _save(keys);
      _keys = keys;
    });
    // A failed write mustn't wedge the ones queued after it.
    _pending = done.catchError((_) {});
    return done;
  }

  Future<void> _save(Map<String, String> keys) async {
    final file = File(path);
    // Created empty and made private before any key goes in; later writes
    // truncate it in place, which keeps the mode.
    if (!await file.exists()) {
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
        await _chmod('700', file.parent.path);
      }
      await file.create();
      await _chmod('600', path);
    }
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(keys),
      flush: true,
    );
  }

  static Future<void> _chmod(String mode, String path) async {
    if (Platform.isWindows) return;
    final r = await Process.run('chmod', [mode, path]);
    if (r.exitCode != 0) {
      throw FileSystemException('chmod $mode failed: ${r.stderr}', path);
    }
  }
}
