import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/wallet/domain/wallet_models.dart';
import '../../features/wallet/presentation/providers/wallet_providers.dart';
import '../../features/wallet/presentation/screens/activity_screens.dart';
import '../../features/wallet/presentation/screens/auth_screens.dart';
import '../../features/wallet/presentation/screens/home_screen.dart';
import '../../features/wallet/presentation/screens/money_screens.dart';
import '../../features/wallet/presentation/screens/qr_screens.dart';
import '../widgets/splash_screen.dart';

/// Elyvori Pay routes.
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const lock = '/lock';
  static const home = '/home';

  /// Screens reachable while signed out.
  static const signedOut = {'/onboarding', '/phone', '/otp', '/login-otp', '/profile-setup', '/create-pin', '/login-pin'};
}

/// Start-up: restores the wallet session while the splash progress bar runs.
final bootProvider = FutureProvider<bool>((ref) async {
  final minimum = Future<void>.delayed(const Duration(milliseconds: 1900));
  try {
    await ref.read(walletAuthProvider.future);
  } catch (_) {
    // a broken saved session just means "signed out"
  }
  await minimum;
  return true;
});

class _GateListenable extends ChangeNotifier {
  _GateListenable(Ref<Object?> ref) {
    ref.listen(bootProvider, (_, __) => notifyListeners());
    ref.listen(walletAuthProvider.select((a) => a.valueOrNull?.gate), (_, __) => notifyListeners());
  }
}

/// Locks the wallet when the app was in the background for 2 minutes or more.
class _AutoLock {
  _AutoLock(this._ref) {
    _listener = AppLifecycleListener(
      onHide: () => _hiddenAt ??= DateTime.now(),
      onShow: () {
        final since = _hiddenAt;
        _hiddenAt = null;
        if (since != null && DateTime.now().difference(since) >= const Duration(minutes: 2)) {
          _ref.read(walletAuthProvider.notifier).lock();
        }
      },
    );
  }

  final Ref<Object?> _ref;
  late final AppLifecycleListener _listener;
  DateTime? _hiddenAt;

  void dispose() => _listener.dispose();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _GateListenable(ref);
  final autoLock = _AutoLock(ref);
  ref.onDispose(() {
    listenable.dispose();
    autoLock.dispose();
  });

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: listenable,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final booted = ref.read(bootProvider).valueOrNull == true;
      if (!booted) return location == Routes.splash ? null : Routes.splash;
      final gate = ref.read(walletAuthProvider).valueOrNull?.gate ?? WalletGate.signedOut;
      switch (gate) {
        case WalletGate.signedOut:
          return Routes.signedOut.contains(location) ? null : Routes.onboarding;
        case WalletGate.locked:
          return location == Routes.lock ? null : Routes.lock;
        case WalletGate.unlocked:
          final atEntry = location == Routes.splash || location == Routes.lock || Routes.signedOut.contains(location);
          return atEntry ? Routes.home : null;
      }
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/phone', builder: (_, __) => const PhoneScreen()),
      GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
      GoRoute(path: '/login-otp', builder: (_, __) => const OtpScreen(forLogin: true)),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/create-pin', builder: (_, __) => const CreatePinScreen()),
      GoRoute(path: '/login-pin', builder: (_, __) => const LoginPinScreen()),
      GoRoute(path: Routes.lock, builder: (_, __) => const LockScreen()),
      GoRoute(
        path: Routes.home,
        builder: (_, state) => WalletShell(initialTab: int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0),
      ),
      GoRoute(path: '/send', builder: (_, state) => SendScreen(initialPhone: state.uri.queryParameters['phone'])),
      GoRoute(path: '/request', builder: (_, __) => const RequestMoneyScreen()),
      GoRoute(path: '/receive', builder: (_, __) => const ReceiveScreen()),
      GoRoute(path: '/scan', builder: (_, state) => ScanScreen(pick: state.uri.queryParameters['pick'] == '1')),
      GoRoute(path: '/topup', builder: (_, __) => const TopUpScreen()),
      GoRoute(path: '/withdraw', builder: (_, __) => const TopUpScreen(withdraw: true)),
      GoRoute(
        path: '/receipt/:id',
        builder: (_, state) => ReceiptScreen(
          id: state.pathParameters['id'] ?? '',
          initial: state.extra is WalletTxn ? state.extra! as WalletTxn : null,
          justDone: state.uri.queryParameters['done'] == '1',
        ),
      ),
    ],
  );
});
