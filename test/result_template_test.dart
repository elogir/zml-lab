import 'package:flutter_test/flutter_test.dart';
import 'package:zml_lab/features/benchmark/domain/result_template.dart';
import 'package:zml_lab/models/benchmark.dart';
import 'package:zml_lab/models/saved_benchmark.dart';
import 'package:zml_lab/models/settings.dart';

BenchmarkRequest _req(
  int i, {
  BenchmarkRequestStatus status = BenchmarkRequestStatus.done,
  int tokens = 100,
  double tps = 50,
  int? ttft,
  int? latency,
  String? finish = 'stop',
}) => BenchmarkRequest(
  index: i,
  status: status,
  tokens: tokens,
  tokensPerSecond: tps,
  ttftMs: ttft,
  latencyMs: latency,
  finishReason: finish,
);

void main() {
  final run = BenchmarkRun(
    prompt: 'hi',
    batchSize: 4,
    maxTokens: 256,
    requests: [
      _req(0, ttft: 100, latency: 1000, tps: 40),
      _req(1, ttft: 200, latency: 2000, tps: 60, finish: 'length'),
      _req(2, ttft: 300, latency: 3000, tps: 50),
      _req(
        3,
        status: BenchmarkRequestStatus.failed,
        tokens: 0,
        tps: 0,
        finish: null,
      ),
    ],
    elapsed: const Duration(milliseconds: 3456),
    frozenAggregate: 150,
  );
  final at = DateTime(2026, 3, 7, 9, 5);
  final values = resultValues(
    BenchmarkResult.fromRun(
      run,
      machine: 'orion',
      endpoint: 'orion:8000',
      at: at,
    ),
  );

  test('every listed variable has a value', () {
    expect(values.keys.toSet(), resultVariables.map((v) => v.name).toSet());
  });

  test('values are computed and formatted from the run', () {
    expect(values['model'], 'zml_model'); // empty field sends zml_model
    expect(values['batch'], '4');
    expect(values['aggregate_tps'], '150.0');
    expect(values['avg_tps'], '50.0'); // failed request (0 tok/s) excluded
    expect(values['ttft_ms'], '200');
    expect(values['ttft_p90_ms'], '300');
    expect(values['latency_ms'], '2000');
    expect(values['tokens'], '300');
    expect(values['tokens_avg'], '100');
    expect(values['ok'], '3');
    expect(values['failed'], '1');
    expect(values['truncated'], '1');
    expect(values['elapsed_s'], '3.5');
    expect(values['max_tokens'], '256');
    expect(values['temperature'], 'default');
    expect(values['date'], '2026-03-07');
    expect(values['time'], '09:05');
  });

  test('unknown placeholders and other braces pass through', () {
    expect(
      renderResultTemplate('{"tps": {aggregate_tps}, "x": {nope}}', values),
      '{"tps": 150.0, "x": {nope}}',
    );
  });

  test('the default template renders with nothing left unfilled', () {
    final out = renderResultTemplate(defaultResultTemplate, values);
    expect(out, isNot(contains('{')));
    expect(out, contains('*150.0 tok/s*'));
  });

  test('presets only use known placeholders', () {
    for (final (name, template) in resultTemplatePresets) {
      expect(
        renderResultTemplate(template, values),
        isNot(matches(RegExp(r'\{[a-z0-9_]+\}'))),
        reason: name,
      );
    }
  });

  test('saved runs without a tracked model show ?', () {
    final saved = SavedBenchmark(
      id: 'b',
      name: 'old run',
      endpoint: 'vega:8001',
      prompt: 'hi',
      batchSize: 2,
      aggregateTokensPerSecond: 12.34,
      completed: 2,
      medianTtftMs: 0,
      elapsedMs: 1000,
      createdAt: at,
    );
    final v = resultValues(BenchmarkResult.fromSaved(saved));
    expect(v['model'], '?');
    expect(v['name'], 'old run');
    expect(v['machine'], 'vega');
    expect(v['aggregate_tps'], '12.3');
    expect(v['max_tokens'], '∞');
  });
}
