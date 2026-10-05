import 'package:flutter_test/flutter_test.dart';

import '../../lib/features/records/domain/entities/record_item.dart';
import '../../lib/features/records/domain/sync/record_merge.dart';

RemoteRecord _remote(String id, DateTime at, {bool deleted = false, String name = 'cloud'}) => RemoteRecord(
      id: id,
      resource: 'orders',
      data: {'name': name},
      deleted: deleted,
      createdAt: at,
      updatedAt: at,
    );

void main() {
  final t0 = DateTime(2026, 1, 1, 10);
  final t1 = t0.add(const Duration(minutes: 5));

  test('new rows from the cloud are added as synced', () {
    final merged = mergeRecords(const [], [_remote('a', t0)]);
    expect(merged.single.id, 'a');
    expect(merged.single.synced, isTrue);
    expect(merged.single.values['name'], 'cloud');
  });

  test('a newer unsynced local edit wins over an older cloud version', () {
    final local = [RecordItem(id: 'a', createdAt: t0, updatedAt: t1, values: const {'name': 'mine'})];
    final merged = mergeRecords(local, [_remote('a', t0)]);
    expect(merged.single.values['name'], 'mine');
    expect(merged.single.synced, isFalse);
  });

  test('a newer cloud version replaces a synced local row', () {
    final local = [RecordItem(id: 'a', createdAt: t0, values: const {'name': 'old'}, synced: true)];
    final merged = mergeRecords(local, [_remote('a', t1, name: 'new')]);
    expect(merged.single.values['name'], 'new');
  });

  test('deletions from the cloud remove the row; pending local deletes stay deleted', () {
    final local = [RecordItem(id: 'a', createdAt: t0, values: const {}, synced: true)];
    expect(mergeRecords(local, [_remote('a', t1, deleted: true)]), isEmpty);
    expect(mergeRecords(const [], [_remote('b', t1)], pendingDeletes: {'b'}), isEmpty);
  });

  test('RemoteRecord parses the API shape', () {
    final r = RemoteRecord.fromJson({
      'id': 'x1',
      'resource': 'orders',
      'data': {'name': 'Ali', 'total': 12},
      'deleted': false,
      'createdAt': '2026-01-01T10:00:00.000Z',
      'updatedAt': '2026-01-02T10:00:00.000Z',
    });
    expect(r.id, 'x1');
    expect(r.data['total'], 12);
    expect(r.updatedAt.isAfter(r.createdAt), isTrue);
  });
}
