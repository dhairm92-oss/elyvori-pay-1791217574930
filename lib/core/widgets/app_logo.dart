import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's mark: its first letter on the neon gradient.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.name, this.size = 84});

  final String name;
  final double size;

  String get _letter {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'E';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.neonGradient,
        borderRadius: BorderRadius.circular(size * 0.31),
        boxShadow: [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.45), blurRadius: size * 0.5, spreadRadius: -4)],
      ),
      child: Text(
        _letter,
        style: TextStyle(fontSize: size * 0.48, fontWeight: FontWeight.w900, color: AppColors.obsidian, height: 1),
      ),
    );
  }
}

/// Text painted with the neon gradient.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => AppColors.neonGradient.createShader(bounds),
      child: Text(text, textAlign: textAlign, style: (style ?? const TextStyle()).copyWith(color: Colors.white)),
    );
  }
}
