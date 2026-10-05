import 'package:equatable/equatable.dart';

class RecordItem extends Equatable {
  RecordItem({
    required this.id,
    required this.createdAt,
    required this.values,
    DateTime? updatedAt,
    this.synced = false,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final DateTime createdAt;

  /// Last local or remote change (last write wins when syncing).
  final DateTime updatedAt;
  final Map<String, Object?> values;

  /// True once the cloud has this exact version.
  final bool synced;

  RecordItem copyWith({Map<String, Object?>? values, bool? synced, DateTime? updatedAt}) => RecordItem(
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        values: values ?? this.values,
        synced: synced ?? this.synced,
      );

  @override
  List<Object?> get props => [id, createdAt, updatedAt, values, synced];
}
