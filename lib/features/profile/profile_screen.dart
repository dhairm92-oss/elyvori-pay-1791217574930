import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/cloud.dart';
import '../../core/di/core_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_button.dart';
import '../account/domain/entities/app_user.dart';
import '../account/presentation/providers/account_controller.dart';
import '../records/presentation/providers/records_providers.dart';

/// Account, cloud sync, about and sign out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, AppUser user) async {
    final controller = TextEditingController(text: user.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: Text(S.editName),
        content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: S.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(S.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(S.save)),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    final error = await ref.read(accountControllerProvider.notifier).updateName(name);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: Text(S.signOut),
        content: Text(S.signOutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(S.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.signOut, style: const TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(accountControllerProvider.notifier).signOut();
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 36),
        title: Text(S.deleteAccount),
        content: Text(S.deleteAccountConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(S.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.delete, style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await ref.read(accountControllerProvider.notifier).deleteAccount();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(appConfigProvider).appName;
    final user = cloudSyncEnabled ? ref.watch(accountControllerProvider).valueOrNull : null;
    final sync = ref.watch(syncControllerProvider);
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(S.profileTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.neonGradient,
                  boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.4), blurRadius: 28)],
                ),
                child: Text(
                  user?.initials ?? '?',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.obsidian),
                ),
              ).animate().scaleXY(begin: 0.85, end: 1, duration: 450.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 12),
              Text(user?.displayName ?? S.guest, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              if (user != null) ...[
                const SizedBox(height: 2),
                Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(
                        user.provider == 'github'
                            ? Icons.code_rounded
                            : user.provider == 'google'
                                ? Icons.public_rounded
                                : Icons.alternate_email_rounded,
                        size: 18,
                      ),
                      label: Text(user.provider == 'password' ? S.email : user.provider),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.edit_rounded, size: 16),
                      label: Text(S.editName),
                      onPressed: () => _editName(context, ref, user),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_sync_rounded, color: AppColors.cyan),
                  const SizedBox(width: 10),
                  Expanded(child: Text(S.syncTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                ],
              ),
              const SizedBox(height: 10),
              if (sync.phase == SyncPhase.disabled)
                Text(S.localOnly, style: const TextStyle(color: AppColors.textSecondary))
              else ...[
                Text(
                  sync.lastSync == null ? S.neverSynced : S.lastSync(S.timeAgo(sync.lastSync!, now)),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (sync.pending > 0) ...[
                  const SizedBox(height: 4),
                  Text(S.pendingChanges(sync.pending), style: const TextStyle(color: AppColors.amber)),
                ],
                if (sync.phase == SyncPhase.error) ...[
                  const SizedBox(height: 4),
                  Text(S.syncFailed, style: const TextStyle(color: AppColors.rose)),
                ],
                const SizedBox(height: 14),
                NeonButton(
                  label: sync.phase == SyncPhase.syncing ? S.syncing : S.syncNow,
                  icon: Icons.sync_rounded,
                  loading: sync.phase == SyncPhase.syncing,
                  onPressed: () => ref.read(syncControllerProvider.notifier).syncNow(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppLogo(name: appName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${S.version} · ${S.builtWith}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (cloudSyncEnabled) ...[
          const SizedBox(height: 12),
          GlassContainer(
            padding: EdgeInsets.zero,
            onTap: () => launchUrl(
              Uri.parse('${ref.read(appConfigProvider).apiBaseUrl}${cloudPath('/privacy')}'),
              mode: LaunchMode.externalApplication,
            ),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.cyan),
              title: Text(S.privacyPolicy),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textMuted),
            ),
          ),
        ],
        if (user != null) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout_rounded, color: AppColors.rose),
            label: Text(S.signOut, style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: AppColors.rose.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _deleteAccount(context, ref),
            icon: const Icon(Icons.delete_forever_rounded, color: AppColors.textMuted, size: 20),
            label: Text(S.deleteAccount, style: const TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ],
    );
  }
}
