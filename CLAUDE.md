# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

ZML-Lab is a **Flutter desktop (macOS) control panel** for launching and babysitting ML inference jobs — primarily `llmd`, a Zig/Bazel LLM server in the ZML monorepo — on a small fleet of machines (the local Mac plus remote GPU boxes reached over SSH). It is a focused working tool, not a metrics dashboard: dark-first, light-ready, restrained color reserved for status only, monospace for anything machine-ish.

The main surfaces (each is a `lib/features/<name>/`):
- **jobs** — the dashboard/home; a dense list of jobs (name, machine, command, port, status dot). "New job" sits above it.
- **new_job** — build a custom job (machine, command, working dir, port pre-filled with a free one, env vars, name/desc). Launch now, save as a config, or both.
- **configs** — saved launch configs; picking one opens the new-job form pre-filled.
- **job_detail** — dominated by a tmux-style terminal multiplexer on the job's real stdout (splittable panes, tabs, embedded web tabs). A collapsible actions panel does kill / restart / profiler / copy command / test endpoint. Has three modes: terminal, **benchmark**, **perf**.
- **benchmark** — fires a concurrent batch at `/v1/chat/completions`, shows per-request streaming + live/aggregate tok/s; any request expands into a multi-turn chat popup; runs can be saved (**saved_benchmarks**).
- **perf** — runs the monorepo's Go load generator (`tools/benchmark`) and mirrors its duckdb `report.sql` natively into live charts + a report.
- **machines** — the local box plus remote hosts (address, ssh port/user/key, hardware); live reachability dots.
- **settings** — theme, terminal font size, port range, health-check interval, benchmark/perf defaults.

## Commands

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # codegen (see below)
flutter run -d macos                                        # run the app

flutter analyze                                             # static analysis / lints
flutter test                                                # all tests
flutter test test/perf_stats_test.dart                      # a single test file
flutter test --name "substring"                             # a single test by name

flutter build macos --release   # → build/macos/Build/Products/Release/zml_lab.app
flutter build macos --debug     # use this to surface a compile error the analyzer missed
```

**Codegen is mandatory and committed.** riverpod, freezed, json_serializable, go_router_builder, and drift all generate `.g.dart` / `.freezed.dart` files that are **checked into git** (≈39 of them). After editing any annotated file (`@riverpod`, `@freezed`, `@DriftDatabase`, a `TypedGoRoute`, a table), re-run `build_runner`. For a tight loop use `dart run build_runner watch --delete-conflicting-outputs`.

**Iterate with hot reload, not full rebuilds.** A `flutter run` registers a DTD instance (`mcp__dart__dtd listDtdUris` shows a `ws://` URI); `dtd connect <uri>` then `mcp__dart__hot_reload` applies widget changes in ~1s with state preserved. Caveats:
- Hot reload keeps runtime state, so fixes to `initState` / focus / controller / lifecycle logic can show STALE behavior — `mcp__dart__hot_restart` (resets state, keeps the app) BEFORE assuming the code is wrong.
- **Any code change kills a running `llmd` job** — reload/restart tears down the isolate, closing the executor's PTY fds → the child gets SIGHUP and dies (and the router resets to `/`). When iterating on code that needs a live server, land the code first, then launch the job once and test without further reloads.
- Class-shape changes (e.g. `ConsumerWidget` → `ConsumerStatefulWidget`, removing an enum value) can't hot-reload — use `hot_restart`.
- Changed **assets** (fonts, wasm, images) need a full `flutter run` restart.

## Architecture

**No Material.** The app is built on `WidgetsApp.router` (`lib/app.dart`), not `MaterialApp`. UI comes from a custom design system: an `AppTheme` InheritedWidget + semantic color tokens in `lib/core/theme/` (`context.colors`, `context.text`), reusable widgets in `lib/core/widgets/`. Material *localizations* are provided only so the low-level `TextField` (used for real text selection) works. When you need a color/spacing/text style, pull it from the theme tokens — don't hardcode.

**Layering** (`lib/`):
- `core/` — cross-cutting: `theme/`, `router/`, `database/`, `execution/`, `widgets/`, `shell/` (title bar + sidebar), `providers/`, `logging/`, `util/`, `bootstrap.dart`.
- `models/` — freezed immutable models + enums (`job`, `launch_config`, `machine`, `benchmark`, `settings`, `perf_report`, …).
- `repositories/` — one per entity: an `abstract interface class` + a `Drift…` impl + a `@Riverpod(keepAlive: true)` provider. `mappers.dart` converts drift rows ⇄ models (and hand-encodes JSON blobs for types without json codegen, e.g. `BenchmarkRequest`).
- `features/<name>/{application,presentation[,domain]}` — `application/` holds `@riverpod` controllers/notifiers, `presentation/` holds widgets, `domain/` (perf only) holds pure logic.

**State management: riverpod, generator-only.** No hand-written providers — everything is `@riverpod` / `@Riverpod(keepAlive: true)`. Long-lived UI state (terminal mux, benchmark runs, profiler, job executor, settings) uses `keepAlive: true` family providers so it survives navigation. Codegen function providers take `Ref ref` (unified ref). `AsyncValue.value` is the nullable non-throwing accessor (`.valueOrNull` does not exist).

**Data: drift (SQLite), reactive.** Single `AppDatabase` (`core/database/database.dart`, tables in `tables.dart`). Reads are drift `.watch()` streams, so **any repository write auto-updates the whole UI** — there is no manual invalidation for data changes. Schema changes require bumping `schemaVersion` AND adding an `onUpgrade` step (see the existing migration chain, currently v10). The live DB file (macOS sandbox disabled) is `~/Documents/zml_lab.sqlite`. The DB starts empty; `ensureLocalMachine` (`core/bootstrap.dart`) seeds the `local` machine at startup.

**Routing: go_router via go_router_builder (typed).** Routes are declared as `TypedGoRoute` classes in `core/router/routes.dart`; a single `AppShellRoute` wraps every screen in the persistent shell (title bar + sidebar). **Gotcha: camelCase route params become kebab-case query keys** (`configId` → `?config-id=`). Always navigate via the typed route object (`NewCustomJobRoute(configId: id).go(context)`), never a hand-built URL string, or the param silently arrives null. The generated mixin is `$RouteName` (single `$`).

**Execution: jobs run REAL processes, and their lifetime is tied to the app.** `core/execution/job_executor.dart` `JobExecutor` (`@Riverpod(keepAlive: true)`, also a `ChangeNotifier`) is the supervisor: it owns a `Map<jobId, TerminalSession>` of live PTYs, launches/health-polls/kills them, and notifies the terminal to swap its borrowed session on restart. Local vs remote is inferred from `Machine.isLocal` (localhost address) — local runs `$SHELL -l -c "<cmd>"` directly, remote wraps the same command in `ssh -tt`. Closing the window kills all jobs (`stopAll` via a `WindowListener` in `main.dart`), and `markStaleStopped()` flips any leftover "running" DB rows to stopped on next launch. `$PORT`/`${PORT}` in a command is substituted with the job's port.

**Platform-specific code uses conditional exports**, so the app still compiles on web while real IO/terminals are native-only. The pattern is a facade file that re-exports a stub or an impl by `dart.library.io`:
- `core/execution/native_io.dart` → `native_io_stub.dart` | `native_io_impl.dart` (free-port scan, health/endpoint probes, port-listener kill, `streamChat`, expandUser).
- `features/job_detail/presentation/terminal_session.dart` → `terminal_session_web.dart` | `terminal_session_native.dart` (flterm controller + `flutter_pty` PTY on native, stub on web).
- `features/perf/domain/bench_runner.dart`, `core/logging/app_log.dart` follow the same shape.
When you add a native capability, add it to BOTH the impl and the stub so web keeps building.

## The terminal multiplexer (the app's most intricate piece)

`features/job_detail/presentation/job_terminal.dart`. Each pane is an flterm `TerminalController` on a PTY. Mux state (tabs / pane tree / sessions) lives in a `@Riverpod(keepAlive: true) terminalMux(ref, jobId)` family holder, NOT in the widget — so the layout and live shells survive navigating away and back. A job-detail terminal *borrows* the executor's session (so it shows real job stdout); a borrowed session must **never** be disposed by the mux (that would kill the job). If you touch this file, respect the hard-won invariants documented at length in the project memory — they cover GlobalKey-vs-ValueKey for panes (focus-tree churn), visual-state-driven focus, post-frame session disposal, and shell-exit handling. Teardown must never dispose a session or read `ref` synchronously against a live, on-screen `TerminalView` (it hard-crashes the app or throws unmount errors) — always navigate/unmount first, then dispose post-frame from a captured reference.

## High-leverage gotchas

- **`.select` on providers is exported by `flutter_riverpod`, not `riverpod_annotation`.** A file importing only `riverpod_annotation` passes the analyzer but fails the real build. Import `flutter_riverpod` or watch the whole state. (The analyzer/compiler disagreement is nasty — `flutter analyze` says clean, `flutter run` fails.)
- **Hot-reload `-32603` has two causes:** (a) a real frontend compile error the analyzer missed — run `flutter build macos --debug` to surface the message; (b) a hot-reload-illegal shape change (analyzer + full build both clean) — `hot_restart` applies it fine. Check (b) when the build passes.
- **`flterm` / `libghostty` are consumed from pub.dev, NOT the local checkout** at `~/Documents/Git-Repos/libghostty-dart`. They declare `resolution: workspace`, so a `path:` override errors out. `libghostty` is a native-assets package — needs `flutter config --enable-native-assets`.
- **Embedded WKWebView (web tabs) has strict interaction rules on macOS** — painting a Flutter layer *over* it snapshots it (kills clicks/scroll), and it has a "phantom hit region" that swallows taps on widgets over/near it. Floating panels use `OverlayPortal` + keyboard-only driving. See the project memory before editing web-tab UI.
- **Verify the UI without OS screen-recording permission** by running `flutter run -d web-server --web-port=8123` and driving Chrome via the browser MCP. (drift on web needs `web/sqlite3.wasm` + `web/drift_worker.js`.)
- **`llmd` is launched via Bazel**, e.g. `bazel run --@zml//platforms:metal=true //llmd:llmd -- --model=... --listen=127.0.0.1:$PORT` from the monorepo at `/Users/raph/Documents/Git-Repos/monorepo`. It serves an OpenAI-compatible API (`/v1/chat/completions`, `/v1/models`, `/health`) and shuts down cleanly only on SIGINT. Prefer `bazel build && bazel-bin/llmd/llmd …` over `bazel run` (the latter holds the workspace lock for the server's whole lifetime). Not every `~/models/<org>/<name>` dir has weights — check for `*.safetensors` first.

## Deeper context

The project memory (`~/.claude/projects/-Users-raph-Documents-Git-Repos-zml-lab/memory/`) holds far more detail on the terminal mux, benchmark/chat internals, the perf tab's duckdb parity invariant, real-execution mechanics, remote SSH/Tailscale specifics, and every platform-view lesson. Consult it (and verify against current code) before deep work on those subsystems.
