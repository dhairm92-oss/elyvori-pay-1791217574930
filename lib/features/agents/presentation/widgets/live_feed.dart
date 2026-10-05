import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../domain/entities/agent_activity.dart';

class LiveFeed extends StatelessWidget {
  const LiveFeed({super.key, required this.items});

  final List<AgentActivity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const GlassContainer(
        child: Row(
          children: [
            Icon(Icons.sensors, color: AppColors.textMuted),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Listening for live agent activity…',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final item in items.take(12))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.bolt, size: 18, color: AppColors.cyan),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (item.message.isNotEmpty)
                          Text(
                            item.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    TimeOfDay.fromDateTime(item.at).format(context),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ).animate(key: ValueKey(item.id)).fadeIn(duration: 300.ms).slideX(begin: 0.05),
          ),
      ],
    );
  }
}
