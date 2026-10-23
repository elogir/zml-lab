import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/features/benchmark/application/benchmark_controller.dart';
import 'package:zml_lab/models/benchmark.dart';

/// A minimal OpenAI-style streaming endpoint: every request gets [words]
/// content deltas ("w0 ", "w1 ", …), a stop, then [DONE].
Future<HttpServer> _fakeServer({required int words}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    await utf8.decoder.bind(req).join();
    final res = req.response
      ..headers.contentType = ContentType('text', 'event-stream');
    String event(Map<String, dynamic> choice) =>
        'data: ${jsonEncode({
          'choices': [choice],
        })}\n\n';
    for (var i = 0; i < words; i++) {
      res.write(
        event({
          'delta': {'content': 'w$i '},
        }),
      );
      await res.flush();
      await Future<void>.delayed(const Duration(milliseconds: 3));
    }
    res.write(event({'delta': <String, dynamic>{}, 'finish_reason': 'stop'}));
    res.write('data: [DONE]\n\n');
    await res.close();
  });
  return server;
}

void main() {
  testWidgets('a big batch publishes every reply in full', (tester) async {
    // Big enough for the throttled flush path; under macOS's 128-connection
    // listen backlog, which a single local test server can't exceed.
    const batch = 120;
    const words = 40;
    final expected = [for (var i = 0; i < words; i++) 'w$i '].join();

    // The test binding fakes every HttpClient (all 400s); this test talks to
    // a real local server.
    final mocked = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = mocked);

    await tester.runAsync(() async {
      final server = await _fakeServer(words: words);
      addTearDown(() => server.close(force: true));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = benchmarkControllerProvider('t');
      final controller = container.read(provider.notifier)..setBatchSize(batch);
      controller.start(host: '127.0.0.1', port: server.port);

      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (container.read(provider).isRunning &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }

      final run = container.read(provider);
      expect(run.isRunning, isFalse);
      expect(run.requests, hasLength(batch));
      for (final r in run.requests) {
        expect(
          r.status,
          BenchmarkRequestStatus.done,
          reason: '#${r.index}: ${r.error}',
        );
        expect(r.text, expected, reason: '#${r.index}');
        expect(r.tokens, words, reason: '#${r.index}');
        expect(r.finishReason, 'stop', reason: '#${r.index}');
        expect(r.latencyMs, isNotNull, reason: '#${r.index}');
      }
      expect(run.aggregateFrozen, isTrue);
      expect(run.completed, batch);
    });
  });
}
