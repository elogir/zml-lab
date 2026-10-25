# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

ZML-Lab is a **Flutter desktop (macOS) control panel** for launching and benchmarking ML inference servers — primarily `llmd`, a Zig/Bazel LLM server built on ZML — on a small fleet of machines (the local Mac plus remote GPU boxes reached over SSH). It is a focused working tool, not a metrics dashboard: dark-first, light-ready, restrained color reserved for status only, monospace for anything machine-ish.

The main surfaces (each is a `lib/features/<name>/`):
- **Benchmark tab** (home, `/`, `features/perf/presentation/benchmark_tool_screen.dart`) — a target bar (machine or custom host + port), the **benchmark** / **perf** tools, and a resizable **terminal** panel beside them where the server under test is launched by hand.
- **terminal** — the tmux-style terminal multiplexer (splittable panes, tabs, embedded web tabs). New shells are always local; you ssh to a box by hand.
- **benchmark** — fires a concurrent batch at `/v1/chat/completions`, shows per-request streaming + live/aggregate tok/s; any request expands into a multi-turn chat popup; runs can be saved (**saved_benchmarks**).
- **perf** — runs the bundled load generator (prebuilt `native/libzmlbench.dylib`, over FFI) against the target with ShareGPT prompts (downloaded once from the tab) and turns its event stream into live charts + a report. Statistics follow the run format's definitions (`docs/perf-run-format.md`, checked against its SQL in `test/perf_contract_test.dart`); each run is recorded as a `.zmlrun.parquet`.
- **machines** — the local box plus remote hosts (name, address, hardware); live reachability dots (a ping).
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
- **Any code change kills an `llmd` running in the app's terminal** — reload/restart tears down the isolate, closing the terminal's PTY fds → the child gets SIGHUP and dies (and the router resets to `/`). When iterating on code that needs a live server, land the code first, then launch the server once and test without further reloads.
- Class-shape changes (e.g. `ConsumerWidget` → `ConsumerStatefulWidget`, removing an enum value) can't hot-reload — use `hot_restart`.
- Changed **assets** (fonts, wasm, images) need a full `flutter run` restart.

## Architecture

**No Material.** The app is built on `WidgetsApp.router` (`lib/app.dart`), not `MaterialApp`. UI comes from a custom design system: an `AppTheme` InheritedWidget + semantic color tokens in `lib/core/theme/` (`context.colors`, `context.text`), reusable widgets in `lib/core/widgets/`. Material *localizations* are provided only so the low-level `TextField` (used for real text selection) works. When you need a color/spacing/text style, pull it from the theme tokens — don't hardcode.

**Layering** (`lib/`):
- `core/` — cross-cutting: `theme/`, `router/`, `database/`, `execution/`, `widgets/`, `shell/` (title bar + sidebar), `providers/`, `logging/`, `util/`, `bootstrap.dart`.
- `models/` — freezed immutable models + enums (`machine`, `benchmark`, `settings`, `perf_report`, …).
- `repositories/` — one per entity: an `abstract interface class` + a `Drift…` impl + a `@Riverpod(keepAlive: true)` provider. `mappers.dart` converts drift rows ⇄ models (and hand-encodes JSON blobs for types without json codegen, e.g. `BenchmarkRequest`).
- `features/<name>/{application,presentation[,domain]}` — `application/` holds `@riverpod` controllers/notifiers, `presentation/` holds widgets, `domain/` (perf only) holds pure logic.

**State management: riverpod, generator-only.** No hand-written providers — everything is `@riverpod` / `@Riverpod(keepAlive: true)`. Long-lived UI state (terminal mux, benchmark runs, benchmark target, settings) uses `keepAlive: true` family providers so it survives navigation. Codegen function providers take `Ref ref` (unified ref). `AsyncValue.value` is the nullable non-throwing accessor (`.valueOrNull` does not exist).

**Data: drift (SQLite), reactive.** Single `AppDatabase` (`core/database/database.dart`, tables in `tables.dart`). Reads are drift `.watch()` streams, so **any repository write auto-updates the whole UI** — there is no manual invalidation for data changes. Schema changes require bumping `schemaVersion` AND adding an `onUpgrade` step (see the existing migration chain, currently v10). The live DB file (macOS sandbox disabled) is `~/Documents/zml_lab.sqlite`. The DB starts empty; `ensureLocalMachine` (`core/bootstrap.dart`) seeds the `local` machine at startup.

**Routing: go_router via go_router_builder (typed).** Routes are declared as `TypedGoRoute` classes in `core/router/routes.dart`; a single `AppShellRoute` wraps every screen in the persistent shell (title bar + sidebar). **Gotcha: camelCase route params become kebab-case query keys** (`machineId` → `?machine-id=`). Always navigate via the typed route object (`EditMachineRoute(id: id).go(context)`), never a hand-built URL string, or the param silently arrives null. The generated mixin is `$RouteName` (single `$`).

**Processes are started by hand in the terminal panel.** There is no job supervisor: each pane is a real PTY (`TerminalSession`) running the user's login shell, owned by the `terminalMux` keep-alive provider. Closing the window closes the PTYs (the shells SIGHUP their jobs). Fullscreen is shared state (`core/shell/app_fullscreen.dart`, `FullscreenSurface.terminal | perf`); a view tearing down only drops its own surface (`exitIf`).

**Platform-specific code uses conditional exports**, so the app still compiles on web while real IO/terminals are native-only. The pattern is a facade file that re-exports a stub or an impl by `dart.library.io`:
- `core/execution/native_io.dart` → `native_io_stub.dart` | `native_io_impl.dart` (`streamChat`, `pingHost` for the machine reachability dot).
- `features/terminal/presentation/terminal_session.dart` → `terminal_session_web.dart` | `terminal_session_native.dart` (flterm controller + `flutter_pty` PTY on native, stub on web).
- `features/perf/domain/bench_runner.dart`, `core/logging/app_log.dart` follow the same shape.
When you add a native capability, add it to BOTH the impl and the stub so web keeps building.

## The terminal multiplexer (the app's most intricate piece)

`features/terminal/presentation/terminal_mux.dart`. Each pane is an flterm `TerminalController` on a PTY. Mux state (tabs / pane tree / sessions) lives in a `@Riverpod(keepAlive: true) terminalMux(ref, muxId)` family holder, NOT in the widget — so the layout and live shells survive navigating away and back. The Benchmark tab keeps its `TerminalMux` under a `GlobalKey` so moving it in/out of fullscreen reparents rather than remounts it. If you touch this file, respect the hard-won invariants documented at length in the project memory — they cover GlobalKey-vs-ValueKey for panes (focus-tree churn), visual-state-driven focus, post-frame session disposal, and shell-exit handling. Teardown must never dispose a session or read `ref` synchronously against a live, on-screen `TerminalView` (it hard-crashes the app or throws unmount errors) — always navigate/unmount first, then dispose post-frame from a captured reference.

## Releases and self-updating

Pushing a `v<major>.<minor>.<patch>` tag runs `.github/workflows/release.yml`: it builds the macOS app with the version stamped in (`--dart-define=ZML_LAB_VERSION`), packs it as `zml-lab-macos.tar.gz`, signs it with Ed25519 (`tool/update_signing.dart`, key in the `ZML_LAB_UPDATE_KEY` secret, public half in `updatePublicKey`) and publishes a GitHub release. Installed release builds (`features/updates`) poll the latest release, verify the signature, unpack it with the system `tar` into `.zml-lab-update/` beside the app, and a detached `sh` script swaps it in after the app exits: via "Restart to update" in the sidebar, or on quit when the Auto update setting is on. Local builds have no stamped version and never update themselves. The swap never happens while the app runs: assets and `libzmlbench` are loaded from the bundle lazily.

## High-leverage gotchas

- **`.select` on providers is exported by `flutter_riverpod`, not `riverpod_annotation`.** A file importing only `riverpod_annotation` passes the analyzer but fails the real build. Import `flutter_riverpod` or watch the whole state. (The analyzer/compiler disagreement is nasty — `flutter analyze` says clean, `flutter run` fails.)
- **Hot-reload `-32603` has two causes:** (a) a real frontend compile error the analyzer missed — run `flutter build macos --debug` to surface the message; (b) a hot-reload-illegal shape change (analyzer + full build both clean) — `hot_restart` applies it fine. Check (b) when the build passes.
- **The perf benchmarker is a prebuilt library, not built here.** `hook/build.dart` bundles `native/libzmlbench.dylib` (gitignored; built elsewhere and copied in by hand — see `native/README.md`) as the `zmlbench` code asset. Without it the app builds but the Perf tab reports the library missing. A new or changed native asset needs a full `flutter run`, not a hot reload/restart.
- **`flterm` / `libghostty` are consumed from pub.dev, NOT a local checkout** of libghostty-dart. They declare `resolution: workspace`, so a `path:` override errors out. `libghostty` is a native-assets package — needs `flutter config --enable-native-assets`.
- **Embedded WKWebView (web tabs) has strict interaction rules on macOS** — painting a Flutter layer *over* it snapshots it (kills clicks/scroll), and it has a "phantom hit region" that swallows taps on widgets over/near it. Floating panels use `OverlayPortal` + keyboard-only driving. See the project memory before editing web-tab UI.
