import 'realtime_event.dart';

/// Common contract of the SSE and WebSocket transports.
abstract class RealtimeClient {
  /// Every message from the server (heartbeats excluded).
  Stream<RealtimeEvent> get events;

  /// Connection status changes, for UI badges.
  Stream<RealtimeStatus> get status;

  RealtimeStatus get currentStatus;

  /// Opens the connection and keeps it alive (auto-reconnect) until [disconnect].
  Future<void> connect();

  /// Sends a message upstream. SSE is one-way, so it posts over HTTP instead.
  Future<void> send(Map<String, dynamic> message);

  Future<void> disconnect();

  Future<void> dispose();
}
