import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/neon_background.dart';

/// Shared frame of the sign-in / sign-up / reset screens.
class AuthLayout extends ConsumerWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(appConfigProvider).appName;
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    if (onBack != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
                      ),
                    AppLogo(name: appName, size: 76)
                        .animate()
                        .scaleXY(begin: 0.8, end: 1, duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 14),
                    GradientText(
                      appName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    GlassContainer(
                      radius: 24,
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                    ),
                    if (footer != null) ...[const SizedBox(height: 14), footer!],
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0, duration: 400.ms),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Text input with an icon and, for passwords, a show / hide toggle.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscure && _hidden,
        keyboardType: widget.keyboardType,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        autocorrect: !widget.obscure,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon),
          suffixIcon: widget.obscure
              ? IconButton(
                  icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
        ),
      ),
    );
  }
}

/// A red (error) or green (info) note inside a form.
class FormMessage extends StatelessWidget {
  const FormMessage(this.text, {super.key, this.isError = true});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.rose : AppColors.emerald;
    final box = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, height: 1.35))),
        ],
      ),
    );
    final animated = box.animate().fadeIn(duration: 200.ms);
    return isError ? animated.shakeX(hz: 4, amount: 3) : animated;
  }
}

/// "or continue with" + Google / GitHub buttons.
class SocialSignIn extends StatelessWidget {
  const SocialSignIn({super.key, required this.onPressed, this.busy});

  final void Function(String provider) onPressed;

  /// The provider currently opening ('google' / 'github'), if any.
  final String? busy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.glassBorder)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(S.orContinueWith, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
            const Expanded(child: Divider(color: AppColors.glassBorder)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                busy: busy == 'google',
                enabled: busy == null,
                leading: const _GoogleMark(),
                onTap: () => onPressed('google'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                label: 'GitHub',
                busy: busy == 'github',
                enabled: busy == null,
                leading: const Icon(Icons.code_rounded, size: 20, color: Colors.white),
                onTap: () => onPressed('github'),
              ),
            ),
          ],
        ),
        if (busy != null) ...[
          const SizedBox(height: 12),
          Text(
            S.waitingBrowser,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.onTap,
    required this.busy,
    required this.enabled,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.glassFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 50,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.cyan),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      leading,
                      const SizedBox(width: 8),
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const SweepGradient(
        colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335), Color(0xFF4285F4)],
      ).createShader(bounds),
      child: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}
