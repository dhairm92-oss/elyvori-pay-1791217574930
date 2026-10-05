import 'package:flutter/material.dart';

/// ElyVori "Cyberpunk Glass" palette.
abstract final class AppColors {
  static const obsidian = Color(0xFF02040F);
  static const surface = Color(0xFF080C1A);
  static const surfaceHigh = Color(0xFF10162B);
  static const cyan = Color(0xFF00E5FF);
  static const violet = Color(0xFF7C3AED);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFCBD5E1);
  static const textMuted = Color(0xFF64748B);
  static const glassFill = Color(0x14FFFFFF);
  static const glassBorder = Color(0x33FFFFFF);

  /// Distinct colours for charts (one per module).
  static const series = <Color>[
    cyan,
    violet,
    emerald,
    amber,
    rose,
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  static Color seriesAt(int index) => series[index % series.length];

  static const neonGradient = LinearGradient(
    colors: [cyan, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const backgroundGradient = RadialGradient(
    center: Alignment(-0.6, -0.8),
    radius: 1.4,
    colors: [Color(0xFF0B1230), obsidian],
  );
}
