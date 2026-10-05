import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/records_providers.dart';

/// "Synced · 2m ago" / "Syncing…" / "Offline" pill.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncControllerProvider);
    final online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    late final Color color;
    late final String label;
    Widget icon;
    if (sync.phase == SyncPhase.disabled) {
      color = online ? AppColors.emerald : AppColors.amber;
      label = online ? S.localOnly : S.offlineSafe;
      icon = Icon(Icons.phone_android_rounded, size: 14, color: color);
    } else if (!online) {
      color = AppColors.amber;
      label = S.offlineSafe;
      icon = Icon(Icons.cloud_off_rounded, size: 14, color: color);
    } else if (sync.phase == SyncPhase.syncing) {
      color = AppColors.cyan;
      label = S.syncing;
      icon = SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.8, color: color));
    } else if (sync.phase == SyncPhase.error) {
      color = AppColors.rose;
      label = S.syncFailed;
      icon = Icon(Icons.sync_problem_rounded, size: 14, color: color);
    } else {
      color = AppColors.emerald;
      final last = sync.lastSync;
      label = last == null ? S.neverSynced : '${S.synced} · ${S.timeAgo(last, DateTime.now())}';
      icon = Icon(Icons.cloud_done_rounded, size: 14, color: color);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
