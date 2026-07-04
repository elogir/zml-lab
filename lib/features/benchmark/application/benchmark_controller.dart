import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/benchmark.dart';

part 'benchmark_controller.g.dart';

const defaultBenchmarkPrompt =
    'Summarize the tradeoffs between tensor and pipeline parallelism '
    'for large models.';

/// Canned completions, revealed token-by-token to fake streaming.
const _answers = <String>[
  'Tensor parallelism shards each layer across GPUs, so every device holds a '
      'slice of the same weight matrix and they exchange activations with an '
      'all-reduce on every step. That keeps per-GPU memory low but makes the '
      'interconnect the bottleneck — it only pays off inside a single node '
      'with fast NVLink or equivalent fabric.',
  'The throughput you observe depends far more on the KV-cache budget than on '
      'raw FLOPs once the model fits in memory. Each concurrent request '
      'reserves cache proportional to its context length, so the scheduler '
      'admits requests until that pool is exhausted and queues the remainder.',
  'A clean way to reason about this is to separate prefill from decode. '
      'Prefill is compute-heavy and parallel across the whole prompt, so it '
      'scales well with more devices and larger batches. Decode is '
      'memory-bound and inherently sequential, one token at a time, so it '
      'benefits from a larger batch of concurrent requests instead.',
  'Pipeline parallelism splits the model by layers across devices and streams '
      'micro-batches through the stages. It tolerates slower links between '
      'nodes, but a bubble forms at the start and end of each batch, so you '
      'trade some latency for the ability to span more machines cheaply.',
];

/// Drives a fake benchmark run: a batch of requests that stream tokens with
/// live per-request and aggregate throughput. Cancelable mid-flight.
@riverpod
class BenchmarkController extends _$BenchmarkController {
  Timer? _ticker;
  final _rng = Random();
  DateTime? _startAt;
  List<double> _rates = const [];
  List<int> _targets = const [];

  @override
  BenchmarkRun build(String jobId) {
    ref.onDispose(() => _ticker?.cancel());
    return const BenchmarkRun(prompt: defaultBenchmarkPrompt, batchSize: 8);
  }

  void setPrompt(String prompt) => state = state.copyWith(prompt: prompt);

  void setBatchSize(int size) =>
      state = state.copyWith(batchSize: size.clamp(1, 64));

  void start() {
    _ticker?.cancel();
    final n = state.batchSize;
    _startAt = DateTime.now();
    _rates = List.generate(n, (_) => 30 + _rng.nextDouble() * 15);
    _targets = List.generate(n, (i) => _answers[i % _answers.length].split(' ').length);
    state = state.copyWith(
      isRunning: true,
      elapsed: Duration.zero,
      requests: List.generate(
        n,
        (i) => BenchmarkRequest(
          index: i + 1,
          status: BenchmarkRequestStatus.streaming,
        ),
      ),
    );
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void cancel() {
    _ticker?.cancel();
    state = state.copyWith(
      isRunning: false,
      requests: [
        for (final r in state.requests)
          r.status == BenchmarkRequestStatus.streaming
              ? r.copyWith(status: BenchmarkRequestStatus.done)
              : r,
      ],
    );
  }

  void _tick() {
    final start = _startAt;
    if (start == null) return;
    final elapsed = DateTime.now().difference(start);

    var anyStreaming = false;
    final next = <BenchmarkRequest>[];
    for (final r in state.requests) {
      if (r.status.isTerminal) {
        next.add(r);
        continue;
      }
      final i = r.index - 1;
      final rate = _rates[i];
      final target = _targets[i];
      final ttft = r.ttftMs ?? (90 + _rng.nextInt(190));
      final produced =
          ((elapsed.inMilliseconds - ttft) / 1000.0 * rate).floor();
      final tokens = produced.clamp(0, target);
      final done = tokens >= target;
      anyStreaming = anyStreaming || !done;
      next.add(
        r.copyWith(
          status: done
              ? BenchmarkRequestStatus.done
              : BenchmarkRequestStatus.streaming,
          ttftMs: ttft,
          tokens: tokens,
          tokensPerSecond: done
              ? r.tokensPerSecond
              : (rate + (_rng.nextDouble() * 6 - 3)).clamp(1, 999),
          latencyMs: done ? elapsed.inMilliseconds : null,
          text: _reveal(i, tokens),
        ),
      );
    }

    state = state.copyWith(
      requests: next,
      elapsed: elapsed,
      isRunning: anyStreaming,
    );
    if (!anyStreaming) _ticker?.cancel();
  }

  String _reveal(int index, int tokens) {
    final words = _answers[index % _answers.length].split(' ');
    return words.take(tokens).join(' ');
  }
}
