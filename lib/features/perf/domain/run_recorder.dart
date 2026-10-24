// Recording perf runs as `.zmlrun.parquet` files (docs/perf-run-format.md):
// the event stream and zml-smi samples are spooled to disk during the run,
// then embedded DuckDB turns them into the run's Parquet file. Native only.
export 'run_recorder_stub.dart' if (dart.library.io) 'run_recorder_io.dart';
