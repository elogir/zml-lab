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
