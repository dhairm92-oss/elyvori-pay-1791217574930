import '../../../core/config/cloud.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/key_value_store.dart';
import '../domain/entities/resource_spec.dart';
import '../domain/sync/record_merge.dart';
import 'datasources/records_local_data_source.dart';

class SyncReport {
  const SyncReport({required this.pushed, required this.pulled});

  final int pushed;
  final int pulled;
}

/// Two-way sync with the app's Elyvori cloud: uploads every unsynced row and
/// deletion, then downloads everything that changed on the server since the
/// last sync (other devices, the web version, …).
class CloudSyncService {
  CloudSyncService({required this.api, required this.local, required this.store, required this.resources});

  final ApiClient api;
  final RecordsLocalDataSource local;
  final KeyValueStore store;
  final List<ResourceSpec> resources;

  static const _cursorKey = 'sync:cursor';
  static const _lastSyncKey = 'sync:last_at';

  DateTime? get lastSyncAt => DateTime.tryParse(store.read(_lastSyncKey) ?? '');

  int get pendingCount {
    var count = local.readTombstones().length;
    for (final spec in resources) {
      count += local.read(spec.key).where((i) => !i.synced).length;
    }
    return count;
  }

  Future<SyncReport> sync() async {
    final tombstones = local.readTombstones();
    final changes = <Map<String, Object?>>[];
    final pushedVersions = <String, DateTime>{};

    for (final spec in resources) {
      for (final item in local.read(spec.key)) {
        if (item.synced) continue;
        pushedVersions[item.id] = item.updatedAt;
        changes.add({
          'id': item.id,
          'resource': spec.key,
          'data': item.values,
          'deleted': false,
          'createdAt': item.createdAt.toIso8601String(),
          'updatedAt': item.updatedAt.toIso8601String(),
        });
      }
    }
    for (final t in tombstones) {
      changes.add({
        'id': t.id,
        'resource': t.resource,
        'data': <String, Object?>{},
        'deleted': true,
        'createdAt': t.at.toIso8601String(),
        'updatedAt': t.at.toIso8601String(),
      });
    }

    final response = await api.post<Map<String, dynamic>>(
      cloudPath('/sync'),
      body: {'since': store.read(_cursorKey), 'changes': changes},
    );

    final rawRows = response['records'];
    final rows = (rawRows is List ? rawRows : const <Object?>[])
        .whereType<Map<String, dynamic>>()
        .map(RemoteRecord.fromJson)
        .toList();

    // deletions made while the request was running stay queued
    final sentDeletes = {for (final t in tombstones) t.id: t.at};
    final remaining = local.readTombstones().where((t) => sentDeletes[t.id] != t.at).toList();
    await local.writeTombstones(remaining);
    final pendingDeletes = remaining.map((t) => t.id).toSet();

    for (final spec in resources) {
      final items = local
          .read(spec.key)
          .map((i) => !i.synced && pushedVersions[i.id] == i.updatedAt ? i.copyWith(synced: true) : i)
          .toList();
      final merged = mergeRecords(items, rows.where((r) => r.resource == spec.key), pendingDeletes: pendingDeletes);
      await local.write(spec.key, merged);
    }

    final cursor = response['serverTime'];
    if (cursor is String && cursor.isNotEmpty) await store.write(_cursorKey, cursor);
    await store.write(_lastSyncKey, DateTime.now().toIso8601String());
    return SyncReport(pushed: changes.length, pulled: rows.length);
  }

  /// Removes this account's data from the device (used on sign out).
  Future<void> clearLocalData() async {
    for (final spec in resources) {
      await local.write(spec.key, const []);
    }
    await local.writeTombstones(const []);
    await store.remove(_cursorKey);
    await store.remove(_lastSyncKey);
  }
}
