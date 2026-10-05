import 'package:hive_ce_flutter/hive_flutter.dart';

/// Minimal string key/value contract over the local database, so caching
/// and the sync queue can be unit-tested with [MemoryKeyValueStore].
abstract class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
  Iterable<String> get keys;
}

class HiveKeyValueStore implements KeyValueStore {
  HiveKeyValueStore._(this._box);

  final Box<String> _box;

  /// Call once at startup (after [initLocalDatabase]).
  static Future<HiveKeyValueStore> open(String name) async =>
      HiveKeyValueStore._(await Hive.openBox<String>(name));

  @override
  String? read(String key) => _box.get(key);

  @override
  Future<void> write(String key, String value) => _box.put(key, value);

  @override
  Future<void> remove(String key) => _box.delete(key);

  @override
  Iterable<String> get keys => _box.keys.cast<String>();
}

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = {};

  @override
  String? read(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Iterable<String> get keys => _data.keys;
}

Future<void> initLocalDatabase() => Hive.initFlutter('elyvori');
