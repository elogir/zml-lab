import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

/// Bundles the perf benchmarker — a prebuilt C shared library — with the app,
/// for the Perf tab to load over FFI (lib/features/perf/domain/bench_lib.dart).
///
/// The library isn't built here: drop it in as `native/libzmlbench.dylib`
/// (built elsewhere, e.g. `bazel build -c opt //tools/benchmark:zmlbench`
/// and copied in). Without it — or with one for another architecture —
/// the app still builds, just without the library; the Perf tab says so.
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final code = input.config.code;
    if (code.targetOS != OS.macOS) return;
    final arch = switch (code.targetArchitecture) {
      Architecture.arm64 => 'arm64',
      Architecture.x64 => 'x86_64',
      final a => throw UnsupportedError('benchmark library: no slice for $a'),
    };

    final prebuilt = File.fromUri(
      input.packageRoot.resolve('native/libzmlbench.dylib'),
    );
    // Picked up (or noticed gone) on the next build.
    output.dependencies.add(prebuilt.parent.uri);
    if (!prebuilt.existsSync()) {
      stderr.writeln(
        'zml_lab: native/libzmlbench.dylib not found — the perf '
        'benchmarker is not bundled.',
      );
      return;
    }
    output.dependencies.add(prebuilt.uri);
    if (!(await _archs(prebuilt)).contains(arch)) {
      stderr.writeln(
        'zml_lab: native/libzmlbench.dylib has no $arch slice — the perf '
        'benchmarker is not bundled for $arch.',
      );
      return;
    }

    final lib = File.fromUri(
      input.outputDirectory.resolve(code.targetOS.dylibFileName('zmlbench')),
    );
    await prebuilt.copy(lib.path);
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

/// The architectures a Mach-O file holds (`lipo -archs`).
Future<List<String>> _archs(File lib) async {
  final r = await Process.run('/usr/bin/lipo', ['-archs', lib.path]);
  return r.exitCode == 0 ? '${r.stdout}'.trim().split(' ') : const [];
}
