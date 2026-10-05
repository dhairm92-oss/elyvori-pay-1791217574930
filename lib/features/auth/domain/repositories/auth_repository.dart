import '../../../../core/result/result.dart';
import '../entities/session.dart';

abstract interface class AuthRepository {
  Future<Result<Session>> signIn({required String email, required String password});
  Future<Session?> restore();
  Future<void> signOut();
}
