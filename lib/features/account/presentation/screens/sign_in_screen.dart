import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neon_button.dart';
import '../providers/account_controller.dart';
import '../widgets/auth_widgets.dart';

class AccountSignInScreen extends ConsumerStatefulWidget {
  const AccountSignInScreen({super.key});

  @override
  ConsumerState<AccountSignInScreen> createState() => _AccountSignInScreenState();
}

class _AccountSignInScreenState extends ConsumerState<AccountSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
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
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await _account.signIn(_email.text, _password.text);
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
      title: S.welcomeBack,
      subtitle: S.signInHint,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(S.noAccount, style: const TextStyle(color: AppColors.textSecondary)),
          TextButton(onPressed: () => context.go('/sign-up'), child: Text(S.createAccount)),
        ],
      ),
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(onPressed: () => context.push('/forgot'), child: Text(S.forgotPassword)),
        ),
        if (_error != null) FormMessage(_error!),
        NeonButton(
          label: S.signIn,
          icon: Icons.login_rounded,
          loading: _loading,
          onPressed: _busy == null ? _submit : null,
        ),
        const SizedBox(height: 18),
        SocialSignIn(busy: _busy, onPressed: _social),
      ],
    );
  }
}
