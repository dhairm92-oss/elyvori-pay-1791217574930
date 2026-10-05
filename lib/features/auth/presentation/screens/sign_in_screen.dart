import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/neon_background.dart';
import '../../../../core/widgets/neon_button.dart';
import '../providers/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
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
    final error = await ref.read(authControllerProvider.notifier).signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appName = ref.watch(appConfigProvider).appName;
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: GlassContainer(
                  glow: AppColors.cyan,
                  padding: const EdgeInsets.all(24),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => AppColors.neonGradient.createShader(b),
                          child: Text(
                            appName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          S.signInSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(hintText: S.email, prefixIcon: const Icon(Icons.alternate_email)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: _hidden,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: S.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              onPressed: () => setState(() => _hidden = !_hidden),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: AppColors.rose)),
                        ],
                        const SizedBox(height: 20),
                        NeonButton(label: S.signIn, icon: Icons.bolt, loading: _loading, onPressed: _submit),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}
