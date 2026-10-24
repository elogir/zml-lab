/// One benchmark run's settings — the CLI's flags, as the C API's JSON.
class BenchLibConfig {
  const BenchLibConfig({
    required this.url,
    required this.inputFile,
    this.apiKey,
    this.model = '',
    this.concurrency = 128,
    this.durationSeconds = 0,
    this.maxCompletionTokens,
    this.ignoreEos = false,
    this.mode = 'all',
    this.sequenceType = 'long',
  });

  /// The API root. Keep the trailing slash on `/v1/`: openai-go resolves
  /// routes RFC 3986-relative to it.
  final String url;

  /// A ShareGPT JSON file.
  final String inputFile;
  final String? apiKey;
  final String model;
  final int concurrency;

  /// 0 runs until stopped (or the dataset runs out).
  final int durationSeconds;
  final int? maxCompletionTokens;

  /// Generate past EOS up to [maxCompletionTokens] (sends `ignore_eos`: an
  /// OpenAI-spec extension llmd, vLLM and SGLang support).
  final bool ignoreEos;
  final String mode;
  final String sequenceType;

  Map<String, Object> toJson() => {
    'url': url,
    'input_file': inputFile,
    if (apiKey != null && apiKey!.isNotEmpty) 'api_key': apiKey!,
    if (model.isNotEmpty) 'model': model,
    'concurrency': concurrency,
    'duration_s': durationSeconds,
    'max_completion_tokens': ?maxCompletionTokens,
    if (ignoreEos) 'ignore_eos': true,
    'mode': mode,
    'sequence_type': sequenceType,
  };
}

/// How a run ended (the C API's done event).
class BenchLibSummary {
  const BenchLibSummary({
    this.error,
    this.server,
    this.events = 0,
    this.errors = 0,
    this.elapsed = Duration.zero,
  });

  factory BenchLibSummary.fromJson(Map<String, dynamic> json) =>
      BenchLibSummary(
        error: json['error'] as String?,
        server: json['server'] as String?,
        events: (json['events'] as num?)?.toInt() ?? 0,
        errors: (json['errors'] as num?)?.toInt() ?? 0,
        elapsed: Duration(
          milliseconds: (json['elapsed_ms'] as num?)?.toInt() ?? 0,
        ),
      );

  /// Why the run failed to start or aborted; null when it ran.
  final String? error;
  final String? server;

  /// Events (CSV rows) written.
  final int events;

  /// Requests that failed.
  final int errors;
  final Duration elapsed;
}

/// A started run.
abstract interface class BenchLibRun {
  /// Asks the run to finish: in-flight requests are cancelled, the remaining
  /// CSV is delivered, then [done] completes. Like the CLI's first Ctrl-C.
  void stop();

  /// Completes once the run is over and every CSV chunk was delivered.
  Future<BenchLibSummary> get done;
}
