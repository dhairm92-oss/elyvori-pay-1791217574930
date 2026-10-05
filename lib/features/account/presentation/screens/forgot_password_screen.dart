import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/widgets/neon_button.dart';
import '../providers/account_controller.dart';
import '../widgets/auth_widgets.dart';

/// Step 1: email -> a 6-digit code by email. Step 2: code + new password.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action, {bool nextStep = false}) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
      if (error == null && nextStep) _codeSent = true;
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.read(accountControllerProvider.notifier);
    return AuthLayout(
      title: S.resetPassword,
      subtitle: S.resetHint,
      onBack: _back,
      children: [
        AuthField(
          controller: _email,
          hint: S.email,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: _codeSent ? TextInputAction.next : TextInputAction.done,
        ),
        if (!_codeSent) ...[
          if (_error != null) FormMessage(_error!),
          NeonButton(
            label: S.sendCode,
            icon: Icons.mark_email_read_outlined,
            loading: _loading,
            onPressed: () => _run(() => account.sendResetCode(_email.text), nextStep: true),
          ),
        ] else ...[
          FormMessage(S.codeSent, isError: false),
          AuthField(
            controller: _code,
            hint: S.code,
            icon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
          ),
          AuthField(
            controller: _password,
            hint: S.newPassword,
            icon: Icons.lock_outline_rounded,
            obscure: true,
            autofillHints: const [AutofillHints.newPassword],
          ),
          AuthField(
            controller: _confirm,
            hint: S.confirmPassword,
            icon: Icons.lock_reset_rounded,
            obscure: true,
            textInputAction: TextInputAction.done,
          ),
          if (_error != null) FormMessage(_error!),
          NeonButton(
            label: S.changePassword,
            icon: Icons.check_rounded,
            loading: _loading,
            onPressed: () => _run(
              () => account.resetPassword(
                email: _email.text,
                code: _code.text,
                password: _password.text,
                confirm: _confirm.text,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
