import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/features/updates/domain/update_installer_native.dart';

void main() {
  test('an update must be validly signed, as the requirement says', () async {
    final dir = Directory.systemTemp.createTempSync('code_signature_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final exe = File('${dir.path}/tool');
    await File('/usr/bin/true').copy(exe.path);
    final signed = await Process.run('/usr/bin/codesign', [
      '--force',
      '--sign',
      '-',
      '--identifier',
      'ai.zml.test',
      exe.path,
    ]);
    expect(signed.exitCode, 0, reason: '${signed.stderr}');

    expect(
      await isCodeSigned(exe.path, requirement: 'identifier "ai.zml.test"'),
      isTrue,
    );
    // Ad hoc: no certificate, so not ours.
    expect(await isCodeSigned(exe.path), isFalse);
    expect(
      await isCodeSigned(exe.path, requirement: 'identifier "ai.zml.other"'),
      isFalse,
    );
    // Changed after signing.
    await exe.writeAsBytes([0], mode: FileMode.append);
    expect(
      await isCodeSigned(exe.path, requirement: 'identifier "ai.zml.test"'),
      isFalse,
    );
  }, skip: !Platform.isMacOS);
}
