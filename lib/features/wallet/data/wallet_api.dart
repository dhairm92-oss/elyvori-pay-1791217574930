import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/wallet_models.dart';

/// Server error code from any error thrown by [ApiClient].
String walletErrorCode(Object error, {String unauthorized = 'session_ended'}) {
  if (error is UnauthorizedException) return unauthorized;
  if (error is NetworkException || error is TimeoutAppException) return 'offline';
  if (error is AppException) return error.message;
  return 'unknown';
}

class LoginResult {
  const LoginResult({this.session, this.needsOtp = false});
  final Map<String, dynamic>? session;
  final bool needsOtp;
}

/// Every Elyvori Pay endpoint (`/wallet/...`).
class WalletApi {
  const WalletApi(this._api);

  final ApiClient _api;

  Future<String?> requestOtp(String phone, String purpose) async {
    final j = await _api.post<Map<String, dynamic>>('/wallet/auth/otp', body: {'phone': phone, 'purpose': purpose}, auth: false);
    final code = j['devCode'];
    return code is String ? code : null;
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String code,
    required String name,
    required String email,
    required String pin,
    required String deviceId,
    required String deviceName,
  }) =>
      _api.post<Map<String, dynamic>>(
        '/wallet/auth/register',
        body: {
          'phone': phone,
          'code': code,
          'name': name,
          'email': email,
          'pin': pin,
          'deviceId': deviceId,
          'deviceName': deviceName,
        },
        auth: false,
      );

  Future<LoginResult> login({
    required String phone,
    required String pin,
    required String deviceId,
    required String deviceName,
    String? code,
  }) async {
    final j = await _api.post<Map<String, dynamic>>(
      '/wallet/auth/login',
      body: {
        'phone': phone,
        'pin': pin,
        'deviceId': deviceId,
        'deviceName': deviceName,
        if (code != null) 'code': code,
      },
      auth: false,
    );
    if (j['needsOtp'] == true) return const LoginResult(needsOtp: true);
    return LoginResult(session: j);
  }

  Future<void> logout() async {
    await _api.post<Map<String, dynamic>>('/wallet/auth/logout');
  }

  Future<WalletProfile> me() async => WalletProfile.fromJson(await _api.get<Map<String, dynamic>>('/wallet/me'));

  Future<WalletParty> lookup(String phone) async {
    final j = await _api.get<Map<String, dynamic>>('/wallet/lookup', query: {'phone': phone});
    return WalletParty(name: j['name']?.toString() ?? '', phone: j['phone']?.toString() ?? phone);
  }

  Future<FeeQuote> quote(String type, String amount, String currency) async {
    final j = await _api.get<Map<String, dynamic>>(
      '/wallet/fees/quote',
      query: {'type': type, 'amount': amount, 'currency': currency},
      auth: false,
    );
    return FeeQuote(amount: '${j['amount']}', fee: '${j['fee']}', total: '${j['total']}');
  }

  Future<List<WalletTxn>> history({String? currency, String? type, int limit = 50}) async {
    final list = await _api.get<List<dynamic>>('/wallet/transactions', query: {
      'limit': '$limit',
      if (currency != null) 'currency': currency,
      if (type != null) 'type': type,
    });
    return list.whereType<Map<String, dynamic>>().map(WalletTxn.fromJson).toList();
  }

  Future<WalletTxn> receipt(String id) async =>
      WalletTxn.fromJson(await _api.get<Map<String, dynamic>>('/wallet/transactions/$id'));

  Future<WalletTxn> transfer({
    required String toPhone,
    required String amount,
    required String currency,
    required String pin,
    required String note,
    required String idempotencyKey,
  }) async =>
      WalletTxn.fromJson(await _api.post<Map<String, dynamic>>('/wallet/transfers', body: {
        'toPhone': toPhone,
        'amount': amount,
        'currency': currency,
        'pin': pin,
        'note': note,
        'idempotencyKey': idempotencyKey,
      }));

  Future<WalletTxn> topUp({required String amount, required String currency, required String idempotencyKey}) async =>
      WalletTxn.fromJson(await _api.post<Map<String, dynamic>>('/wallet/topups/sandbox', body: {
        'amount': amount,
        'currency': currency,
        'idempotencyKey': idempotencyKey,
      }));

  Future<CardTopup> cardTopUp({required String amount, required String currency, required String idempotencyKey}) async =>
      CardTopup.fromJson(await _api.post<Map<String, dynamic>>('/wallet/topups/stripe', body: {
        'amount': amount,
        'currency': currency,
        'idempotencyKey': idempotencyKey,
      }));

  Future<CardTopup> topupStatus(String id) async => CardTopup.fromJson(await _api.get<Map<String, dynamic>>('/wallet/topups/$id'));

  Future<WalletTxn> withdraw({
    required String amount,
    required String currency,
    required String pin,
    required String idempotencyKey,
  }) async =>
      WalletTxn.fromJson(await _api.post<Map<String, dynamic>>('/wallet/withdrawals/sandbox', body: {
        'amount': amount,
        'currency': currency,
        'pin': pin,
        'idempotencyKey': idempotencyKey,
      }));

  Future<List<PayRequest>> requests() async {
    final list = await _api.get<List<dynamic>>('/wallet/requests');
    return list.whereType<Map<String, dynamic>>().map(PayRequest.fromJson).toList();
  }

  Future<void> createRequest({required String fromPhone, required String amount, required String currency, required String note}) async {
    await _api.post<Map<String, dynamic>>('/wallet/requests', body: {
      'fromPhone': fromPhone,
      'amount': amount,
      'currency': currency,
      'note': note,
    });
  }

  Future<WalletTxn> payRequest(String id, String pin) async =>
      WalletTxn.fromJson(await _api.post<Map<String, dynamic>>('/wallet/requests/$id/pay', body: {'pin': pin}));

  Future<void> closeRequest(String id) async {
    await _api.post<Map<String, dynamic>>('/wallet/requests/$id/close');
  }

  Future<List<Map<String, dynamic>>> devices() async {
    final list = await _api.get<List<dynamic>>('/wallet/me/devices');
    return list.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> revokeDevice(String id) async {
    await _api.delete<Map<String, dynamic>>('/wallet/me/devices/$id');
  }

  Future<void> changePin(String currentPin, String newPin) async {
    await _api.post<Map<String, dynamic>>('/wallet/me/pin', body: {'currentPin': currentPin, 'newPin': newPin});
  }
}
