# ZML-Lab

A macOS control panel for launching and babysitting LLM inference jobs
(primarily [llmd](https://github.com/zml/zml)) on your own machines — local or
remote over SSH. One calm place to start servers, watch their output, poke
their endpoints, and measure them.

## What it does

- **Jobs** — launch from saved configs or a custom command, live status
  (silent TCP health probes), kill / force-kill / restart, delete.
- **Terminal** — each job opens on its real stdout in a tmux-style
  multiplexer: tabs, splits, web tabs. New terminals on a remote job ssh in
  automatically.
- **Benchmark** — fire a concurrent batch at `/v1/chat/completions`, watch
  per-request streams and aggregate tok/s, expand any request into a chat,
  save runs for later.
- **Profiler** — capture an `x-zml-profiler` trace and serve it with xprof in
  an embedded tab, local or port-forwarded over ssh.
- **Machines** — the local box plus remote GPU hosts (address, ssh port/key),
  with live reachability dots.

## Install

Download `ZML-Lab.dmg` from the
[latest release](https://github.com/elogir/zml-lab/releases/latest), open it
and drag ZML-Lab onto Applications. The app is signed with our own
certificate, not Apple's, so the first launch is blocked as from an
unidentified developer: open System Settings → Privacy & Security and click
**Open Anyway** (once). Or install without the download quarantine:

```sh
curl -fsSL https://github.com/elogir/zml-lab/releases/latest/download/zml-lab-macos.tar.gz | tar -xz -C /Applications
```

After that it updates itself (Settings → Updates), keeping its permissions.
Data lives in `~/Library/Application Support/ZML-Lab`; builds before 0.1.4
kept the database in `~/Documents`, which Settings → Data → Import brings
over.

## Run it

```sh
flutter pub get
dart run build_runner build     # riverpod / freezed / drift codegen
flutter run -d macos
```

Release build: `flutter build macos --release` →
`build/macos/Build/Products/Release/ZML-Lab.app`.

Built with Flutter (no Material — custom widgets over `WidgetsApp`), riverpod,
drift, and [flterm](https://pub.dev/packages/flterm).
