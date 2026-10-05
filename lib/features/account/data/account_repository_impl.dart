import 'dart:convert';

import '../../../core/error/app_exception.dart';
import '../../../core/error/failure.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/key_value_store.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/account_repository.dart';
import 'account_remote_data_source.dart';

class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({required this.remote, required this.tokens, required this.store});

  final AccountRemoteDataSource remote;
  final TokenStorage tokens;
  final KeyValueStore store;

  static const _userKey = 'account:user';

  /// Server error codes -> friendly, translated messages.
  Failure _failure(Object error, {String unauthorizedCode = 'wrong_credentials'}) {
    if (error is UnauthorizedException) return Failure(S.serverError(unauthorizedCode), kind: FailureKind.unauthorized);
    if (error is NetworkException || error is TimeoutAppException) {
      return Failure(S.serverError('offline'), kind: FailureKind.network);
    }
    if (error is AppException) return Failure(S.serverError(error.message), kind: FailureKind.server);
    return Failure(S.somethingWrong);
  }

  Future<Result<AppUser>> _session(Future<Map<String, dynamic>> Function() call, {String unauthorizedCode = 'wrong_credentials'}) async {
    try {
      final json = await call();
      final access = json['accessToken'];
      final refresh = json['refreshToken'];
      final rawUser = json['user'];
      if (access is! String || access.isEmpty || rawUser is! Map<String, dynamic>) {
        return Result.failure(Failure(S.somethingWrong));
      }
      await tokens.save(accessToken: access, refreshToken: refresh is String ? refresh : null);
      final user = AppUser.fromJson(rawUser);
      await store.write(_userKey, jsonEncode(user.toJson()));
      return Result.success(user);
    } catch (error) {
      return Result.failure(_failure(error, unauthorizedCode: unauthorizedCode));
    }
  }

  @override
  Future<AppUser?> restore() async {
    final token = await tokens.readRefreshToken() ?? await tokens.readAccessToken();
    if (token == null || token.isEmpty) return null;
    final raw = store.read(_userKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? AppUser.fromJson(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<Result<AppUser>> signIn({required String email, required String password}) =>
      _session(() => remote.signIn(email.trim().toLowerCase(), password));

  @override
  Future<Result<AppUser>> signUp({required String name, required String email, required String password}) =>
      _session(() => remote.signUp(name.trim(), email.trim().toLowerCase(), password));

  @override
  Future<Result<bool>> sendResetCode(String email) async {
    try {
      await remote.sendResetCode(email.trim().toLowerCase());
      return const Result.success(true);
    } catch (error) {
      return Result.failure(_failure(error));
    }
  }

  @override
  Future<Result<AppUser>> resetPassword({required String email, required String code, required String password}) =>
      _session(
        () => remote.resetPassword(email.trim().toLowerCase(), code.trim(), password),
        unauthorizedCode: 'invalid_code',
      );

  @override
  Future<Result<OAuthStart>> startOAuth(String provider) async {
    try {
      final json = await remote.startOAuth(provider);
      final id = json['sessionId'];
      final url = json['url'];
      if (id is! String || url is! String) return Result.failure(Failure(S.serverError('oauth_failed')));
      return Result.success(OAuthStart(sessionId: id, url: url));
    } catch (error) {
      return Result.failure(_failure(error));
    }
  }

  @override
  Future<OAuthPoll> pollOAuth(String sessionId) async {
    try {
      final json = await remote.pollOAuth(sessionId);
      final status = json['status'];
      if (status == 'pending') return const OAuthPoll(OAuthStatus.pending);
      final session = json['session'];
      if (status == 'done' && session is Map<String, dynamic>) {
        final result = await _session(() async => session);
        return result.when<OAuthPoll>(
          success: (user) => OAuthPoll(OAuthStatus.done, user),
          failure: (_) => const OAuthPoll(OAuthStatus.failed),
        );
      }
      return const OAuthPoll(OAuthStatus.failed);
    } catch (_) {
      // a network blip while waiting is not a failure: keep polling
      return const OAuthPoll(OAuthStatus.pending);
    }
  }

  @override
  Future<Result<AppUser>> updateName(String name) async {
    try {
      final json = await remote.updateName(name.trim());
      final raw = store.read(_userKey);
      final current = raw == null ? null : jsonDecode(raw);
      final merged = <String, dynamic>{
        if (current is Map<String, dynamic>) ...current,
        ...json,
      };
      final user = AppUser.fromJson(merged);
      await store.write(_userKey, jsonEncode(user.toJson()));
      return Result.success(user);
    } catch (error) {
      return Result.failure(_failure(error, unauthorizedCode: ''));
    }
  }

  @override
  Future<Result<bool>> deleteAccount() async {
    try {
      await remote.deleteAccount();
      await signOut();
      return const Result.success(true);
    } catch (error) {
      return Result.failure(_failure(error, unauthorizedCode: ''));
    }
  }

  @override
  Future<void> signOut() async {
    await tokens.clear();
    await store.remove(_userKey);
  }
}
