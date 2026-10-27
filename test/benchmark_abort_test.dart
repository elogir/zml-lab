import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/execution/native_io.dart';
import 'package:zml_lab/features/benchmark/application/benchmark_controller.dart';
import 'package:zml_lab/models/benchmark.dart';

/// A server that generates one reply at a time, like llmd at batch size 1: a
/// request waits until the one before it finishes or its client goes away.
/// Every reply is endless, so only a disconnect frees the slot. Raw sockets:
/// dart:io's HttpServer never notices a client hanging up mid-response.
Future<ServerSocket> _serialServer() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  var slot = Future<void>.value();
  server.listen((socket) {
    final turn = Completer<void>();
    final previous = slot;
    slot = turn.future;
    var gone = false;
    socket.listen(
      (_) {}, // the request; its contents don't matter here
      onDone: () => gone = true,
      onError: (Object _) => gone = true,
    );
    // Writing to a socket the client reset fails here.
    socket.done.catchError((Object _) => gone = true);
    () async {
      await previous;
      socket.write(
        'HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\n'
        'Connection: close\r\n\r\n',
      );
      for (var i = 0; !gone; i++) {
        final delta = {
          'choices': [
            {
              'delta': {'content': 'w$i '},
            },
          ],
        };
        socket.write('data: ${jsonEncode(delta)}\n\n');
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      socket.destroy();
      turn.complete();
    }();
  });
  return server;
}

Future<void> _until(
  bool Function() done, {
  Duration max = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(max);
  while (!done() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  late HttpOverrides? mocked;
  setUp(() {
    // The test binding fakes every HttpClient (all 400s); these talk to a
    // real local server.
    mocked = HttpOverrides.current;
    HttpOverrides.global = null;
  });
  tearDown(() => HttpOverrides.global = mocked);

  for (final restart in ['Stop then Send', 'Send again']) {
    testWidgets('$restart frees a serial server for the new batch', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final server = await _serialServer();
        addTearDown(() => server.close());
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final provider = benchmarkControllerProvider('t');
        final controller = container.read(provider.notifier)
          ..setBatchSize(1)
          ..setModel('m');
        final endpoint = ChatEndpoint.hostPort('127.0.0.1', server.port);

        await controller.start(endpoint: endpoint);
        await _until(() => container.read(provider).requests.first.tokens > 5);
        expect(container.read(provider).requests.first.tokens, greaterThan(5));

        if (restart == 'Stop then Send') controller.cancel();
        await controller.start(endpoint: endpoint);
        // Right away (~100 ms): a killed worker left its socket open, and the
        // new request waited seconds, or for the old reply to end.
        await _until(
          () => container.read(provider).requests.first.tokens > 5,
          max: const Duration(seconds: 1),
        );
        final r = container.read(provider).requests.first;
        expect(r.status, BenchmarkRequestStatus.streaming, reason: r.error);
        expect(
          r.tokens,
          greaterThan(5),
          reason: 'the new request never got the server',
        );
        controller.cancel();
      });
    });
  }
}
