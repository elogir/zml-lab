import 'package:flutter/widgets.dart';

import 'app_icon_button.dart';
import 'app_icons.dart';
import 'app_text_field.dart';

/// A search input built on [AppTextField]: a magnifier prefix and a clear
/// button that appears once there's text. Owns its own controller and reports
/// the query through [onChanged].
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.onChanged,
    this.hintText = 'Search',
  });

  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      placeholder: widget.hintText,
      prefixIcon: AppIcons.search,
      onChanged: (v) {
        widget.onChanged(v);
        setState(() {}); // toggle the clear button
      },
      suffix: _controller.text.isEmpty
          ? null
          : AppIconButton(
              icon: AppIcons.close,
              size: 13,
              padding: const EdgeInsets.all(3),
              onPressed: _clear,
            ),
    );
  }
}
