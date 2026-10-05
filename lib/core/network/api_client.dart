import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/app_exception.dart';
import 'auth_interceptor.dart';
import 'error_mapper.dart';
import 'token_storage.dart';

/// Thin, typed wrapper around Dio. Every method throws an [AppException]
/// (never a DioException), so repositories can rely on one error type.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStorage tokens,
    required void Function() onSessionExpired,
    String refreshPath = '/auth/refresh',
    Dio? dio,
  }) : dio = dio ?? Dio(_options(baseUrl)) {
    final refreshDio = Dio(_options(baseUrl));
    this.dio.interceptors.add(
          AuthInterceptor(
            tokens: tokens,
            refreshDio: refreshDio,
            onSessionExpired: onSessionExpired,
            refreshPath: refreshPath,
          ),
        );
    if (kDebugMode) {
      this.dio.interceptors.add(LogInterceptor(requestBody: false, responseBody: false));
    }
  }

  final Dio dio;

  static BaseOptions _options(String baseUrl) => BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        // Free-tier servers can take up to a minute to wake up.
        receiveTimeout: const Duration(seconds: 70),
        sendTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
        contentType: Headers.jsonContentType,
      );

  Future<T> get<T>(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send<T>(() => dio.get<T>(path, queryParameters: query, options: _opts(auth)));

  Future<T> post<T>(String path, {Object? body, bool auth = true}) =>
      _send<T>(() => dio.post<T>(path, data: body, options: _opts(auth)));

  Future<T> patch<T>(String path, {Object? body, bool auth = true}) =>
      _send<T>(() => dio.patch<T>(path, data: body, options: _opts(auth)));

  Future<T> delete<T>(String path, {Object? body, bool auth = true}) =>
      _send<T>(() => dio.delete<T>(path, data: body, options: _opts(auth)));

  Options _opts(bool auth) => Options(extra: {AuthInterceptor.skipAuthFlag: !auth});

  Future<T> _send<T>(Future<Response<T>> Function() call) async {
    try {
      final response = await call();
      final data = response.data;
      if (data == null && null is! T) {
        throw const ServerException('The server returned an empty response.');
      }
      return data as T;
    } catch (error) {
      throw mapDioError(error);
    }
  }
}
