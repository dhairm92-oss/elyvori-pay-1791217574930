import 'dart:async';
import 'dart:convert';

import 'realtime_event.dart';

/// Parses a Server-Sent Events byte stream (text/event-stream) into
/// [RealtimeEvent]s, following the WHATWG event-stream rules:
/// `event:`, `data:` (multi-line), `id:`, comments (`:`) and blank-line dispatch.
class SseParser extends StreamTransformerBase<String, RealtimeEvent> {
  const SseParser();

  @override
  Stream<RealtimeEvent> bind(Stream<String> lines) async* {
    String? eventName;
    String? lastId;
    final data = StringBuffer();
    var hasData = false;

    await for (final rawLine in lines) {
      final line = rawLine.endsWith('\r') ? rawLine.substring(0, rawLine.length - 1) : rawLine;

      if (line.isEmpty) {
        if (hasData) {
          yield RealtimeEvent.fromRaw(data.toString(), fallbackType: eventName ?? 'message', id: lastId);
        }
        eventName = null;
        data.clear();
        hasData = false;
        continue;
      }
      if (line.startsWith(':')) continue; // comment / keep-alive

      final colon = line.indexOf(':');
      final field = colon == -1 ? line : line.substring(0, colon);
      var value = colon == -1 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);

      switch (field) {
        case 'event':
          eventName = value;
        case 'data':
          if (hasData) data.write('\n');
          data.write(value);
          hasData = true;
        case 'id':
          lastId = value;
        default:
          break;
      }
    }
    if (hasData) {
      yield RealtimeEvent.fromRaw(data.toString(), fallbackType: eventName ?? 'message', id: lastId);
    }
  }

  /// Convenience: bytes -> UTF-8 lines -> events.
  static Stream<RealtimeEvent> fromBytes(Stream<List<int>> bytes) =>
      bytes.transform(utf8.decoder).transform(const LineSplitter()).transform(const SseParser());
}
