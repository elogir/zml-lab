// Release signing for the self-updater (lib/features/updates).
//
//   dart run tool/update_signing.dart generate <key file>
//       Makes a key pair: writes the private key (a base64 Ed25519 seed) to
//       <key file>, readable only by you, and prints the public key for
//       `updatePublicKey`. The private key goes in the repository's
//       ZML_LAB_UPDATE_KEY secret.
//
//   dart run tool/update_signing.dart sign <version> <archive>
//       Prints the archive's signature (base64), signed with the private key
//       in $ZML_LAB_UPDATE_KEY. The release workflow runs this.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:zml_lab/features/updates/domain/update_release.dart';

Future<void> main(List<String> args) async {
  switch (args) {
    case ['generate', final keyFile]:
      await _generate(File(keyFile));
    case ['sign', final version, final archive]:
      await _sign(version, File(archive));
    default:
      stderr.writeln(
        'usage: update_signing.dart generate <key file>\n'
        '       update_signing.dart sign <version> <archive>',
      );
      exit(64);
  }
}

Future<void> _generate(File keyFile) async {
  if (keyFile.existsSync()) {
    stderr.writeln('${keyFile.path} already exists; not overwriting it.');
    exit(1);
  }
  final pair = await Ed25519().newKeyPair();
  final seed = await pair.extractPrivateKeyBytes();
  final public = await pair.extractPublicKey();
  keyFile.parent.createSync(recursive: true);
  keyFile.writeAsStringSync('${base64.encode(seed)}\n');
  await Process.run('chmod', ['600', keyFile.path]);
  stdout.writeln(base64.encode(public.bytes));
}

Future<void> _sign(String version, File archive) async {
  final key = Platform.environment['ZML_LAB_UPDATE_KEY']?.trim() ?? '';
  if (key.isEmpty) {
    stderr.writeln('ZML_LAB_UPDATE_KEY is not set.');
    exit(1);
  }
  final pair = await Ed25519().newKeyPairFromSeed(base64.decode(key));
  final digest = await sha256.bind(archive.openRead()).first;
  final asset = archive.uri.pathSegments.last;
  final signature = await Ed25519().sign(
    updateSignedMessage(version, asset, '$digest'),
    keyPair: pair,
  );
  // Refuse to publish a signature the app's key wouldn't accept.
  final public = base64.encode((await pair.extractPublicKey()).bytes);
  if (public != updatePublicKey) {
    stderr.writeln(
      "ZML_LAB_UPDATE_KEY doesn't match updatePublicKey in "
      'lib/features/updates/domain/update_release.dart.',
    );
    exit(1);
  }
  stdout.writeln(base64.encode(signature.bytes));
}
