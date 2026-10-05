import '../../../core/config/cloud.dart';
import '../../../core/network/api_client.dart';

/// HTTP calls to the app's Elyvori cloud (`/cloud/<appId>/…`).
class AccountRemoteDataSource {
  const AccountRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> signIn(String email, String password) => _api.post<Map<String, dynamic>>(
        cloudPath('/auth/login'),
        body: {'email': email, 'password': password},
        auth: false,
      );

  Future<Map<String, dynamic>> signUp(String name, String email, String password) =>
      _api.post<Map<String, dynamic>>(
        cloudPath('/auth/signup'),
        body: {'name': name, 'email': email, 'password': password},
        auth: false,
      );

  Future<void> sendResetCode(String email) async {
    await _api.post<Map<String, dynamic>>(cloudPath('/auth/forgot'), body: {'email': email}, auth: false);
  }

  Future<Map<String, dynamic>> resetPassword(String email, String code, String password) =>
      _api.post<Map<String, dynamic>>(
        cloudPath('/auth/reset'),
        body: {'email': email, 'code': code, 'password': password},
        auth: false,
      );

  Future<Map<String, dynamic>> startOAuth(String provider) =>
      _api.post<Map<String, dynamic>>(cloudPath('/oauth/$provider/session'), auth: false);

  Future<Map<String, dynamic>> pollOAuth(String sessionId) =>
      _api.get<Map<String, dynamic>>(cloudPath('/oauth/session/$sessionId'), auth: false);

  Future<void> deleteAccount() async {
    await _api.delete<Map<String, dynamic>>(cloudPath('/auth/me'));
  }

  Future<Map<String, dynamic>> updateName(String name) =>
      _api.patch<Map<String, dynamic>>(cloudPath('/auth/me'), body: {'name': name});
}
