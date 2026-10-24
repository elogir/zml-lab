# native/

Prebuilt native libraries the app bundles (see `hook/build.dart`).

- `libzmlbench.dylib` — the perf benchmarker (C API: `zmlbench_start`,
  `_stop`, `_free`, `_version`). Not built here and not committed: copy a
  built one in, then do a full `flutter run`.

  Without it the app still builds; the Perf tab reports the library
  missing.
