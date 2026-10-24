import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/sharegpt_dataset.dart';
import '../domain/sharegpt.dart';

/// The Perf tab's first screen until ShareGPT is on disk: what it is, one
/// button, then live progress (resumable, verified).
class ShareGptDownloadCard extends StatelessWidget {
  const ShareGptDownloadCard({
    super.key,
    required this.state,
    required this.onDownload,
    required this.onCancel,
  });

  final DatasetState state;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final downloading = state.phase == DatasetPhase.downloading;
    final failed = state.phase == DatasetPhase.failed;
    final partial = state.received > 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: AppPanel(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(AppIcons.download, size: 20, color: c.accent),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'ShareGPT dataset',
              style: context.text.bodyStrong,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The benchmarker replays ~94k real ChatGPT conversations '
              'shared on ShareGPT. A one-time '
              '${_mb(ShareGpt.bytes, digits: 0)} download.',
              style: context.text.smallMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (downloading || partial || failed) ...[
              _Progress(state: state),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (failed) ...[
              Text(
                state.error ?? 'the download failed',
                style: context.text.small.copyWith(color: c.statusFailed),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Center(
              child: downloading
                  ? AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.ghost,
                      onPressed: onCancel,
                    )
                  : AppButton(
                      label: failed
                          ? 'Retry'
                          : partial
                          ? 'Resume download'
                          : 'Download ShareGPT',
                      icon: AppIcons.download,
                      variant: AppButtonVariant.primary,
                      onPressed: onDownload,
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            // The folder (the file name is long and always the same; the
            // full path is in Settings).
            Text(
              'saved to ${state.path.substring(0, state.path.lastIndexOf('/').clamp(0, state.path.length))}',
              style: context.text.monoSmall.copyWith(color: c.textFaint),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.state});

  final DatasetState state;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fraction = state.fraction ?? 0;
    final downloading = state.phase == DatasetPhase.downloading;
    final speed = state.bytesPerSecond;
    final remaining = state.remaining;
    final mono = context.text.monoSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${(fraction * 100).floor()}%',
              style: context.text.mono.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                downloading
                    ? [
                        if (speed != null) '${_mb(speed.round())}/s',
                        if (remaining != null) _left(remaining),
                      ].join('  ·  ')
                    : '',
                style: mono.copyWith(color: c.textMuted),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _Bar(
          fraction: fraction,
          color: state.phase == DatasetPhase.failed ? c.statusFailed : c.accent,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_mb(state.received)} of ${_mb(state.total ?? ShareGpt.bytes)}',
          style: mono.copyWith(color: c.textFaint),
        ),
      ],
    );
  }
}

/// A rounded track and fill that glides between updates.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 8,
        color: c.surfaceSelected,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: fraction),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          builder: (context, value, _) => FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
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
