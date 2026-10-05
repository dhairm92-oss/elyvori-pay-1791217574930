import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Animated vertical bars with labels underneath (e.g. the last 7 days).
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values, required this.labels, this.height = 170});

  final List<int> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => SizedBox(
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _BarPainter(
            values: values,
            labels: labels,
            progress: progress,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({required this.values, required this.labels, required this.progress, required this.textDirection});

  final List<int> values;
  final List<String> labels;
  final double progress;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const labelSpace = 22.0;
    const topSpace = 18.0;
    final chartHeight = size.height - labelSpace - topSpace;
    final maxValue = math.max(1, values.reduce(math.max));
    final slot = size.width / values.length;
    final barWidth = math.min(28.0, slot * 0.55);

    final grid = Paint()
      ..color = AppColors.glassBorder.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topSpace + chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (var i = 0; i < values.length; i++) {
      // right-to-left apps read time from right to left
      final position = textDirection == TextDirection.rtl ? values.length - 1 - i : i;
      final centerX = slot * position + slot / 2;
      final barHeight = chartHeight * (values[i] / maxValue) * progress;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(centerX - barWidth / 2, topSpace + chartHeight - barHeight, barWidth, math.max(barHeight, 2.0)),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );
      final isLast = i == values.length - 1;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: isLast ? const [AppColors.violet, AppColors.cyan] : [AppColors.violet.withValues(alpha: 0.55), AppColors.cyan.withValues(alpha: 0.75)],
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);

      if (values[i] > 0 && progress > 0.6) {
        _text(canvas, '${values[i]}', Offset(centerX, topSpace + chartHeight - barHeight - 16), AppColors.textPrimary, 11, bold: true);
      }
      if (i < labels.length) {
        _text(canvas, labels[i], Offset(centerX, size.height - labelSpace + 6), isLast ? AppColors.cyan : AppColors.textMuted, 11);
      }
    }
  }

  void _text(Canvas canvas, String text, Offset center, Color color, double size, {bool bold = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      textDirection: textDirection,
    )..layout();
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.progress != progress || old.values != values || old.labels != labels || old.textDirection != textDirection;
}

/// Animated ring split by share, with the total in the middle.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.values, required this.colors, required this.centerLabel, this.size = 150});

  final List<int> values;
  final List<Color> colors;
  final String centerLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = values.fold<int>(0, (a, b) => a + b);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DonutPainter(values: values, colors: colors, progress: progress),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(total * progress).round()}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                Text(centerLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors, required this.progress});

  final List<int> values;
  final List<Color> colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.glassFill;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = math.pi * 2 * (values[i] / total) * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = colors[i % colors.length];
      canvas.drawArc(rect, start, math.max(0.0, sweep - 0.03), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.values != values || old.colors != colors;
}

/// A number that counts up when it first appears.
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: style),
    );
  }
}
