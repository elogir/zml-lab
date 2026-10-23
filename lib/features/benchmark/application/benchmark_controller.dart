import 'dart:async';

import 'package:flutter/scheduler.dart';
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
  DateTime start; // re-set to when the worker actually sent the request
  DateTime? firstTokenAt;
  DateTime? endAt;
  final StringBuffer buffer = StringBuffer();
  final StringBuffer reasoning = StringBuffer(); // thinking output, if any
  int chunkTokens = 0; // fallback token count (content + reasoning deltas)
  int usageTokens = 0; // exact count from the server's usage, when present
  String? finishReason; // the server's finish_reason, once the reply ends
  String? error; // why it failed, when it did
  BenchmarkRequestStatus status = BenchmarkRequestStatus.streaming;

  /// Set by every token / completion; cleared by the flush that folds it in.
  bool dirty = true;

  // The buffers' contents as of the last flush, re-read only when they grew —
  // copying every reply's whole text on every flush adds up fast in a batch
  // of hundreds of long replies.
  String text = '';
  String reasoningText = '';

  /// What the last flush published. A settled request with nothing new is
  /// re-published as this same object, so nothing downstream sees a change.
  BenchmarkRequest? published;

  int get tokens => usageTokens > 0 ? usageTokens : chunkTokens;
}

/// Strips the `Exception: ` wrapper off an error message.
String _cleanError(Object e) {
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring('Exception: '.length) : s;
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
  /// The batch's merged progress, streamed from a background isolate (see
  /// [streamChatBatch]): receiving hundreds of streams here starved the UI.
  StreamSubscription<List<ChatBatchDelta>>? _batch;
  int _settled = 0;

  /// Requests whose text is on screen right now (a grid card, a chat popup),
  /// with how many views hold each. While a big batch streams, only these get
  /// their text republished each flush — re-joining all of hundreds of long
  /// replies every flush was most of the UI thread's time. The rest catch up
  /// when they finish (or come into view).
  final Map<int, int> _watched = {};

  /// Small batches always republish everything; it's cheap at that size.
  static const _watchAllUpTo = 64;
  Timer? _ticker;
  DateTime? _startAt;
  List<_Progress> _progs = [];
  bool _flushScheduled = false;
  Timer? _flushDelay;
  DateTime _lastFlush = DateTime.fromMillisecondsSinceEpoch(0);

  // Throughput time-series. Appended on a ~250ms cadence (flush runs per-frame,
  // far too often to sample every time); the snapshot is a stable reference so
  // state.copyWith only churns when a point is actually added.
  final List<BenchmarkSample> _samples = [];
  List<BenchmarkSample> _samplesSnapshot = const [];
  static const _sampleIntervalMs = 250;

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
      model: s.benchModel,
    );
  }

  /// Every flush publishes a new run object, so identity is the right test —
  /// the default `==` deep-compares every request's text on each flush.
  @override
  bool updateShouldNotify(BenchmarkRun previous, BenchmarkRun next) =>
      !identical(previous, next);

  /// A view started showing request [index]'s text (see [_watched]).
  void watchText(int index) {
    _watched.update(index, (n) => n + 1, ifAbsent: () => 1);
    // Newly visible mid-run: bring its text up to date on the next flush.
    if (index >= 1 && index <= _progs.length) {
      _progs[index - 1].dirty = true;
      if (state.isRunning) _scheduleFlush();
    }
  }

  void unwatchText(int index) {
    final n = (_watched[index] ?? 0) - 1;
    if (n <= 0) {
      _watched.remove(index);
    } else {
      _watched[index] = n;
    }
  }

  void setPrompt(String prompt) => state = state.copyWith(prompt: prompt);

  /// Empty = send `zml_model` (the server-agnostic default).
  void setModel(String model) => state = state.copyWith(model: model.trim());

  void setBatchSize(int size) =>
      state = state.copyWith(batchSize: size < 1 ? 1 : size);

  /// Null = unlimited: the server generates until EOS or its max seqlen.
  void setMaxTokens(int? tokens) => state = state.copyWith(
    maxTokens: tokens == null || tokens < 1 ? null : tokens,
  );

  /// Null = the server's default sampling temperature.
  void setTemperature(double? temperature) =>
      state = state.copyWith(temperature: temperature?.clamp(0.0, 2.0));

  /// Fires the batch at `http://[host]:[port]/v1/chat/completions`.
  void start({required String host, required int port}) {
    _teardown();
    final n = state.batchSize;
    final prompt = state.prompt.trim().isEmpty
        ? defaultBenchmarkPrompt
        : state.prompt;
    final now = DateTime.now();
    _startAt = now;
    _progs = List.generate(n, (i) => _Progress(index: i + 1, start: now));
    _settled = 0;
    _samples.clear();
    _samplesSnapshot = const [];

    state = state.copyWith(
      isRunning: true,
      elapsed: Duration.zero,
      frozenAggregate: 0,
      runToken: state.runToken + 1,
      samples: const [],
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
    _batch =
        streamChatBatch(
          host,
          port,
          messages,
          count: n,
          maxTokens: state.maxTokens,
          temperature: state.temperature,
          model: state.model,
          // Token-by-token for a small batch; coarser merges for a big one,
          // whose flushes back off anyway (see [_flushInterval]).
          interval: Duration(milliseconds: n <= 32 ? 16 : 50),
        ).listen(
          _onDeltas,
          // The worker itself failed (not one request): fail what's left.
          onError: (Object e) {
            for (final p in _progs) {
              _finish(p, failed: true, error: _cleanError(e));
            }
          },
        );

    // Slow tick just keeps the live elapsed / tok-s readout advancing between
    // tokens; token *text* is flushed per-token (frame-coalesced) below.
    _ticker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _flush(),
    );
  }

  void cancel() {
    _batch?.cancel();
    _batch = null;
    _ticker?.cancel();
    // Lock the aggregate at whatever was live if we never hit a natural
    // first-completion (same reasoning as the freeze in [_flush]).
    final frozen = state.aggregateFrozen
        ? state.frozenAggregate
        : _liveAggregate();

    final now = DateTime.now();
    for (final p in _progs) {
      if (!p.status.isTerminal) {
        p.status = BenchmarkRequestStatus.done;
        p.endAt = now;
        p.dirty = true;
      }
    }
    // A full flush, so unwatched requests publish their text as it stood.
    _flush();
    state = state.copyWith(isRunning: false, frozenAggregate: frozen);
  }

  /// Drops the run's results — back to the empty state, ready for a fresh
  /// batch. The parameters (prompt, batch size, max tokens, temperature,
  /// model) are deliberately kept: clearing is about the numbers on screen,
  /// not the setup that produced them.
  ///
  /// Aborts a live run first, and bumps [BenchmarkRun.runToken] so any chat
  /// opened from a request in the cleared batch resets instead of mirroring a
  /// request that no longer exists.
  void clear() {
    _teardown();
    _samples.clear();
    _samplesSnapshot = const [];
    state = state.copyWith(
      isRunning: false,
      runToken: state.runToken + 1,
      requests: const [],
      samples: const [],
      elapsed: Duration.zero,
      frozenAggregate: 0,
    );
  }

  double _liveAggregate() => state.requests
      .where((r) => r.status == BenchmarkRequestStatus.streaming)
      .fold(0.0, (sum, r) => sum + r.tokensPerSecond);

  /// Folds one merged update from the batch worker into the requests' scratch
  /// progress. Timestamps come from the worker, taken as bytes arrived.
  void _onDeltas(List<ChatBatchDelta> deltas) {
    var firstOrLast = false;
    for (final d in deltas) {
      final p = _progs[d.index - 1];
      if (p.status.isTerminal) continue; // cancelled meanwhile
      if (d.startUs != null) {
        p.start = DateTime.fromMicrosecondsSinceEpoch(d.startUs!);
      }
      // The decode clock starts at the first *real* token (content or
      // thinking), not the empty role delta — the worker stamps that one.
      if (d.firstTokenUs != null) {
        p.firstTokenAt ??= DateTime.fromMicrosecondsSinceEpoch(d.firstTokenUs!);
      }
      if (d.reasoning.isNotEmpty) p.reasoning.write(d.reasoning);
      if (d.content.isNotEmpty) p.buffer.write(d.content);
      p.chunkTokens += d.chunks;
      if (d.completionTokens != null && d.completionTokens! > 0) {
        p.usageTokens = d.completionTokens!;
      }
      if (d.finishReason != null) p.finishReason = d.finishReason;
      p.dirty = true;
      if (d.done) {
        p
          ..status = d.error != null
              ? BenchmarkRequestStatus.failed
              : BenchmarkRequestStatus.done
          ..error = d.error
          ..endAt = d.endUs != null
              ? DateTime.fromMicrosecondsSinceEpoch(d.endUs!)
              : DateTime.now();
        _settled++;
        if (_settled == 1 || _settled == _progs.length) firstOrLast = true;
      }
    }
    // The first completion (it freezes the aggregate) and the last show at
    // once; everything else rides the regular cadence.
    firstOrLast ? _flush() : _scheduleFlush();
  }

  /// How often a running batch republishes. Per frame reads token-by-token
  /// for a handful of requests; with hundreds, every flush rebuilds hundreds
  /// of requests and the visible cards, so it backs off — the numbers stay
  /// live and the text still streams, just in steps.
  Duration get _flushInterval => switch (_progs.length) {
    <= 32 => Duration.zero,
    <= 128 => const Duration(milliseconds: 50),
    <= 512 => const Duration(milliseconds: 100),
    _ => const Duration(milliseconds: 200),
  };

  /// Coalesces flushes to at most one per frame (and per [_flushInterval]): a
  /// token shows up within a frame of arriving, while a burst across many
  /// concurrent requests still rebuilds only once.
  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    final wait = _flushInterval - DateTime.now().difference(_lastFlush);
    void onFrame() => SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!_flushScheduled) return; // torn down meanwhile
      _flushScheduled = false;
      _flush();
    });
    if (wait > Duration.zero) {
      _flushDelay = Timer(wait, onFrame);
    } else {
      onFrame();
    }
  }

  void _finish(_Progress p, {required bool failed, String? error}) {
    if (p.status.isTerminal) return;
    p.status = failed
        ? BenchmarkRequestStatus.failed
        : BenchmarkRequestStatus.done;
    if (failed) p.error = error;
    p.endAt = DateTime.now();
    p.dirty = true;
    _settled++;
    if (_settled == 1 || _settled == _progs.length) {
      _flush();
    } else {
      _scheduleFlush();
    }
  }

  /// Folds the scratch progress into immutable request state. Per-request tok/s
  /// is decode speed (tokens since first token / decode time); once a request
  /// ends its `endAt` is fixed so its reading holds steady.
  void _flush() {
    final start = _startAt;
    if (start == null) return;
    final now = DateTime.now();
    _lastFlush = now;

    final requests = <BenchmarkRequest>[];
    for (final p in _progs) {
      // Settled and untouched since: its numbers are fixed.
      final published = p.published;
      if (published != null && !p.dirty && p.status.isTerminal) {
        requests.add(published);
        continue;
      }
      if (p.status.isTerminal ||
          _progs.length <= _watchAllUpTo ||
          _watched.containsKey(p.index)) {
        if (p.buffer.length != p.text.length) p.text = p.buffer.toString();
        if (p.reasoning.length != p.reasoningText.length) {
          p.reasoningText = p.reasoning.toString();
        }
      }
      p.dirty = false;
      final endRef = p.endAt ?? now;
      final decodeMs = p.firstTokenAt == null
          ? 0
          : endRef.difference(p.firstTokenAt!).inMilliseconds;
      // Rate of the tokens *after* the first, over the first→last interval.
      // Using (tokens-1) — and ignoring a sub-50ms warm-up while still
      // streaming — avoids the huge early spike from dividing a single token
      // by a near-zero elapsed time (which made avg tok/s start around 1000).
      final settled = p.status.isTerminal;
      final tps = (p.tokens > 1 && decodeMs > 0 && (settled || decodeMs >= 50))
          ? (p.tokens - 1) / (decodeMs / 1000.0)
          : 0.0;
      requests.add(
        p.published = BenchmarkRequest(
          index: p.index,
          status: p.status,
          text: p.text,
          reasoning: p.reasoningText,
          tokens: p.tokens,
          tokensPerSecond: tps,
          ttftMs: p.firstTokenAt?.difference(p.start).inMilliseconds,
          latencyMs: p.status.isTerminal
              ? (p.endAt ?? now).difference(p.start).inMilliseconds
              : null,
          finishReason: p.finishReason,
          error: p.error,
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
    final elapsedMs = now.difference(start).inMilliseconds;

    // Sample throughput for the chart, on a fixed cadence (flush is per-frame)
    // and always once at the end so the tail is captured. tps here is the live
    // aggregate rate of the requests still streaming — the real instantaneous
    // throughput, which ramps up then decays as requests finish.
    final dueForSample =
        _samples.isEmpty ||
        (elapsedMs - _samples.last.elapsedMs) >= _sampleIntervalMs ||
        !anyActive;
    if (dueForSample) {
      final streaming = requests
          .where((r) => r.status == BenchmarkRequestStatus.streaming)
          .toList();
      final liveTps = streaming.fold(0.0, (sum, r) => sum + r.tokensPerSecond);
      // Average over only the requests that have actually started decoding — a
      // request still in its prefill (no first token yet, so a 0 rate) is NOT
      // counted, or it would drag the per-request average down for exactly as
      // long as prefill takes. This is the same definition as the headline
      // AVG/REQ (meanRequestTps filters rate > 0); a finished request is
      // already excluded since only still-streaming ones are considered.
      final avgTps = meanRequestTps(streaming);
      final totalTokens = requests.fold(0, (sum, r) => sum + r.tokens);
      _samples.add(
        BenchmarkSample(
          elapsedMs: elapsedMs,
          tps: liveTps,
          avgTps: avgTps,
          tokens: totalTokens,
        ),
      );
      _samplesSnapshot = List.unmodifiable(_samples);
    }

    state = state.copyWith(
      requests: requests,
      elapsed: now.difference(start),
      isRunning: anyActive,
      frozenAggregate: frozen,
      samples: _samplesSnapshot,
    );
    if (!anyActive) _ticker?.cancel();
  }

  void _teardown() {
    _batch?.cancel();
    _batch = null;
    _ticker?.cancel();
    _flushDelay?.cancel();
    _progs = [];
    // A pending frame-callback flush becomes a no-op ([_flush] returns on a
    // null start), so it can't set state on a disposed notifier.
    _startAt = null;
    _flushScheduled = false;
  }
}
