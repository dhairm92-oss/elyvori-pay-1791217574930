import '../../domain/entities/agent.dart';
import '../../domain/entities/agent_activity.dart';

abstract final class AgentMapper {
  static Agent fromJson(Map<String, dynamic> json) => Agent(
        id: json['id'].toString(),
        name: (json['name'] as String?) ?? 'Agent',
        type: (json['type'] as String?) ?? 'general',
        state: _state(json['status'] as String?),
        updatedAt: DateTime.tryParse((json['updatedAt'] ?? json['createdAt'] ?? '').toString()) ?? DateTime.now(),
        lastActivity: json['lastActivity'] as String?,
      );

  static Map<String, dynamic> toJson(Agent a) => {
        'id': a.id,
        'name': a.name,
        'type': a.type,
        'status': a.state.name.toUpperCase(),
        'updatedAt': a.updatedAt.toIso8601String(),
        'lastActivity': a.lastActivity,
      };

  static AgentState _state(String? raw) => switch ((raw ?? '').toUpperCase()) {
        'ACTIVE' || 'IDLE' || 'ONLINE' => AgentState.active,
        'BUSY' || 'RUNNING' || 'EXECUTING' => AgentState.busy,
        'PAUSED' || 'DISABLED' || 'INACTIVE' => AgentState.paused,
        'ERROR' || 'FAILED' => AgentState.error,
        _ => AgentState.active,
      };

  /// Turns a realtime notification (`{type, title, message, id, createdAt}`) into a feed item.
  static AgentActivity activityFromEvent(String eventType, Map<String, dynamic> data) => AgentActivity(
        id: (data['id'] ?? DateTime.now().microsecondsSinceEpoch).toString(),
        kind: (data['type'] as String?) ?? eventType,
        title: (data['title'] as String?) ?? eventType,
        message: (data['message'] as String?) ?? (data['value']?.toString() ?? ''),
        at: DateTime.tryParse((data['createdAt'] ?? '').toString()) ?? DateTime.now(),
      );
}
