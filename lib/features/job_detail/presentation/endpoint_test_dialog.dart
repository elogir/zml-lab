import 'package:flutter/widgets.dart';

import '../../../core/execution/native_io.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';

/// Opens a popup that GETs `http://[host]:[port][path]` and shows the result —
/// the "Test endpoint" action. Runs the probe immediately and can retry.
Future<void> showEndpointTest(
  BuildContext context, {
  required String host,
  required int port,
  String path = '/v1/models',
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xCC000000),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) =>
          _EndpointTest(host: host, port: port, path: path),
      transitionsBuilder: (context, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

class _EndpointTest extends StatefulWidget {
  const _EndpointTest({
    required this.host,
    required this.port,
    required this.path,
  });

  final String host;
  final int port;
  final String path;

  @override
  State<_EndpointTest> createState() => _EndpointTestState();
}

class _EndpointTestState extends State<_EndpointTest> {
  bool _loading = true;
  EndpointProbe? _result;

  String get _url => 'http://${widget.host}:${widget.port}${widget.path}';

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    final result = await probeEndpoint(widget.host, widget.port, path: widget.path);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth * 0.5).clamp(440.0, 820.0);
        final height = (constraints.maxHeight * 0.6).clamp(320.0, 720.0);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width, maxHeight: height),
              child: AppPanel(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SectionLabel('Test endpoint'),
                        const Spacer(),
                        AppIconButton(
                          icon: AppIcons.close,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(_url, style: context.text.monoSmall),
                    const SizedBox(height: AppSpacing.lg),
                    Flexible(child: _body(context)),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Spacer(),
                        AppButton(
                          label: 'Retry',
                          icon: AppIcons.restart,
                          onPressed: _loading ? null : _run,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppButton(
                          label: 'Close',
                          variant: AppButtonVariant.primary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context) {
    final c = context.colors;
    if (_loading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('Testing…', style: context.text.smallMuted),
      );
    }
    final result = _result!;
    final ok = result.error == null &&
        result.status != null &&
        result.status! >= 200 &&
        result.status! < 400;
    final tint = ok ? c.statusRunning : c.statusFailed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              result.error != null
                  ? 'unreachable'
                  : 'HTTP ${result.status}',
              style: context.text.mono.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text('${result.latencyMs} ms', style: context.text.monoSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Flexible(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: AppRadius.smAll,
              border: Border.all(color: c.borderMuted),
            ),
            child: SingleChildScrollView(
              child: Text(
                result.error ??
                    (result.body == null || result.body!.isEmpty
                        ? '(empty response body)'
                        : result.body!),
                style: context.text.monoSmall,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
