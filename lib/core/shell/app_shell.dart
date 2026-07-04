import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../features/job_detail/application/terminal_fullscreen.dart';
import '../theme/app_theme.dart';
import 'sidebar.dart';

/// The persistent window chrome: a custom draggable title bar across the top,
/// the collapsible [Sidebar] on the left, and the routed screen filling the
/// rest. Rendered once and kept alive across navigation via the shell route.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fullscreen = ref.watch(terminalFullscreenProvider);
    return ColoredBox(
      color: c.window,
      child: Column(
        children: [
          const _TitleBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The sidebar stays in the tree and collapses to zero width
                // (rather than being removed) so the routed content keeps its
                // slot — and its live terminal sessions stay mounted.
                TweenAnimationBuilder<double>(
                  tween: Tween(end: fullscreen ? 0.0 : 1.0),
                  duration: AppDurations.normal,
                  curve: Curves.easeOutCubic,
                  builder: (context, f, child) => ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: f,
                      child: child,
                    ),
                  ),
                  child: Sidebar(
                    collapsed: _collapsed,
                    onToggleCollapsed: () =>
                        setState(() => _collapsed = !_collapsed),
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DragToMoveArea(
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: c.titleBar,
          border: Border(bottom: BorderSide(color: c.borderMuted)),
        ),
        alignment: Alignment.center,
        // Left inset leaves room for the native macOS traffic lights.
        padding: const EdgeInsets.only(left: 72),
        child: Text(
          'ZML-Lab',
          style: context.text.monoSmall.copyWith(color: c.textMuted),
        ),
      ),
    );
  }
}
