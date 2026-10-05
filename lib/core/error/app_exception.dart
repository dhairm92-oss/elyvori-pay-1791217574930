/// Every error that leaves the data layer is one of these, never a raw
/// DioException or a platform error, so the domain layer stays independent
/// of the HTTP / storage libraries.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection.']);
}

class TimeoutAppException extends AppException {
  const TimeoutAppException([super.message = 'The server took too long to respond.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Your session has expired. Please sign in again.']);
}

class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});
  final int? statusCode;
}

class CacheException extends AppException {
  const CacheException([super.message = 'Local storage is not available.']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong.']);
}
