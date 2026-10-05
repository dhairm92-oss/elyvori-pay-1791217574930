import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: AuthRemoteDataSource(ref.watch(apiClientProvider)),
    tokens: ref.watch(tokenStorageProvider),
    store: ref.watch(keyValueStoreProvider),
  );
});

/// The signed-in session (null = signed out). Drives routing.
class AuthController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    ref.listen(sessionExpiredProvider, (_, next) {
      if (next > 0) state = const AsyncData(null);
    });
    try {
      return await ref.read(authRepositoryProvider).restore();
    } catch (_) {
      return null;
    }
  }

  /// Returns an error message, or null on success.
  Future<String?> signIn(String email, String password) async {
    final result = await SignIn(ref.read(authRepositoryProvider))(email: email, password: password);
    return result.when(
      success: (session) {
        state = AsyncData(session);
        return null;
      },
      failure: (failure) => failure.message,
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, Session?>(AuthController.new);
