// Web: the database lives in the browser (drift's web options), so these
// native paths are never used.

String appDataDir() => '';

Future<String> appDatabasePath() async => 'zml_lab.sqlite';

String legacyDatabaseDir() => '';
