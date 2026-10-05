import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failure.dart';
import '../l10n/strings.dart';
import '../theme/app_colors.dart';
import 'glass_container.dart';

/// Renders loading / error / empty / data states for an [AsyncValue].
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.isEmpty,
    this.emptyMessage,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final bool Function(T data)? isEmpty;
  final String? emptyMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      error: (error, _) => _Message(
        icon: Icons.cloud_off_rounded,
        text: error is Failure ? error.message : S.somethingWrong,
        onRetry: onRetry,
      ),
      data: (d) => (isEmpty?.call(d) ?? false)
          ? _Message(icon: Icons.inbox_rounded, text: emptyMessage ?? S.nothingYet)
          : data(d),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onRetry, child: Text(S.tryAgain)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
