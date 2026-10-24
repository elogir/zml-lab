import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/sharegpt_dataset.dart';
import '../domain/sharegpt.dart';

/// What the Perf tab shows (centred) until ShareGPT is on disk: a download
/// button and where it saves — then a thin progress bar with one line of
/// figures. Resumable, verified.
class ShareGptDownload extends StatelessWidget {
  const ShareGptDownload({
    super.key,
    required this.state,
    required this.folder,
    required this.onDownload,
    required this.onCancel,
    this.onChooseFolder,
  });

  final DatasetState state;

  /// Where it saves, as shown (e.g. `~/Library/Application Support/…`).
  final String folder;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  /// Opens a folder picker; null where there's none (web).
  final VoidCallback? onChooseFolder;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final downloading = state.phase == DatasetPhase.downloading;
    final failed = state.phase == DatasetPhase.failed;
    final started = downloading || failed || state.received > 0;
    final mono = context.text.monoSmall.copyWith(color: c.textMuted);
    final total = state.total ?? ShareGpt.bytes;

    // The whole path, wrapped if need be, and the folder picker under it.
    final destination = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${_mb(ShareGpt.bytes, digits: 0)}  ·  to $folder',
          style: mono.copyWith(color: c.textFaint),
          textAlign: TextAlign.center,
        ),
        if (onChooseFolder != null) ...[
          const SizedBox(height: AppSpacing.xs),
          HoverRegion(
            onTap: onChooseFolder,
            builder: (context, hovered) => Text(
              'Change folder…',
              style: context.text.small.copyWith(
                color: hovered ? c.textPrimary : c.accent,
              ),
            ),
          ),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (started) ...[
            _Bar(
              fraction: state.fraction ?? 0,
              color: failed ? c.statusFailed : c.accent,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    failed
                        ? (state.error ?? 'the download failed')
                        : [
                            '${((state.fraction ?? 0) * 100).floor()}%',
                            '${_mb(state.received)} of ${_mb(total)}',
                            if (downloading && state.bytesPerSecond != null)
                              '${_mb(state.bytesPerSecond!.round())}/s',
                            if (downloading && state.remaining != null)
                              _left(state.remaining!),
                          ].join('  ·  '),
                    style: failed
                        ? context.text.small.copyWith(color: c.statusFailed)
                        : mono,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (downloading)
                  AppIconButton(
                    icon: AppIcons.close,
                    size: 13,
                    padding: const EdgeInsets.all(4),
                    onPressed: onCancel,
                  ),
              ],
            ),
          ],
          if (!downloading) ...[
            if (started) const SizedBox(height: AppSpacing.lg),
            Center(
              child: AppButton(
                label: failed
                    ? 'Retry'
                    : started
                    ? 'Resume download'
                    : 'Download ShareGPT',
                icon: AppIcons.download,
                variant: AppButtonVariant.primary,
                onPressed: onDownload,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(child: destination),
          ],
        ],
      ),
    );
  }
}

/// A thin track and fill that glides between updates.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 4,
        color: context.colors.borderMuted,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          builder: (context, value, _) => FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1,
            child: ColoredBox(color: color),
          ),
        ),
      ),
    );
  }
}

/// Decimal megabytes, as download sizes are quoted.
String _mb(int bytes, {int digits = 1}) =>
    '${(bytes / 1e6).toStringAsFixed(digits)} MB';

String _left(Duration d) {
  final s = d.inSeconds;
  if (s < 60) return '$s s left';
  final m = d.inMinutes;
  return '$m min ${s - m * 60} s left';
}
