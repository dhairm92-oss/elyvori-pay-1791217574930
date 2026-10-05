import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/core_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/neon_background.dart';
import '../dashboard/presentation/screens/dashboard_screen.dart';
import '../home/presentation/screens/home_screen.dart';
import '../profile/profile_screen.dart';
import '../records/presentation/providers/records_providers.dart';

/// The signed-in app: Home · Dashboard · Profile with a floating glass tab bar.
/// Keeps the cloud in sync (on start, when back online, and every 2 minutes).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  Timer? _timer;
  late final SyncController _sync;

  @override
  void initState() {
    super.initState();
    _sync = ref.read(syncControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync.activate();
    });
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => unawaited(_sync.syncNow()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
      if (next.valueOrNull == true && previous?.valueOrNull == false) unawaited(_sync.syncNow());
    });

    final pages = <Widget>[
      HomeScreen(onProfile: () => setState(() => _index = 2)),
      const DashboardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: NeonBackground(
        child: SafeArea(bottom: false, child: IndexedStack(index: _index, children: pages)),
      ),
      bottomNavigationBar: _GlassTabBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          (Icons.home_rounded, S.tabHome),
          (Icons.insights_rounded, S.tabDashboard),
          (Icons.person_rounded, S.tabProfile),
        ],
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({required this.index, required this.onTap, required this.items});

  final int index;
  final ValueChanged<int> onTap;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 66,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _TabItem(
                      icon: items[i].$1,
                      label: items[i].$2,
                      selected: i == index,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.neonGradient : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.obsidian : AppColors.textMuted),
            if (selected) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.obsidian, fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
