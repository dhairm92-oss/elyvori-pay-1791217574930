import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/registry.dart';
import '../config/app_config.dart';
import '../config/cloud.dart';
import '../connectivity/connectivity_service.dart';
import '../network/api_client.dart';
import '../network/token_storage.dart';
import '../realtime/realtime_client.dart';
import '../realtime/realtime_event.dart';
import '../realtime/sse_client.dart';
import '../realtime/websocket_client.dart';
import '../storage/key_value_store.dart';
import '../storage/local_cache.dart';
import '../storage/sync_queue.dart';

/// Overridden in main() once the local database is open.
final keyValueStoreProvider = Provider<KeyValueStore>((ref) => throw UnimplementedError('Override in main()'));

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureTokenStorage());

/// Increments every time the server rejects the session; the auth
/// controller listens and signs the user out.
class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void expire() => state = state + 1;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, int>(SessionExpiredNotifier.new);

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient(
    baseUrl: config.apiBaseUrl,
    tokens: ref.watch(tokenStorageProvider),
    onSessionExpired: () => ref.read(sessionExpiredProvider.notifier).expire(),
    // apps with their own Elyvori cloud refresh their tokens there
    refreshPath: cloudEnabled && !useElyvoriAgents ? cloudPath('/auth/refresh') : '/auth/refresh',
  );
});

final localCacheProvider = Provider<LocalCache>((ref) => LocalCache(ref.watch(keyValueStoreProvider)));

final syncQueueProvider = Provider<SyncQueue>((ref) {
  final queue = SyncQueue(ref.watch(keyValueStoreProvider));
  ref.onDispose(queue.dispose);
  return queue;
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.isOnline;
  yield* service.onStatusChange;
});

/// One shared realtime connection for the whole app (SSE by default,
/// WebSocket when REALTIME_TRANSPORT=websocket).
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokens = ref.watch(tokenStorageProvider);
  final RealtimeClient client = config.transport == RealtimeTransport.webSocket
      ? WebSocketClient(uri: config.realtimeUri, tokens: tokens)
      : SseClient(uri: config.realtimeUri, tokens: tokens);
  ref.onDispose(client.dispose);
  return client;
});

final realtimeStatusProvider = StreamProvider<RealtimeStatus>((ref) async* {
  final client = ref.watch(realtimeClientProvider);
  yield client.currentStatus;
  yield* client.status;
});
