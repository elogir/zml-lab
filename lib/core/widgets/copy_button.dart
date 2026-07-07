import 'dart:async';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';

import 'app_button.dart';
import 'app_icons.dart';

/// A "Copy" button that puts [text] on the clipboard and briefly flips its
/// label to "Copied" as feedback.
class CopyButton extends StatefulWidget {
  const CopyButton({super.key, required this.text, this.label = 'Copy'});

  final String text;
  final String label;

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  Timer? _reset;
  bool _copied = false;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: _copied ? 'Copied' : widget.label,
      icon: _copied ? AppIcons.check : AppIcons.copy,
      dense: true,
      onPressed: _copy,
    );
  }
}

/// Like [CopyButton] but the text is produced on demand by an async builder
/// (e.g. shelling out to a command) — the button shows "…" while it runs.
class AsyncCopyButton extends StatefulWidget {
  const AsyncCopyButton({
    super.key,
    required this.textBuilder,
    this.label = 'Copy',
  });

  final Future<String> Function() textBuilder;
  final String label;

  @override
  State<AsyncCopyButton> createState() => _AsyncCopyButtonState();
}

class _AsyncCopyButtonState extends State<AsyncCopyButton> {
  Timer? _reset;
  bool _copied = false;
  bool _busy = false;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    if (_busy) return;
    setState(() => _busy = true);
    String text;
    try {
      text = await widget.textBuilder();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: _busy
          ? 'Copying…'
          : _copied
          ? 'Copied'
          : widget.label,
      icon: _copied ? AppIcons.check : AppIcons.copy,
      dense: true,
      onPressed: _busy ? null : _copy,
    );
  }
}
