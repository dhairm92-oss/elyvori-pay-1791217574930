import 'dart:convert';

import 'package:equatable/equatable.dart';

/// One message received from the realtime channel (SSE or WebSocket).
class RealtimeEvent extends Equatable {
  const RealtimeEvent({required this.type, required this.data, required this.receivedAt, this.id});

  /// Builds an event from a raw text frame. JSON objects are decoded;
  /// a `type` field inside the JSON wins over [fallbackType].
  factory RealtimeEvent.fromRaw(String raw, {String fallbackType = 'message', String? id}) {
    Object? decoded = raw;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      decoded = raw;
    }
    var type = fallbackType;
    Map<String, dynamic> data;
    if (decoded is Map<String, dynamic>) {
      final inner = decoded['type'];
      if (inner is String && inner.isNotEmpty && fallbackType == 'message') type = inner;
      final payload = decoded['data'];
      data = payload is Map<String, dynamic> ? payload : decoded;
    } else {
      data = {'value': decoded};
    }
    return RealtimeEvent(type: type, data: data, receivedAt: DateTime.now(), id: id);
  }

  final String type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  final String? id;

  bool get isHeartbeat => type == 'heartbeat' || type == 'ping';

  @override
  List<Object?> get props => [type, data, id];
}

/// Connection state of the realtime channel, for status badges.
enum RealtimeStatus { idle, connecting, connected, reconnecting, offline }
