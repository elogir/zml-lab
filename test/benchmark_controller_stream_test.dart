import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/execution/native_io.dart';
import 'package:zml_lab/features/benchmark/application/benchmark_controller.dart';
import 'package:zml_lab/models/benchmark.dart';

/// A minimal OpenAI-style streaming endpoint: every request gets [words]
/// content deltas ("w0 ", "w1 ", …), a stop, then [DONE]. Request bodies go
/// to [bodies] when given. `/v1/models` lists [models] (read per request, so
/// a test can change them).
Future<HttpServer> _fakeServer({
  required int words,
  Duration pace = const Duration(milliseconds: 3),
  List<Map<String, dynamic>>? bodies,
  List<String> models = const ['org/model'],
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    if (req.uri.path == '/v1/models') {
      req.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'data': [
              for (final m in models) {'id': m},
            ],
          }),
        );
      await req.response.close();
      return;
    }
    final body = await utf8.decoder.bind(req).join();
    bodies?.add(jsonDecode(body) as Map<String, dynamic>);
    // Unbuffered, so each delta goes out as written (like a real server).
    final res = req.response
      ..bufferOutput = false
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
      await Future<void>.delayed(pace);
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
      await controller.start(
        endpoint: ChatEndpoint.hostPort('127.0.0.1', server.port),
      );

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
        // Stamped by the batch worker as bytes arrived.
        expect(r.ttftMs, isNotNull, reason: '#${r.index}');
        expect(r.ttftMs, greaterThanOrEqualTo(0), reason: '#${r.index}');
        // Equal when a loaded local server bursts a whole reply in one read.
        expect(
          r.latencyMs,
          greaterThanOrEqualTo(r.ttftMs!),
          reason: '#${r.index}',
        );
      }
      expect(run.aggregateFrozen, isTrue);
      expect(run.completed, batch);
    });
  });

  testWidgets('cancelling mid-run publishes every partial reply', (
    tester,
  ) async {
    // Big enough that off-screen requests' text isn't kept live while it
    // streams — cancel has to bring all of it up to date.
    const batch = 120;
    final mocked = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = mocked);

    await tester.runAsync(() async {
      final server = await _fakeServer(
        words: 1000,
        pace: const Duration(milliseconds: 20),
      );
      addTearDown(() => server.close(force: true));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = benchmarkControllerProvider('t');
      final controller = container.read(provider.notifier)..setBatchSize(batch);
      await controller.start(
        endpoint: ChatEndpoint.hostPort('127.0.0.1', server.port),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      controller.cancel();

      final run = container.read(provider);
      expect(run.isRunning, isFalse);
      for (final r in run.requests) {
        expect(r.status, BenchmarkRequestStatus.done, reason: '#${r.index}');
        // One "wN " per token: the published text is the full partial reply.
        expect(' '.allMatches(r.text).length, r.tokens, reason: '#${r.index}');
      }
      // Most were well into their reply (a few may still be connecting).
      expect(
        run.requests.where((r) => r.tokens > 10).length,
        greaterThan(batch ~/ 2),
      );
    });
  });

  testWidgets('Ignore EOS rides on every request, and only when on', (
    tester,
  ) async {
    final mocked = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = mocked);

    await tester.runAsync(() async {
      final bodies = <Map<String, dynamic>>[];
      final server = await _fakeServer(words: 3, bodies: bodies);
      addTearDown(() => server.close(force: true));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = benchmarkControllerProvider('t');
      final controller = container.read(provider.notifier)
        ..setBatchSize(4)
        ..setMaxTokens(64)
        ..setIgnoreEos(true);
      final endpoint = ChatEndpoint.hostPort('127.0.0.1', server.port);

      Future<void> runBatch() async {
        await controller.start(endpoint: endpoint);
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (container.read(provider).isRunning &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      }

      await runBatch();
      expect(bodies, hasLength(4));
      for (final b in bodies) {
        expect(b['ignore_eos'], isTrue);
        expect(b['max_tokens'], 64);
      }

      // Off: not sent at all (hosted APIs reject unknown fields).
      bodies.clear();
      controller.setIgnoreEos(false);
      await runBatch();
      expect(bodies, hasLength(4));
      expect(bodies.any((b) => b.containsKey('ignore_eos')), isFalse);
    });
  });

  testWidgets('an empty Model is resolved from /v1/models, never filled', (
    tester,
  ) async {
    final mocked = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = mocked);

    await tester.runAsync(() async {
      final bodies = <Map<String, dynamic>>[];
      final models = ['org/only'];
      final server = await _fakeServer(
        words: 3,
        bodies: bodies,
        models: models,
      );
      addTearDown(() => server.close(force: true));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = benchmarkControllerProvider('t');
      final controller = container.read(provider.notifier)..setBatchSize(2);
      final endpoint = ChatEndpoint.hostPort('127.0.0.1', server.port);

      Future<void> runBatch() async {
        bodies.clear();
        await controller.start(endpoint: endpoint);
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (container.read(provider).isRunning &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      }

      // Just one: sent, and recorded as what was sent — the field stays
      // empty.
      await runBatch();
      expect(bodies.map((b) => b['model']), ['org/only', 'org/only']);
      var run = container.read(provider);
      expect(run.model, isEmpty);
      expect(run.sentModel, 'org/only');
      expect(run.serverModels, ['org/only']);

      // None listed: `zml_model`, as before.
      models.clear();
      await runBatch();
      expect(bodies.map((b) => b['model']), ['zml_model', 'zml_model']);
      expect(container.read(provider).sentModel, isEmpty);

      // Several: nothing starts (the last batch stays), it asks for one.
      models.addAll(['org/a', 'org/b']);
      await runBatch();
      expect(bodies, isEmpty);
      run = container.read(provider);
      expect(run.isRunning, isFalse);
      expect(run.requests, hasLength(2));
      expect(run.startError, contains('pick one'));
      expect(run.serverModels, ['org/a', 'org/b']);

      // Picked: sent as is, and the ask goes away.
      controller.setModel('org/b');
      expect(container.read(provider).startError, isNull);
      await runBatch();
      expect(bodies.map((b) => b['model']), ['org/b', 'org/b']);
      expect(container.read(provider).sentModel, 'org/b');
    });
  });
}
