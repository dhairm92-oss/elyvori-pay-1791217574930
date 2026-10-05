import '../../../../core/result/result.dart';
import '../entities/app_user.dart';

/// Where to send the browser for Google / GitHub, and the id to poll.
class OAuthStart {
  const OAuthStart({required this.sessionId, required this.url});

  final String sessionId;
  final String url;
}

enum OAuthStatus { pending, done, failed }

class OAuthPoll {
  const OAuthPoll(this.status, [this.user]);

  final OAuthStatus status;
  final AppUser? user;
}

abstract interface class AccountRepository {
  Future<AppUser?> restore();
  Future<Result<AppUser>> signIn({required String email, required String password});
  Future<Result<AppUser>> signUp({required String name, required String email, required String password});
  Future<Result<bool>> sendResetCode(String email);
  Future<Result<AppUser>> resetPassword({required String email, required String code, required String password});
  Future<Result<OAuthStart>> startOAuth(String provider);
  Future<OAuthPoll> pollOAuth(String sessionId);
  Future<Result<AppUser>> updateName(String name);
  Future<Result<bool>> deleteAccount();
  Future<void> signOut();
}
