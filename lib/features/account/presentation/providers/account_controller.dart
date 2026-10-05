import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/l10n/strings.dart';
import '../../../records/presentation/providers/records_providers.dart';
import '../../data/account_remote_data_source.dart';
import '../../data/account_repository_impl.dart';
import '../../domain/account_validators.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(
    remote: AccountRemoteDataSource(ref.watch(apiClientProvider)),
    tokens: ref.watch(tokenStorageProvider),
    store: ref.watch(keyValueStoreProvider),
  );
});

/// The signed-in user of this app (null = signed out). Drives routing.
class AccountController extends AsyncNotifier<AppUser?> {
  bool _oauthCancelled = false;

  /// Google / GitHub sessions created ahead of the tap, so the browser opens
  /// instantly (and web pop-up blockers allow it).
  final Map<String, (OAuthStart, DateTime)> _prepared = {};

  @override
  Future<AppUser?> build() async {
    ref.listen(sessionExpiredProvider, (_, next) {
      if (next > 0) state = const AsyncData(null);
    });
    try {
      return await ref.read(accountRepositoryProvider).restore();
    } catch (_) {
      return null;
    }
  }

  AccountRepository get _repo => ref.read(accountRepositoryProvider);

  String? _apply(AppUser user) {
    state = AsyncData(user);
    return null;
  }

  /// Each method returns an error message to show, or null on success.
  Future<String?> signIn(String email, String password) async {
    final invalid = AccountValidators.first([
      () => AccountValidators.email(email),
      () => password.isEmpty ? S.shortPassword : null,
    ]);
    if (invalid != null) return invalid;
    final result = await _repo.signIn(email: email, password: password);
    return result.when(success: _apply, failure: (f) => f.message);
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String confirm,
  }) async {
    final invalid = AccountValidators.first([
      () => AccountValidators.name(name),
      () => AccountValidators.email(email),
      () => AccountValidators.password(password),
      () => AccountValidators.confirm(password, confirm),
    ]);
    if (invalid != null) return invalid;
    final result = await _repo.signUp(name: name, email: email, password: password);
    return result.when(success: _apply, failure: (f) => f.message);
  }

  Future<String?> sendResetCode(String email) async {
    final invalid = AccountValidators.email(email);
    if (invalid != null) return invalid;
    final result = await _repo.sendResetCode(email);
    return result.when(success: (_) => null, failure: (f) => f.message);
  }

  Future<String?> resetPassword({
    required String email,
    required String code,
    required String password,
    required String confirm,
  }) async {
    final invalid = AccountValidators.first([
      () => AccountValidators.email(email),
      () => AccountValidators.code(code),
      () => AccountValidators.password(password),
      () => AccountValidators.confirm(password, confirm),
    ]);
    if (invalid != null) return invalid;
    final result = await _repo.resetPassword(email: email, code: code, password: password);
    return result.when(success: _apply, failure: (f) => f.message);
  }

  /// Call when a sign-in screen opens.
  void prepareOAuth() {
    for (final provider in const ['google', 'github']) {
      unawaited(_prepare(provider));
    }
  }

  Future<void> _prepare(String provider) async {
    final result = await _repo.startOAuth(provider);
    final start = result.when<OAuthStart?>(success: (s) => s, failure: (_) => null);
    if (start != null) _prepared[provider] = (start, DateTime.now());
  }

  /// Google / GitHub: opens the browser, then waits until the sign-in is done.
  Future<String?> signInWith(String provider) async {
    _oauthCancelled = false;
    OAuthStart? start;
    final cached = _prepared.remove(provider);
    if (cached != null && DateTime.now().difference(cached.$2) < const Duration(minutes: 8)) start = cached.$1;
    if (start == null) {
      final started = await _repo.startOAuth(provider);
      start = started.when<OAuthStart?>(success: (s) => s, failure: (_) => null);
      if (start == null) return started.when(success: (_) => S.somethingWrong, failure: (f) => f.message);
    }
    unawaited(_prepare(provider)); // a fresh session in case this one is abandoned

    final opened = await launchUrl(
      Uri.parse(start.url),
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened) return S.serverError('oauth_failed');

    final deadline = DateTime.now().add(const Duration(minutes: 4));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_oauthCancelled) return null;
      final poll = await _repo.pollOAuth(start.sessionId);
      if (poll.status == OAuthStatus.done && poll.user != null) return _apply(poll.user!);
      if (poll.status == OAuthStatus.failed) return S.serverError('oauth_failed');
    }
    return S.serverError('oauth_timeout');
  }

  void cancelOAuth() => _oauthCancelled = true;

  Future<String?> updateName(String name) async {
    final invalid = AccountValidators.name(name);
    if (invalid != null) return invalid;
    final result = await _repo.updateName(name);
    return result.when(success: _apply, failure: (f) => f.message);
  }

  /// Deletes the account and all its data (cloud + this device).
  Future<String?> deleteAccount() async {
    final result = await _repo.deleteAccount();
    return result.when<Future<String?>>(
      success: (_) async {
        await ref.read(syncControllerProvider.notifier).clearLocalData();
        state = const AsyncData(null);
        return null;
      },
      failure: (f) async => f.message,
    );
  }

  Future<void> signOut() async {
    await ref.read(syncControllerProvider.notifier).clearLocalData();
    await _repo.signOut();
    state = const AsyncData(null);
  }
}

final accountControllerProvider = AsyncNotifierProvider<AccountController, AppUser?>(AccountController.new);
