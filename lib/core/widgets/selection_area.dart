import 'package:flutter/material.dart' show SelectionArea;
import 'package:flutter/widgets.dart';

/// Makes a read-only subtree mouse-selectable: drag to select, right-click
/// menu, ⌘C to copy. A thin wrapper so popups showing commands/responses opt
/// into selection uniformly.
class AppSelectionArea extends StatelessWidget {
  const AppSelectionArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SelectionArea(child: child);
}
