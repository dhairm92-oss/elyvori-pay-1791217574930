import 'package:equatable/equatable.dart';

import 'app_exception.dart';

/// A user-presentable failure produced by the domain layer.
class Failure extends Equatable {
  const Failure(this.message, {this.kind = FailureKind.unknown});

  factory Failure.fromException(Object error) {
    if (error is UnauthorizedException) {
      return Failure(error.message, kind: FailureKind.unauthorized);
    }
    if (error is NetworkException || error is TimeoutAppException) {
      return Failure((error as AppException).message, kind: FailureKind.network);
    }
    if (error is ServerException) {
      return Failure(error.message, kind: FailureKind.server);
    }
    if (error is CacheException) {
      return Failure(error.message, kind: FailureKind.cache);
    }
    if (error is AppException) {
      return Failure(error.message);
    }
    return const Failure('Something went wrong.');
  }

  final String message;
  final FailureKind kind;

  bool get isOffline => kind == FailureKind.network;

  @override
  List<Object?> get props => [message, kind];
}

enum FailureKind { network, unauthorized, server, cache, unknown }
