import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/error/failure.dart';
import '../../data/datasources/agents_local_data_source.dart';
import '../../data/datasources/agents_remote_data_source.dart';
import '../../data/repositories/agents_repository_impl.dart';
import '../../domain/entities/agent.dart';
import '../../domain/entities/agent_activity.dart';
import '../../domain/usecases/agent_usecases.dart';

final agentsRepositoryProvider = Provider<AgentsRepositoryImpl>((ref) {
  return AgentsRepositoryImpl(
    remote: AgentsRemoteDataSource(ref.watch(apiClientProvider), ref.watch(realtimeClientProvider)),
    local: AgentsLocalDataSource(ref.watch(localCacheProvider)),
    queue: ref.watch(syncQueueProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    api: ref.watch(apiClientProvider),
  );
});

/// Agents list: cache first, then network; refreshes when the device comes
/// back online (and flushes queued offline commands at the same time).
final agentsProvider = StreamProvider.autoDispose<List<Agent>>((ref) {
  final repository = ref.watch(agentsRepositoryProvider);
  ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
    final wasOffline = previous?.valueOrNull == false;
    if (wasOffline && next.valueOrNull == true) {
      unawaited(repository.syncPending());
      ref.invalidateSelf();
    }
  });
  return WatchAgents(repository)().map(
    (result) => result.when(success: (agents) => agents, failure: (failure) => throw failure),
  );
});

/// Live activity feed: keeps the latest 50 events, newest first, and keeps
/// the realtime connection open while a screen is watching it.
class ActivityFeedNotifier extends AutoDisposeNotifier<List<AgentActivity>> {
  StreamSubscription<AgentActivity>? _subscription;

  @override
  List<AgentActivity> build() {
    final repository = ref.watch(agentsRepositoryProvider);
    final client = ref.watch(realtimeClientProvider);
    unawaited(client.connect());
    _subscription = WatchAgentActivity(repository)().listen((activity) {
      state = [activity, ...state].take(50).toList();
    });
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      unawaited(client.disconnect());
    });
    return const [];
  }
}

final activityFeedProvider =
    AutoDisposeNotifierProvider<ActivityFeedNotifier, List<AgentActivity>>(ActivityFeedNotifier.new);

/// Sends commands; returns a user-facing message.
class CommandController extends AutoDisposeNotifier<bool> {
  @override
  bool build() => false; // true while sending

  Future<String> send(String agentId, String command) async {
    state = true;
    try {
      final result = await SendAgentCommand(ref.read(agentsRepositoryProvider))(agentId, command);
      final message = result.when<String>(
        success: (sentNow) => sentNow ? 'Command sent ⚡' : 'You are offline — it will be sent automatically.',
        failure: (Failure f) => f.message,
      );
      return message;
    } finally {
      state = false;
    }
  }
}

final commandControllerProvider = AutoDisposeNotifierProvider<CommandController, bool>(CommandController.new);
