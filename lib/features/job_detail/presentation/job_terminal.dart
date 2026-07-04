import 'dart:async';
import 'dart:collection';

import 'package:flterm/flterm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/services.dart'
    show
        HardwareKeyboard,
        KeyDownEvent,
        KeyEvent,
        KeyRepeatEvent,
        LogicalKeyboardKey,
        TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/terminal_font.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/job.dart';
import '../../../models/machine.dart';
import '../application/browser_history.dart';
import '../application/terminal_fullscreen.dart';
import 'terminal_session.dart';

part 'job_terminal.g.dart';

/// Fixed width of a tab chip. When the tabs (plus the pinned add buttons) no
/// longer fit, the tab strip scrolls horizontally instead of shrinking them.
const double _kTabWidth = 150;

/// Width the bar reserves for the two pinned "add tab" buttons when deciding
/// whether the strip fits — a slight overestimate so the strip switches to
/// scrolling just before the row could ever overflow.
const double _kAddButtonsWidth = 80;

// ── Pane tree ────────────────────────────────────────────────────────────
// A tab holds a tree of panes: a leaf is one pane (a terminal *or* a web
// view), a split holds two children side-by-side (Axis.horizontal) or stacked
// (Axis.vertical). Splitting works on any leaf regardless of its content.

/// The content of a single leaf: either a live terminal or a web view.
sealed class _Content {
  void dispose();
}

class _TermContent extends _Content {
  _TermContent(this.session);
  final TerminalSession session;
  @override
  void dispose() => session.dispose();
}

class _WebContent extends _Content {
  _WebContent(this.session);
  final _WebSession session;
  @override
  void dispose() {} // WebViewController has no dispose; freed on unmount.
}

sealed class _Pane {}

class _Leaf extends _Pane {
  _Leaf(this.content) : id = 'leaf-${_counter++}';
  final _Content content;
  final String id;
  // A GlobalKey so the leaf's live view element (TerminalView / web view and
  // its FocusNode) is *moved* rather than rebuilt when a split restructures
  // the pane tree — see [_buildPane]. Created once and persists with the leaf.
  final GlobalKey viewKey = GlobalKey();
  static int _counter = 0;
}

class _Split extends _Pane {
  _Split(this.axis, this.first, this.second) : id = 'split-${_counter++}';
  final String id;
  final Axis axis;
  _Pane first;
  _Pane second;
  double ratio = 0.5;
  static int _counter = 0;
}

class _Tab {
  _Tab(this.root) : id = 'tab-${_counter++}';
  _Pane root;
  final String id;
  static int _counter = 0;
}

/// A single web view. The native webview is owned by an [InAppWebView] widget;
/// [keepAlive] keeps it (and its loaded page) alive when the tab is switched
/// away and the widget unmounts. [currentUrl] tracks the live location.
class _WebSession {
  _WebSession([String? url])
    : id = 'web-${_counter++}',
      currentUrl = (url == null || url.isEmpty) ? '' : _normalize(url);

  final String id;
  String currentUrl;
  final InAppWebViewKeepAlive keepAlive = InAppWebViewKeepAlive();
  InAppWebViewController? controller;
  static int _counter = 0;

  // Interactive webview is native-only; the (degraded) web build shows a note.
  bool get isLive => !kIsWeb;

  /// A compact host:port label for the tab; 'web' until an address is entered.
  String get label {
    if (currentUrl.isEmpty) return 'web';
    final uri = Uri.tryParse(currentUrl);
    if (uri == null || uri.host.isEmpty) return currentUrl;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }

  static String _normalize(String raw) =>
      raw.startsWith('http') ? raw : 'http://$raw';

  /// A genuine, current desktop Safari user agent (macOS 26 / Safari 26) so
  /// sites serve their real desktop pages. The platform WebView's own default
  /// UA omits the "Version/x Safari/x" tokens, which makes some sites (e.g.
  /// Google) fall back to a stripped-down page — hence the explicit string.
  static const String userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15';
}

/// Disposes every session in a pane subtree (kills PTYs / frees web views).
void _disposePaneTree(_Pane pane) {
  switch (pane) {
    case _Leaf l:
      l.content.dispose();
    case _Split s:
      _disposePaneTree(s.first);
      _disposePaneTree(s.second);
  }
}

/// The persistent multiplexer state for one job: its tabs, the pane tree in
/// each, and which pane/tab is active. Held outside the widget (in a keep-alive
/// provider) so the live sessions — running shells and loaded web pages — and
/// the split layout survive navigating away from the detail view and back.
class TerminalMuxState {
  // Internal pane model; the holder is only ever reached through the provider
  // within this library, so the private element type doesn't actually leak.
  // ignore: library_private_types_in_public_api
  final List<_Tab> tabs = [];
  int active = 0;
  String? focusedId;

  void disposeAll() {
    for (final tab in tabs) {
      _disposePaneTree(tab.root);
    }
  }
}

/// Keep-alive so a job's terminals, web views and layout persist across
/// navigation. Keyed by job id; seeded with a single shell tab on first read.
/// The sessions live here, not in [JobTerminal], so unmounting the widget no
/// longer tears them down — only invalidating the provider does.
@Riverpod(keepAlive: true)
TerminalMuxState terminalMux(Ref ref, String jobId) {
  final state = TerminalMuxState();
  final leaf = _Leaf(_TermContent(TerminalSession()));
  state.tabs.add(_Tab(leaf));
  state.focusedId = leaf.id;
  ref.onDispose(state.disposeAll);
  return state;
}

/// The terminal region of the job detail view: a real terminal multiplexer —
/// tabs, split panes (draggable dividers). Each pane is either a live
/// interactive flterm terminal running the user's shell, or an embedded web
/// view with its own browser chrome.
class JobTerminal extends ConsumerStatefulWidget {
  const JobTerminal({super.key, required this.job, required this.machine});

  final Job job;
  final Machine? machine;

  @override
  ConsumerState<JobTerminal> createState() => _JobTerminalState();
}

class _JobTerminalState extends ConsumerState<JobTerminal> {
  // The tabs / panes / sessions live in a keep-alive provider (seeded on first
  // read), so they and their live sessions survive this widget being unmounted
  // when the user navigates back to the jobs list and returns.
  late final TerminalMuxState _s = ref.read(
    terminalMuxProvider(widget.job.id),
  );

  List<_Tab> get _tabs => _s.tabs;
  int get _active => _s.active;
  set _active(int v) => _s.active = v;
  String? get _focusedId => _s.focusedId;
  set _focusedId(String? v) => _s.focusedId = v;

  // Scrolls the tab strip when the tabs overflow; used to reveal a freshly
  // added tab (appended at the end) that would otherwise open off-screen, and
  // to auto-scroll while dragging a tab near an edge.
  final ScrollController _tabScroll = ScrollController();
  // Identifies the scrollable strip so drag-over positions can be measured
  // against its bounds (attached only when the tabs overflow).
  final GlobalKey _stripKey = GlobalKey();
  Timer? _autoScrollTimer;
  double _autoScrollDir = 0; // -1 = left, +1 = right, 0 = idle

  @override
  void dispose() {
    // Leaving the detail view drops fullscreen so it never lingers elsewhere.
    // The sessions themselves are NOT disposed here — they're owned by the
    // keep-alive provider so the layout persists across navigation.
    final fullscreen = ref.read(terminalFullscreenProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => fullscreen.exit());
    _autoScrollTimer?.cancel();
    _tabScroll.dispose();
    super.dispose();
  }

  _Leaf _firstLeaf(_Pane pane) => switch (pane) {
    _Leaf l => l,
    _Split s => _firstLeaf(s.first),
  };

  _Leaf? _findLeaf(_Pane pane, String id) => switch (pane) {
    _Leaf l => l.id == id ? l : null,
    _Split s => _findLeaf(s.first, id) ?? _findLeaf(s.second, id),
  };

  _Split? _findParent(_Pane node, _Pane child) {
    if (node is _Split) {
      if (identical(node.first, child) || identical(node.second, child)) {
        return node;
      }
      return _findParent(node.first, child) ?? _findParent(node.second, child);
    }
    return null;
  }

  /// Replaces [target] with [replacement] in the tree, mutating splits in
  /// place so their ratios stay stable. Returns the (possibly new) root.
  _Pane _replaceNode(_Pane root, _Pane target, _Pane replacement) {
    if (identical(root, target)) return replacement;
    if (root is _Split) {
      if (identical(root.first, target)) {
        root.first = replacement;
      } else if (identical(root.second, target)) {
        root.second = replacement;
      } else {
        _replaceNode(root.first, target, replacement);
        _replaceNode(root.second, target, replacement);
      }
    }
    return root;
  }

  /// A new pane of the same kind as [source] — splitting a terminal yields a
  /// terminal, splitting a web view yields another web view at the same URL.
  _Content _sameKind(_Content source) => switch (source) {
    _TermContent _ => _TermContent(TerminalSession()),
    _WebContent w => _WebContent(
      _WebSession(w.session.currentUrl.isEmpty ? null : w.session.currentUrl),
    ),
  };

  void _split(Axis axis) {
    final tab = _tabs[_active];
    final id = _focusedId;
    final leaf =
        (id == null ? null : _findLeaf(tab.root, id)) ?? _firstLeaf(tab.root);
    final newLeaf = _Leaf(_sameKind(leaf.content));
    setState(() {
      tab.root = _replaceNode(tab.root, leaf, _Split(axis, leaf, newLeaf));
      _focusedId = newLeaf.id;
    });
    _applyFocus();
  }

  void _closeLeaf(_Leaf leaf) {
    final tab = _tabs[_active];
    final parent = _findParent(tab.root, leaf);
    if (parent == null) return; // sole pane — not closable
    final sibling = identical(parent.first, leaf)
        ? parent.second
        : parent.first;
    setState(() {
      tab.root = _replaceNode(tab.root, parent, sibling);
      if (_focusedId == leaf.id) _focusedId = _firstLeaf(sibling).id;
    });
    _applyFocus();
    // Dispose after the closed pane's view has unmounted this frame.
    _disposeLater(leaf.content);
  }

  void _disposeLater(_Content content) {
    WidgetsBinding.instance.addPostFrameCallback((_) => content.dispose());
  }

  void _addTab() {
    final leaf = _Leaf(_TermContent(TerminalSession()));
    setState(() {
      _tabs.add(_Tab(leaf));
      _active = _tabs.length - 1;
      _focusedId = leaf.id;
    });
    _applyFocus();
    _revealLastTab();
  }

  void _addWebTab() {
    final leaf = _Leaf(_WebContent(_WebSession()));
    setState(() {
      _tabs.add(_Tab(leaf));
      _active = _tabs.length - 1;
      _focusedId = leaf.id;
    });
    _revealLastTab();
  }

  /// After a tab is appended, scroll the strip to its end so the new (now
  /// active) tab is visible even when the tabs overflow. No-op when they fit
  /// (the scroll view isn't mounted, so there are no clients to drive).
  void _revealLastTab() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tabScroll.hasClients) return;
      _tabScroll.animateTo(
        _tabScroll.position.maxScrollExtent,
        duration: AppDurations.normal,
        curve: Curves.easeOutCubic,
      );
    });
  }

  // ── Drag-to-reorder edge auto-scroll ─────────────────────────────────────
  // While dragging a tab, scroll the overflowing strip when the pointer nears
  // an edge, so tabs can be reordered past the visible range.
  static const double _dragEdge = 52; // edge hot-zone width
  static const double _dragScrollStep = 14; // px per tick

  void _onTabDragUpdate(Offset globalPos) {
    final box = _stripKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_tabScroll.hasClients) {
      _stopAutoScroll();
      return;
    }
    final left = box.localToGlobal(Offset.zero).dx;
    final right = left + box.size.width;
    if (globalPos.dx < left + _dragEdge) {
      _startAutoScroll(-1);
    } else if (globalPos.dx > right - _dragEdge) {
      _startAutoScroll(1);
    } else {
      _stopAutoScroll();
    }
  }

  void _startAutoScroll(double dir) {
    if (_autoScrollDir == dir && _autoScrollTimer != null) return;
    _autoScrollDir = dir;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_tabScroll.hasClients) return;
      final pos = _tabScroll.position;
      final next = (pos.pixels + dir * _dragScrollStep)
          .clamp(0.0, pos.maxScrollExtent);
      if (next != pos.pixels) _tabScroll.jumpTo(next);
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollDir = 0;
  }

  void _selectTab(int i) {
    setState(() {
      _active = i;
      _focusedId = _firstLeaf(_tabs[i].root).id;
    });
    _applyFocus();
  }

  void _closeTab(int i) {
    final removed = _tabs[i].root;
    setState(() {
      _tabs.removeAt(i);
      if (_tabs.isEmpty) {
        _tabs.add(_Tab(_Leaf(_TermContent(TerminalSession()))));
      }
      _active = _active.clamp(0, _tabs.length - 1);
      _focusedId = _firstLeaf(_tabs[_active].root).id;
    });
    _applyFocus();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _disposePaneTree(removed),
    );
  }

  void _reorderTab(int from, int to) {
    if (from == to) return;
    setState(() {
      final activeTab = _tabs[_active];
      final moved = _tabs.removeAt(from);
      final target = from < to ? to - 1 : to;
      _tabs.insert(target.clamp(0, _tabs.length), moved);
      _active = _tabs.indexOf(activeTab);
    });
  }

  void _focus(_Leaf leaf) {
    if (_focusedId != leaf.id) setState(() => _focusedId = leaf.id);
    _applyFocus();
  }

  /// Drives real keyboard focus from [_focusedId] so the pane wearing the focus
  /// frame is always the one that receives keystrokes. Without this the visual
  /// state and Flutter's focus tree drift apart: a split leaves keyboard focus
  /// on the old pane (its autofocus is ignored while another node holds focus),
  /// and clicking between panes can highlight one while typing lands in another.
  ///
  /// Runs twice on purpose: immediately, for panes already on screen — this
  /// moves focus on the same pointer-down, closing the "typed into the old
  /// pane" gap when switching splits fast — and again after the next frame, for
  /// panes a split / new tab just created and haven't mounted their FocusNode
  /// yet. Web panes own their own keyboard focus (the native view / address
  /// bar), so we leave them alone.
  void _applyFocus() {
    void focusNow() {
      if (!mounted) return;
      final id = _focusedId;
      if (id == null) return;
      final content = _findLeaf(_tabs[_active].root, id)?.content;
      if (content is _TermContent) {
        final node = content.session.focusNode;
        // Only if it's attached to a live Focus widget — a not-yet-mounted
        // pane (fresh split/tab) is picked up by the post-frame pass below.
        if (node.context != null) node.requestFocus();
      }
    }

    focusNow();
    WidgetsBinding.instance.addPostFrameCallback((_) => focusNow());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final font = ref.watch(terminalFontProvider).value;
    final fullscreen = ref.watch(terminalFullscreenProvider);
    final tab = _tabs[_active];

    // The border must paint *behind* the content, never in the foreground:
    // a Flutter layer painted over an embedded web view forces macOS to
    // snapshot it into a non-interactive texture (no clicks/scroll). Using a
    // Container border (which insets the child) keeps the border visible while
    // staying in the background paint pass.
    final radius = fullscreen ? BorderRadius.zero : AppRadius.lgAll;
    return Container(
      decoration: BoxDecoration(
        color: c.terminalBackground,
        borderRadius: radius,
        border: Border.all(color: c.terminalBorder, width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Column(
          children: [
            _buildTabBar(fullscreen: fullscreen),
            Expanded(
              child: _buildPane(tab.root, font, closable: tab.root is _Split),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar({required bool fullscreen}) {
    final c = context.colors;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.terminalBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The tab strip takes the free space and scrolls horizontally when
          // the tabs overflow; the two add buttons stay pinned just after it.
          Expanded(child: _buildTabStrip()),
          Center(
            child: AppIconButton(
              icon: AppIcons.splitHorizontal,
              size: 15,
              onPressed: () => _split(Axis.horizontal),
            ),
          ),
          Center(
            child: AppIconButton(
              icon: AppIcons.splitVertical,
              size: 15,
              onPressed: () => _split(Axis.vertical),
            ),
          ),
          _Separator(color: c.terminalBorder),
          Center(
            child: AppIconButton(
              icon: fullscreen ? AppIcons.exitFullscreen : AppIcons.fullscreen,
              size: 15,
              onPressed: () =>
                  ref.read(terminalFullscreenProvider.notifier).toggle(),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  /// The tabs followed by the two pinned add-tab buttons. When the tabs fit,
  /// the strip sits at its natural width (buttons hugging the last tab, free
  /// space trailing); when they don't, the tabs scroll horizontally while the
  /// buttons stay pinned to the right of the scroll area.
  Widget _buildTabStrip() {
    final addButtons = <Widget>[
      _BarButton(icon: AppIcons.add, onPressed: _addTab),
      _BarButton(icon: AppIcons.web, onPressed: _addWebTab),
    ];
    return LayoutBuilder(
      builder: (context, cons) {
        final tabs = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (var i = 0; i < _tabs.length; i++) _buildTab(i)],
        );
        final fits =
            _tabs.length * _kTabWidth + _kAddButtonsWidth <= cons.maxWidth;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fits)
              tabs
            else
              Expanded(
                child: SingleChildScrollView(
                  key: _stripKey,
                  controller: _tabScroll,
                  scrollDirection: Axis.horizontal,
                  child: tabs,
                ),
              ),
            ...addButtons,
          ],
        );
      },
    );
  }

  Widget _buildTab(int i) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != i,
      onAcceptWithDetails: (d) => _reorderTab(d.data, i),
      builder: (context, candidate, rejected) {
        final tab = _tabVisual(i, dropTarget: candidate.isNotEmpty);
        return Draggable<int>(
          data: i,
          axis: Axis.horizontal,
          onDragUpdate: (d) => _onTabDragUpdate(d.globalPosition),
          onDragEnd: (_) => _stopAutoScroll(),
          onDraggableCanceled: (_, _) => _stopAutoScroll(),
          feedback: _tabFeedback(i),
          childWhenDragging: Opacity(opacity: 0.3, child: tab),
          child: tab,
        );
      },
    );
  }

  ({IconData icon, String label}) _tabInfo(int i) {
    final leaf = _firstLeaf(_tabs[i].root);
    return switch (leaf.content) {
      _TermContent _ => (icon: AppIcons.terminal, label: 'shell'),
      _WebContent w => (icon: AppIcons.web, label: w.session.label),
    };
  }

  Widget _tabBadge(
    BuildContext context,
    IconData icon, {
    required bool active,
  }) {
    final c = context.colors;
    return Container(
      width: 19,
      height: 19,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: c.border),
      ),
      child: Icon(
        icon,
        size: 11,
        color: active ? c.textSecondary : c.textMuted,
      ),
    );
  }

  Widget _tabVisual(int i, {required bool dropTarget}) {
    final c = context.colors;
    final active = i == _active;
    final info = _tabInfo(i);
    return HoverRegion(
      onTap: () => _selectTab(i),
      builder: (context, hovered) {
        final indicator = active
            ? c.accent
            : (dropTarget
                  ? c.accent.withValues(alpha: 0.5)
                  : const Color(0x00000000));
        return Container(
          width: _kTabWidth,
          padding: const EdgeInsets.only(left: 10, right: 8),
          decoration: BoxDecoration(
            color: active
                ? c.terminalBackground
                : (hovered ? c.surfaceHover : null),
            border: Border(
              right: BorderSide(color: c.terminalBorder),
              bottom: BorderSide(color: indicator, width: 2),
            ),
          ),
          child: Row(
            children: [
              _tabBadge(context, info.icon, active: active),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  info.label,
                  style: context.text.monoSmall.copyWith(
                    color: active ? c.textSecondary : c.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Pinned to the right; reserved so the row doesn't jump.
              SizedBox(
                width: 16,
                child: hovered && _tabs.length > 1
                    ? AppIconButton(
                        icon: AppIcons.close,
                        size: 12,
                        padding: const EdgeInsets.all(3),
                        onPressed: () => _closeTab(i),
                      )
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  /// The floating tab shown while dragging to reorder.
  Widget _tabFeedback(int i) {
    final c = context.colors;
    final info = _tabInfo(i);
    return DefaultTextStyle(
      style: context.text.monoSmall.copyWith(color: c.textSecondary),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: c.borderStrong),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _tabBadge(context, info.icon, active: true),
            const SizedBox(width: AppSpacing.sm),
            Text(info.label),
          ],
        ),
      ),
    );
  }

  Widget _buildPane(_Pane pane, Uint8List? font, {required bool closable}) {
    // Leaves carry a GlobalKey, splits a ValueKey. The GlobalKey lets Flutter
    // *move* a leaf's element when a split wraps it in a new Row (or a close
    // promotes a sibling up the tree) instead of tearing it down and rebuilding
    // it. A rebuild would detach and reattach the terminal's FocusNode, churning
    // the focus tree so a refocused pane's block cursor renders hollow — and
    // would reset the flterm view. Splits hold no widget state, so a local key
    // (identity, never reused across sessions) is enough for them.
    return switch (pane) {
      _Leaf l => KeyedSubtree(
        key: l.viewKey,
        child: _buildLeaf(l, font, closable: closable),
      ),
      _Split s => KeyedSubtree(
        key: ValueKey(s.id),
        child: _buildSplit(s, font),
      ),
    };
  }

  Widget _buildSplit(_Split split, Uint8List? font) {
    final c = context.colors;
    final horizontal = split.axis == Axis.horizontal;
    const dividerSize = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final usable = (extent - dividerSize).clamp(0.0, double.infinity);
        final firstExtent = usable * split.ratio;
        final secondExtent = usable * (1 - split.ratio);

        SizedBox sized(double e, Widget child) => SizedBox(
          width: horizontal ? e : null,
          height: horizontal ? null : e,
          child: child,
        );

        final divider = MouseRegion(
          cursor: horizontal
              ? SystemMouseCursors.resizeLeftRight
              : SystemMouseCursors.resizeUpDown,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (d) {
              final delta = horizontal ? d.delta.dx : d.delta.dy;
              setState(() {
                split.ratio = (split.ratio + delta / extent).clamp(0.08, 0.92);
              });
            },
            child: Container(
              width: horizontal ? dividerSize : null,
              height: horizontal ? null : dividerSize,
              color: c.border,
            ),
          ),
        );

        final children = [
          sized(firstExtent, _buildPane(split.first, font, closable: true)),
          divider,
          sized(secondExtent, _buildPane(split.second, font, closable: true)),
        ];

        return horizontal
            ? Row(children: children)
            : Column(children: children);
      },
    );
  }

  Widget _buildLeaf(_Leaf leaf, Uint8List? font, {required bool closable}) {
    return switch (leaf.content) {
      _TermContent t => _buildTermLeaf(
        leaf,
        t.session,
        font,
        closable: closable,
      ),
      _WebContent w => _buildWebLeaf(leaf, w.session, closable: closable),
    };
  }

  Widget _buildTermLeaf(
    _Leaf leaf,
    TerminalSession session,
    Uint8List? font, {
    required bool closable,
  }) {
    final focused = leaf.id == _focusedId;

    final Widget inner = session.isLive
        ? TerminalView(
            controller: session.controller,
            focusNode: session.focusNode,
            theme: TerminalTheme.dark(),
            fontData: font,
            autofocus: focused,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          )
        : const _NativeOnlyNotice(
            label: 'Interactive terminal runs on the native desktop build.',
          );

    return HoverRegion(
      builder: (context, hovered) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _focus(leaf),
        child: Stack(
          children: [
            Positioned.fill(child: _focusFrame(focused && closable, inner)),
            if (closable && hovered)
              Positioned(
                top: 6,
                right: 6,
                child: AppIconButton(
                  icon: AppIcons.close,
                  size: 13,
                  onPressed: () => _closeLeaf(leaf),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebLeaf(
    _Leaf leaf,
    _WebSession session, {
    required bool closable,
  }) {
    final focused = leaf.id == _focusedId;
    final Widget inner = session.isLive
        ? _WebView(
            session: session,
            closable: closable,
            onActivate: () => _focus(leaf),
            onClose: () => _closeLeaf(leaf),
            onNavigated: () {
              if (mounted) setState(() {}); // refresh the tab label
            },
          )
        : const _NativeOnlyNotice(
            label: 'Web view runs on the native desktop build.',
          );

    // Focus-follows-mouse (via MouseRegion) rather than an intercepting
    // Listener — a pointer Listener over the native web view swallows the
    // clicks/scroll the page needs.
    return MouseRegion(
      onEnter: (_) => _focus(leaf),
      child: _focusFrame(focused && closable, inner),
    );
  }

  /// A 1px accent frame marking the focused pane (only meaningful when split).
  Widget _focusFrame(bool focused, Widget child) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: focused
              ? context.colors.accent.withValues(alpha: 0.6)
              : const Color(0x00000000),
        ),
      ),
      child: child,
    );
  }
}

/// A small icon button in the tab bar with even margins around it.
class _BarButton extends StatelessWidget {
  const _BarButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Center(
        child: AppIconButton(
          icon: icon,
          size: 15,
          padding: const EdgeInsets.all(5),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// A short vertical rule between the split controls and the fullscreen button.
class _Separator extends StatelessWidget {
  const _Separator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Center(
        child: SizedBox(width: 1, height: 16, child: ColoredBox(color: color)),
      ),
    );
  }
}

/// An embedded web view with a browser chrome bar: back / forward / reload, an
/// address bar that doubles as a search box (with history autocomplete), and a
/// Cmd+F in-page find bar.
class _WebView extends ConsumerStatefulWidget {
  const _WebView({
    required this.session,
    required this.closable,
    required this.onActivate,
    required this.onClose,
    required this.onNavigated,
  });

  final _WebSession session;
  final bool closable;
  final VoidCallback onActivate;
  final VoidCallback onClose;
  final VoidCallback onNavigated;

  @override
  ConsumerState<_WebView> createState() => _WebViewState();
}

class _WebViewState extends ConsumerState<_WebView> {
  late final TextEditingController _addr;
  late final FocusNode _addrFocus;
  bool _addrFocused = false;
  bool _canBack = false;
  bool _canForward = false;
  String? _lastRequested;
  List<String> _suggestions = const [];
  int _highlight = -1; // keyboard-highlighted suggestion, -1 = none
  bool _paneHovered = false;
  final LayerLink _addrLink = LayerLink();
  double _fieldWidth = 320;
  // The suggestions render in the app's top-level Overlay (not the web view's
  // own layer) so they float over the visible page without snapshotting it
  // into black bars.
  final OverlayPortalController _portalCtrl = OverlayPortalController();

  // In-page find.
  late final FindInteractionController _find;
  final TextEditingController _findText = TextEditingController();
  late final FocusNode _findFocus;
  bool _findOpen = false;
  int _findMatches = 0;
  int _findActive = 0;

  // A document-start script so Cmd/Ctrl+F opens our find bar even while the
  // page (not the Flutter chrome) holds keyboard focus.
  static final _findKeyScript = UserScript(
    source: '''
(function(){
  document.addEventListener('keydown', function(e){
    if ((e.metaKey||e.ctrlKey) && (e.key==='f'||e.key==='F')) {
      e.preventDefault();
      window.flutter_inappwebview.callHandler('zmlFind');
    } else if (e.key==='Escape') {
      window.flutter_inappwebview.callHandler('zmlFindClose');
    }
  }, true);
})();''',
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );

  _WebSession get _session => widget.session;
  InAppWebViewController? get _controller => _session.controller;

  @override
  void initState() {
    super.initState();
    _addr = TextEditingController(text: _session.currentUrl)
      ..addListener(_syncSuggestions);
    _addrFocus = FocusNode()
      ..addListener(() {
        if (_addrFocus.hasFocus) widget.onActivate();
        setState(() => _addrFocused = _addrFocus.hasFocus);
        _syncSuggestions();
      });
    _findFocus = FocusNode();
    _find = FindInteractionController(
      onFindResultReceived:
          (controller, activeMatchOrdinal, numberOfMatches, isDoneCounting) {
            if (!mounted) return;
            setState(() {
              _findMatches = numberOfMatches;
              _findActive = numberOfMatches == 0 ? 0 : activeMatchOrdinal + 1;
            });
          },
    );
    // A hover-gated global key handler so Cmd/Ctrl+F opens find whenever the
    // pointer is over this pane — no click-to-focus needed first.
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  bool _onKey(KeyEvent event) {
    final down = event is KeyDownEvent;
    // Cmd/Ctrl+F opens find when merely hovering the pane.
    if (down &&
        _paneHovered &&
        !_findOpen &&
        event.logicalKey == LogicalKeyboardKey.keyF &&
        (HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed)) {
      _openFind();
      return true;
    }
    // Escape: close find, else restore the current URL and unfocus the address
    // bar (the focused field consumes it before Shortcuts, so handle it here).
    if (down && event.logicalKey == LogicalKeyboardKey.escape) {
      if (_findOpen) {
        _closeFind();
        return true;
      }
      if (_addrFocused) {
        _addrFocus.unfocus();
        _addr.text = _session.currentUrl;
        return true;
      }
    }
    // Arrow keys move the address-bar suggestion highlight. We move the
    // highlight but let the event fall through (return false) — claiming it
    // wedges the macOS text-input session and drops the following Enter.
    if ((down || event is KeyRepeatEvent) &&
        _addrFocused &&
        _suggestions.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _highlightNext();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _highlightPrev();
      }
    }
    return false;
  }

  void _onUrl(String? url) {
    // The inline error page loads as about:blank / a data: URL — keep showing
    // the address the user actually asked for instead.
    if (url == null || url.isEmpty) return;
    if (url == 'about:blank' || url.startsWith('data:')) return;
    _session.currentUrl = url;
    ref.read(browserHistoryProvider.notifier).add(url);
    // Don't stomp on the user mid-edit.
    if (!_addrFocus.hasFocus && _addr.text != url) _addr.text = url;
    _syncNav();
    widget.onNavigated();
  }

  // ── Find ────────────────────────────────────────────────────────────────
  void _openFind() {
    setState(() => _findOpen = true);
    _findFocus.requestFocus();
    if (_findText.text.isNotEmpty) _find.findAll(find: _findText.text);
  }

  void _closeFind() {
    _find.clearMatches();
    setState(() {
      _findOpen = false;
      _findMatches = 0;
      _findActive = 0;
    });
  }

  void _runFind(String query) {
    if (query.isEmpty) {
      _find.clearMatches();
      setState(() {
        _findMatches = 0;
        _findActive = 0;
      });
      return;
    }
    _find.findAll(find: query);
  }

  void _syncSuggestions() {
    // Drop the page we're already on — suggesting it is pointless.
    final next = _addrFocus.hasFocus
        ? ref
              .read(browserHistoryProvider.notifier)
              .suggestions(_addr.text)
              .where((u) => u != _session.currentUrl)
              .toList()
        : const <String>[];
    if (!listEquals(next, _suggestions)) {
      setState(() {
        _suggestions = next;
        _highlight = -1;
      });
    }
    _updatePortal();
  }

  void _updatePortal() {
    final show = _addrFocused && _suggestions.isNotEmpty;
    if (show && !_portalCtrl.isShowing) {
      _portalCtrl.show();
    } else if (!show && _portalCtrl.isShowing) {
      _portalCtrl.hide();
    }
  }

  void _highlightNext() {
    if (!_addrFocused || _suggestions.isEmpty) return;
    setState(
      () => _highlight = (_highlight + 1).clamp(0, _suggestions.length - 1),
    );
  }

  void _highlightPrev() {
    if (!_addrFocused || _suggestions.isEmpty) return;
    setState(() => _highlight = _highlight <= 0 ? -1 : _highlight - 1);
  }

  void _submitAddress() {
    if (_highlight >= 0 && _highlight < _suggestions.length) {
      _submit(_suggestions[_highlight]);
    } else {
      _submit(_addr.text);
    }
  }

  void _showError(String? failedUrl, String description) {
    final target = failedUrl ?? _lastRequested ?? _session.currentUrl;
    _controller?.loadData(
      data: _errorHtml(target, description),
      mimeType: 'text/html',
      baseUrl: WebUri('about:blank'),
    );
    widget.onNavigated();
  }

  Future<void> _syncNav() async {
    final ctrl = _controller;
    if (ctrl == null) return;
    final back = await ctrl.canGoBack();
    final fwd = await ctrl.canGoForward();
    if (!mounted) return;
    if (back != _canBack || fwd != _canForward) {
      setState(() {
        _canBack = back;
        _canForward = fwd;
      });
    }
  }

  void _submit(String raw) {
    widget.onActivate();
    final url = _resolve(raw);
    if (url.isEmpty) return;
    _addr.text = url;
    _session.currentUrl = url;
    _lastRequested = url;
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    _addrFocus.unfocus();
  }

  /// A URL as typed, or a Google search when it isn't one.
  String _resolve(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return _session.currentUrl;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    final looksLikeHost = !t.contains(' ') && t.contains('.');
    if (looksLikeHost) return 'https://$t';
    return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(t)}';
  }

  /// A dark, terminal-matching error page shown in place of a failed load.
  String _errorHtml(String url, String description) {
    final u = _escapeHtml(url);
    final d = _escapeHtml(
      description.isEmpty ? 'The page could not be loaded.' : description,
    );
    return '''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html,body{height:100%;margin:0}
  body{background:#0B0C0E;color:#8A919B;
    font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
    display:flex;align-items:center;justify-content:center;padding:24px}
  .box{max-width:520px;text-align:center}
  .title{color:#E6E8EB;font-size:15px;margin-bottom:12px}
  .url{color:#6EA8FF;font-size:13px;word-break:break-all;margin-bottom:14px}
  .desc{font-size:12px;line-height:1.6;color:#8A919B}
</style></head><body><div class="box">
  <div class="title">Can't reach this page</div>
  <div class="url">$u</div>
  <div class="desc">$d</div>
</div></body></html>''';
  }

  String _escapeHtml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// A dark, terminal-matching start page shown for a blank new web tab.
  static const String _newTabHtml = '''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html,body{margin:0;height:100%}
  body{background:#0B0C0E;color:#8A919B;
    font-family:ui-monospace,SFMono-Regular,Menlo,monospace;
    position:fixed;inset:0;
    display:flex;align-items:center;justify-content:center;
    -webkit-user-select:none;user-select:none}
  .box{text-align:center}
  .glyph{width:44px;height:44px;margin:0 auto 18px;opacity:.55;
    border:1.5px solid #2A2E37;border-radius:12px;
    display:flex;align-items:center;justify-content:center}
  .glyph svg{width:22px;height:22px;stroke:#8A919B;fill:none;stroke-width:1.6}
  .title{color:#E6E8EB;font-size:15px;margin-bottom:10px;letter-spacing:.02em}
  .hint{font-size:12px;line-height:1.9;color:#8A919B}
</style></head><body><div class="box">
  <div class="glyph"><svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/>
    <line x1="2" y1="12" x2="22" y2="12"/>
    <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
    </svg></div>
  <div class="title">New tab</div>
  <div class="hint">Type an address or search in the bar above.</div>
</div></body></html>''';

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _addr.dispose();
    _addrFocus.dispose();
    _findText.dispose();
    _findFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = _session.currentUrl;
    // Cmd+F opens find / Esc closes it when the Flutter chrome holds focus;
    // the hover key handler + injected script cover the page-focused case.
    return MouseRegion(
      onEnter: (_) => _paneHovered = true,
      onExit: (_) => _paneHovered = false,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _openFind,
          const SingleActivator(LogicalKeyboardKey.escape): _onEscape,
        },
        child: Column(
          children: [
            _toolbar(),
            if (_findOpen) _findBar(),
            Expanded(
              child: InAppWebView(
                keepAlive: _session.keepAlive,
                findInteractionController: _find,
                initialUrlRequest: initial.isEmpty
                    ? null
                    : URLRequest(url: WebUri(initial)),
                // A styled start page instead of a blank white void.
                initialData: initial.isEmpty
                    ? InAppWebViewInitialData(data: _newTabHtml)
                    : null,
                initialUserScripts: UnmodifiableListView([_findKeyScript]),
                initialSettings: InAppWebViewSettings(
                  userAgent: _WebSession.userAgent,
                ),
                onWebViewCreated: (controller) {
                  _session.controller = controller;
                  controller.addJavaScriptHandler(
                    handlerName: 'zmlFind',
                    callback: (_) {
                      _openFind();
                      return null;
                    },
                  );
                  controller.addJavaScriptHandler(
                    handlerName: 'zmlFindClose',
                    callback: (_) {
                      if (_findOpen) _closeFind();
                      return null;
                    },
                  );
                  _syncNav();
                },
                onLoadStart: (controller, url) => _onUrl(url?.toString()),
                onLoadStop: (controller, url) => _onUrl(url?.toString()),
                onUpdateVisitedHistory: (controller, url, isReload) =>
                    _onUrl(url?.toString()),
                onReceivedError: (controller, request, error) {
                  // Only replace the page when the main frame itself fails,
                  // and never for a load cancelled by navigating away.
                  if (request.isForMainFrame != true) return;
                  if (error.type == WebResourceErrorType.CANCELLED) return;
                  _showError(request.url.toString(), error.description);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onEscape() {
    if (_findOpen) {
      _closeFind();
    } else if (_addrFocused) {
      _addrFocus.unfocus();
    }
  }

  Widget _findBar() {
    final c = context.colors;
    final count = _findMatches == 0
        ? (_findText.text.isEmpty ? '' : 'No results')
        : '$_findActive/$_findMatches';
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.terminalBorder)),
      ),
      child: Row(
        children: [
          Icon(AppIcons.search, size: 13, color: c.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: DefaultSelectionStyle(
              cursorColor: c.accent,
              selectionColor: c.accent.withValues(alpha: 0.28),
              child: Material(
                type: MaterialType.transparency,
                child: TextField(
                  controller: _findText,
                  focusNode: _findFocus,
                  autofocus: true,
                  style: context.text.monoSmall.copyWith(color: c.textPrimary),
                  cursorColor: c.accent,
                  cursorWidth: 1.6,
                  onChanged: _runFind,
                  // Keep focus so repeated Enter cycles to the next match.
                  onSubmitted: (_) {
                    _find.findNext(forward: true);
                    _findFocus.requestFocus();
                  },
                  decoration: InputDecoration.collapsed(
                    hintText: 'Find in page',
                    hintStyle: context.text.monoSmall.copyWith(
                      color: c.textFaint,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(count, style: context.text.smallMuted),
          ],
          const SizedBox(width: 4),
          AppIconButton(
            icon: AppIcons.findPrev,
            size: 15,
            onPressed: () => _find.findNext(forward: false),
          ),
          AppIconButton(
            icon: AppIcons.findNext,
            size: 15,
            onPressed: () => _find.findNext(forward: true),
          ),
          AppIconButton(icon: AppIcons.close, size: 14, onPressed: _closeFind),
        ],
      ),
    );
  }

  Widget _toolbar() {
    final c = context.colors;
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.terminalBorder)),
      ),
      child: Row(
        children: [
          _navButton(
            AppIcons.navBack,
            enabled: _canBack,
            onTap: () {
              widget.onActivate();
              _controller?.goBack();
            },
          ),
          _navButton(
            AppIcons.navForward,
            enabled: _canForward,
            onTap: () {
              widget.onActivate();
              _controller?.goForward();
            },
          ),
          _navButton(
            AppIcons.refresh,
            enabled: true,
            onTap: () {
              widget.onActivate();
              _controller?.reload();
            },
          ),
          const SizedBox(width: 4),
          Expanded(child: _addressBar()),
          if (widget.closable) ...[
            const SizedBox(width: 4),
            AppIconButton(
              icon: AppIcons.close,
              size: 14,
              onPressed: widget.onClose,
            ),
          ],
        ],
      ),
    );
  }

  Widget _navButton(
    IconData icon, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    if (!enabled) {
      return Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 15, color: context.colors.textFaint),
      );
    }
    return AppIconButton(icon: icon, size: 15, onPressed: onTap);
  }

  Widget _addressBar() {
    final c = context.colors;
    return CompositedTransformTarget(
      link: _addrLink,
      child: OverlayPortal(
        controller: _portalCtrl,
        overlayChildBuilder: (context) => _suggestionsOverlay(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _fieldWidth = constraints.maxWidth;
            return DefaultSelectionStyle(
              cursorColor: c.accent,
              selectionColor: c.accent.withValues(alpha: 0.28),
              child: Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: AppRadius.smAll,
                  border: Border.all(
                    color: _addrFocused ? c.accent : c.border,
                    width: _addrFocused ? 1.2 : 1,
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: TextField(
                    controller: _addr,
                    focusNode: _addrFocus,
                    style: context.text.monoSmall.copyWith(
                      color: c.textPrimary,
                    ),
                    cursorColor: c.accent,
                    cursorWidth: 1.6,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _submitAddress(),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Search or enter address',
                      hintStyle: context.text.monoSmall.copyWith(
                        color: c.textFaint,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The suggestions dropdown placed in the app Overlay, anchored under the
  /// address bar. Lives above the native web view (top-level layer) so it
  /// floats over the visible page without snapshotting it.
  Widget _suggestionsOverlay() {
    // TextFieldTapRegion keeps taps on the dropdown from unfocusing the address
    // field, so deleting a row leaves the field focused and the dropdown open.
    return TextFieldTapRegion(
      child: CompositedTransformFollower(
        link: _addrLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 4),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: _fieldWidth, child: _suggestionsPanel()),
        ),
      ),
    );
  }

  /// History dropdown card, floated under the address bar over the page.
  Widget _suggestionsPanel() {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: c.borderStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.smAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _suggestions.length; i++)
              _historyRow(_suggestions[i], i == _highlight),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(String url, bool highlighted) {
    final c = context.colors;
    return HoverRegion(
      builder: (context, rowHovered) => Container(
        color: highlighted
            ? c.surfaceSelected
            : (rowHovered ? c.surfaceHover : null),
        child: Row(
          children: [
            // Main area selects the URL.
            Expanded(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _submit(url),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
                  child: Row(
                    children: [
                      _favicon(url),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          url,
                          style: context.text.monoSmall.copyWith(
                            color: highlighted
                                ? c.textPrimary
                                : c.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Delete button removes this entry from history (separate Listener
            // so its pointer-down doesn't also select the row).
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _deleteHistory(url),
              child: HoverRegion(
                builder: (context, xHovered) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: xHovered ? c.surfaceHover : null,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Icon(
                      AppIcons.close,
                      size: 12,
                      color: xHovered ? c.textPrimary : c.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteHistory(String url) {
    ref.read(browserHistoryProvider.notifier).remove(url);
    // Refresh the visible suggestions; the field keeps focus (TextFieldTapRegion)
    // so the dropdown stays open unless it's now empty.
    _syncSuggestions();
  }

  /// The site's favicon (via a favicon service), falling back to a globe.
  Widget _favicon(String url) {
    final c = context.colors;
    final host = Uri.tryParse(url)?.host ?? '';
    final fallback = Icon(AppIcons.web, size: 13, color: c.textMuted);
    if (host.isEmpty) return SizedBox(width: 14, height: 14, child: fallback);
    return SizedBox(
      width: 14,
      height: 14,
      child: Image.network(
        'https://www.google.com/s2/favicons?sz=64&domain=$host',
        width: 14,
        height: 14,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}

/// Placeholder shown on the (unsupported) web build for a terminal or web pane.
class _NativeOnlyNotice extends StatelessWidget {
  const _NativeOnlyNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, style: context.text.monoSmall));
  }
}
