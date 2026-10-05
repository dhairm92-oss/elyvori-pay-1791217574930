import '../../../../core/connectivity/connectivity_service.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/sync_queue.dart';
import '../../domain/entities/agent.dart';
import '../../domain/entities/agent_activity.dart';
import '../../domain/repositories/agents_repository.dart';
import '../datasources/agents_local_data_source.dart';
import '../datasources/agents_remote_data_source.dart';
import '../models/agent_model.dart';

class AgentsRepositoryImpl implements AgentsRepository {
  AgentsRepositoryImpl({
    required this.remote,
    required this.local,
    required this.queue,
    required this.connectivity,
    required this.api,
  });

  final AgentsRemoteDataSource remote;
  final AgentsLocalDataSource local;
  final SyncQueue queue;
  final ConnectivityService connectivity;
  final ApiClient api;

  @override
  Stream<Result<List<Agent>>> watchAgents() async* {
    final cached = local.read();
    if (cached != null) yield Result.success(cached);
    try {
      final fresh = await remote.fetchAgents();
      await local.write(fresh);
      yield Result.success(fresh);
    } catch (error) {
      // Offline with a cache: keep showing it silently.
      if (cached == null) yield Result.failure(Failure.fromException(error));
    }
  }

  @override
  Stream<AgentActivity> watchActivity() =>
      remote.events.map((e) => AgentMapper.activityFromEvent(e.type, e.data));

  @override
  Future<Result<bool>> sendCommand(String agentId, String command) async {
    final body = {'text': command, 'agentId': agentId};
    if (!await connectivity.isOnline) {
      await queue.enqueue(method: 'POST', path: '/orchestrator/command', body: body);
      return const Result.success(false); // false = queued, sent when back online
    }
    try {
      await remote.sendCommand(agentId, command);
      return const Result.success(true);
    } on NetworkException {
      await queue.enqueue(method: 'POST', path: '/orchestrator/command', body: body);
      return const Result.success(false);
    } catch (error) {
      return Result.failure(Failure.fromException(error));
    }
  }

  /// Replays commands queued while offline. Called when connectivity returns.
  Future<int> syncPending() => queue.flush((op) async {
        try {
          switch (op.method) {
            case 'POST':
              await api.post<dynamic>(op.path, body: op.body);
            case 'PATCH':
              await api.patch<dynamic>(op.path, body: op.body);
            case 'DELETE':
              await api.delete<dynamic>(op.path, body: op.body);
            default:
              return SyncOutcome.drop;
          }
          return SyncOutcome.done;
        } on NetworkException {
          return SyncOutcome.retryLater;
        } on TimeoutAppException {
          return SyncOutcome.retryLater;
        } on ServerException catch (e) {
          // 4xx will never succeed: drop it. 5xx: try again later.
          return (e.statusCode ?? 500) >= 500 ? SyncOutcome.retryLater : SyncOutcome.drop;
        }
      });
}
