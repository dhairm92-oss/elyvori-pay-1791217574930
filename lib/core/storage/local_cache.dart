import 'dart:convert';

import 'key_value_store.dart';

/// JSON cache with a timestamp per entry: read stale data instantly while
/// offline, and know how old it is.
class LocalCache {
  LocalCache(this._store);

  final KeyValueStore _store;

  Future<void> put(String key, Object? json) => _store.write(
        'cache:$key',
        jsonEncode({'at': DateTime.now().toIso8601String(), 'v': json}),
      );

  CacheEntry? get(String key) {
    final raw = _store.read('cache:$key');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CacheEntry(value: map['v'], savedAt: DateTime.parse(map['at'] as String));
    } on FormatException {
      return null;
    }
  }

  Future<void> remove(String key) => _store.remove('cache:$key');
}

class CacheEntry {
  const CacheEntry({required this.value, required this.savedAt});
  final Object? value;
  final DateTime savedAt;

  bool isOlderThan(Duration age) => DateTime.now().difference(savedAt) > age;
}
