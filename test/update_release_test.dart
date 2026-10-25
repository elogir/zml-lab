// The self-updater's pure parts: versions, GitHub's release JSON, and the
// release signature (signed here with a throwaway key, the way
// tool/update_signing.dart signs in CI).
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/features/updates/domain/update_release.dart';

void main() {
  group('AppVersion', () {
    test('parses tags and plain versions', () {
      expect(AppVersion.tryParse('v1.2.3'), const AppVersion(1, 2, 3));
      expect(AppVersion.tryParse('0.10.0'), const AppVersion(0, 10, 0));
      expect(AppVersion.tryParse('1.2'), isNull);
      expect(AppVersion.tryParse('v1.2.3-beta'), isNull);
      expect(AppVersion.tryParse('zmlbench'), isNull);
    });

    test('orders numerically, not as text', () {
      expect(
        AppVersion.tryParse('1.10.0')! > AppVersion.tryParse('1.9.9')!,
        isTrue,
      );
      expect(
        AppVersion.tryParse('2.0.0')! > AppVersion.tryParse('1.99.99')!,
        isTrue,
      );
      expect(
        AppVersion.tryParse('1.2.3')! > AppVersion.tryParse('1.2.3')!,
        isFalse,
      );
    });
  });

  group('UpdateRelease.fromGitHub', () {
    Map<String, dynamic> release(String tag, List<String> assets) => {
      'tag_name': tag,
      'assets': [
        for (final a in assets)
          {'name': a, 'browser_download_url': 'https://example.com/$a'},
      ],
    };

    test('picks this platform\'s archive and its signature', () {
      final r = UpdateRelease.fromGitHub(
        release('v1.4.0', [
          'zml-lab-linux-x64.tar.gz',
          'zml-lab-linux-x64.tar.gz.sig',
          'zml-lab-macos.tar.gz',
          'zml-lab-macos.tar.gz.sig',
        ]),
        'zml-lab-macos.tar.gz',
      )!;
      expect(r.version, const AppVersion(1, 4, 0));
      expect(r.archiveUrl.path, '/zml-lab-macos.tar.gz');
      expect(r.signatureUrl.path, '/zml-lab-macos.tar.gz.sig');
    });

    test('is null without a signed build for this platform', () {
      expect(
        UpdateRelease.fromGitHub(
          release('v1.4.0', ['zml-lab-macos.tar.gz']),
          'zml-lab-macos.tar.gz',
        ),
        isNull,
      );
      expect(
        UpdateRelease.fromGitHub(
          release('v1.4.0', [
            'zml-lab-macos.tar.gz',
            'zml-lab-macos.tar.gz.sig',
          ]),
          'zml-lab-linux-x64.tar.gz',
        ),
        isNull,
      );
      expect(
        UpdateRelease.fromGitHub(
          release('nightly', [
            'zml-lab-macos.tar.gz',
            'zml-lab-macos.tar.gz.sig',
          ]),
          'zml-lab-macos.tar.gz',
        ),
        isNull,
      );
    });
  });

  group('verifyUpdateSignature', () {
    const asset = 'zml-lab-macos.tar.gz';
    const sha =
        'a3f5c1e0b7d24e8f9a6b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f';
    late String publicKey;
    late String signature;

    setUpAll(() async {
      final pair = await Ed25519().newKeyPair();
      publicKey = base64.encode((await pair.extractPublicKey()).bytes);
      final sig = await Ed25519().sign(
        updateSignedMessage('1.4.0', asset, sha),
        keyPair: pair,
      );
      signature = base64.encode(sig.bytes);
    });

    Future<bool> verify({
      String version = '1.4.0',
      String a = asset,
      String digest = sha,
      String? sig,
      String? key,
    }) => verifyUpdateSignature(
      version: version,
      asset: a,
      sha256: digest,
      signature: sig ?? signature,
      publicKey: key ?? publicKey,
    );

    test('accepts the signed archive', () async {
      expect(await verify(), isTrue);
    });

    test('rejects another version, platform or archive', () async {
      expect(await verify(version: '1.5.0'), isFalse);
      expect(await verify(a: 'zml-lab-linux-x64.tar.gz'), isFalse);
      expect(await verify(digest: sha.replaceFirst('a', 'b')), isFalse);
    });

    test('rejects another key and garbage', () async {
      final other = await Ed25519().newKeyPair();
      final otherKey = base64.encode((await other.extractPublicKey()).bytes);
      expect(await verify(key: otherKey), isFalse);
      expect(await verify(sig: 'not base64!'), isFalse);
    });

    test('the release key is a valid Ed25519 public key', () {
      expect(base64.decode(updatePublicKey), hasLength(32));
    });
  });
}
