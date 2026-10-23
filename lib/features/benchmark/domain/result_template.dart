import '../../../models/benchmark.dart';
import '../../../models/saved_benchmark.dart';
import '../../../models/settings.dart';

/// A finished benchmark reduced to what a "Copy results" template can
/// reference — built from a live run or a saved one, so both copy the same.
class BenchmarkResult {
  const BenchmarkResult({
    this.name = '',
    required this.machine,
    required this.endpoint,
    required this.model,
    required this.prompt,
    required this.batchSize,
    this.maxTokens,
    this.temperature,
    required this.requests,
    required this.aggregateTokensPerSecond,
    required this.elapsed,
    required this.at,
  });

  factory BenchmarkResult.fromRun(
    BenchmarkRun run, {
    required String machine,
    required String endpoint,
    DateTime? at,
  }) => BenchmarkResult(
    machine: machine,
    endpoint: endpoint,
    // What was actually sent: an empty field sends `zml_model`.
    model: run.model.isEmpty ? 'zml_model' : run.model,
    prompt: run.prompt,
    batchSize: run.requests.isEmpty ? run.batchSize : run.requests.length,
    maxTokens: run.maxTokens,
    temperature: run.temperature,
    requests: run.requests,
    aggregateTokensPerSecond: run.aggregateTokensPerSecond,
    elapsed: run.elapsed,
    at: at ?? DateTime.now(),
  );

  factory BenchmarkResult.fromSaved(SavedBenchmark b) => BenchmarkResult(
    name: b.name,
    machine: b.machineLabel,
    endpoint: b.endpoint,
    // Runs saved before the model was tracked.
    model: switch (b.model) {
      null => '?',
      '' => 'zml_model',
      final m => m,
    },
    prompt: b.prompt,
    batchSize: b.batchSize,
    maxTokens: b.maxTokens,
    temperature: b.temperature,
    requests: b.requests,
    aggregateTokensPerSecond: b.aggregateTokensPerSecond,
    elapsed: Duration(milliseconds: b.elapsedMs),
    at: b.createdAt,
  );

  /// A plausible finished run, for the template preview in Settings.
  factory BenchmarkResult.example() => BenchmarkResult(
    machine: 'orion',
    endpoint: 'orion:8000',
    model: 'Qwen/Qwen3-8B',
    prompt: defaultBenchmarkPrompt,
    batchSize: 16,
    maxTokens: 512,
    requests: [
      for (var i = 0; i < 16; i++)
        BenchmarkRequest(
          index: i,
          status: BenchmarkRequestStatus.done,
          tokens: 480 + i * 2,
          tokensPerSecond: 41.0 + (i % 5) * 0.8,
          ttftMs: 180 + i * 9,
          latencyMs: 11800 + i * 40,
          finishReason: 'stop',
        ),
    ],
    aggregateTokensPerSecond: 668.4,
    elapsed: const Duration(milliseconds: 12460),
    at: DateTime(2026, 10, 23, 14, 30),
  );

  /// The saved run's name; empty for a live run.
  final String name;
  final String machine;
  final String endpoint;
  final String model;
  final String prompt;
  final int batchSize;
  final int? maxTokens;
  final double? temperature;
  final List<BenchmarkRequest> requests;
  final double aggregateTokensPerSecond;
  final Duration elapsed;
  final DateTime at;
}

/// One placeholder a template can use, as `{name}`.
class ResultVariable {
  const ResultVariable(this.name, this.description);
  final String name;
  final String description;
}

/// Every placeholder, in the order the Settings reference lists them.
const resultVariables = <ResultVariable>[
  ResultVariable('model', 'model name sent'),
  ResultVariable('machine', 'machine it ran on'),
  ResultVariable('endpoint', 'host:port'),
  ResultVariable('name', 'saved run name (empty when live)'),
  ResultVariable('batch', 'requests in the batch'),
  ResultVariable('aggregate_tps', 'aggregate tok/s at full concurrency'),
  ResultVariable('avg_tps', 'mean tok/s per request'),
  ResultVariable('ttft_ms', 'median time to first token'),
  ResultVariable('ttft_p90_ms', 'p90 time to first token'),
  ResultVariable('latency_ms', 'median full-request latency'),
  ResultVariable('tokens', 'output tokens, all requests'),
  ResultVariable('tokens_avg', 'output tokens per request'),
  ResultVariable('ok', 'requests that finished'),
  ResultVariable('failed', 'requests that errored'),
  ResultVariable('truncated', 'replies cut off by a token limit'),
  ResultVariable('elapsed_s', 'wall time of the batch'),
  ResultVariable('max_tokens', 'output cap (∞ = none)'),
  ResultVariable('temperature', 'sampling temperature'),
  ResultVariable('prompt', 'the prompt sent'),
  ResultVariable('date', 'YYYY-MM-DD'),
  ResultVariable('time', 'HH:MM'),
];

/// The values for each of [resultVariables], formatted for pasting.
Map<String, String> resultValues(BenchmarkResult r) {
  final ttfts = [for (final q in r.requests) ?q.ttftMs]..sort();
  final latencies = [for (final q in r.requests) ?q.latencyMs]..sort();
  final tokens = r.requests.fold(0, (sum, q) => sum + q.tokens);
  final produced = r.requests.where((q) => q.tokens > 0).length;
  String two(int n) => n.toString().padLeft(2, '0');
  return {
    'model': r.model,
    'machine': r.machine,
    'endpoint': r.endpoint,
    'name': r.name,
    'batch': '${r.batchSize}',
    'aggregate_tps': r.aggregateTokensPerSecond.toStringAsFixed(1),
    'avg_tps': meanRequestTps(r.requests).toStringAsFixed(1),
    'ttft_ms': '${_median(ttfts)}',
    'ttft_p90_ms': '${_percentile(ttfts, 0.9)}',
    'latency_ms': '${_median(latencies)}',
    'tokens': '$tokens',
    'tokens_avg': produced == 0 ? '0' : '${(tokens / produced).round()}',
    'ok': '${_count(r, BenchmarkRequestStatus.done)}',
    'failed': '${_count(r, BenchmarkRequestStatus.failed)}',
    'truncated': '${r.requests.where((q) => q.truncated).length}',
    'elapsed_s': (r.elapsed.inMilliseconds / 1000).toStringAsFixed(1),
    'max_tokens': r.maxTokens?.toString() ?? '∞',
    'temperature': r.temperature?.toString() ?? 'default',
    'prompt': r.prompt,
    'date': '${r.at.year}-${two(r.at.month)}-${two(r.at.day)}',
    'time': '${two(r.at.hour)}:${two(r.at.minute)}',
  };
}

final _placeholder = RegExp(r'\{([a-z0-9_]+)\}');

/// Fills `{name}` placeholders in [template] from [values]. Unknown names are
/// left as typed, so literal braces (JSON, code) pass through untouched.
String renderResultTemplate(String template, Map<String, String> values) =>
    template.replaceAllMapped(
      _placeholder,
      (m) => values[m.group(1)!] ?? m.group(0)!,
    );

/// [renderResultTemplate] over [r]'s values.
String renderResult(String template, BenchmarkResult r) =>
    renderResultTemplate(template, resultValues(r));

int _count(BenchmarkResult r, BenchmarkRequestStatus status) =>
    r.requests.where((q) => q.status == status).length;

/// Same rule as [BenchmarkRun.medianTtftMs]: mean of the middle two when even.
int _median(List<int> sorted) {
  if (sorted.isEmpty) return 0;
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : ((sorted[mid - 1] + sorted[mid]) / 2).round();
}

/// Nearest-rank percentile of an ascending list.
int _percentile(List<int> sorted, double p) {
  if (sorted.isEmpty) return 0;
  final rank = (p * sorted.length).ceil().clamp(1, sorted.length);
  return sorted[rank - 1];
}

/// Starting points offered in Settings. The first is the default.
const resultTemplatePresets = <(String, String)>[
  ('Slack', defaultResultTemplate),
  (
    'One line',
    '{model} @ {machine} · bs {batch} · {aggregate_tps} tok/s aggregate · '
        '{avg_tps} tok/s/req · TTFT {ttft_ms} ms',
  ),
  (
    'Markdown table',
    '| model | machine | batch | aggregate tok/s | per-req tok/s | TTFT ms | elapsed s |\n'
        '|---|---|---|---|---|---|---|\n'
        '| {model} | {machine} | {batch} | {aggregate_tps} | {avg_tps} | {ttft_ms} | {elapsed_s} |',
  ),
  (
    'Spreadsheet row',
    '{date}\t{model}\t{machine}\t{batch}\t{aggregate_tps}\t{avg_tps}\t'
        '{ttft_ms}\t{elapsed_s}',
  ),
];
