import 'package:drift/drift.dart';

/// Remote hosts jobs run on.
@DataClassName('MachineRow')
class Machines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  IntColumn get sshPort => integer().withDefault(const Constant(22))();
  TextColumn get user => text().nullable()();
  TextColumn get sshKey => text().nullable()();

  /// [Vendor.name], or null if unknown.
  TextColumn get vendor => text().nullable()();
  TextColumn get gpus => text().nullable()();
  TextColumn get memory => text().nullable()();
  BoolColumn get online => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Reusable saved launch presets.
@DataClassName('LaunchConfigRow')
class LaunchConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get machineId => text()();
  TextColumn get command => text()();
  TextColumn get workingDir => text().nullable()();
  IntColumn get port => integer()();

  /// JSON-encoded `List<EnvVar>`.
  TextColumn get envJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Named snapshots of completed benchmark runs.
@DataClassName('SavedBenchmarkRow')
class SavedBenchmarks extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get endpoint => text()();

  /// The machine it ran on, for display. Nullable: rows saved before this
  /// column existed fall back to the endpoint's host part.
  TextColumn get machineName => text().nullable()();

  /// The job's launch command at save time.
  TextColumn get command => text().withDefault(const Constant(''))();
  TextColumn get prompt => text()();
  IntColumn get batchSize => integer()();
  RealColumn get aggregateTokensPerSecond => real()();
  IntColumn get completed => integer()();
  IntColumn get medianTtftMs => integer()();
  IntColumn get elapsedMs => integer()();
  DateTimeColumn get createdAt => dateTime()();

  /// JSON-encoded `List<BenchmarkRequest>` — the saved per-request responses.
  TextColumn get requestsJson => text().withDefault(const Constant('[]'))();

  /// JSON-encoded `List<BenchmarkSample>` — the throughput time-series.
  TextColumn get samplesJson => text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Saved perf benchmark reports (runs of the monorepo's tools/benchmark load
/// generator). Scalar columns cover what the list cards show; the full report
/// (stats table, time series, per-request data) lives in [reportJson].
@DataClassName('PerfReportRow')
class PerfReports extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get machineName => text()();
  TextColumn get endpoint => text()();

  /// Server type the tool detected ('zml', 'vllm', 'openai', 'unknown').
  TextColumn get server => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get totalRequests => integer()();
  RealColumn get tokensPerSecond => real()();
  RealColumn get requestsPerSecond => real()();

  /// JSON-encoded remainder of the [PerfReport].
  TextColumn get reportJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// App-wide preferences as a key/value store (values stringified). One row
/// per setting; absent keys mean "use the built-in default".
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Visited URLs for the web-tab address bar history/autocomplete.
@DataClassName('BrowserHistoryRow')
class BrowserHistoryEntries extends Table {
  TextColumn get url => text()();
  DateTimeColumn get visitedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {url};
}

/// Launched (or once-launched) processes.
@DataClassName('JobRow')
class Jobs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get machineId => text()();
  TextColumn get command => text()();
  TextColumn get workingDir => text().nullable()();
  IntColumn get port => integer()();

  /// The saved config this job launched from, if any.
  TextColumn get configId => text().nullable()();

  /// [JobStatus.name].
  TextColumn get status => text()();
  TextColumn get envJson => text().withDefault(const Constant('[]'))();
  IntColumn get pid => integer().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
