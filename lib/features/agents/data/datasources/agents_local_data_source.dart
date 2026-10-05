import '../../../../core/storage/local_cache.dart';
import '../../domain/entities/agent.dart';
import '../models/agent_model.dart';

class AgentsLocalDataSource {
  const AgentsLocalDataSource(this._cache);

  final LocalCache _cache;
  static const _key = 'agents';

  List<Agent>? read() {
    final value = _cache.get(_key)?.value;
    if (value is! List) return null;
    return value.whereType<Map<String, dynamic>>().map(AgentMapper.fromJson).toList();
  }

  Future<void> write(List<Agent> agents) => _cache.put(_key, agents.map(AgentMapper.toJson).toList());
}
