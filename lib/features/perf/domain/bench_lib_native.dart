import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bench_lib_types.dart';

export 'bench_lib_types.dart';

// The C API of tools/benchmark/capi (see capi.go). Bundled as a code asset by
// hook/build.dart.
const _asset = 'package:zml_lab/zmlbench.dart';
const _apiVersion = 1;

const _kindCsv = 0;
const _kindLog = 1;
const _kindDone = 2;

typedef _Callback = Void Function(Int64, Int32, Pointer<Uint8>, Int64);

@Native<Int64 Function(Pointer<Utf8>, Pointer<NativeFunction<_Callback>>)>(
  assetId: _asset,
  symbol: 'zmlbench_start',
)
external int _start(
  Pointer<Utf8> config,
  Pointer<NativeFunction<_Callback>> cb,
);

@Native<Void Function(Int64)>(assetId: _asset, symbol: 'zmlbench_stop')
external void _stop(int run);

@Native<Void Function(Pointer<Void>)>(assetId: _asset, symbol: 'zmlbench_free')
external void _free(Pointer<Void> p);

@Native<Int32 Function()>(assetId: _asset, symbol: 'zmlbench_version')
external int _version();

/// Why the benchmark library can't be used here; null when it can.
String? benchLibProblem() {
  try {
    final v = _version();
    return v == _apiVersion
        ? null
        : 'benchmark library speaks API v$v, the app expects v$_apiVersion';
  } on ArgumentError {
    // The asset isn't bundled: the build had no Go or no benchmarker source.
    return 'benchmark library not bundled — build the app with Go installed '
        'and the benchmarker source checked out (see hook/build.dart)';
  }
}

/// Starts a run. CSV arrives in [onCsv] in chunks (rows may span chunks);
/// progress lines in [onLog]. Both on this isolate's event loop.
BenchLibRun startBenchLib(
  BenchLibConfig config, {
  required void Function(String chunk) onCsv,
  required void Function(String line) onLog,
}) {
  final json = jsonEncode(config.toJson()).toNativeUtf8();
  try {
    final id = _start(json, _callback.nativeFunction);
    final run = _Run(id, onCsv, onLog);
    _runs[id] = run;
    return run;
  } finally {
    malloc.free(json);
  }
}

final _runs = <int, _Run>{};

/// One listener for every run, kept for the app's lifetime: the library may
/// call it from any of its threads, and calls land on this isolate's loop.
final _callback = NativeCallable<_Callback>.listener(_onEvent);

void _onEvent(int id, int kind, Pointer<Uint8> data, int len) {
  final bytes = data == nullptr
      ? Uint8List(0)
      : Uint8List.fromList(data.asTypedList(len));
  if (data != nullptr) _free(data.cast());
  final run = _runs[id];
  if (run == null) return;
  switch (kind) {
    case _kindCsv:
      run._csv.add(bytes);
    case _kindLog:
      run._onLog(utf8.decode(bytes, allowMalformed: true));
    case _kindDone:
      _runs.remove(id);
      run._csv.close();
      run._done.complete(
        BenchLibSummary.fromJson(
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
        ),
      );
  }
}

class _Run implements BenchLibRun {
  _Run(this._id, void Function(String) onCsv, this._onLog)
    // Chunks are cut by time, not on character boundaries.
    : _csv = utf8.decoder.startChunkedConversion(_StringCallbackSink(onCsv));

  final int _id;
  final void Function(String line) _onLog;
  final ByteConversionSink _csv;
  final _done = Completer<BenchLibSummary>();

  @override
  void stop() {
    if (!_done.isCompleted) _stop(_id);
  }

  @override
  Future<BenchLibSummary> get done => _done.future;
}

class _StringCallbackSink implements Sink<String> {
  _StringCallbackSink(this._onData);

  final void Function(String) _onData;

  @override
  void add(String data) {
    if (data.isNotEmpty) _onData(data);
  }

  @override
  void close() {}
}
