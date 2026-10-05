import '../entities/record_item.dart';

/// One row as the cloud returns it.
class RemoteRecord {
  const RemoteRecord({
    required this.id,
    required this.resource,
    required this.data,
    required this.deleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RemoteRecord.fromJson(Map<String, dynamic> json) {
    final updated = DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now();
    final rawData = json['data'];
    return RemoteRecord(
      id: json['id'] as String,
      resource: json['resource'] as String,
      data: rawData is Map ? Map<String, Object?>.from(rawData) : <String, Object?>{},
      deleted: json['deleted'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? updated,
      updatedAt: updated,
    );
  }

  final String id;
  final String resource;
  final Map<String, Object?> data;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Applies the cloud's rows to one module's local rows.
///
/// * a local edit that is not uploaded yet and is newer than the cloud's
///   version wins (it is uploaded on the next sync);
/// * rows deleted on this device and not uploaded yet stay deleted;
/// * everything else follows the cloud (added, changed, deleted elsewhere).
List<RecordItem> mergeRecords(
  List<RecordItem> local,
  Iterable<RemoteRecord> remote, {
  Set<String> pendingDeletes = const {},
}) {
  final byId = <String, RecordItem>{for (final item in local) item.id: item};
  for (final row in remote) {
    if (pendingDeletes.contains(row.id)) continue;
    final mine = byId[row.id];
    if (mine != null && !mine.synced && mine.updatedAt.isAfter(row.updatedAt)) continue;
    if (row.deleted) {
      byId.remove(row.id);
      continue;
    }
    byId[row.id] = RecordItem(
      id: row.id,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      values: row.data,
      synced: true,
    );
  }
  return byId.values.toList();
}
