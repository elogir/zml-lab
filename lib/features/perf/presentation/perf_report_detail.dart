import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/util/format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/perf_report.dart';
import '../../../models/run_meta.dart';
import '../../../repositories/perf_report_repository.dart';
import '../../saved_benchmarks/presentation/edit_run_dialog.dart';
import '../../saved_benchmarks/presentation/run_details_summary.dart';
import '../domain/bench_runner.dart';
import '../domain/report_text.dart';
import '../domain/run_recorder.dart';
import 'export_run_dialog.dart';
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
  String? _exportedTo;

  /// The run's recording, for reports recorded since runs are kept (older
  /// ones only have their CSV).
  late final String? _runFile = runFileExists(_report.id)
      ? runFilePath(_report.id)
      : null;

  /// The name and model as ZML-Lab shows them, which go over the run file's
  /// (a fresh file still has its automatic label).
  Map<String, String> get _shown => {
    'label': _report.name,
    'model.name': _report.displayModel,
  };

  /// Edits the details in the run file's meta.json (the report's own, for
  /// runs without a file), then keeps both in step.
  Future<void> _editDetails() async {
    final repo = ref.read(perfReportRepositoryProvider);
    final file = _runFile;
    final Map<String, Object?> meta;
    try {
      meta = file == null
          ? _report.details.toMeta()
          : withRunMetaFields(await readRunMeta(file) ?? {}, _shown);
    } catch (e) {
      if (mounted) setState(() => _exportedTo = 'could not read the run: $e');
      return;
    }
    if (!mounted) return;
    final edited = await showEditRunDialog(
      context,
      meta: meta,
      sentModel: _report.params.model,
    );
    if (edited == null || !mounted) return;
    final updated = _report.withDetails(RunDetails.fromMeta(edited));
    setState(() => _report = updated);
    await repo.save(updated);
    if (file == null) return;
    try {
      await rewriteRunMeta(file, edited);
    } catch (e) {
      if (mounted) setState(() => _exportedTo = 'run file not updated: $e');
    }
  }

  Future<void> _exportRun() async {
    final dest = await showExportRunDialog(
      context,
      runFile: _runFile!,
      overrides: _shown,
    );
    if (dest == null) return;
    await revealInFinder(dest);
    if (mounted) setState(() => _exportedTo = dest);
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
                            child: Row(
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
                                  onPressed: _editDetails,
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
                                '${_report.machineName} ${_report.portLabel}',
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
                          RunDetailsSummary(details: _report.details),
                        ],
                      ),
                    ),
                    CopyButton(
                      text: perfReportTable(_report),
                      label: 'Copy results',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label: _runFile != null ? 'Export run' : 'Export CSV',
                      icon: AppIcons.download,
                      dense: true,
                      onPressed: _runFile != null ? _exportRun : _export,
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
