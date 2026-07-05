import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../theme/app_theme.dart';

/// Renders model output as markdown in the app's visual language.
///
/// The app deliberately has no MaterialApp, but `gpt_markdown` resolves its
/// colors through `Theme.of` and a few of its pieces (task-list checkboxes)
/// need a `Material` ancestor — so this wraps the renderer in a minimal,
/// palette-mapped Material theme that never leaks outside this subtree. Code
/// blocks and inline code get app-styled builders (mono, muted surfaces)
/// instead of the package's Material defaults.
class AppMarkdown extends StatelessWidget {
  const AppMarkdown(this.data, {super.key, this.style});

  /// The markdown source — a model response, possibly still streaming.
  final String data;

  /// Base text style. Defaults to the app's secondary body style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = style ?? context.text.bodySecondary.copyWith(height: 1.55);
    final baseSize = base.fontSize ?? 13;

    TextStyle heading(double size) => base.copyWith(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: c.textPrimary,
      height: 1.3,
    );

    final scheme =
        (c.brightness == Brightness.dark
                ? const ColorScheme.dark()
                : const ColorScheme.light())
            .copyWith(
              primary: c.accent,
              surface: c.surface,
              onSurface: c.textPrimary,
              onSurfaceVariant: c.textSecondary,
              onInverseSurface: c.surfaceMuted,
              outline: c.border,
              error: c.statusFailed,
            );

    return Theme(
      data: ThemeData(
        colorScheme: scheme,
        textTheme: TextTheme(bodyMedium: base),
        dividerColor: c.borderMuted,
      ),
      child: GptMarkdownTheme(
        gptThemeData: GptMarkdownThemeData(
          brightness: c.brightness,
          highlightColor: c.surfaceSelected,
          h1: heading(baseSize + 6),
          h2: heading(baseSize + 4),
          h3: heading(baseSize + 2),
          h4: heading(baseSize + 1),
          h5: heading(baseSize),
          h6: heading(baseSize),
          hrLineColor: c.borderMuted,
          linkColor: c.accent,
          linkHoverColor: c.accent,
          autoAddDividerLineAfterH1: false,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: GptMarkdown(
            data,
            style: base,
            codeBuilder: _codeBlock,
            highlightBuilder: _inlineCode,
          ),
        ),
      ),
    );
  }

  /// A fenced code block: muted well, optional language label, mono text that
  /// scrolls horizontally instead of wrapping.
  Widget _codeBlock(BuildContext context, String name, String code, bool _) {
    final c = context.colors;
    final t = context.text;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: c.borderMuted),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(name, style: t.monoSmall),
            ),
            Container(height: 1, color: c.borderMuted),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              code,
              style: t.monoSmall.copyWith(color: c.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Inline `code`: a subtle mono chip.
  Widget _inlineCode(BuildContext context, String text, TextStyle style) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: c.surfaceSelected,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: style.copyWith(
          fontFamily: AppTypography.monoFamily,
          fontSize: (style.fontSize ?? 13) - 0.5,
          height: 1.35,
        ),
      ),
    );
  }
}
