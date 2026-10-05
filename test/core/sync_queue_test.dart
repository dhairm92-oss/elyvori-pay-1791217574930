import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/storage/key_value_store.dart';
import '../../lib/core/storage/local_cache.dart';
import '../../lib/core/storage/sync_queue.dart';

void main() {
  group('SyncQueue', () {
    test('keeps operations in order and stops at the first that must wait', () async {
      final queue = SyncQueue(MemoryKeyValueStore());
      await queue.enqueue(method: 'POST', path: '/a', body: {'n': 1});
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await queue.enqueue(method: 'POST', path: '/b', body: {'n': 2});
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await queue.enqueue(method: 'POST', path: '/c', body: {'n': 3});

      final sent = <String>[];
      final done = await queue.flush((op) async {
        sent.add(op.path);
        return op.path == '/b' ? SyncOutcome.retryLater : SyncOutcome.done;
      });

      expect(done, 1);
      expect(sent, ['/a', '/b']);
      expect(queue.pending.map((o) => o.path), ['/b', '/c']);
      expect(queue.pending.first.attempts, 1);

      final second = await queue.flush((op) async => SyncOutcome.done);
      expect(second, 2);
      expect(queue.pending, isEmpty);
      await queue.dispose();
    });

    test('drops an operation after too many attempts', () async {
      final queue = SyncQueue(MemoryKeyValueStore(), maxAttempts: 2);
      await queue.enqueue(method: 'POST', path: '/x');
      await queue.flush((_) async => SyncOutcome.retryLater);
      expect(queue.pending, hasLength(1));
      await queue.flush((_) async => SyncOutcome.retryLater);
      expect(queue.pending, isEmpty);
      await queue.dispose();
    });

    test('a throwing sender counts as retry later', () async {
      final queue = SyncQueue(MemoryKeyValueStore());
      await queue.enqueue(method: 'POST', path: '/y');
      await queue.flush((_) async => throw Exception('offline'));
      expect(queue.pending.single.attempts, 1);
      await queue.dispose();
    });
  });

  test('LocalCache round-trips JSON with a timestamp', () async {
    final cache = LocalCache(MemoryKeyValueStore());
    await cache.put('agents', [
      {'id': '1', 'name': 'Revenue'},
    ]);
    final entry = cache.get('agents');
    expect(entry, isNotNull);
    expect((entry!.value! as List).single, {'id': '1', 'name': 'Revenue'});
    expect(entry.isOlderThan(const Duration(minutes: 1)), isFalse);
  });
}
