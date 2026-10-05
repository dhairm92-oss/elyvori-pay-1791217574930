import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/wallet_strings.dart';
import '../../data/wallet_api.dart';
import '../../domain/wallet_models.dart';

// ------------------------------------------------------------------ API
final walletApiProvider = Provider<WalletApi>((ref) {
  final config = ref.watch(appConfigProvider);
  return WalletApi(
    ApiClient(
      baseUrl: config.apiBaseUrl,
      tokens: ref.watch(tokenStorageProvider),
      onSessionExpired: () => ref.read(walletAuthProvider.notifier).sessionExpired(),
      refreshPath: '/wallet/auth/refresh',
    ),
  );
});

/// A new key per payment screen: a double tap or a retry never pays twice.
String newIdempotencyKey() {
  final r = Random.secure();
  return 'pay-${DateTime.now().microsecondsSinceEpoch}-${r.nextInt(1 << 31)}';
}

// ------------------------------------------------------------------ session gate
enum WalletGate { signedOut, locked, unlocked }

class WalletAuth {
  const WalletAuth({required this.gate, this.profile, this.phone, this.name});

  final WalletGate gate;
  final WalletProfile? profile;

  /// Remembered on this device for the lock screen.
  final String? phone;
  final String? name;
}

class WalletAuthController extends AsyncNotifier<WalletAuth> {
  static const _phoneKey = 'wallet:phone';
  static const _nameKey = 'wallet:name';
  static const _deviceKey = 'wallet:device';
  static const _bioKey = 'wallet:biometric';

  WalletApi get _api => ref.read(walletApiProvider);

  @override
  Future<WalletAuth> build() async {
    final store = ref.read(keyValueStoreProvider);
    final phone = store.read(_phoneKey);
    final refresh = await ref.read(tokenStorageProvider).readRefreshToken();
    if (phone != null && phone.isNotEmpty && refresh != null && refresh.isNotEmpty) {
      return WalletAuth(gate: WalletGate.locked, phone: phone, name: store.read(_nameKey));
    }
    return const WalletAuth(gate: WalletGate.signedOut);
  }

  WalletAuth get _now => state.valueOrNull ?? const WalletAuth(gate: WalletGate.signedOut);

  String deviceId() {
    final store = ref.read(keyValueStoreProvider);
    final existing = store.read(_deviceKey);
    if (existing != null && existing.length >= 6) return existing;
    final id = 'dev-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 31)}';
    unawaited(store.write(_deviceKey, id));
    return id;
  }

  String get deviceName => kIsWeb ? 'Web browser' : '${defaultTargetPlatform.name} phone';

  bool get biometricEnabled => ref.read(keyValueStoreProvider).read(_bioKey) == 'true';

  Future<void> setBiometric(bool on) async {
    await ref.read(keyValueStoreProvider).write(_bioKey, on ? 'true' : 'false');
    ref.invalidate(biometricEnabledProvider);
  }

  Future<void> _signedIn(Map<String, dynamic> session) async {
    final access = session['accessToken'];
    final refresh = session['refreshToken'];
    if (access is! String || refresh is! String) throw const ServerExceptionCode('unknown');
    await ref.read(tokenStorageProvider).save(accessToken: access, refreshToken: refresh);
    final user = session['user'];
    final profile = user is Map<String, dynamic> ? WalletProfile.fromJson(user) : await _api.me();
    final store = ref.read(keyValueStoreProvider);
    await store.write(_phoneKey, profile.phone);
    await store.write(_nameKey, profile.name);
    state = AsyncData(WalletAuth(gate: WalletGate.unlocked, profile: profile, phone: profile.phone, name: profile.name));
  }

  /// Returns (error code, sandbox code).
  Future<(String?, String?)> requestOtp(String phone, String purpose) async {
    try {
      return (null, await _api.requestOtp(phone, purpose));
    } catch (e) {
      return (walletErrorCode(e), null);
    }
  }

  Future<String?> register({
    required String phone,
    required String code,
    required String name,
    required String email,
    required String pin,
  }) async {
    try {
      final session = await _api.register(
        phone: phone,
        code: code,
        name: name,
        email: email,
        pin: pin,
        deviceId: deviceId(),
        deviceName: deviceName,
      );
      await _signedIn(session);
      return null;
    } catch (e) {
      return e is ServerExceptionCode ? e.code : walletErrorCode(e);
    }
  }

  /// Returns (error code, needs SMS code).
  Future<(String?, bool)> login(String phone, String pin, {String? code}) async {
    try {
      final result = await _api.login(phone: phone, pin: pin, deviceId: deviceId(), deviceName: deviceName, code: code);
      if (result.needsOtp) return (null, true);
      await _signedIn(result.session ?? const {});
      return (null, false);
    } catch (e) {
      return (e is ServerExceptionCode ? e.code : walletErrorCode(e, unauthorized: 'wrong_phone_or_pin'), false);
    }
  }

  Future<String?> unlockWithPin(String pin) async {
    final phone = _now.phone;
    if (phone == null) return 'session_ended';
    final (error, needsOtp) = await login(phone, pin);
    if (needsOtp) {
      await signOut();
      return 'session_ended';
    }
    return error;
  }

  Future<String?> unlockWithBiometric() async {
    if (kIsWeb) return 'unknown';
    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: WS.biometricReason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!ok) return 'unknown';
      final profile = await _api.me();
      state = AsyncData(WalletAuth(gate: WalletGate.unlocked, profile: profile, phone: profile.phone, name: profile.name));
      return null;
    } catch (e) {
      return walletErrorCode(e);
    }
  }

  Future<void> refreshProfile() async {
    if (_now.gate != WalletGate.unlocked) return;
    try {
      final profile = await _api.me();
      state = AsyncData(WalletAuth(gate: WalletGate.unlocked, profile: profile, phone: profile.phone, name: profile.name));
    } catch (_) {
      // keep showing the last known balances
    }
  }

  void lock() {
    final now = _now;
    if (now.gate == WalletGate.unlocked) {
      state = AsyncData(WalletAuth(gate: WalletGate.locked, phone: now.phone, name: now.name));
    }
  }

  void sessionExpired() {
    final now = _now;
    if (now.gate == WalletGate.unlocked) {
      state = AsyncData(WalletAuth(gate: WalletGate.locked, phone: now.phone, name: now.name));
    }
  }

  Future<void> signOut() async {
    try {
      await _api.logout();
    } catch (_) {
      // signing out works offline too
    }
    await ref.read(tokenStorageProvider).clear();
    final store = ref.read(keyValueStoreProvider);
    await store.remove(_phoneKey);
    await store.remove(_nameKey);
    await store.remove(_bioKey);
    state = const AsyncData(WalletAuth(gate: WalletGate.signedOut));
  }
}

/// Internal: a server reply we could not use.
class ServerExceptionCode implements Exception {
  const ServerExceptionCode(this.code);
  final String code;
}

final walletAuthProvider = AsyncNotifierProvider<WalletAuthController, WalletAuth>(WalletAuthController.new);

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) return false;
  try {
    final auth = LocalAuthentication();
    return await auth.isDeviceSupported() && await auth.canCheckBiometrics;
  } catch (_) {
    return false;
  }
});

final biometricEnabledProvider = Provider<bool>((ref) => ref.watch(keyValueStoreProvider).read('wallet:biometric') == 'true');

// ------------------------------------------------------------------ data
class SelectedCurrency extends Notifier<String> {
  @override
  String build() => 'ILS';

  void select(String currency) => state = currency;
}

final selectedCurrencyProvider = NotifierProvider<SelectedCurrency, String>(SelectedCurrency.new);

class HideBalance extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final hideBalanceProvider = NotifierProvider<HideBalance, bool>(HideBalance.new);

/// (currency or null for all, type or null for all)
final historyProvider = FutureProvider.autoDispose.family<List<WalletTxn>, (String?, String?)>((ref, filter) {
  return ref.watch(walletApiProvider).history(currency: filter.$1, type: filter.$2);
});

final requestsProvider = FutureProvider.autoDispose<List<PayRequest>>((ref) => ref.watch(walletApiProvider).requests());

final devicesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(walletApiProvider).devices());

/// Refresh balances, history and requests after any money movement.
void refreshWallet(WidgetRef ref) {
  ref.invalidate(historyProvider);
  ref.invalidate(requestsProvider);
  unawaited(ref.read(walletAuthProvider.notifier).refreshProfile());
}

// ------------------------------------------------------------------ sign-up / sign-in draft
class AuthDraft {
  const AuthDraft({this.signup = true, this.phone = '', this.code = '', this.devCode, this.name = '', this.email = '', this.pin = ''});

  final bool signup;
  final String phone;
  final String code;
  final String? devCode;
  final String name;
  final String email;
  final String pin;

  AuthDraft copyWith({bool? signup, String? phone, String? code, String? devCode, String? name, String? email, String? pin}) => AuthDraft(
        signup: signup ?? this.signup,
        phone: phone ?? this.phone,
        code: code ?? this.code,
        devCode: devCode ?? this.devCode,
        name: name ?? this.name,
        email: email ?? this.email,
        pin: pin ?? this.pin,
      );
}

class AuthDraftNotifier extends Notifier<AuthDraft> {
  @override
  AuthDraft build() => const AuthDraft();

  void start({required bool signup}) => state = AuthDraft(signup: signup);
  void update(AuthDraft Function(AuthDraft d) change) => state = change(state);
}

final authDraftProvider = NotifierProvider<AuthDraftNotifier, AuthDraft>(AuthDraftNotifier.new);
