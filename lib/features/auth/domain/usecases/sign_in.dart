import '../../../../core/error/failure.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/result/result.dart';
import '../entities/session.dart';
import '../repositories/auth_repository.dart';

class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Result<Session>> call({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(cleanEmail)) {
      return Result.failure(Failure(S.invalidEmail));
    }
    if (password.length < 6) {
      return Result.failure(Failure(S.shortPassword));
    }
    return _repository.signIn(email: cleanEmail, password: password);
  }
}
