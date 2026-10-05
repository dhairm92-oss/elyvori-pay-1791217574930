import 'dart:async';

import 'package:dio/dio.dart';

import 'token_storage.dart';

/// Attaches the JWT to every request and transparently refreshes it once
/// when the server answers 401. Concurrent 401s share a single refresh call
/// (the interceptor is queued), then every failed request is retried.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokens,
    required this.refreshDio,
    required this.onSessionExpired,
    this.refreshPath = '/auth/refresh',
  });

  final TokenStorage tokens;

  /// A bare Dio (no interceptors) used for the refresh call and the retries,
  /// so a failing refresh can never loop back into this interceptor.
  final Dio refreshDio;
  final void Function() onSessionExpired;
  final String refreshPath;

  static const _retriedFlag = 'elyvori_retried';
  static const skipAuthFlag = 'elyvori_skip_auth';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[skipAuthFlag] != true) {
      final token = await tokens.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = request.extra[_retriedFlag] == true;
    final isRefreshCall = request.path.endsWith(refreshPath);

    if (!isUnauthorized || alreadyRetried || isRefreshCall || request.extra[skipAuthFlag] == true) {
      handler.next(err);
      return;
    }

    // Another queued request may already have refreshed the token.
    final sentWith = request.headers['Authorization'];
    final current = await tokens.readAccessToken();
    final alreadyRefreshed = current != null && sentWith != 'Bearer $current';

    final newToken = alreadyRefreshed ? current : await _refresh();
    if (newToken == null) {
      await tokens.clear();
      onSessionExpired();
      handler.next(err);
      return;
    }

    try {
      request.headers['Authorization'] = 'Bearer $newToken';
      request.extra[_retriedFlag] = true;
      final response = await refreshDio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refresh() async {
    final refreshToken = await tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        refreshPath,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      final access = data?['accessToken'];
      if (access is! String || access.isEmpty) return null;
      final nextRefresh = data?['refreshToken'];
      await tokens.save(accessToken: access, refreshToken: nextRefresh is String ? nextRefresh : null);
      return access;
    } on DioException {
      return null;
    }
  }
}
