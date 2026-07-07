import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/perf_report.dart';
import '../../../repositories/perf_report_repository.dart';
import '../domain/bench_runner.dart';
import '../domain/report_text.dart';
import 'perf_report_view.dart';

/// Opens a saved perf report as a popup over the current screen (same pattern
/// as the saved chat-benchmark detail).
void showPerfReportDetail(BuildContext context, PerfReport report) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0xCC000000),
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: AppDurations.normal,
      pageBuilder: (context, _, _) => _DetailView(report: report),
      transitionsBuilder: (context, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

class _DetailView extends ConsumerStatefulWidget {
  const _DetailView({required this.report});

  final PerfReport report;

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  late PerfReport _report = widget.report;
  bool _editingName = false;
  String? _exportedTo;
  late final TextEditingController _name = TextEditingController(
    text: _report.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _commitName() {
    final name = _name.text.trim();
    if (name.isEmpty || name == _report.name) {
      _name.text = _report.name;
      setState(() => _editingName = false);
      return;
    }
    final updated = _report.copyWith(name: name);
    setState(() {
      _report = updated;
      _editingName = false;
    });
    ref.read(perfReportRepositoryProvider).save(updated);
  }

  Future<void> _export() async {
    try {
      final dest = await exportTextFile(
        content: perfReportCsv(_report),
        name: _report.name,
      );
      await revealInFinder(dest);
      if (mounted) setState(() => _exportedTo = dest);
    } catch (e) {
      if (mounted) setState(() => _exportedTo = 'export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = MediaQuery.sizeOf(context);
    final width = (size.width * 0.68).clamp(520.0, 1160.0);
    final height = (size.height * 0.8).clamp(420.0, 960.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: height),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: AppPanel(
            color: c.surface,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 28,
                            child: _editingName
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: AppTextField(
                                          controller: _name,
                                          dense: true,
                                          autofocus: true,
                                          onSubmitted: (_) => _commitName(),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      AppIconButton(
                                        icon: AppIcons.check,
                                        size: 13,
                                        onPressed: _commitName,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _report.name,
                                          style: context.text.bodyStrong,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      AppIconButton(
                                        icon: AppIcons.edit,
                                        size: 13,
                                        onPressed: () => setState(
                                          () => _editingName = true,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                AppIcons.machines,
                                size: 12,
                                color: c.textFaint,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _report.endpoint,
                                style: context.text.monoSmall,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                formatAgo(_report.createdAt),
                                style: context.text.smallMuted,
                              ),
                              if (_exportedTo != null) ...[
                                const SizedBox(width: AppSpacing.md),
                                Flexible(
                                  child: Text(
                                    _exportedTo!,
                                    style: context.text.monoSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    CopyButton(
                      text: perfReportTable(_report),
                      label: 'Copy results',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: 'Export CSV',
                      icon: AppIcons.download,
                      dense: true,
                      onPressed: _export,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppIconButton(
                      icon: AppIcons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(child: PerfReportView(report: _report)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
