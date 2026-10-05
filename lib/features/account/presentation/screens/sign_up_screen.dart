import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neon_button.dart';
import '../providers/account_controller.dart';
import '../widgets/auth_widgets.dart';

class AccountSignUpScreen extends ConsumerStatefulWidget {
  const AccountSignUpScreen({super.key});

  @override
  ConsumerState<AccountSignUpScreen> createState() => _AccountSignUpScreenState();
}

class _AccountSignUpScreenState extends ConsumerState<AccountSignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final AccountController _account;
  bool _loading = false;
  String? _busy;
  String? _error;

  @override
  void initState() {
    super.initState();
    _account = ref.read(accountControllerProvider.notifier)..prepareOAuth();
  }

  @override
  void dispose() {
    _account.cancelOAuth();
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await _account.signUp(
      name: _name.text,
      email: _email.text,
      password: _password.text,
      confirm: _confirm.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  Future<void> _social(String provider) async {
    setState(() {
      _busy = provider;
      _error = null;
    });
    final error = await _account.signInWith(provider);
    if (!mounted) return;
    setState(() {
      _busy = null;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: S.createAccount,
      subtitle: S.createAccountHint,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(S.haveAccount, style: const TextStyle(color: AppColors.textSecondary)),
          TextButton(onPressed: () => context.go('/sign-in'), child: Text(S.signIn)),
        ],
      ),
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                controller: _name,
                hint: S.name,
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                autofillHints: const [AutofillHints.name],
              ),
              AuthField(
                controller: _email,
                hint: S.email,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              AuthField(
                controller: _password,
                hint: S.password,
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
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        if (_error != null) FormMessage(_error!),
        NeonButton(
          label: S.signUp,
          icon: Icons.rocket_launch_rounded,
          loading: _loading,
          onPressed: _busy == null ? _submit : null,
        ),
        const SizedBox(height: 18),
        SocialSignIn(busy: _busy, onPressed: _social),
      ],
    );
  }
}
