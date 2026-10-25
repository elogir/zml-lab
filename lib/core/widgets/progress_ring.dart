import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A small ring that fills clockwise from the top as [progress] (0–1) rises,
/// easing between updates. At 0 it spins a short arc instead, so a wait that
/// hasn't reported progress yet still visibly moves.
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    required this.track,
    this.size = 17,
  });

  final double progress;
  final Color color;
  final Color track;
  final double size;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _syncSpin();
  }

  @override
  void didUpdateWidget(ProgressRing old) {
    super.didUpdateWidget(old);
    _syncSpin();
  }

  // Only spins while there's no progress to show: no ticker once it fills.
  void _syncSpin() {
    if (widget.progress > 0) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => AnimatedBuilder(
        animation: _spin,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _RingPainter(
            progress: progress,
            spin: widget.progress > 0 ? null : _spin.value,
            color: widget.color,
            track: widget.track,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.spin,
    required this.color,
    required this.track,
  });

  final double progress;

  /// 0–1 turn of the spinning arc; null once there's progress to draw.
  final double? spin;
  final Color color;
  final Color track;

  static const _stroke = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2 + 0.5);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = track,
    );
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    const top = -math.pi / 2;
    final spin = this.spin;
    if (spin != null) {
      canvas.drawArc(rect, top + spin * 2 * math.pi, math.pi / 2, false, arc);
    } else if (progress > 0) {
      canvas.drawArc(rect, top, progress * 2 * math.pi, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.spin != spin ||
      old.color != color ||
      old.track != track;
}
