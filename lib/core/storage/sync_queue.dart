import 'dart:async';
import 'dart:convert';

import 'key_value_store.dart';

/// A write made while offline, persisted until the server accepts it.
class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.method,
    required this.path,
    required this.createdAt,
    this.body,
    this.attempts = 0,
  });

  factory PendingOperation.fromJson(Map<String, dynamic> json) => PendingOperation(
        id: json['id'] as String,
        method: json['method'] as String,
        path: json['path'] as String,
        body: json['body'],
        createdAt: DateTime.parse(json['createdAt'] as String),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String method;
  final String path;
  final Object? body;
  final DateTime createdAt;
  final int attempts;

  PendingOperation retried() => PendingOperation(
        id: id,
        method: method,
        path: path,
        body: body,
        createdAt: createdAt,
        attempts: attempts + 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
      };
}

/// Outcome of sending one operation.
enum SyncOutcome { done, retryLater, drop }

/// Durable FIFO of offline writes. [flush] replays them in order and stops at
/// the first one that must wait (still offline / server down), so ordering is kept.
class SyncQueue {
  SyncQueue(this._store, {this.maxAttempts = 8});

  final KeyValueStore _store;
  final int maxAttempts;
  bool _flushing = false;
  final _changes = StreamController<int>.broadcast();

  static const _prefix = 'sync:';

  /// Emits the number of pending operations whenever it changes.
  Stream<int> get pendingCount => _changes.stream;

  List<PendingOperation> get pending {
    final ops = <PendingOperation>[];
    for (final key in _store.keys.where((k) => k.startsWith(_prefix))) {
      final raw = _store.read(key);
      if (raw == null) continue;
      try {
        ops.add(PendingOperation.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } on FormatException {
        continue;
      }
    }
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  Future<PendingOperation> enqueue({required String method, required String path, Object? body}) async {
    final now = DateTime.now();
    final op = PendingOperation(
      id: '${now.microsecondsSinceEpoch}',
      method: method,
      path: path,
      body: body,
      createdAt: now,
    );
    await _store.write('$_prefix${op.id}', jsonEncode(op.toJson()));
    _changes.add(pending.length);
    return op;
  }

  /// Replays queued operations with [send]. Returns how many were completed.
  Future<int> flush(Future<SyncOutcome> Function(PendingOperation op) send) async {
    if (_flushing) return 0;
    _flushing = true;
    var done = 0;
    try {
      for (final op in pending) {
        SyncOutcome outcome;
        try {
          outcome = await send(op);
        } catch (_) {
          outcome = SyncOutcome.retryLater;
        }
        if (outcome == SyncOutcome.done || outcome == SyncOutcome.drop) {
          await _store.remove('$_prefix${op.id}');
          if (outcome == SyncOutcome.done) done++;
          continue;
        }
        final next = op.retried();
        if (next.attempts >= maxAttempts) {
          await _store.remove('$_prefix${op.id}');
        } else {
          await _store.write('$_prefix${op.id}', jsonEncode(next.toJson()));
        }
        break; // keep order: wait before sending anything newer
      }
    } finally {
      _flushing = false;
      _changes.add(pending.length);
    }
    return done;
  }

  Future<void> dispose() => _changes.close();
}
