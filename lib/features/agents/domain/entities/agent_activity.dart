import 'package:equatable/equatable.dart';

/// One live item in the activity feed (from the realtime channel).
class AgentActivity extends Equatable {
  const AgentActivity({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.at,
  });

  final String id;
  final String kind;
  final String title;
  final String message;
  final DateTime at;

  @override
  List<Object?> get props => [id, kind, title, message, at];
}
