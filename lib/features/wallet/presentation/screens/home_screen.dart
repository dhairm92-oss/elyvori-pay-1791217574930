import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/neon_background.dart';
import '../../domain/wallet_models.dart';
import '../../domain/wallet_strings.dart';
import '../providers/wallet_providers.dart';
import '../widgets/wallet_widgets.dart';
import 'activity_screens.dart';
import 'settings_screen.dart';

/// Signed-in shell: Home · Activity · Requests · Settings.
class WalletShell extends ConsumerStatefulWidget {
  const WalletShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<WalletShell> createState() => _WalletShellState();
}

class _WalletShellState extends ConsumerState<WalletShell> {
  late int _tab = widget.initialTab.clamp(0, 3);

  @override
  void didUpdateWidget(covariant WalletShell old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab) _tab = widget.initialTab.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(requestsProvider).valueOrNull?.where((r) => r.role == 'payer' && r.isPending).length ?? 0;
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: IndexedStack(
                  index: _tab,
                  children: [
                    HomeTab(onOpenTab: (i) => setState(() => _tab = i)),
                    const HistoryTab(),
                    const RequestsTab(),
                    const SettingsTab(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.cyan.withValues(alpha: 0.18),
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i == 1) ref.invalidate(historyProvider);
          if (i == 2) ref.invalidate(requestsProvider);
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet_rounded), label: WS.t('الرئيسية', 'Home')),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long_rounded), label: WS.t('الحركات', 'Activity')),
          NavigationDestination(
            icon: Badge(isLabelVisible: pending > 0, label: Text('$pending'), child: const Icon(Icons.request_page_outlined)),
            selectedIcon: const Icon(Icons.request_page_rounded),
            label: WS.t('الطلبات', 'Requests'),
          ),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: WS.settingsTitle),
        ],
      ),
    );
  }
}

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return WS.t('صباح الخير', 'Good morning');
    if (h < 18) return WS.t('مساء الخير', 'Good afternoon');
    return WS.t('مساء الخير', 'Good evening');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(walletAuthProvider).valueOrNull?.profile;
    final currency = ref.watch(selectedCurrencyProvider);
    final recent = ref.watch(historyProvider((currency, null)));
    final pending = ref.watch(requestsProvider).valueOrNull?.where((r) => r.role == 'payer' && r.isPending).toList() ?? const <PayRequest>[];
    if (profile == null) return const Center(child: CircularProgressIndicator(color: AppColors.cyan));

    final List<(IconData, String, VoidCallback, int)> actions = [
      (Icons.north_east_rounded, WS.send, () => context.push('/send'), 0),
      (Icons.south_west_rounded, WS.receive, () => context.push('/receive'), 0),
      (Icons.qr_code_scanner_rounded, WS.scan, () => context.push('/scan'), 0),
      (Icons.request_page_rounded, WS.request, () => context.push('/request'), 0),
      (Icons.add_card_rounded, WS.topUp, () => context.push('/topup'), 0),
      (Icons.account_balance_rounded, WS.withdraw, () => context.push('/withdraw'), 0),
      (Icons.receipt_long_rounded, WS.t('الحركات', 'Activity'), () => onOpenTab(1), 0),
      (Icons.inbox_rounded, WS.t('الطلبات', 'Requests'), () => onOpenTab(2), pending.length),
    ];

    return RefreshIndicator(
      color: AppColors.cyan,
      onRefresh: () async => refreshWallet(ref),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.violet.withValues(alpha: 0.3),
                child: Text(
                  profile.firstName.isEmpty ? '?' : profile.firstName.characters.first.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text(profile.firstName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                  ],
                ),
              ),
              IconButton(
                tooltip: WS.t('قفل', 'Lock'),
                onPressed: () => ref.read(walletAuthProvider.notifier).lock(),
                icon: const Icon(Icons.lock_outline_rounded),
              ),
            ],
          ),
          if (profile.sandbox) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, color: AppColors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(WS.sandboxBanner, style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w600, fontSize: 12.5))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const CurrencySwitcher(compact: true),
          const SizedBox(height: 12),
          BalanceCard(profile: profile),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.82,
            children: [
              for (final (i, a) in actions.indexed)
                ActionTile(icon: a.$1, label: a.$2, onTap: a.$3, badge: a.$4).animate().fadeIn(delay: (40 * i).ms).scale(begin: const Offset(0.9, 0.9)),
            ],
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 10),
            GlassContainer(
              glow: AppColors.cyan,
              onTap: () => onOpenTab(2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.cyan),
                  const SizedBox(width: 10),
                  Expanded(child: Text(WS.pendingRequests(pending.length), style: const TextStyle(fontWeight: FontWeight.w700))),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Text(WS.recent, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              TextButton(onPressed: () => onOpenTab(1), child: Text(WS.seeAll)),
            ],
          ),
          const SizedBox(height: 6),
          recent.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
            ),
            error: (e, _) => _EmptyNote(icon: Icons.cloud_off_rounded, text: WS.error('offline')),
            data: (list) => list.isEmpty
                ? _EmptyNote(icon: Icons.receipt_long_outlined, text: WS.noTransactions)
                : Column(
                    children: [
                      for (final t in list.take(6)) TxnTile(txn: t, onTap: () => context.push('/receipt/${t.id}', extra: t)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
