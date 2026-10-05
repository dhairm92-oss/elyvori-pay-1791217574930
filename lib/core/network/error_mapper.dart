import 'package:dio/dio.dart';

import '../error/app_exception.dart';

/// Converts transport errors into the app's own [AppException] types.
AppException mapDioError(Object error) {
  if (error is AppException) return error;
  if (error is! DioException) {
    if (_isSocketError(error)) return const NetworkException();
    return UnknownException(error.toString());
  }
  if (error.error is AppException) return error.error! as AppException;

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutAppException();
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badCertificate:
      return const ServerException('The server certificate is not trusted.');
    case DioExceptionType.cancel:
      return const UnknownException('The request was cancelled.');
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;
      if (status == 401) return const UnauthorizedException();
      return ServerException(_messageFrom(error.response?.data) ?? 'Server error ($status).', statusCode: status);
    // unknown + any type a newer Dio adds (e.g. transformTimeout)
    default:
      if (_isSocketError(error.error)) return const NetworkException();
      return UnknownException(error.message ?? 'Something went wrong.');
  }
}

/// Web-safe check (no dart:io): matches dart:io's SocketException on mobile.
bool _isSocketError(Object? e) => e != null && e.runtimeType.toString().contains('SocketException');

String? _messageFrom(Object? data) {
  if (data is Map) {
    final message = data['message'];
    if (message is String) return message;
    if (message is List && message.isNotEmpty) return message.first.toString();
    final err = data['error'];
    if (err is String) return err;
  }
  if (data is String && data.isNotEmpty && data.length < 300) return data;
  return null;
}
