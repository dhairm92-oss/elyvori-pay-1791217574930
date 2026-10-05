import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/realtime/realtime_event.dart';
import '../../lib/core/realtime/sse_parser.dart';

Stream<List<int>> _bytes(String text) => Stream.fromIterable([utf8.encode(text)]);

void main() {
  group('SseParser', () {
    test('parses named events with JSON data and ids', () async {
      const raw = 'id: 7\nevent: notification\ndata: {"title":"New lead","message":"Cafe X"}\n\n';
      final events = await SseParser.fromBytes(_bytes(raw)).toList();
      expect(events, hasLength(1));
      expect(events.single.type, 'notification');
      expect(events.single.id, '7');
      expect(events.single.data['title'], 'New lead');
    });

    test('joins multi-line data and ignores comments', () async {
      const raw = ': keep-alive\n\ndata: line one\ndata: line two\n\n';
      final events = await SseParser.fromBytes(_bytes(raw)).toList();
      expect(events, hasLength(1));
      expect(events.single.data['value'], 'line one\nline two');
      expect(events.single.type, 'message');
    });

    test('handles CRLF and events split across chunks', () async {
      final stream = Stream<List<int>>.fromIterable([
        utf8.encode('event: heartbeat\r\ndata: {}\r\n'),
        utf8.encode('\r\nevent: notification\r\ndata: {"ti'),
        utf8.encode('tle":"Paid"}\r\n\r\n'),
      ]);
      final events = await SseParser.fromBytes(stream).toList();
      expect(events.map((e) => e.type), ['heartbeat', 'notification']);
      expect(events.first.isHeartbeat, isTrue);
      expect(events.last.data['title'], 'Paid');
    });

    test('a type inside the JSON names an unnamed event', () {
      final e = RealtimeEvent.fromRaw('{"type":"agent_status","data":{"id":"a1","status":"BUSY"}}');
      expect(e.type, 'agent_status');
      expect(e.data['status'], 'BUSY');
    });
  });
}
