import 'package:flutter_test/flutter_test.dart';

import '../../lib/features/dashboard/domain/dashboard_stats.dart';
import '../../lib/features/records/domain/entities/record_item.dart';

void main() {
  test('totals, today, last 7 days and recent activity', () {
    final now = DateTime(2026, 3, 10, 15);
    RecordItem item(String id, DateTime at) => RecordItem(id: id, createdAt: at, values: const {});
    final data = {
      'orders': [
        item('o1', DateTime(2026, 3, 10, 9)), // today
        item('o2', DateTime(2026, 3, 9, 9)), // yesterday
        item('o3', DateTime(2026, 2, 1, 9)), // old
      ],
      'customers': [item('c1', DateTime(2026, 3, 4, 9))], // 6 days ago (inside the window)
    };

    final stats = DashboardStats.compute(data, now, recentLimit: 3);
    expect(stats.total, 4);
    expect(stats.today, 1);
    expect(stats.thisWeek, 3);
    expect(stats.perModule, {'orders': 3, 'customers': 1});
    expect(stats.last7Days, [1, 0, 0, 0, 0, 1, 1]);
    expect(stats.recent.map((e) => e.item.id), ['o1', 'o2', 'c1']);
    expect(stats.isEmpty, isFalse);
  });

  test('empty data', () {
    final stats = DashboardStats.compute(const {}, DateTime(2026, 1, 1));
    expect(stats.isEmpty, isTrue);
    expect(stats.last7Days, List<int>.filled(7, 0));
  });
}
