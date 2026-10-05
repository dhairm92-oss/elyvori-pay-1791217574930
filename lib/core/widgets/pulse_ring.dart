import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated "live" indicator drawn with a CustomPainter: a solid core and
/// expanding rings. Runs on the raster thread at the display refresh rate.
class PulseRing extends StatefulWidget {
  const PulseRing({super.key, required this.color, this.size = 18, this.active = true});

  final Color color;
  final double size;
  final bool active;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(painter: _PulsePainter(_controller, widget.color, widget.active)),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.animation, this.color, this.active) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    if (active) {
      for (var i = 0; i < 2; i++) {
        final t = (animation.value + i * 0.5) % 1.0;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: (1 - t) * 0.8);
        canvas.drawCircle(center, maxR * (0.35 + 0.65 * t), paint);
      }
    }
    canvas.drawCircle(center, maxR * 0.32, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter old) => old.color != color || old.active != active;
}

/// A circular progress arc with a neon sweep gradient (dashboard gauge).
class NeonGauge extends StatelessWidget {
  const NeonGauge({super.key, required this.value, this.size = 64, this.label});

  /// 0..1
  final double value;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _GaugePainter(v),
          child: Center(
            child: Text(
              label ?? '${(v * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(5);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0x22FFFFFF);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2, false, track);
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0xFF00E5FF), Color(0xFF7C3AED), Color(0xFF00E5FF)],
      ).createShader(arcRect);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * value, false, sweep);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}
