import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/pulse_ring.dart';
import '../../domain/entities/agent.dart';

class AgentStatusCard extends StatelessWidget {
  const AgentStatusCard({super.key, required this.agent, required this.onTap});

  final Agent agent;
  final VoidCallback onTap;

  static Color colorFor(AgentState s) => switch (s) {
        AgentState.active => AppColors.emerald,
        AgentState.busy => AppColors.cyan,
        AgentState.paused => AppColors.amber,
        AgentState.error => AppColors.rose,
      };

  static String labelFor(AgentState s) => switch (s) {
        AgentState.active => 'Online',
        AgentState.busy => 'Working',
        AgentState.paused => 'Paused',
        AgentState.error => 'Error',
      };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(agent.state);
    return GlassContainer(
      glow: agent.state == AgentState.busy ? AppColors.cyan : null,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: AppColors.neonGradient,
            ),
            alignment: Alignment.center,
            child: Text(
              agent.name.isEmpty ? '?' : agent.name.characters.first.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.obsidian),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  agent.lastActivity ?? agent.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PulseRing(color: color, active: agent.state != AgentState.paused),
              const SizedBox(height: 4),
              Text(labelFor(agent.state), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
