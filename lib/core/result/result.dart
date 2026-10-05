import '../error/failure.dart';

/// Explicit success / failure value returned by repositories and use cases.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;

  R when<R>({required R Function(T value) success, required R Function(Failure failure) failure}) {
    final self = this;
    if (self is Success<T>) return success(self.value);
    return failure((self as FailureResult<T>).failure);
  }

  Result<R> map<R>(R Function(T value) transform) {
    final self = this;
    if (self is Success<T>) return Result<R>.success(transform(self.value));
    return Result<R>.failure((self as FailureResult<T>).failure);
  }

  T getOrElse(T Function(Failure failure) orElse) => when(success: (v) => v, failure: orElse);

  /// Runs [body] and converts any thrown error into a [FailureResult].
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Result<T>.success(await body());
    } catch (error) {
      return Result<T>.failure(Failure.fromException(error));
    }
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  final Failure failure;
}
