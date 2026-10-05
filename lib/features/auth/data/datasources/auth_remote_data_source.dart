import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';

class LoginResponse {
  const LoginResponse({required this.accessToken, required this.raw, this.refreshToken});

  final String accessToken;
  final String? refreshToken;
  final Map<String, dynamic> raw;
}

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._api);

  final ApiClient _api;

  Future<LoginResponse> login(String email, String password) async {
    final json = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    final access = json['accessToken'];
    if (access is! String || access.isEmpty) {
      throw const ServerException('The server did not return an access token.');
    }
    final refresh = json['refreshToken'];
    return LoginResponse(accessToken: access, refreshToken: refresh is String ? refresh : null, raw: json);
  }
}
