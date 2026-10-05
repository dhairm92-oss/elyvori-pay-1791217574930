import '../../../../core/result/result.dart';
import '../../domain/entities/record_item.dart';
import '../../domain/entities/resource_spec.dart';
import '../../domain/repositories/records_repository.dart';
import '../datasources/records_local_data_source.dart';

/// Offline-first: every change is saved on the device immediately. When the
/// app has an Elyvori cloud, unsynced rows and deletions are uploaded by the
/// cloud sync service (see `cloud_sync_service.dart`).
class RecordsRepositoryImpl implements RecordsRepository {
  RecordsRepositoryImpl({required this.local, required this.trackDeletes});

  final RecordsLocalDataSource local;

  /// Remember deletions so the cloud can delete them too.
  final bool trackDeletes;

  @override
  Future<Result<List<RecordItem>>> list(ResourceSpec spec) => Result.guard(() async {
        final items = local.read(spec.key)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      });

  @override
  Future<Result<RecordItem>> save(ResourceSpec spec, RecordItem item) => Result.guard(() async {
        final items = local.read(spec.key);
        final index = items.indexWhere((i) => i.id == item.id);
        if (index == -1) {
          items.add(item);
        } else {
          items[index] = item;
        }
        await local.write(spec.key, items);
        return item;
      });

  @override
  Future<Result<bool>> delete(ResourceSpec spec, String id) => Result.guard(() async {
        final items = local.read(spec.key)..removeWhere((i) => i.id == id);
        await local.write(spec.key, items);
        if (trackDeletes) {
          final tombstones = local.readTombstones()..removeWhere((t) => t.id == id);
          tombstones.add(Tombstone(id: id, resource: spec.key, at: DateTime.now()));
          await local.writeTombstones(tombstones);
        }
        return true;
      });
}
