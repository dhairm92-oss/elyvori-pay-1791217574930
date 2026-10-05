import '../../../../core/network/api_client.dart';
import '../../../../core/realtime/realtime_client.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../domain/entities/agent.dart';
import '../models/agent_model.dart';

class AgentsRemoteDataSource {
  const AgentsRemoteDataSource(this._api, this._realtime);

  final ApiClient _api;
  final RealtimeClient _realtime;

  Future<List<Agent>> fetchAgents() async {
    final list = await _api.get<List<dynamic>>('/agents');
    return list.whereType<Map<String, dynamic>>().map(AgentMapper.fromJson).toList();
  }

  /// Sends a natural-language command to the platform's agent orchestrator.
  Future<void> sendCommand(String agentId, String command) async {
    await _api.post<Map<String, dynamic>>('/orchestrator/command', body: {'text': command, 'agentId': agentId});
  }

  Stream<RealtimeEvent> get events => _realtime.events;
}
