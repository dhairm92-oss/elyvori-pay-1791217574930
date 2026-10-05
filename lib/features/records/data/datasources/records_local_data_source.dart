import 'dart:convert';

import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/record_item.dart';

/// A record deleted on this device that the cloud has not heard about yet.
class Tombstone {
  const Tombstone({required this.id, required this.resource, required this.at});

  factory Tombstone.fromJson(Map<String, dynamic> json) => Tombstone(
        id: json['id'] as String,
        resource: json['resource'] as String,
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      );

  final String id;
  final String resource;
  final DateTime at;

  Map<String, dynamic> toJson() => {'id': id, 'resource': resource, 'at': at.toIso8601String()};
}

class RecordsLocalDataSource {
  const RecordsLocalDataSource(this._store);

  final KeyValueStore _store;

  static const _tombstonesKey = 'records:_deleted';

  String _key(String resource) => 'records:$resource';

  List<RecordItem> read(String resource) {
    final raw = _store.read(_key(resource));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().map(_fromJson).toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> write(String resource, List<RecordItem> items) =>
      _store.write(_key(resource), jsonEncode(items.map(_toJson).toList()));

  List<Tombstone> readTombstones() {
    final raw = _store.read(_tombstonesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().map(Tombstone.fromJson).toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> writeTombstones(List<Tombstone> items) =>
      _store.write(_tombstonesKey, jsonEncode(items.map((t) => t.toJson()).toList()));

  static RecordItem _fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return RecordItem(
      id: json['id'] as String,
      createdAt: created,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? created,
      values: Map<String, Object?>.from((json['values'] as Map<dynamic, dynamic>?) ?? const <String, Object?>{}),
      synced: json['synced'] == true,
    );
  }

  static Map<String, dynamic> _toJson(RecordItem item) => {
        'id': item.id,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
        'values': item.values,
        'synced': item.synced,
      };
}
