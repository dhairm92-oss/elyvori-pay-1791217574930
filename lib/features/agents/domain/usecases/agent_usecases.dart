import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/agent.dart';
import '../entities/agent_activity.dart';
import '../repositories/agents_repository.dart';

class WatchAgents {
  const WatchAgents(this._repository);
  final AgentsRepository _repository;

  Stream<Result<List<Agent>>> call() => _repository.watchAgents().map(
        (result) => result.map((agents) => [...agents]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt))),
      );
}

class WatchAgentActivity {
  const WatchAgentActivity(this._repository);
  final AgentsRepository _repository;

  Stream<AgentActivity> call() => _repository.watchActivity();
}

class SendAgentCommand {
  const SendAgentCommand(this._repository);
  final AgentsRepository _repository;

  Future<Result<bool>> call(String agentId, String command) async {
    final text = command.trim();
    if (text.isEmpty) return const Result.failure(Failure('Write a command first.'));
    if (text.length > 2000) return const Result.failure(Failure('The command is too long.'));
    return _repository.sendCommand(agentId, text);
  }
}
