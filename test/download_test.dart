import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/features/perf/domain/download.dart';

/// Serves [body], honouring `Range: bytes=N-`, in small slow-ish chunks so a
/// download can be cancelled midway. Records the Range headers it saw.
Future<(HttpServer, List<String?>)> _server(Uint8List body) async {
  final ranges = <String?>[];
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    final range = req.headers.value(HttpHeaders.rangeHeader);
    ranges.add(range);
    var start = 0;
    if (range != null) {
      start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
      req.response.statusCode = HttpStatus.partialContent;
    }
    final res = req.response
      ..bufferOutput = false
      ..contentLength = body.length - start;
    try {
      for (var i = start; i < body.length; i += 64 * 1024) {
        res.add(body.sublist(i, (i + 64 * 1024).clamp(0, body.length)));
        await res.flush();
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await res.close();
    } catch (_) {
      // Client went away (cancelled).
    }
  });
  return (server, ranges);
}

void main() {
  // 3 MB of non-repeating bytes.
  final body = Uint8List.fromList([
    for (var i = 0; i < 3 * 1024 * 1024; i++) (i * 7919 + (i >> 8)) & 0xff,
  ]);
  final hash = sha256.convert(body).toString();

  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('download_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  // Real sockets and isolates: run outside the fake-async zone, without the
  // test binding's HttpClient mock.
  Future<void> real(WidgetTester tester, Future<void> Function() body) async {
    final mocked = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = mocked);
    await tester.runAsync(body);
  }

  testWidgets('downloads, reports progress and verifies', (tester) async {
    await real(tester, () async {
      final (server, _) = await _server(body);
      addTearDown(() => server.close(force: true));
      final dest = '${tmp.path}/nested/dir/data.json';
      final seen = <DownloadProgress>[];
      final d = startDownload(
        url: Uri.parse('http://127.0.0.1:${server.port}/data.json'),
        dest: dest,
        sha256: hash,
      );
      d.progress.listen(seen.add);
      await d.done.timeout(const Duration(seconds: 30));

      expect(File(dest).readAsBytesSync(), body);
      expect(File('$dest.part').existsSync(), isFalse);
      expect(seen.last, (received: body.length, total: body.length));
      expect(seen.length, greaterThan(2)); // progress along the way
    });
  });

  testWidgets('cancel keeps the part; the next download resumes it', (
    tester,
  ) async {
    await real(tester, () async {
      final (server, ranges) = await _server(body);
      addTearDown(() => server.close(force: true));
      final url = Uri.parse('http://127.0.0.1:${server.port}/data.json');
      final dest = '${tmp.path}/data.json';

      final first = startDownload(url: url, dest: dest, sha256: hash);
      await first.progress.firstWhere((p) => p.received > 512 * 1024);
      first.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final kept = partialDownloadBytes(dest);
      expect(kept, greaterThan(0));
      expect(kept, lessThan(body.length));
      expect(File(dest).existsSync(), isFalse);

      final second = startDownload(url: url, dest: dest, sha256: hash);
      final firstReport = await second.progress.first;
      await second.done.timeout(const Duration(seconds: 30));
      expect(ranges.last, 'bytes=$kept-');
      expect(firstReport.received, kept); // starts where it stopped
      expect(File(dest).readAsBytesSync(), body);
    });
  });

  testWidgets('a corrupted download is rejected and discarded', (
    tester,
  ) async {
    await real(tester, () async {
      final (server, _) = await _server(body);
      addTearDown(() => server.close(force: true));
      final dest = '${tmp.path}/data.json';
      final d = startDownload(
        url: Uri.parse('http://127.0.0.1:${server.port}/data.json'),
        dest: dest,
        sha256: 'not-the-hash',
      );
      await expectLater(d.done, throwsA(contains('checksum mismatch')));
      expect(File(dest).existsSync(), isFalse);
      expect(partialDownloadBytes(dest), 0);
    });
  });
}
