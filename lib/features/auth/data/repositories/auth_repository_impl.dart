import 'dart:convert';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/result/result.dart';
import '../../../../core/storage/key_value_store.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.remote, required this.tokens, required this.store});

  final AuthRemoteDataSource remote;
  final TokenStorage tokens;
  final KeyValueStore store;

  static const _sessionKey = 'auth:session';

  @override
  Future<Result<Session>> signIn({required String email, required String password}) {
    return Result.guard(() async {
      final response = await remote.login(email, password);
      await tokens.save(accessToken: response.accessToken, refreshToken: response.refreshToken);
      final session = SessionModel.fromLoginJson(response.raw);
      final resolved = session.email.isEmpty
          ? SessionModel(email: email, name: session.name, organizationName: session.organizationName)
          : session;
      await store.write(_sessionKey, jsonEncode(resolved.toJson()));
      return resolved;
    });
  }

  @override
  Future<Session?> restore() async {
    final token = await tokens.readAccessToken();
    if (token == null || token.isEmpty) return null;
    final raw = store.read(_sessionKey);
    if (raw == null) return null;
    try {
      return SessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      throw const CacheException();
    }
  }

  @override
  Future<void> signOut() async {
    await tokens.clear();
    await store.remove(_sessionKey);
  }
}
