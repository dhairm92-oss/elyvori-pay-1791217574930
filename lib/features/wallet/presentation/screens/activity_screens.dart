import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../data/wallet_api.dart';
import '../../domain/wallet_models.dart';
import '../../domain/wallet_strings.dart';
import '../providers/wallet_providers.dart';
import '../widgets/pin_pad.dart';
import '../widgets/wallet_widgets.dart';

String _day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _dateTime(DateTime d) => '${_day(d)}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 90),
        Icon(icon, size: 46, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        if (onRetry != null) Center(child: TextButton(onPressed: onRetry, child: Text(WS.t('إعادة المحاولة', 'Try again')))),
      ],
    );
  }
}

// ---------------------------------------------------------------- history
class _HistoryFilter extends Notifier<(String?, String?)> {
  @override
  (String?, String?) build() => (null, null);

  void choose((String?, String?) f) => state = f;
}

final _historyFilterProvider = NotifierProvider<_HistoryFilter, (String?, String?)>(_HistoryFilter.new);

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_historyFilterProvider);
    final history = ref.watch(historyProvider(filter));
    final types = <String?>[null, 'transfer', 'request_pay', 'topup', 'withdraw', 'reversal'];

    Widget chip(String label, bool selected, VoidCallback onTap) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onTap(),
            selectedColor: AppColors.cyan.withValues(alpha: 0.2),
            side: BorderSide(color: selected ? AppColors.cyan : AppColors.glassBorder),
            visualDensity: VisualDensity.compact,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(WS.historyTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              chip(WS.all, filter.$1 == null, () => ref.read(_historyFilterProvider.notifier).choose((null, filter.$2))),
              for (final c in walletCurrencies) chip('${currencySymbol(c)} $c', filter.$1 == c, () => ref.read(_historyFilterProvider.notifier).choose((c, filter.$2))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final t in types)
                chip(t == null ? WS.all : WS.txType(t), filter.$2 == t, () => ref.read(_historyFilterProvider.notifier).choose((filter.$1, t))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.cyan,
            onRefresh: () async => ref.invalidate(historyProvider(filter)),
            child: history.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
              error: (e, _) => _Message(icon: Icons.cloud_off_rounded, text: WS.error(walletErrorCode(e)), onRetry: () => ref.invalidate(historyProvider(filter))),
              data: (list) {
                if (list.isEmpty) return _Message(icon: Icons.receipt_long_outlined, text: WS.noTransactions);
                final rows = <Widget>[];
                String? lastDay;
                for (final t in list) {
                  final day = _day(t.createdAt);
                  if (day != lastDay) {
                    lastDay = day;
                    rows.add(Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                      child: Text(day, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ));
                  }
                  rows.add(TxnTile(txn: t, onTap: () => context.push('/receipt/${t.id}', extra: t)));
                }
                return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: rows);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- requests
class RequestsTab extends ConsumerStatefulWidget {
  const RequestsTab({super.key});

  @override
  ConsumerState<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<RequestsTab> {
  bool _incoming = true;
  String? _busyId;

  Future<void> _pay(PayRequest r) async {
    final pin = await askPin(context, title: '${WS.pay} ${formatMoney(r.amount, r.currency)}');
    if (pin == null || !mounted) return;
    setState(() => _busyId = r.id);
    try {
      final txn = await ref.read(walletApiProvider).payRequest(r.id, pin);
      if (!mounted) return;
      refreshWallet(ref);
      context.push('/receipt/${txn.id}?done=1', extra: txn);
    } catch (e) {
      if (mounted) showWalletError(context, walletErrorCode(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _close(PayRequest r) async {
    setState(() => _busyId = r.id);
    try {
      await ref.read(walletApiProvider).closeRequest(r.id);
      ref.invalidate(requestsProvider);
    } catch (e) {
      if (mounted) showWalletError(context, walletErrorCode(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(requestsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              Expanded(child: Text(WS.requestsTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
              IconButton.filledTonal(onPressed: () => context.push('/request'), icon: const Icon(Icons.add_rounded)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(WS.incoming), icon: const Icon(Icons.call_received_rounded)),
              ButtonSegment(value: false, label: Text(WS.outgoing), icon: const Icon(Icons.call_made_rounded)),
            ],
            selected: {_incoming},
            onSelectionChanged: (s) => setState(() => _incoming = s.first),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.cyan,
            onRefresh: () async => ref.invalidate(requestsProvider),
            child: requests.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
              error: (e, _) => _Message(icon: Icons.cloud_off_rounded, text: WS.error(walletErrorCode(e)), onRetry: () => ref.invalidate(requestsProvider)),
              data: (all) {
                final list = all.where((r) => (r.role == 'payer') == _incoming).toList();
                if (list.isEmpty) return _Message(icon: Icons.inbox_outlined, text: WS.noRequests);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _RequestCard(
                    request: list[i],
                    busy: _busyId == list[i].id,
                    onPay: () => _pay(list[i]),
                    onClose: () => _close(list[i]),
                  ).animate().fadeIn(delay: (30 * i).ms),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.busy, required this.onPay, required this.onClose});

  final PayRequest request;
  final bool busy;
  final VoidCallback onPay;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final incoming = r.role == 'payer';
    final other = incoming ? r.requester : r.payer;
    final statusColor = switch (r.status) {
      'pending' => AppColors.amber,
      'paid' => AppColors.emerald,
      _ => AppColors.textMuted,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(other.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(other.phone, textDirection: TextDirection.ltr, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Text(formatMoney(r.amount, r.currency), textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ],
            ),
            if ((r.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('“${r.note}”', style: const TextStyle(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(WS.requestStatus(r.status), style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Text(_dateTime(r.createdAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                const Spacer(),
                if (busy)
                  const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan))
                else if (r.isPending) ...[
                  TextButton(onPressed: onClose, child: Text(incoming ? WS.decline : WS.cancel)),
                  if (incoming) FilledButton(onPressed: onPay, child: Text(WS.pay)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- receipt
final receiptProvider = FutureProvider.autoDispose.family<WalletTxn, String>((ref, id) => ref.watch(walletApiProvider).receipt(id));

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.id, this.initial, this.justDone = false});

  final String id;
  final WalletTxn? initial;
  final bool justDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = initial == null ? ref.watch(receiptProvider(id)) : AsyncData<WalletTxn>(initial!);
    return WalletPage(
      title: justDone ? null : WS.receiptTitle,
      child: loaded.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
        error: (e, _) => _Message(icon: Icons.error_outline_rounded, text: WS.error(walletErrorCode(e)), onRetry: () => ref.invalidate(receiptProvider(id))),
        data: (t) => _ReceiptBody(txn: t, justDone: justDone),
      ),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.txn, required this.justDone});

  final WalletTxn txn;
  final bool justDone;

  @override
  Widget build(BuildContext context) {
    final t = txn;
    final reversed = t.status == 'reversed';
    final color = reversed ? AppColors.amber : (t.isIncoming ? AppColors.emerald : AppColors.cyan);
    return ListView(
      padding: EdgeInsets.only(top: justDone ? 30 : 70),
      children: [
        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color, width: 2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: -6)],
            ),
            child: Icon(justDone ? Icons.check_rounded : txnIcon(t), size: 48, color: color),
          ),
        ).animate().scale(begin: const Offset(0.6, 0.6), curve: Curves.elasticOut, duration: 700.ms),
        const SizedBox(height: 16),
        if (justDone)
          Text(WS.success, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(
          '${t.isIncoming ? '+' : ''}${formatMoney(t.change, t.currency)}',
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 18),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              InfoRow(WS.t('النوع', 'Type'), WS.txType(t.type)),
              if (t.from != null) InfoRow(WS.from, '${t.from!.name}  ${t.from!.phone}'),
              if (t.to != null) InfoRow(WS.to, '${t.to!.name}  ${t.to!.phone}'),
              InfoRow(WS.amount, formatMoney(t.amount, t.currency), ltr: true),
              if (t.fee.isNotEmpty && double.tryParse(t.fee) != 0) InfoRow(WS.fee, formatMoney(t.fee, t.currency), ltr: true),
              if ((t.description ?? '').isNotEmpty) InfoRow(WS.t('ملاحظة', 'Note'), WS.note(t.description)),
              InfoRow(WS.date, _dateTime(t.createdAt), ltr: true),
              InfoRow(WS.status, reversed ? WS.reversed : WS.completed),
              const Divider(color: AppColors.glassBorder),
              Row(
                children: [
                  Text(WS.reference, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(t.id, textAlign: TextAlign.end, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: t.id));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(WS.copied), behavior: SnackBarBehavior.floating));
                    },
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.06, end: 0),
        const SizedBox(height: 22),
        if (justDone) NeonButton(label: WS.done, icon: Icons.home_rounded, onPressed: () => context.go('/home')),
      ],
    );
  }
}
