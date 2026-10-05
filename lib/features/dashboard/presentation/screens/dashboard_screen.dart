import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/section_title.dart';
import '../../../records/presentation/providers/records_providers.dart';
import '../../../registry.dart';
import '../../domain/dashboard_stats.dart';
import '../widgets/charts.dart';

/// The owner's control room: KPIs, 7-day activity, share per section.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final stats = DashboardStats.compute(ref.watch(allRecordsProvider), now);
    final today = DateTime(now.year, now.month, now.day);
    final dayLabels = [
      for (var i = 6; i >= 0; i--) S.weekdaysShort[today.subtract(Duration(days: i)).weekday - 1],
    ];
    final counts = [for (final m in appResources) stats.perModule[m.key] ?? 0];
    final colors = [for (var i = 0; i < appResources.length; i++) AppColors.seriesAt(i)];

    return RefreshIndicator(
      color: AppColors.cyan,
      onRefresh: () => ref.read(syncControllerProvider.notifier).syncNow(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Text(S.dashboardTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(S.dashboardHint, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 640 ? 4 : 2;
              final cards = [
                _Kpi(icon: Icons.inventory_2_rounded, label: S.totalItems, value: stats.total, color: AppColors.cyan),
                _Kpi(icon: Icons.today_rounded, label: S.today, value: stats.today, color: AppColors.emerald),
                _Kpi(icon: Icons.date_range_rounded, label: S.thisWeek, value: stats.thisWeek, color: AppColors.violet),
                _Kpi(icon: Icons.dashboard_rounded, label: S.sectionsCount, value: appResources.length, color: AppColors.amber),
              ];
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: [
                  for (var i = 0; i < cards.length; i++)
                    cards[i].animate().fadeIn(delay: (70 * i).ms, duration: 350.ms).scaleXY(begin: 0.95, end: 1),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          GlassContainer(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(S.activity7Days),
                BarChart(values: stats.last7Days, labels: dayLabels),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(S.distribution),
                if (stats.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(S.noDataYet, style: const TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final donut = DonutChart(values: counts, colors: colors, centerLabel: S.totalItems);
                      final legend = _Legend(counts: counts, colors: colors, total: stats.total);
                      if (constraints.maxWidth < 420) {
                        return Column(children: [donut, const SizedBox(height: 16), legend]);
                      }
                      return Row(children: [donut, const SizedBox(width: 20), Expanded(child: legend)]);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      glow: color,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CountUp(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.counts, required this.colors, required this.total});

  final List<int> counts;
  final List<Color> colors;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < appResources.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(appResources[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Text(
                      '${counts[i]} · ${total == 0 ? 0 : (counts[i] * 100 / total).round()}%',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0.0 : counts[i] / total,
                    minHeight: 6,
                    backgroundColor: AppColors.glassFill,
                    valueColor: AlwaysStoppedAnimation<Color>(colors[i]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
