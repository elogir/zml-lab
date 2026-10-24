import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Shows a live time series at the display's frame rate, so a chart grows
/// smoothly instead of in sample-sized steps.
///
/// Samples arrive every ~100 ms. The series is drawn up to a display clock
/// that runs in real time just behind the newest sample: the tip glides
/// between the last two real samples (linear interpolation), and waits at
/// the newest one if the next is late. Never ahead of the data, so nothing
/// is guessed and nothing snaps back.
class SmoothLiveSeries<T> extends StatefulWidget {
  const SmoothLiveSeries({
    super.key,
    required this.points,
    required this.timeMs,
    required this.lerp,
    required this.live,
    required this.builder,
    this.maxLagMs = 300,
  });

  final List<T> points;

  /// A point's time on the run's clock.
  final int Function(T point) timeMs;

  /// The point at [atMs], a fraction [t] of the way from [a] to [b].
  final T Function(T a, T b, double t, int atMs) lerp;

  /// While false (a finished run) the points are shown as they are.
  final bool live;

  /// The display clock is never further than this behind the newest sample
  /// (it catches up after a stall instead of trailing forever).
  final int maxLagMs;

  final Widget Function(BuildContext context, List<T> shown) builder;

  @override
  State<SmoothLiveSeries<T>> createState() => _SmoothLiveSeriesState<T>();
}

class _SmoothLiveSeriesState<T> extends State<SmoothLiveSeries<T>>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  /// The display clock, on the run's clock (ms).
  double? _displayMs;
  Duration _lastTick = Duration.zero;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SmoothLiveSeries<T> old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _sync() {
    final points = widget.points;
    if (!widget.live || points.length < 2) {
      _ticker.stop();
      _displayMs = null;
      return;
    }
    final newest = widget.timeMs(points.last).toDouble();
    // Start one sample behind the newest, and never fall too far behind.
    _displayMs ??= widget.timeMs(points[points.length - 2]).toDouble();
    _displayMs = math.max(_displayMs!, newest - widget.maxLagMs);
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final display = _displayMs;
    final points = widget.points;
    if (display == null || points.isEmpty) return;
    final dt = (elapsed - _lastTick).inMicroseconds / 1000;
    _lastTick = elapsed;
    final newest = widget.timeMs(points.last).toDouble();
    final next = math.min(newest, display + dt);
    if (next != display) setState(() => _displayMs = next);
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final display = _displayMs;
    if (display == null) return widget.builder(context, points);
    return widget.builder(context, _upTo(points, display));
  }

  /// The points up to [atMs], plus one interpolated at [atMs].
  List<T> _upTo(List<T> points, double atMs) {
    // The display clock is near the end: search from there.
    var i = points.length - 1;
    while (i > 0 && widget.timeMs(points[i]) > atMs) {
      i--;
    }
    final shown = points.sublist(0, i + 1);
    if (i + 1 < points.length) {
      final a = points[i];
      final b = points[i + 1];
      final from = widget.timeMs(a);
      final span = widget.timeMs(b) - from;
      if (span > 0 && atMs > from) {
        final t = ((atMs - from) / span).clamp(0.0, 1.0);
        shown.add(widget.lerp(a, b, t, atMs.round()));
      }
    }
    return shown;
  }
}
