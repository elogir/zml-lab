import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/core/database/database.dart';
import 'package:zml_lab/core/database/database_provider.dart';
import 'package:zml_lab/core/execution/native_io.dart';
import 'package:zml_lab/features/perf/application/benchmark_target.dart';
import 'package:zml_lab/models/api_endpoint.dart';
import 'package:zml_lab/repositories/endpoint_repository.dart';

class _MemoryKeys implements ApiKeyStore {
  final keys = <String, String>{};
  @override
  Future<String?> read(String id) async => keys[id];
  @override
  Future<void> write(String id, String key) async => keys[id] = key;
  @override
  Future<void> delete(String id) async => keys.remove(id);
}

void main() {
  group('ChatEndpoint', () {
    test('parses what people type as an API root', () {
      expect(
        ChatEndpoint.parseBaseUrl('https://api.openai.com/v1').toString(),
        'https://api.openai.com/v1',
      );
      // No path: OpenAI-compatible servers serve under /v1.
      expect(
        ChatEndpoint.parseBaseUrl('http://4090:8000').toString(),
        'http://4090:8000/v1',
      );
      // No scheme: http.
      expect(
        ChatEndpoint.parseBaseUrl('4090.tail:8000/v1').toString(),
        'http://4090.tail:8000/v1',
      );
      expect(ChatEndpoint.parseBaseUrl(''), isNull);
      expect(ChatEndpoint.parseBaseUrl('ftp://x/v1'), isNull);
    });

    test('joins request paths under the root', () {
      final e = ChatEndpoint(Uri.parse('https://example.com/proxy/v1/'));
      expect(
        e.chatCompletions.toString(),
        'https://example.com/proxy/v1/chat/completions',
      );
      expect(e.host, 'example.com');
      expect(e.port, 443);
      expect(
        ChatEndpoint.hostPort('127.0.0.1', 8000).chatCompletions.toString(),
        'http://127.0.0.1:8000/v1/chat/completions',
      );
    });
  });

  testWidgets('requests carry the key and suit hosted APIs', (tester) async {
    final mocked = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = mocked);
    await tester.runAsync(() async {
      final seen = <({String path, String? auth, Map body})>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((req) async {
        final body = jsonDecode(await utf8.decoder.bind(req).join()) as Map;
        seen.add((
          path: req.uri.path,
          auth: req.headers.value(HttpHeaders.authorizationHeader),
          body: body,
        ));
        req.response
          ..headers.contentType = ContentType('text', 'event-stream')
          ..write('data: [DONE]\n\n');
        await req.response.close();
      });

      // A saved (hosted) endpoint with a key and a non-default root.
      final hosted = ChatEndpoint(
        Uri.parse('http://127.0.0.1:${server.port}/proxy/v1'),
        apiKey: 'sk-test',
      );
      await streamChat(hosted, const [
        {'role': 'user', 'content': 'hi'},
      ]).drain<void>();
      // A self-hosted server: no key, extended usage stats.
      await streamChat(ChatEndpoint.hostPort('127.0.0.1', server.port), const [
        {'role': 'user', 'content': 'hi'},
      ]).drain<void>();

      expect(seen[0].path, '/proxy/v1/chat/completions');
      expect(seen[0].auth, 'Bearer sk-test');
      expect(
        (seen[0].body['stream_options'] as Map).containsKey(
          'continuous_usage_stats',
        ),
        isFalse,
      );
      expect(seen[1].path, '/v1/chat/completions');
      expect(seen[1].auth, isNull);
      expect(
        (seen[1].body['stream_options'] as Map)['continuous_usage_stats'],
        isTrue,
      );
    });
  });

  test('endpoints round-trip through the database', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftEndpointRepository(db);
    final e = ApiEndpoint(
      id: 'ep-1',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      hasApiKey: true,
      createdAt: DateTime(2026, 10, 23),
    );
    await repo.save(e);
    expect(await repo.watchEndpoints().first, [e]);
    await repo.delete('ep-1');
    expect(await repo.watchEndpoints().first, isEmpty);
  });

  test('picking an endpoint targets its URL with its key', () async {
    final keys = _MemoryKeys()..keys['ep-1'] = 'sk-test';
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiKeyStoreProvider.overrideWithValue(keys),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final target = container.read(benchmarkTargetControllerProvider.notifier);
    await target.selectEndpoint(
      ApiEndpoint(
        id: 'ep-1',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        hasApiKey: true,
        createdAt: DateTime(2026),
      ),
    );
    final t = container.read(benchmarkTargetControllerProvider);
    expect(t.label, 'OpenAI');
    expect(t.chat.baseUrl.toString(), 'https://api.openai.com/v1');
    expect(t.chat.apiKey, 'sk-test');
    expect(t.chat.selfHosted, isFalse);

    // Back to a typed host: no key, self-hosted.
    target.selectCustom();
    final custom = container.read(benchmarkTargetControllerProvider);
    expect(custom.chat.apiKey, isNull);
    expect(custom.chat.selfHosted, isTrue);
  });

  test('a custom host can be a URL, with a key', () async {
    final keys = _MemoryKeys();
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        apiKeyStoreProvider.overrideWithValue(keys),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final target = container.read(benchmarkTargetControllerProvider.notifier);
    BenchmarkTarget read() => container.read(benchmarkTargetControllerProvider);

    // A plain host keeps host + port, self-hosted.
    expect(read().customIsUrl, isFalse);
    expect(read().chat.selfHosted, isTrue);

    // A URL carries its own port and path.
    target.setHostText('https://api.openai.com/v1');
    expect(read().customIsUrl, isTrue);
    expect(
      read().chat.chatCompletions.toString(),
      'https://api.openai.com/v1/chat/completions',
    );
    expect(read().host, 'api.openai.com');
    expect(read().port, 443);
    // No key: treated as a server of ours.
    expect(read().chat.selfHosted, isTrue);

    // A key makes it a hosted API, and is kept in the key store.
    target.setCustomKey('sk-test');
    expect(read().chat.apiKey, 'sk-test');
    expect(read().chat.selfHosted, isFalse);
    expect(keys.keys[BenchmarkTargetController.customKeyId], 'sk-test');

    // Clearing it removes it from the store.
    target.setCustomKey('');
    expect(read().chat.apiKey, isNull);
    expect(keys.keys, isEmpty);
  });
}
