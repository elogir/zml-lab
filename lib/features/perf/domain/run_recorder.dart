// Recording perf runs as `.jsonl.gz` files (docs/perf-run-format.md):
// the event stream is spooled to disk during the run, then turned with the
// zml-smi samples into the run's gzipped JSON Lines. Native only.
export 'run_recorder_stub.dart' if (dart.library.io) 'run_recorder_io.dart';
