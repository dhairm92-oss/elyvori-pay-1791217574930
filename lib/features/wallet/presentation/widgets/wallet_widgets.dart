import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/neon_background.dart';
import '../../domain/wallet_models.dart';
import '../../domain/wallet_strings.dart';
import '../providers/wallet_providers.dart';

/// Page frame used by every wallet screen.
class WalletPage extends StatelessWidget {
  const WalletPage({super.key, this.title, required this.child, this.actions, this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24)});

  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: title == null
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              title: Text(title!, style: const TextStyle(fontWeight: FontWeight.w800)),
              actions: actions,
            ),
      // phones use the full width; tablets / desktop / web keep a phone-like column
      body: NeonBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SizedBox(width: double.infinity, height: double.infinity, child: Padding(padding: padding, child: child)),
            ),
          ),
        ),
      ),
    );
  }
}

/// ILS / USD / JOD switcher.
class CurrencySwitcher extends ConsumerWidget {
  const CurrencySwitcher({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCurrencyProvider);
    return Wrap(
      spacing: 8,
      children: [
        for (final c in walletCurrencies)
          ChoiceChip(
            label: Text('${currencySymbol(c)}  $c'),
            selected: c == selected,
            onSelected: (_) => ref.read(selectedCurrencyProvider.notifier).select(c),
            selectedColor: AppColors.cyan.withValues(alpha: 0.22),
            side: BorderSide(color: c == selected ? AppColors.cyan : AppColors.glassBorder),
            labelStyle: TextStyle(fontWeight: FontWeight.w700, color: c == selected ? AppColors.cyan : AppColors.textSecondary),
            visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
          ),
      ],
    );
  }
}

/// The big gradient balance card.
class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key, required this.profile});

  final WalletProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(selectedCurrencyProvider);
    final hidden = ref.watch(hideBalanceProvider);
    final wallet = profile.wallet(currency);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF0E7490), Color(0xFF6D28D9)],
        ),
        boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.35), blurRadius: 34, spreadRadius: -6, offset: const Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(WS.totalBalance, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => ref.read(hideBalanceProvider.notifier).toggle(),
                icon: Icon(hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white70, size: 20),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              hidden ? '•••••• ${currencySymbol(currency)}' : formatMoney(wallet.balance, currency),
              key: ValueKey('$hidden$currency${wallet.balance}'),
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.phone_iphone_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(profile.phone, textDirection: TextDirection.ltr, style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              const Text('Elyvori Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

/// Round action button (Send, Receive, ...).
class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.icon, required this.label, required this.onTap, this.badge = 0});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: ShaderMask(
                  shaderCallback: (b) => AppColors.neonGradient.createShader(b),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

String txnTitle(WalletTxn t) {
  if (t.type == 'transfer' || t.type == 'request_pay') {
    final party = t.isIncoming ? t.from : t.to;
    if (party != null && party.name.isNotEmpty) return party.name;
  }
  return WS.txType(t.type);
}

IconData txnIcon(WalletTxn t) => switch (t.type) {
      'topup' => Icons.add_card_rounded,
      'withdraw' => Icons.account_balance_rounded,
      'request_pay' => Icons.request_page_rounded,
      'reversal' => Icons.undo_rounded,
      _ => t.isIncoming ? Icons.south_west_rounded : Icons.north_east_rounded,
    };

/// One row in the activity list.
class TxnTile extends StatelessWidget {
  const TxnTile({super.key, required this.txn, required this.onTap});

  final WalletTxn txn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = txn.isIncoming ? AppColors.emerald : AppColors.textPrimary;
    final d = txn.createdAt;
    final when = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (txn.isIncoming ? AppColors.emerald : AppColors.violet).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(txnIcon(txn), color: txn.isIncoming ? AppColors.emerald : AppColors.cyan, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txnTitle(txn), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    txn.status == 'reversed' ? '${WS.txType(txn.type)} · ${WS.reversed}' : when,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${txn.isIncoming ? '+' : ''}${formatMoney(txn.change, txn.currency)}',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontWeight: FontWeight.w800, color: color, decoration: txn.status == 'reversed' ? TextDecoration.lineThrough : null),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small label/value row used on confirm and receipt screens.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.bold = false, this.ltr = false});

  final String label;
  final String value;
  final bool bold;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              textDirection: ltr ? TextDirection.ltr : null,
              style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, fontSize: bold ? 18 : 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a translated error from a server code.
void showWalletError(BuildContext context, String code) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(WS.error(code)), backgroundColor: AppColors.rose.withValues(alpha: 0.9), behavior: SnackBarBehavior.floating),
  );
}
