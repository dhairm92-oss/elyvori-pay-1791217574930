import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../network/token_storage.dart';
import 'backoff.dart';
import 'realtime_client.dart';
import 'realtime_event.dart';

/// Bidirectional WebSocket client with JWT auth header, ping keep-alive,
/// an outbound queue while disconnected, and automatic reconnect.
class WebSocketClient implements RealtimeClient {
  WebSocketClient({
    required this.uri,
    required this.tokens,
    Backoff? backoff,
    this.pingInterval = const Duration(seconds: 20),
  }) : _backoff = backoff ?? Backoff();

  final Uri uri;
  final TokenStorage tokens;
  final Duration pingInterval;
  final Backoff _backoff;

  final _events = StreamController<RealtimeEvent>.broadcast();
  final _status = StreamController<RealtimeStatus>.broadcast();
  final _outbox = <String>[];
  RealtimeStatus _current = RealtimeStatus.idle;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  bool _wanted = false;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Stream<RealtimeStatus> get status => _status.stream;

  @override
  RealtimeStatus get currentStatus => _current;

  void _setStatus(RealtimeStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  @override
  Future<void> connect() async {
    _wanted = true;
    await _open();
  }

  Future<void> _open() async {
    if (!_wanted) return;
    _retryTimer?.cancel();
    _setStatus(_backoff.attempt == 0 ? RealtimeStatus.connecting : RealtimeStatus.reconnecting);
    try {
      final token = await tokens.readAccessToken();
      // cross-platform (mobile + web): browsers can't set headers, so the token goes in the URL
      final target = (token != null && token.isNotEmpty)
          ? uri.replace(queryParameters: {...uri.queryParameters, 'access_token': token})
          : uri;
      final channel = WebSocketChannel.connect(target);
      await channel.ready.timeout(const Duration(seconds: 20));
      _channel = channel;
      _setStatus(RealtimeStatus.connected);
      _backoff.reset();
      _flushOutbox();
      await _subscription?.cancel();
      _subscription = channel.stream.listen(
        (Object? frame) {
          final text = frame is String ? frame : utf8.decode(frame as List<int>);
          final event = RealtimeEvent.fromRaw(text);
          if (!event.isHeartbeat && !_events.isClosed) _events.add(event);
        },
        onError: (Object _) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect(offline: true);
    }
  }

  void _scheduleReconnect({bool offline = false}) {
    _channel = null;
    if (!_wanted) return;
    _setStatus(offline ? RealtimeStatus.offline : RealtimeStatus.reconnecting);
    _retryTimer?.cancel();
    _retryTimer = Timer(_backoff.next(), () => unawaited(_open()));
  }

  void _flushOutbox() {
    final channel = _channel;
    if (channel == null) return;
    while (_outbox.isNotEmpty) {
      channel.sink.add(_outbox.removeAt(0));
    }
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    final encoded = jsonEncode(message);
    final channel = _channel;
    if (channel == null || _current != RealtimeStatus.connected) {
      _outbox.add(encoded); // delivered as soon as the socket is back
      return;
    }
    channel.sink.add(encoded);
  }

  @override
  Future<void> disconnect() async {
    _wanted = false;
    _retryTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _backoff.reset();
    _setStatus(RealtimeStatus.idle);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _events.close();
    await _status.close();
  }
}
