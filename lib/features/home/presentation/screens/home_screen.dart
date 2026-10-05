import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../account/presentation/providers/account_controller.dart';
import '../../../dashboard/domain/dashboard_stats.dart';
import '../../../dashboard/presentation/widgets/charts.dart';
import '../../../records/presentation/providers/records_providers.dart';
import '../../../records/presentation/widgets/resource_icons.dart';
import '../../../records/presentation/widgets/sync_status_chip.dart';
import '../../../registry.dart';
import '../widgets/modules_grid.dart';

/// Home: greeting, today's numbers, the app's sections and recent activity.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onProfile});

  /// Opens the profile tab (the avatar in the header).
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(appConfigProvider).appName;
    final user = cloudSyncEnabled ? ref.watch(accountControllerProvider).valueOrNull : null;
    final now = DateTime.now();
    final stats = DashboardStats.compute(ref.watch(allRecordsProvider), now);

    return RefreshIndicator(
      color: AppColors.cyan,
      onRefresh: () => ref.read(syncControllerProvider.notifier).syncNow(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.greeting(now.hour), style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 2),
                    GradientText(
                      user?.firstName ?? appName,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onProfile,
                child: user == null
                    ? AppLogo(name: appName, size: 48)
                    : CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.violet,
                        child: Text(
                          user.initials,
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
              ),
            ],
          ).animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 10),
          const Align(alignment: AlignmentDirectional.centerStart, child: SyncStatusChip()),
          const SizedBox(height: 18),
          _HeroCard(stats: stats).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 26),
          SectionTitle(S.modules),
          if (appResources.isEmpty)
            GlassContainer(child: Text(S.noModules))
          else
            ModulesGrid(modules: appResources, counts: stats.perModule),
          const SizedBox(height: 26),
          SectionTitle(S.recentActivity),
          if (stats.recent.isEmpty)
            GlassContainer(child: Text(S.noActivity, style: const TextStyle(color: AppColors.textSecondary)))
          else
            for (var i = 0; i < stats.recent.length; i++)
              _ActivityTile(entry: stats.recent[i], now: now)
                  .animate()
                  .fadeIn(delay: (60 * i).ms, duration: 300.ms)
                  .slideX(begin: 0.04, end: 0),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [AppColors.cyan.withValues(alpha: 0.28), AppColors.violet.withValues(alpha: 0.38)],
        ),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.25), blurRadius: 30, spreadRadius: -8)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.totalItems, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                CountUp(stats.total, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: S.today, value: stats.today, color: AppColors.cyan),
                    _Pill(label: S.thisWeek, value: stats.thisWeek, color: AppColors.emerald),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: BarChart(values: stats.last7Days, labels: const [], height: 90),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.obsidian.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry, required this.now});

  final ActivityEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final spec = specFor(entry.moduleKey);
    final title = entry.item.values[spec.primaryField.key]?.toString() ?? spec.title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => context.push('/records/${spec.key}'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(resourceIcon(spec.icon), color: AppColors.cyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(spec.title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text(S.timeAgo(entry.item.updatedAt, now), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
