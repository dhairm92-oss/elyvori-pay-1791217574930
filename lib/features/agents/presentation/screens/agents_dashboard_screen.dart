import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_view.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/neon_background.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../../../core/widgets/pulse_ring.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../home/presentation/widgets/modules_grid.dart';
import '../../../registry.dart';
import '../../domain/entities/agent.dart';
import '../providers/agents_providers.dart';
import '../widgets/agent_status_card.dart';
import '../widgets/live_feed.dart';

class AgentsDashboardScreen extends ConsumerWidget {
  const AgentsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(agentsProvider);
    final feed = ref.watch(activityFeedProvider);
    final status = ref.watch(realtimeStatusProvider).valueOrNull ?? RealtimeStatus.idle;
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final session = ref.watch(authControllerProvider).valueOrNull;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(ref.watch(appConfigProvider).appName, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          _ConnectionBadge(status: status, online: online),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: NeonBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.cyan,
            onRefresh: () async => ref.invalidate(agentsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (!online)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      glow: AppColors.amber,
                      child: Text(
                        'Offline — showing saved data. Commands will be sent when you reconnect.',
                        style: TextStyle(color: AppColors.amber),
                      ),
                    ),
                  ),
                _Header(name: session?.name ?? session?.email ?? ''),
                const SizedBox(height: 16),
                AsyncView<List<Agent>>(
                  value: agents,
                  onRetry: () => ref.invalidate(agentsProvider),
                  isEmpty: (list) => list.isEmpty,
                  emptyMessage: 'No agents yet.',
                  data: (list) => Column(
                    children: [
                      _StatsRow(agents: list),
                      const SizedBox(height: 16),
                      for (var i = 0; i < list.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AgentStatusCard(
                            agent: list[i],
                            onTap: () => _openCommandSheet(context, list[i]),
                          ).animate().fadeIn(delay: (60 * i).ms, duration: 350.ms).slideY(begin: 0.1),
                        ),
                    ],
                  ),
                ),
                if (appResources.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Modules', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 10),
                  const ModulesGrid(modules: appResources),
                ],
                const SizedBox(height: 20),
                const Text('Live activity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 10),
                LiveFeed(items: feed),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCommandSheet(BuildContext context, Agent agent) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommandSheet(agent: agent),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Command center', style: TextStyle(color: AppColors.textSecondary)),
        if (name.isNotEmpty)
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.agents});

  final List<Agent> agents;

  @override
  Widget build(BuildContext context) {
    final working = agents.where((a) => a.state == AgentState.busy).length;
    final healthy = agents.where((a) => a.state != AgentState.error).length;
    final ratio = agents.isEmpty ? 0.0 : healthy / agents.length;
    return GlassContainer(
      child: Row(
        children: [
          NeonGauge(value: ratio, label: '${(ratio * 100).round()}%'),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System health', style: TextStyle(color: AppColors.textSecondary)),
                Text('${agents.length} agents · $working working',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.status, required this.online});

  final RealtimeStatus status;
  final bool online;

  @override
  Widget build(BuildContext context) {
    final (color, label) = !online
        ? (AppColors.amber, 'Offline')
        : switch (status) {
            RealtimeStatus.connected => (AppColors.emerald, 'Live'),
            RealtimeStatus.connecting || RealtimeStatus.reconnecting => (AppColors.cyan, 'Syncing'),
            RealtimeStatus.offline => (AppColors.amber, 'Offline'),
            RealtimeStatus.idle => (AppColors.textMuted, 'Idle'),
          };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          PulseRing(color: color, size: 14, active: status == RealtimeStatus.connected),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CommandSheet extends ConsumerStatefulWidget {
  const _CommandSheet({required this.agent});

  final Agent agent;

  @override
  ConsumerState<_CommandSheet> createState() => _CommandSheetState();
}

class _CommandSheetState extends ConsumerState<_CommandSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = await ref.read(commandControllerProvider.notifier).send(widget.agent.id, _controller.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sending = ref.watch(commandControllerProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GlassContainer(
        radius: 24,
        blur: 24,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Command ${widget.agent.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'e.g. Find 5 cafés in Dubai without a website'),
            ),
            const SizedBox(height: 16),
            NeonButton(label: 'Send', icon: Icons.send_rounded, loading: sending, onPressed: _send),
          ],
        ),
      ),
    );
  }
}
