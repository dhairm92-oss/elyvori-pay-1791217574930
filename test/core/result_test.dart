import 'package:flutter_test/flutter_test.dart';

import '../../lib/core/error/app_exception.dart';
import '../../lib/core/error/failure.dart';
import '../../lib/core/result/result.dart';

void main() {
  group('Result', () {
    test('guard wraps a value in Success', () async {
      final result = await Result.guard(() async => 42);
      expect(result.isSuccess, isTrue);
      expect(result.getOrElse((_) => 0), 42);
    });

    test('guard maps AppException to a typed Failure', () async {
      final result = await Result.guard<int>(() async => throw const NetworkException());
      expect(result.isSuccess, isFalse);
      result.when(
        success: (_) => fail('should fail'),
        failure: (f) {
          expect(f.kind, FailureKind.network);
          expect(f.isOffline, isTrue);
        },
      );
    });

    test('map transforms only successes', () {
      const ok = Result<int>.success(2);
      const bad = Result<int>.failure(Failure('x'));
      expect(ok.map((v) => v * 10).getOrElse((_) => -1), 20);
      expect(bad.map((v) => v * 10).getOrElse((_) => -1), -1);
    });

    test('unauthorized maps to the unauthorized kind', () {
      expect(Failure.fromException(const UnauthorizedException()).kind, FailureKind.unauthorized);
      expect(Failure.fromException(const ServerException('boom', statusCode: 500)).kind, FailureKind.server);
      expect(Failure.fromException(StateError('x')).kind, FailureKind.unknown);
    });
  });
}
