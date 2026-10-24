import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

/// Builds the perf benchmarker — the Go library in `native/zmlbench` — as a
/// shared library and bundles it with the app, for the Perf tab to load over
/// FFI (lib/features/perf/domain/bench_lib.dart).
///
/// Needs Go at build time. Without it the app still builds, just without the
/// library — the Perf tab says so.
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

    final source = Directory.fromUri(
      input.packageRoot.resolve('native/zmlbench/'),
    );
    output.dependencies.addAll(_goSources(source));
    final go = _goBinary();
    if (go == null) {
      stderr.writeln(
        'zml_lab: go not found — the perf benchmarker is not bundled '
        '(install Go: brew install go).',
      );
      return;
    }

    final lib = File.fromUri(
      input.outputDirectory.resolve(code.targetOS.dylibFileName('zmlbench')),
    );
    // The SDK spelled out: inside an Xcode build, a bare clang finds no
    // headers (stdlib.h) for cgo.
    final sdk = await Process.run('/usr/bin/xcrun', [
      '--sdk',
      'macosx',
      '--show-sdk-path',
    ]);
    if (sdk.exitCode != 0) {
      throw Exception('xcrun found no macOS SDK:\n${sdk.stderr}');
    }
    final cflags =
        '-isysroot ${'${sdk.stdout}'.trim()} '
        '-mmacosx-version-min=${code.macOS.targetVersion}';
    final result = await Process.run(
      go,
      [
        'build',
        '-buildmode=c-shared',
        '-trimpath',
        // Room in the header for Flutter to rewrite the install name when it
        // bundles the library (into a framework, or a test's build dir).
        '-ldflags=-extldflags=-Wl,-headerpad_max_install_names',
        '-o',
        lib.path,
        './capi',
      ],
      workingDirectory: source.path,
      environment: {
        'CGO_ENABLED': '1',
        'GOOS': 'darwin',
        'GOARCH': arch.go,
        'CC': '/usr/bin/xcrun --sdk macosx clang -arch ${arch.clang}',
        'CGO_CFLAGS': cflags,
        'CGO_LDFLAGS': cflags,
        'MACOSX_DEPLOYMENT_TARGET': '${code.macOS.targetVersion}',
      },
    );
    if (result.exitCode != 0) {
      throw Exception(
        'go build of the benchmark library failed:\n'
        '${result.stderr}${result.stdout}',
      );
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

/// The library's inputs: rebuilding is needed when any of these change.
List<Uri> _goSources(Directory dir) => [
  for (final f in dir.listSync(recursive: true).whereType<File>())
    if (f.path.endsWith('.go') ||
        f.path.endsWith('/go.mod') ||
        f.path.endsWith('/go.sum'))
      f.uri,
];
