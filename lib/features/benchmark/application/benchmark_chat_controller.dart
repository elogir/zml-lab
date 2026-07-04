import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../models/benchmark.dart';
import '../../../models/benchmark_chat.dart';
import 'benchmark_controller.dart';

part 'benchmark_chat_controller.g.dart';

/// Canned replies, cycled through to fake a streaming chat. Purely presentation
/// stand-ins until a real endpoint is wired up.
const _replies = <String>[
  'Good question. The short version: it depends on where the bottleneck is. '
      'If you are memory-bound during decode, a larger batch of concurrent '
      'requests helps far more than adding devices, because each step is '
      'already latency-bound on a single token.',
  'You can push the batch higher until the KV-cache pool is exhausted — after '
      'that the scheduler queues new requests rather than admitting them, so '
      'throughput plateaus and per-request latency climbs. Watch the cache '
      'occupancy, not just GPU utilisation.',
  'For a 70B model on a single node, tensor parallelism across the GPUs keeps '
      'per-device memory manageable and the NVLink fabric hides most of the '
      'all-reduce cost. Across nodes you would reach for pipeline parallelism '
      'instead and eat a small bubble at the batch edges.',
  'Prefill and decode behave differently: prefill is compute-bound and scales '
      'with more devices, decode is memory-bound and scales with concurrency. '
      'Tuning them together is usually what moves aggregate tokens/sec.',
  'Yes — that is expected. As requests in the batch finish, the survivors get '
      'a larger share of the server and speed up, so the per-request rate rises '
      'even though the aggregate at full concurrency is the number to quote.',
];

/// Drives a chat with a job's endpoint inside the benchmark focus popup. Seeded
/// (per job + request) from the clicked benchmark request; each [send] appends
/// the user's prompt and streams a single reply token-by-token.
@riverpod
class BenchmarkChatController extends _$BenchmarkChatController {
  Timer? _ticker;
  final _rng = Random();
  int _replyCursor = 0;

  DateTime? _turnStart;
  double _rate = 0;
  int _target = 0;
  int _ttftMs = 0;

  @override
  BenchmarkChat build(String jobId, int index) {
    ref.onDispose(() => _ticker?.cancel());
    // Seed the first turn from the request that was opened: its prompt and the
    // reply it already produced. Read (not watch) — the chat is a snapshot the
    // user drives from here, not a live mirror of the batch.
    final run = ref.read(benchmarkControllerProvider(jobId));
    final request = run.requests.firstWhere(
      (r) => r.index == index,
      orElse: () => BenchmarkRequest(index: index),
    );
    return BenchmarkChat(
      turns: [
        ChatTurn(fromUser: true, text: run.prompt),
        ChatTurn(
          fromUser: false,
          text: request.text,
          tokensPerSecond: request.tokensPerSecond,
        ),
      ],
    );
  }

  /// Fire a single request: append the user's prompt and an empty reply, then
  /// stream the reply in.
  void send(String prompt) {
    if (prompt.trim().isEmpty || state.isStreaming) return;
    _ticker?.cancel();

    final reply = _replies[_replyCursor % _replies.length];
    _replyCursor++;
    _target = reply.split(' ').length;
    _rate = 28 + _rng.nextDouble() * 22;
    _ttftMs = 80 + _rng.nextInt(160);
    _turnStart = DateTime.now();

    state = state.copyWith(
      turns: [
        ...state.turns,
        ChatTurn(fromUser: true, text: prompt),
        const ChatTurn(fromUser: false, streaming: true),
      ],
    );
    _ticker = Timer.periodic(
      const Duration(milliseconds: 60),
      (_) => _tick(reply),
    );
  }

  void _tick(String reply) {
    final start = _turnStart;
    if (start == null) return;
    final elapsedMs = DateTime.now().difference(start).inMilliseconds;
    final produced = ((elapsedMs - _ttftMs) / 1000.0 * _rate).floor();
    final tokens = produced.clamp(0, _target);
    final done = tokens >= _target;
    final words = reply.split(' ');

    final turns = [...state.turns];
    turns[turns.length - 1] = ChatTurn(
      fromUser: false,
      text: words.take(tokens).join(' '),
      streaming: !done,
      tokensPerSecond: done
          ? turns.last.tokensPerSecond
          : (_rate + (_rng.nextDouble() * 6 - 3)).clamp(1, 999),
    );
    state = state.copyWith(turns: turns);
    if (done) _ticker?.cancel();
  }
}
