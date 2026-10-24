import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/execution/native_io.dart';

void main() {
  // The machines' reachability dot: a real ping.
  test('a host that answers is reachable', () async {
    expect(await pingHost('127.0.0.1'), isTrue);
  });

  test('nothing to ping, or no answer in time, is unreachable', () async {
    expect(await pingHost('  '), isFalse);
    // TEST-NET-1: reserved, never answers.
    final started = DateTime.now();
    expect(
      await pingHost('192.0.2.1', timeout: const Duration(seconds: 1)),
      isFalse,
    );
    expect(DateTime.now().difference(started).inSeconds, lessThan(3));
  });
}
