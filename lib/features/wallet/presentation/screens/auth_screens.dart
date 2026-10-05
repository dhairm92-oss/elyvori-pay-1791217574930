import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../domain/wallet_strings.dart';
import '../providers/wallet_providers.dart';
import '../widgets/pin_pad.dart';
import '../widgets/wallet_widgets.dart';

// ---------------------------------------------------------------- onboarding
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(bool signup) {
    ref.read(authDraftProvider.notifier).start(signup: signup);
    context.push('/phone');
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      (Icons.account_balance_wallet_rounded, WS.onb1Title, WS.onb1Body),
      (Icons.shield_rounded, WS.onb2Title, WS.onb2Body),
      (Icons.qr_code_2_rounded, WS.onb3Title, WS.onb3Body),
    ];
    final last = _page == slides.length - 1;
    return WalletPage(
      child: Column(
        children: [
          Row(
            children: [
              AppLogo(name: ref.watch(appConfigProvider).appName, size: 40),
              const SizedBox(width: 10),
              const Text('Elyvori Pay', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const Spacer(),
              if (!last) TextButton(onPressed: () => _pages.jumpToPage(slides.length - 1), child: Text(WS.skip)),
            ],
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final (icon, title, body) = slides[i];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.neonGradient,
                        boxShadow: [BoxShadow(color: AppColors.cyan.withValues(alpha: 0.35), blurRadius: 60)],
                      ),
                      child: Icon(icon, size: 84, color: AppColors.obsidian),
                    ).animate(key: ValueKey(i)).scaleXY(begin: 0.7, end: 1, duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 40),
                    Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.6, fontSize: 15)),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: i == _page ? AppColors.neonGradient : null,
                    color: i == _page ? null : AppColors.glassBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (last) ...[
            NeonButton(label: WS.createWallet, icon: Icons.rocket_launch_rounded, onPressed: () => _go(true)),
            const SizedBox(height: 10),
            TextButton(onPressed: () => _go(false), child: Text(WS.haveWallet, style: const TextStyle(fontWeight: FontWeight.w700))),
          ] else
            NeonButton(
              label: WS.next,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _pages.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- phone
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phone = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final draft = ref.read(authDraftProvider);
    final phone = _phone.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length < 8) {
      showWalletError(context, 'invalid_phone');
      return;
    }
    ref.read(authDraftProvider.notifier).update((d) => d.copyWith(phone: phone));
    if (!draft.signup) {
      context.push('/login-pin');
      return;
    }
    setState(() => _loading = true);
    final (error, devCode) = await ref.read(walletAuthProvider.notifier).requestOtp(phone, 'signup');
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      showWalletError(context, error);
      return;
    }
    ref.read(authDraftProvider.notifier).update((d) => d.copyWith(devCode: devCode));
    context.push('/otp');
  }

  @override
  Widget build(BuildContext context) {
    final signup = ref.watch(authDraftProvider).signup;
    return WalletPage(
      title: WS.phoneTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 70),
          Text(signup ? WS.phoneHint : WS.phoneLoginHint, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 18),
          TextField(
            controller: _phone,
            autofocus: true,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 1.2),
            decoration: InputDecoration(hintText: WS.phone, prefixIcon: const Icon(Icons.phone_iphone_rounded)),
            onSubmitted: (_) => _continue(),
          ),
          const Spacer(),
          NeonButton(label: WS.continueLabel, icon: Icons.arrow_forward_rounded, loading: _loading, onPressed: _continue),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- OTP
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.forLogin = false});

  final bool forLogin;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _code = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      showWalletError(context, 'invalid_code');
      return;
    }
    final draft = ref.read(authDraftProvider);
    ref.read(authDraftProvider.notifier).update((d) => d.copyWith(code: code));
    if (!widget.forLogin) {
      context.push('/profile-setup');
      return;
    }
    setState(() => _loading = true);
    final (error, _) = await ref.read(walletAuthProvider.notifier).login(draft.phone, draft.pin, code: code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) showWalletError(context, error);
  }

  Future<void> _resend() async {
    final draft = ref.read(authDraftProvider);
    final (error, devCode) = await ref.read(walletAuthProvider.notifier).requestOtp(draft.phone, widget.forLogin ? 'login' : 'signup');
    if (!mounted) return;
    if (error != null) {
      showWalletError(context, error);
    } else {
      ref.read(authDraftProvider.notifier).update((d) => d.copyWith(devCode: devCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(authDraftProvider);
    return WalletPage(
      title: WS.otpTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 70),
          Text(WS.otpHint(draft.phone), style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          if (draft.devCode != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
              ),
              child: Text(WS.sandboxCode(draft.devCode!), style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700)),
            ),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.oneTimeCode],
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 14),
            decoration: const InputDecoration(counterText: '', hintText: '••••••'),
            onChanged: (v) {
              if (v.length == 6) _verify();
            },
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: _resend, child: Text(WS.resend)),
          ),
          const Spacer(),
          NeonButton(label: WS.continueLabel, icon: Icons.verified_rounded, loading: _loading, onPressed: _verify),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- profile (sign-up)
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _next() {
    if (_name.text.trim().length < 2) {
      showWalletError(context, 'name_required');
      return;
    }
    final email = _email.text.trim();
    if (email.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      showWalletError(context, 'invalid_email');
      return;
    }
    ref.read(authDraftProvider.notifier).update((d) => d.copyWith(name: _name.text.trim(), email: email));
    context.push('/create-pin');
  }

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: WS.profileTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 70),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: WS.fullName, prefixIcon: const Icon(Icons.person_rounded)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: WS.emailOptional, prefixIcon: const Icon(Icons.alternate_email_rounded)),
          ),
          const Spacer(),
          NeonButton(label: WS.next, icon: Icons.arrow_forward_rounded, onPressed: _next),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- create PIN (sign-up)
class CreatePinScreen extends ConsumerStatefulWidget {
  const CreatePinScreen({super.key});

  @override
  ConsumerState<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends ConsumerState<CreatePinScreen> {
  String? _first;
  String? _error;
  bool _busy = false;

  Future<void> _onPin(String pin) async {
    if (_first == null) {
      setState(() {
        _first = pin;
        _error = null;
      });
      return;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _error = WS.pinMismatch;
      });
      return;
    }
    setState(() => _busy = true);
    final d = ref.read(authDraftProvider);
    final error = await ref
        .read(walletAuthProvider.notifier)
        .register(phone: d.phone, code: d.code, name: d.name, email: d.email, pin: pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error != null) {
        _first = null;
        _error = WS.error(error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: _first == null ? WS.createPin : WS.confirmPin,
      child: Column(
        children: [
          const SizedBox(height: 70),
          Text(WS.createPinHint, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          PinPad(key: ValueKey(_first == null), onCompleted: _onPin, busy: _busy, error: _error),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- PIN sign-in
class LoginPinScreen extends ConsumerStatefulWidget {
  const LoginPinScreen({super.key});

  @override
  ConsumerState<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends ConsumerState<LoginPinScreen> {
  String? _error;
  bool _busy = false;

  Future<void> _onPin(String pin) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final draft = ref.read(authDraftProvider);
    final auth = ref.read(walletAuthProvider.notifier);
    final (error, needsOtp) = await auth.login(draft.phone, pin);
    if (!mounted) return;
    if (needsOtp) {
      ref.read(authDraftProvider.notifier).update((d) => d.copyWith(pin: pin));
      final (otpError, devCode) = await auth.requestOtp(draft.phone, 'login');
      if (!mounted) return;
      setState(() => _busy = false);
      if (otpError != null) {
        setState(() => _error = WS.error(otpError));
        return;
      }
      ref.read(authDraftProvider.notifier).update((d) => d.copyWith(devCode: devCode));
      context.push('/login-otp');
      return;
    }
    setState(() {
      _busy = false;
      _error = error == null ? null : WS.error(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WalletPage(
      title: WS.enterPin,
      child: Column(
        children: [
          const SizedBox(height: 70),
          Text(ref.watch(authDraftProvider).phone, textDirection: TextDirection.ltr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const Spacer(),
          PinPad(onCompleted: _onPin, busy: _busy, error: _error),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- lock screen
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String? _error;
  bool _busy = false;
  bool _triedBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoBiometric());
  }

  Future<void> _autoBiometric() async {
    if (_triedBiometric || !mounted) return;
    _triedBiometric = true;
    final available = await ref.read(biometricAvailableProvider.future);
    if (available && ref.read(biometricEnabledProvider)) await _biometric();
  }

  Future<void> _biometric() async {
    final error = await ref.read(walletAuthProvider.notifier).unlockWithBiometric();
    if (!mounted) return;
    if (error != null && error != 'unknown') setState(() => _error = WS.error(error));
  }

  Future<void> _onPin(String pin) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(walletAuthProvider.notifier).unlockWithPin(pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error == null ? null : WS.error(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(walletAuthProvider).valueOrNull;
    final bio = (ref.watch(biometricAvailableProvider).valueOrNull ?? false) && ref.watch(biometricEnabledProvider);
    final name = auth?.name ?? '';
    return WalletPage(
      child: Column(
        children: [
          const SizedBox(height: 30),
          AppLogo(name: ref.watch(appConfigProvider).appName, size: 64),
          const SizedBox(height: 16),
          Text(WS.unlockTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          if (name.isNotEmpty) Text(name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const Spacer(),
          PinPad(onCompleted: _onPin, busy: _busy, error: _error, onBiometric: bio ? _biometric : null),
          TextButton(
            onPressed: () => ref.read(walletAuthProvider.notifier).signOut(),
            child: Text(WS.notYou, style: const TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
