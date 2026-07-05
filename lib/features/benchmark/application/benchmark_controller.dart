import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/execution/native_io.dart';
import '../../../models/benchmark.dart';
import '../../../models/settings.dart';
import '../../settings/application/settings_controller.dart';

part 'benchmark_controller.g.dart';

/// Mutable per-request scratch, updated by the stream as tokens arrive and
/// folded into an immutable [BenchmarkRequest] on each flush. Decouples network
/// events (which can be very frequent) from widget rebuilds.
class _Progress {
  _Progress({required this.index, required this.start});
  final int index;
  final DateTime start;
  DateTime? firstTokenAt;
  DateTime? endAt;
  final StringBuffer buffer = StringBuffer();
  int chunkTokens = 0; // fallback token count (content deltas seen)
  int usageTokens = 0; // exact count from the server's usage, when present
  String? finishReason; // the server's finish_reason, once the reply ends
  BenchmarkRequestStatus status = BenchmarkRequestStatus.streaming;

  int get tokens => usageTokens > 0 ? usageTokens : chunkTokens;
}

/// Drives a real benchmark run: fires [batchSize] concurrent streaming requests
/// at the job's `/v1/chat/completions` endpoint and reports per-request and
/// aggregate throughput live. Cancelable mid-flight.
///
/// Keep-alive (keyed by job id) so a run — and the prompt/batch settings —
/// survive switching to the terminal tab or navigating away and back. The live
/// requests keep streaming in the background; invalidating the provider (or
/// cancelling) aborts them.
@Riverpod(keepAlive: true)
class BenchmarkController extends _$BenchmarkController {
  final List<StreamSubscription<ChatToken>> _subs = [];
  Timer? _ticker;
  DateTime? _startAt;
  List<_Progress> _progs = [];

  @override
  BenchmarkRun build(String jobId) {
    ref.onDispose(_teardown);
    // Seed from the configured defaults (read, not watch: an already-open run
    // keeps its state; changed defaults apply to freshly opened jobs).
    final s = ref.read(settingsControllerProvider);
    return BenchmarkRun(
      prompt: s.benchPrompt,
      batchSize: s.benchBatchSize,
      maxTokens: s.benchMaxTokens,
      temperature: s.benchTemperature,
    );
  }

  void setPrompt(String prompt) => state = state.copyWith(prompt: prompt);

  void setBatchSize(int size) =>
      state = state.copyWith(batchSize: size < 1 ? 1 : size);

  /// Null = unlimited: the server generates until EOS or its max seqlen.
  void setMaxTokens(int? tokens) => state = state.copyWith(
    maxTokens: tokens == null || tokens < 1 ? null : tokens,
  );

  /// Null = the server's default sampling temperature.
  void setTemperature(double? temperature) => state = state.copyWith(
    temperature: temperature?.clamp(0.0, 2.0),
  );

  /// Fires the batch at `http://[host]:[port]/v1/chat/completions`.
  void start({required String host, required int port}) {
    _teardown();
    final n = state.batchSize;
    final prompt =
        state.prompt.trim().isEmpty ? defaultBenchmarkPrompt : state.prompt;
    final now = DateTime.now();
    _startAt = now;
    _progs = List.generate(n, (i) => _Progress(index: i + 1, start: now));

    state = state.copyWith(
      isRunning: true,
      elapsed: Duration.zero,
      frozenAggregate: 0,
      runToken: state.runToken + 1,
      requests: [
        for (final p in _progs)
          BenchmarkRequest(
            index: p.index,
            status: BenchmarkRequestStatus.streaming,
          ),
      ],
    );

    final messages = [
      {'role': 'user', 'content': prompt},
    ];
    for (final p in _progs) {
      final sub =
          streamChat(
            host,
            port,
            messages,
            maxTokens: state.maxTokens,
            temperature: state.temperature,
          ).listen(
            (tok) => _onToken(p, tok),
            onError: (_) => _finish(p, failed: true),
            onDone: () => _finish(p, failed: false),
            cancelOnError: true,
          );
      _subs.add(sub);
    }

    _ticker = Timer.periodic(const Duration(milliseconds: 120), (_) => _flush());
  }

  void cancel() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _ticker?.cancel();

    final now = DateTime.now();
    final start = _startAt;
    for (final p in _progs) {
      if (!p.status.isTerminal) {
        p.status = BenchmarkRequestStatus.done;
        p.endAt = now;
      }
    }
    state = state.copyWith(
      isRunning: false,
      // Lock the aggregate at whatever was live if we never hit a natural
      // first-completion (same reasoning as the freeze below).
      frozenAggregate:
          state.aggregateFrozen ? state.frozenAggregate : _liveAggregate(),
      elapsed: start != null ? now.difference(start) : state.elapsed,
      requests: [
        for (final r in state.requests)
          r.status == BenchmarkRequestStatus.streaming
              ? r.copyWith(status: BenchmarkRequestStatus.done)
              : r,
      ],
    );
  }

  double _liveAggregate() => state.requests
      .where((r) => r.status == BenchmarkRequestStatus.streaming)
      .fold(0.0, (sum, r) => sum + r.tokensPerSecond);

  void _onToken(_Progress p, ChatToken tok) {
    p.firstTokenAt ??= DateTime.now();
    final content = tok.content;
    if (content != null && content.isNotEmpty) {
      p.buffer.write(content);
      p.chunkTokens += 1;
    }
    if (tok.completionTokens != null && tok.completionTokens! > 0) {
      p.usageTokens = tok.completionTokens!;
    }
    if (tok.finishReason != null) p.finishReason = tok.finishReason;
  }

  void _finish(_Progress p, {required bool failed}) {
    if (p.status.isTerminal) return;
    p.status =
        failed ? BenchmarkRequestStatus.failed : BenchmarkRequestStatus.done;
    p.endAt = DateTime.now();
    _flush(); // reflect the completion (and the aggregate freeze) immediately
  }

  /// Folds the scratch progress into immutable request state. Per-request tok/s
  /// is decode speed (tokens since first token / decode time); once a request
  /// ends its `endAt` is fixed so its reading holds steady.
  void _flush() {
    final start = _startAt;
    if (start == null) return;
    final now = DateTime.now();

    final requests = <BenchmarkRequest>[];
    for (final p in _progs) {
      final endRef = p.endAt ?? now;
      final decodeMs = p.firstTokenAt == null
          ? 0
          : endRef.difference(p.firstTokenAt!).inMilliseconds;
      final tps = decodeMs > 0 ? p.tokens / (decodeMs / 1000.0) : 0.0;
      requests.add(
        BenchmarkRequest(
          index: p.index,
          status: p.status,
          text: p.buffer.toString(),
          tokens: p.tokens,
          tokensPerSecond: tps,
          ttftMs: p.firstTokenAt?.difference(p.start).inMilliseconds,
          latencyMs: p.status.isTerminal
              ? (p.endAt ?? now).difference(p.start).inMilliseconds
              : null,
          finishReason: p.finishReason,
        ),
      );
    }

    // Freeze the aggregate the first time a request finishes — up to then the
    // whole batch is at full concurrency, so the combined rate is the real
    // throughput at the launched batch size (see [BenchmarkRun]).
    var frozen = state.frozenAggregate;
    if (!state.aggregateFrozen && requests.any((r) => r.status.isTerminal)) {
      frozen = requests
          .where(
            (r) =>
                r.status == BenchmarkRequestStatus.streaming ||
                r.status == BenchmarkRequestStatus.done,
          )
          .fold(0.0, (sum, r) => sum + r.tokensPerSecond);
    }

    final anyActive = _progs.any((p) => !p.status.isTerminal);
    state = state.copyWith(
      requests: requests,
      elapsed: now.difference(start),
      isRunning: anyActive,
      frozenAggregate: frozen,
    );
    if (!anyActive) _ticker?.cancel();
  }

  void _teardown() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _ticker?.cancel();
    _progs = [];
  }
}
