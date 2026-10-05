import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/core_providers.dart';
import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';
import 'neon_background.dart';

/// Branded launch screen: pulsing logo, the app's name and a progress bar.
/// The router leaves it as soon as start-up is done.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  String _step(double value) {
    if (value < 0.45) return S.splashPreparing;
    if (value < 0.92) return S.splashLoading;
    return S.splashReady;
  }

  @override
  Widget build(BuildContext context) {
    final appName = ref.watch(appConfigProvider).appName;
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              AppLogo(name: appName, size: 96)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.95, end: 1.05, duration: 1100.ms, curve: Curves.easeInOut),
              const SizedBox(height: 22),
              GradientText(
                appName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0, duration: 500.ms),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _progress,
                builder: (context, _) {
                  final value = Curves.easeInOutCubic.transform(_progress.value);
                  return Column(
                    children: [
                      SizedBox(
                        width: 220,
                        height: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              const Positioned.fill(child: ColoredBox(color: AppColors.glassFill)),
                              FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: value,
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(gradient: AppColors.neonGradient),
                                  child: SizedBox.expand(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          _step(value),
                          key: ValueKey(_step(value)),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(flex: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(S.builtWith, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
