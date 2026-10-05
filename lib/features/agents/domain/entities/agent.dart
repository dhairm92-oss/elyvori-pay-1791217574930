import 'package:equatable/equatable.dart';

enum AgentState { active, busy, paused, error }

class Agent extends Equatable {
  const Agent({
    required this.id,
    required this.name,
    required this.type,
    required this.state,
    required this.updatedAt,
    this.lastActivity,
  });

  final String id;
  final String name;
  final String type;
  final AgentState state;
  final DateTime updatedAt;
  final String? lastActivity;

  Agent copyWith({AgentState? state, String? lastActivity, DateTime? updatedAt}) => Agent(
        id: id,
        name: name,
        type: type,
        state: state ?? this.state,
        updatedAt: updatedAt ?? this.updatedAt,
        lastActivity: lastActivity ?? this.lastActivity,
      );

  @override
  List<Object?> get props => [id, name, type, state, updatedAt, lastActivity];
}
