import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../data/wallet_api.dart';
import '../../domain/wallet_models.dart';
import '../../domain/wallet_strings.dart';
import '../providers/wallet_providers.dart';
import '../widgets/pin_pad.dart';
import '../widgets/wallet_widgets.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final current = await askPin(context, title: WS.currentPin);
    if (current == null || !context.mounted) return;
    final next = await askPin(context, title: WS.newPin);
    if (next == null || !context.mounted) return;
    final again = await askPin(context, title: WS.confirmPin);
    if (again == null || !context.mounted) return;
    if (again != next) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(WS.pinMismatch), behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      await ref.read(walletApiProvider).changePin(current, next);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(WS.pinChanged), backgroundColor: AppColors.emerald.withValues(alpha: 0.9), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (context.mounted) showWalletError(context, walletErrorCode(e, unauthorized: 'wrong_pin'));
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: Text(WS.signOut),
        content: Text(WS.t('سيتم إخراجك من هذا الجهاز. أموالك تبقى آمنة في محفظتك.', 'You will be signed out of this device. Your money stays safe in your wallet.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(WS.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(WS.signOut)),
        ],
      ),
    );
    if (ok == true) await ref.read(walletAuthProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(walletAuthProvider).valueOrNull?.profile;
    final currency = ref.watch(selectedCurrencyProvider);
    final bioAvailable = ref.watch(biometricAvailableProvider).valueOrNull ?? false;
    final bioOn = ref.watch(biometricEnabledProvider);
    final devices = ref.watch(devicesProvider);
    if (profile == null) return const SizedBox.shrink();
    final limits = profile.wallet(currency).limits;
    final kycLabel = switch (profile.kycLevel) {
      0 => WS.t('أساسي', 'Basic'),
      1 => WS.t('موثّق', 'Verified'),
      _ => WS.t('موثّق بالكامل', 'Fully verified'),
    };

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
                child: Text(title, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
              ),
              GlassContainer(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), child: Column(children: children)),
            ],
          ),
        );

    return RefreshIndicator(
      color: AppColors.cyan,
      onRefresh: () async {
        ref.invalidate(devicesProvider);
        await ref.read(walletAuthProvider.notifier).refreshProfile();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(WS.settingsTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          GlassContainer(
            glow: AppColors.violet,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.violet.withValues(alpha: 0.3),
                  child: Text(
                    profile.firstName.isEmpty ? '?' : profile.firstName.characters.first.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      Text(profile.phone, textDirection: TextDirection.ltr, style: const TextStyle(color: AppColors.textSecondary)),
                      if ((profile.email ?? '').isNotEmpty) Text(profile.email!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.emerald),
                  label: Text(kycLabel, style: const TextStyle(fontSize: 12)),
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          section(WS.t('الأمان', 'Security'), [
            ListTile(
              leading: const Icon(Icons.password_rounded, color: AppColors.cyan),
              title: Text(WS.changePin),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _changePin(context, ref),
            ),
            if (bioAvailable)
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.cyan),
                title: Text(WS.enableBiometric),
                value: bioOn,
                onChanged: (v) => ref.read(walletAuthProvider.notifier).setBiometric(v),
              ),
            ListTile(
              leading: const Icon(Icons.lock_clock_rounded, color: AppColors.cyan),
              title: Text(WS.t('القفل التلقائي', 'Auto-lock')),
              subtitle: Text(WS.t('بعد دقيقتين في الخلفية', 'After 2 minutes in the background')),
            ),
          ]),
          section('${WS.limits} · $currency', [
            const Padding(padding: EdgeInsets.fromLTRB(10, 8, 10, 4), child: CurrencySwitcher(compact: true)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  InfoRow(WS.kyc, kycLabel),
                  InfoRow(WS.perTx, limits.perTx == '-' ? '-' : formatMoney(limits.perTx, currency), ltr: true),
                  InfoRow(WS.daily, limits.daily == '-' ? '-' : formatMoney(limits.daily, currency), ltr: true),
                  InfoRow(WS.monthly, limits.monthly == '-' ? '-' : formatMoney(limits.monthly, currency), ltr: true),
                ],
              ),
            ),
          ]),
          section(WS.devices, [
            ...devices.when(
              loading: () => [const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(color: AppColors.cyan)))],
              error: (e, _) => [ListTile(title: Text(WS.error(walletErrorCode(e))))],
              data: (list) => [
                for (final d in list)
                  ListTile(
                    leading: Icon(d['current'] == true ? Icons.smartphone_rounded : Icons.devices_other_rounded,
                        color: d['current'] == true ? AppColors.emerald : AppColors.textSecondary),
                    title: Text('${d['deviceName'] ?? ''}'),
                    subtitle: Text(
                      d['current'] == true ? WS.thisDevice : (DateTime.tryParse('${d['lastSeenAt']}')?.toLocal().toString().substring(0, 16) ?? ''),
                    ),
                    trailing: d['current'] == true
                        ? null
                        : TextButton(
                            onPressed: () async {
                              try {
                                await ref.read(walletApiProvider).revokeDevice('${d['id']}');
                                ref.invalidate(devicesProvider);
                              } catch (e) {
                                if (context.mounted) showWalletError(context, walletErrorCode(e));
                              }
                            },
                            child: Text(WS.signOutDevice, style: const TextStyle(color: AppColors.rose)),
                          ),
                  ),
              ],
            ),
          ]),
          section(WS.t('حول', 'About'), [
            ListTile(leading: const Icon(Icons.support_agent_rounded, color: AppColors.cyan), title: Text(WS.support), subtitle: const Text('support@elyvori.com')),
            ListTile(leading: const Icon(Icons.info_outline_rounded, color: AppColors.cyan), title: const Text('Elyvori Pay'), subtitle: Text(WS.version)),
          ]),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rose,
              side: BorderSide(color: AppColors.rose.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: Text(WS.signOut),
          ),
        ],
      ),
    );
  }
}
