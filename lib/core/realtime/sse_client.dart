import 'dart:async';

import 'package:dio/dio.dart';

import '../network/token_storage.dart';
import 'backoff.dart';
import 'realtime_client.dart';
import 'realtime_event.dart';
import 'sse_parser.dart';

/// Server-Sent Events client over Dio streaming, with JWT auth,
/// `Last-Event-ID` resume and automatic reconnect with backoff.
class SseClient implements RealtimeClient {
  SseClient({
    required this.uri,
    required this.tokens,
    Dio? dio,
    this.sendPath,
    Backoff? backoff,
  })  : _dio = dio ??
            // no receiveTimeout: the event stream stays open on purpose
            Dio(BaseOptions(connectTimeout: const Duration(seconds: 20))),
        _backoff = backoff ?? Backoff();

  final Uri uri;
  final TokenStorage tokens;

  /// Optional HTTP endpoint used by [send] (SSE itself is one-way).
  final Uri? sendPath;

  final Dio _dio;
  final Backoff _backoff;
  final _events = StreamController<RealtimeEvent>.broadcast();
  final _status = StreamController<RealtimeStatus>.broadcast();
  RealtimeStatus _current = RealtimeStatus.idle;
  CancelToken? _cancel;
  StreamSubscription<RealtimeEvent>? _subscription;
  Timer? _retryTimer;
  String? _lastEventId;
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
    _cancel = CancelToken();
    try {
      final token = await tokens.readAccessToken();
      final response = await _dio.getUri<ResponseBody>(
        uri,
        cancelToken: _cancel,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            if (_lastEventId != null) 'Last-Event-ID': _lastEventId,
          },
        ),
      );
      final body = response.data;
      if (body == null) throw StateError('Empty event stream');
      _setStatus(RealtimeStatus.connected);
      _backoff.reset();
      await _subscription?.cancel();
      _subscription = SseParser.fromBytes(body.stream).listen(
        (event) {
          if (event.id != null) _lastEventId = event.id;
          if (!event.isHeartbeat && !_events.isClosed) _events.add(event);
        },
        onError: (Object _) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      _scheduleReconnect(offline: e.type == DioExceptionType.connectionError);
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect({bool offline = false}) {
    if (!_wanted) return;
    _setStatus(offline ? RealtimeStatus.offline : RealtimeStatus.reconnecting);
    _retryTimer?.cancel();
    _retryTimer = Timer(_backoff.next(), () => unawaited(_open()));
  }

  @override
  Future<void> send(Map<String, dynamic> message) async {
    final target = sendPath;
    if (target == null) {
      throw UnsupportedError('This SSE channel is receive-only (no sendPath configured).');
    }
    final token = await tokens.readAccessToken();
    await _dio.postUri<dynamic>(
      target,
      data: message,
      options: Options(headers: {if (token != null) 'Authorization': 'Bearer $token'}),
    );
  }

  @override
  Future<void> disconnect() async {
    _wanted = false;
    _retryTimer?.cancel();
    _cancel?.cancel();
    await _subscription?.cancel();
    _subscription = null;
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
