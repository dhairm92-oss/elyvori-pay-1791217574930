import '../../records/domain/entities/record_item.dart';

/// One row in "recent activity".
class ActivityEntry {
  const ActivityEntry({required this.moduleKey, required this.item});

  final String moduleKey;
  final RecordItem item;
}

/// Numbers behind the home screen and the dashboard (pure, unit-tested).
class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.today,
    required this.thisWeek,
    required this.perModule,
    required this.last7Days,
    required this.recent,
  });

  /// Computes everything from each module's rows, relative to [now].
  factory DashboardStats.compute(Map<String, List<RecordItem>> data, DateTime now, {int recentLimit = 6}) {
    // calendar days in UTC, so daylight-saving changes never shift a day
    final startOfToday = DateTime.utc(now.year, now.month, now.day);
    final startOfWindow = startOfToday.subtract(const Duration(days: 6));
    final days = List<int>.filled(7, 0);
    final perModule = <String, int>{};
    final recent = <ActivityEntry>[];
    var total = 0;
    var today = 0;
    var week = 0;

    data.forEach((key, items) {
      perModule[key] = items.length;
      total += items.length;
      for (final item in items) {
        final t = item.createdAt;
        final day = DateTime.utc(t.year, t.month, t.day);
        if (!day.isBefore(startOfToday)) today++;
        if (!day.isBefore(startOfWindow) && !day.isAfter(startOfToday)) {
          week++;
          final index = day.difference(startOfWindow).inDays;
          if (index >= 0 && index < 7) days[index]++;
        }
        recent.add(ActivityEntry(moduleKey: key, item: item));
      }
    });

    recent.sort((a, b) => b.item.updatedAt.compareTo(a.item.updatedAt));
    return DashboardStats(
      total: total,
      today: today,
      thisWeek: week,
      perModule: perModule,
      last7Days: days,
      recent: recent.take(recentLimit).toList(),
    );
  }

  final int total;
  final int today;

  /// The last 7 days, today included.
  final int thisWeek;
  final Map<String, int> perModule;

  /// Oldest first; the last value is today.
  final List<int> last7Days;
  final List<ActivityEntry> recent;

  bool get isEmpty => total == 0;
}
