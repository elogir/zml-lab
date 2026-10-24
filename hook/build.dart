import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

/// Bundles the Go benchmarker, built as a shared library, for the
/// perf tab to load over FFI.
///
/// The library is prebuilt with Bazel:
///
///     bazel build -c opt //tools/benchmark:zmlbench
///
/// and picked up from `bazel-out/<config>/bin/tools/benchmark/`.
/// Where the benchmarker source is comes from the `bench_source_dir` user-define
/// (`hooks: user_defines: zml_lab: bench_source_dir: …` in pubspec.yaml), else
/// the usual checkout locations under $HOME. `benchmark_lib` points at a
/// library file directly instead.
///
/// With no prebuilt library (or one for another architecture) the hook falls
/// back to `go build -buildmode=c-shared` when Go is installed. Without
/// either the app still builds, just without the library — the perf tab
/// says so.
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final code = input.config.code;
    if (code.targetOS != OS.macOS) return;
    final arch = switch (code.targetArchitecture) {
      Architecture.arm64 => (go: 'arm64', clang: 'arm64'),
      Architecture.x64 => (go: 'amd64', clang: 'x86_64'),
      final a => throw UnsupportedError('benchmark library: no Go arch for $a'),
    };

    final lib = File.fromUri(
      input.outputDirectory.resolve(code.targetOS.dylibFileName('zmlbench')),
    );
    final benchSource = _benchSourceDir(input);
    final prebuilt = _prebuilt(input, benchSource);
    final Uri dependency;
    if (prebuilt != null &&
        await _archs(prebuilt).then((a) => a.contains(arch.clang))) {
      await prebuilt.copy(lib.path);
      dependency = prebuilt.uri;
    } else {
      final go = _goBinary();
      final dir = benchSource == null
          ? null
          : Directory('${benchSource.path}/tools/benchmark');
      if (go == null || dir == null) {
        stderr.writeln(
          'zml_lab: not bundling the benchmark library — run '
          '`bazel build //tools/benchmark:zmlbench` '
          '(${benchSource?.path ?? 'not found: set hooks.user_defines.zml_lab.bench_source_dir'}).',
        );
        return;
      }
      await _goBuild(go, dir, lib, arch, '${code.macOS.targetVersion}');
      dependency = dir.uri;
      output.dependencies.addAll(_goSources(dir));
    }

    output.dependencies.add(dependency);
    // A build in a new configuration should be picked up too.
    final bazelOut = Directory('${benchSource?.path}/bazel-out');
    if (benchSource != null && bazelOut.existsSync()) {
      output.dependencies.add(bazelOut.uri);
    }
    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'zmlbench.dart',
        linkMode: DynamicLoadingBundled(),
        file: lib.uri,
      ),
    );
  });
}

Directory? _benchSourceDir(BuildInput input) {
  final defined = input.userDefines.path('bench_source_dir');
  final home = Platform.environment['HOME'];
  final candidates = [
    if (defined != null) Directory.fromUri(defined),
    if (home != null) ...[
      Directory('$home/benchmark'),
      Directory('$home/src/benchmark'),
    ],
  ];
  return candidates
      .where((d) => File('${d.path}/tools/benchmark/capi/capi.go').existsSync())
      .firstOrNull;
}

/// `benchmark_lib` if set, else the newest Bazel build of the library in any
/// configuration (`-c opt`, the default dbg, …) — bazel-bin only points at
/// whichever configuration built last.
File? _prebuilt(BuildInput input, Directory? benchSource) {
  final defined = input.userDefines.path('benchmark_lib');
  if (defined != null) {
    final f = File.fromUri(defined);
    return f.existsSync() ? f : null;
  }
  final out = Directory('${benchSource?.path}/bazel-out');
  if (benchSource == null || !out.existsSync()) return null;
  // Resolved: bazel-out is a symlink into the output base, and the build
  // cache should track the real file.
  final builds = [
    for (final config in out.listSync().whereType<Directory>())
      File('${config.path}/bin/tools/benchmark/libzmlbench.dylib'),
  ].where((f) => f.existsSync()).map((f) => File(f.resolveSymbolicLinksSync()));
  return builds.sortedByMtime().lastOrNull;
}

extension on Iterable<File> {
  List<File> sortedByMtime() {
    final files = [for (final f in this) (f, f.lastModifiedSync())];
    files.sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (f, _) in files) f];
  }
}

/// The architectures a Mach-O file holds (`lipo -archs`).
Future<List<String>> _archs(File lib) async {
  final r = await Process.run('/usr/bin/lipo', ['-archs', lib.path]);
  return r.exitCode == 0 ? '${r.stdout}'.trim().split(' ') : const [];
}

Future<void> _goBuild(
  String go,
  Directory dir,
  File lib,
  ({String go, String clang}) arch,
  String macosVersion,
) async {
  final minVersion = '-mmacosx-version-min=$macosVersion';
  final result = await Process.run(
    go,
    ['build', '-buildmode=c-shared', '-trimpath', '-o', lib.path, './capi'],
    workingDirectory: dir.path,
    environment: {
      'CGO_ENABLED': '1',
      'GOOS': 'darwin',
      'GOARCH': arch.go,
      'CC': 'clang -arch ${arch.clang}',
      'CGO_CFLAGS': minVersion,
      'CGO_LDFLAGS': minVersion,
      'MACOSX_DEPLOYMENT_TARGET': macosVersion,
    },
  );
  if (result.exitCode != 0) {
    throw Exception(
      'go build of the benchmark library failed:\n'
      '${result.stderr}${result.stdout}',
    );
  }
}

/// `go` on PATH, else the usual install locations (an IDE-launched build may
/// not have Homebrew on PATH).
String? _goBinary() {
  final path = Platform.environment['PATH'] ?? '';
  final candidates = [
    for (final p in path.split(':'))
      if (p.isNotEmpty) '$p/go',
    '/opt/homebrew/bin/go',
    '/usr/local/go/bin/go',
    '/usr/local/bin/go',
  ];
  return candidates.where((p) => File(p).existsSync()).firstOrNull;
}

/// The Go build's inputs: rebuilding is needed when any of these change.
List<Uri> _goSources(Directory dir) => [
  for (final f in dir.listSync(recursive: true).whereType<File>())
    if (f.path.endsWith('.go') ||
        f.path.endsWith('/go.mod') ||
        f.path.endsWith('/go.sum'))
      f.uri,
];
