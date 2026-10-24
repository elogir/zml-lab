import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart' as crypto;

import 'download_types.dart';

export 'download_types.dart';

/// Where an unfinished download of [dest] accumulates.
String _partPath(String dest) => '$dest.part';

/// Bytes of [dest] already fetched by an interrupted download.
int partialDownloadBytes(String dest) {
  final part = File(_partPath(dest));
  return part.existsSync() ? part.lengthSync() : 0;
}

/// Downloads [url] to [dest] in a background isolate (hundreds of MB must
/// not stall the UI). Bytes land in `dest.part` — resumed with a Range
/// request if one is there — and the file is renamed into place only once
/// complete and, with [sha256], verified.
FileDownload startDownload({
  required Uri url,
  required String dest,
  String? sha256,
}) => _IsolateDownload(url, dest, sha256);

class _IsolateDownload implements FileDownload {
  _IsolateDownload(Uri url, String dest, String? sha256) {
    final port = ReceivePort();
    _port = port;
    port.listen(_onMessage);
    Isolate.spawn(
      _worker,
      (port: port.sendPort, url: url, dest: dest, sha256: sha256),
      onError: port.sendPort,
      onExit: port.sendPort,
      errorsAreFatal: true,
    ).then((isolate) {
      if (_cancelled) {
        isolate.kill(priority: Isolate.immediate);
      } else {
        _isolate = isolate;
      }
    }, onError: _fail);
  }

  late final ReceivePort _port;
  Isolate? _isolate;
  bool _cancelled = false;
  final _progress = StreamController<DownloadProgress>.broadcast();
  final _done = Completer<void>();

  @override
  Stream<DownloadProgress> get progress => _progress.stream;

  @override
  Future<void> get done => _done.future;

  @override
  void cancel() {
    if (_done.isCompleted || _cancelled) return;
    _cancelled = true;
    _isolate?.kill(priority: Isolate.immediate);
    _close();
  }

  void _onMessage(Object? message) {
    if (_cancelled) return;
    switch (message) {
      case (int received, int? total):
        _progress.add((received: received, total: total));
      case 'done':
        _close();
        _done.complete();
      case String error:
        _fail(error);
      // An uncaught error in the worker: [message, stack].
      case [final Object? error, _]:
        _fail('$error');
      // Exited without saying why (it always reports otherwise).
      case null:
        _fail('the download stopped unexpectedly');
    }
  }

  void _fail(Object error) {
    if (_done.isCompleted) return;
    _close();
    _done.completeError(
      error is String ? error : '$error'.replaceFirst('Exception: ', ''),
    );
  }

  void _close() {
    _port.close();
    _progress.close();
  }
}

typedef _Job = ({SendPort port, Uri url, String dest, String? sha256});

/// The isolate: fetch (resuming), hash, write, verify, rename. Reports
/// `(received, total)` tuples, then 'done' or an error message.
Future<void> _worker(_Job job) async {
  final port = job.port;
  final part = File(_partPath(job.dest));
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    await part.parent.create(recursive: true);
    var have = part.existsSync() ? part.lengthSync() : 0;

    final request = await client.getUrl(job.url);
    if (have > 0) request.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
    final response = await request.close();
    final resumed = response.statusCode == HttpStatus.partialContent;
    if (!resumed && response.statusCode != HttpStatus.ok) {
      // 416: the part file is already complete (or bogus) — start over.
      if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
        await part.delete();
      }
      port.send('download failed: HTTP ${response.statusCode}');
      return;
    }
    if (!resumed) have = 0;
    final length = response.contentLength;
    final total = length < 0 ? null : have + length;

    // Hash what a resumed download already has, then the rest as it comes.
    final digest = _DigestSink();
    final hasher = crypto.sha256.startChunkedConversion(digest);
    if (have > 0) {
      await for (final chunk in part.openRead(0, have)) {
        hasher.add(chunk);
      }
    }

    final out = part.openWrite(
      mode: resumed ? FileMode.append : FileMode.write,
    );
    var received = have;
    var lastReport = DateTime.now();
    port.send((received, total));
    await for (final chunk in response) {
      out.add(chunk);
      hasher.add(chunk);
      received += chunk.length;
      final now = DateTime.now();
      if (now.difference(lastReport) >= const Duration(milliseconds: 100)) {
        lastReport = now;
        port.send((received, total));
      }
    }
    await out.close();
    hasher.close();
    port.send((received, total));

    if (total != null && received != total) {
      port.send('download cut short: $received of $total bytes');
      return;
    }
    if (job.sha256 != null && digest.value.toString() != job.sha256) {
      await part.delete();
      port.send('checksum mismatch — the file was corrupted; try again');
      return;
    }
    final dest = File(job.dest);
    if (dest.existsSync()) await dest.delete();
    await part.rename(job.dest);
    port.send('done');
  } catch (e) {
    port.send('download failed: $e');
  } finally {
    client.close(force: true);
  }
}

class _DigestSink implements Sink<crypto.Digest> {
  late crypto.Digest value;

  @override
  void add(crypto.Digest data) => value = data;

  @override
  void close() {}
}
