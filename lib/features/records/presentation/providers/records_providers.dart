import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/cloud.dart';
import '../../../../core/di/core_providers.dart';
import '../../../registry.dart';
import '../../data/cloud_sync_service.dart';
import '../../data/datasources/records_local_data_source.dart';
import '../../data/repositories/records_repository_impl.dart';
import '../../domain/entities/record_item.dart';
import '../../domain/entities/resource_spec.dart';
import '../../domain/repositories/records_repository.dart';
import '../../domain/usecases/records_usecases.dart';

/// The app syncs with its Elyvori cloud (standalone apps that have one).
bool get cloudSyncEnabled => cloudEnabled && !useElyvoriAgents;

final recordsLocalProvider = Provider<RecordsLocalDataSource>(
  (ref) => RecordsLocalDataSource(ref.watch(keyValueStoreProvider)),
);

final recordsRepositoryProvider = Provider<RecordsRepository>(
  (ref) => RecordsRepositoryImpl(local: ref.watch(recordsLocalProvider), trackDeletes: cloudSyncEnabled),
);

/// Bumped after every local or synced change; every data view rebuilds.
class DataVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

final dataVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

ResourceSpec specFor(String key) => appResources.firstWhere(
      (r) => r.key == key,
      orElse: () => throw ArgumentError('Unknown module "$key"'),
    );

/// Every module's rows, read straight from the device (always instant).
final allRecordsProvider = Provider<Map<String, List<RecordItem>>>((ref) {
  ref.watch(dataVersionProvider);
  final local = ref.watch(recordsLocalProvider);
  return {for (final spec in appResources) spec.key: local.read(spec.key)};
});

/// Items of one module, keyed by the module key.
class RecordsNotifier extends FamilyAsyncNotifier<List<RecordItem>, String> {
  ResourceSpec get spec => specFor(arg);

  @override
  Future<List<RecordItem>> build(String arg) async {
    ref.watch(dataVersionProvider);
    final result = await ref.read(recordsRepositoryProvider).list(specFor(arg));
    return result.when(success: (items) => items, failure: (f) => throw f);
  }

  void _changed() {
    ref.read(dataVersionProvider.notifier).bump();
    ref.read(syncControllerProvider.notifier).schedule();
  }

  /// Returns an error message, or null when saved.
  Future<String?> save(Map<String, String> input, {RecordItem? existing}) async {
    final result = await SaveRecord(ref.read(recordsRepositoryProvider))(spec, input, existing: existing);
    return result.when(
      success: (_) {
        _changed();
        return null;
      },
      failure: (f) => f.message,
    );
  }

  Future<void> remove(String id) async {
    final previous = state.valueOrNull ?? const <RecordItem>[];
    state = AsyncData(previous.where((i) => i.id != id).toList()); // optimistic
    final result = await ref.read(recordsRepositoryProvider).delete(spec, id);
    if (result.isSuccess) {
      _changed();
    } else {
      state = AsyncData(previous);
    }
  }
}

final recordsProvider =
    AsyncNotifierProvider.family<RecordsNotifier, List<RecordItem>, String>(RecordsNotifier.new);

// ------------------------------------------------------------------ cloud sync
final cloudSyncServiceProvider = Provider<CloudSyncService>(
  (ref) => CloudSyncService(
    api: ref.watch(apiClientProvider),
    local: ref.watch(recordsLocalProvider),
    store: ref.watch(keyValueStoreProvider),
    resources: appResources,
  ),
);

enum SyncPhase { disabled, idle, syncing, error }

class SyncState {
  const SyncState({required this.phase, this.lastSync, this.pending = 0});

  final SyncPhase phase;
  final DateTime? lastSync;
  final int pending;

  SyncState copyWith({SyncPhase? phase, DateTime? lastSync, int? pending}) => SyncState(
        phase: phase ?? this.phase,
        lastSync: lastSync ?? this.lastSync,
        pending: pending ?? this.pending,
      );
}

class SyncController extends Notifier<SyncState> {
  Timer? _debounce;
  bool _active = false;

  CloudSyncService get _service => ref.read(cloudSyncServiceProvider);

  @override
  SyncState build() {
    ref.onDispose(() => _debounce?.cancel());
    if (!cloudSyncEnabled) return const SyncState(phase: SyncPhase.disabled);
    final service = ref.read(cloudSyncServiceProvider);
    return SyncState(phase: SyncPhase.idle, lastSync: service.lastSyncAt, pending: service.pendingCount);
  }

  /// Starts syncing for the signed-in account (call after sign in / app start).
  void activate() {
    if (!cloudSyncEnabled) return;
    _active = true;
    unawaited(syncNow());
  }

  /// Stops syncing (sign out).
  void deactivate() {
    _active = false;
    _debounce?.cancel();
  }

  /// Syncs shortly after a burst of changes.
  void schedule() {
    if (!cloudSyncEnabled) return;
    state = state.copyWith(pending: _service.pendingCount);
    if (!_active) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () => unawaited(syncNow()));
  }

  Future<void> syncNow() async {
    if (!cloudSyncEnabled || !_active || state.phase == SyncPhase.syncing) return;
    state = state.copyWith(phase: SyncPhase.syncing);
    try {
      final report = await _service.sync();
      state = SyncState(phase: SyncPhase.idle, lastSync: DateTime.now(), pending: _service.pendingCount);
      if (report.pulled > 0 || report.pushed > 0) ref.read(dataVersionProvider.notifier).bump();
    } catch (_) {
      state = state.copyWith(phase: SyncPhase.error, pending: _service.pendingCount);
    }
  }

  Future<void> clearLocalData() async {
    deactivate();
    await _service.clearLocalData();
    state = const SyncState(phase: SyncPhase.idle);
    ref.read(dataVersionProvider.notifier).bump();
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);
