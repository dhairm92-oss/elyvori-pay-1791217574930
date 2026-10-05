import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Obsidian backdrop with two soft neon orbs, shared by every screen.
class NeonBackground extends StatelessWidget {
  const NeonBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Stack(
        children: [
          const Positioned(top: -120, right: -80, child: _Orb(color: AppColors.violet, size: 280)),
          const Positioned(bottom: -140, left: -100, child: _Orb(color: AppColors.cyan, size: 320)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
