import '../../../../core/result/result.dart';
import '../entities/agent.dart';
import '../entities/agent_activity.dart';

abstract interface class AgentsRepository {
  /// Cached list first (instant, works offline), then fresh from the server.
  Stream<Result<List<Agent>>> watchAgents();

  /// Live activity from the realtime channel.
  Stream<AgentActivity> watchActivity();

  /// Sends a command to an agent; queued and retried later when offline.
  Future<Result<bool>> sendCommand(String agentId, String command);
}
