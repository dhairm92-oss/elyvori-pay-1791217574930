/// Elyvori Pay data as the app uses it (amounts are exact decimal strings from the server).
const walletCurrencies = ['ILS', 'USD', 'JOD'];

String currencySymbol(String c) => switch (c) {
      'ILS' => '₪',
      'USD' => r'$',
      'JOD' => 'JD',
      _ => c,
    };

int currencyDecimals(String c) => c == 'JOD' ? 3 : 2;

/// "1234.50" -> "1,234.50"
String groupDigits(String amount) {
  final negative = amount.startsWith('-');
  final clean = negative ? amount.substring(1) : amount;
  final parts = clean.split('.');
  final whole = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${negative ? '-' : ''}$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
}

String formatMoney(String amount, String currency) => '${groupDigits(amount)} ${currencySymbol(currency)}';

/// Accepts "12", "12.5", "12,50" -> "12.50"-style string, or null when invalid for the currency.
String? normalizeAmount(String input, String currency) {
  final s = input.trim().replaceAll(',', '.');
  final m = RegExp(r'^(\d{1,9})(?:\.(\d+))?$').firstMatch(s);
  if (m == null) return null;
  final frac = m.group(2) ?? '';
  if (frac.length > currencyDecimals(currency)) return null;
  if (double.parse(s) <= 0) return null;
  return s;
}

String _str(Object? v) => v?.toString() ?? '';

class WalletLimits {
  const WalletLimits({required this.perTx, required this.daily, required this.monthly});
  final String perTx;
  final String daily;
  final String monthly;
}

class WalletBalance {
  const WalletBalance({required this.currency, required this.balance, required this.limits});

  factory WalletBalance.fromJson(Map<String, dynamic> j) {
    final l = j['limits'];
    final limits = l is Map<String, dynamic> ? l : const <String, dynamic>{};
    return WalletBalance(
      currency: _str(j['currency']),
      balance: _str(j['balance']),
      limits: WalletLimits(perTx: _str(limits['perTx']), daily: _str(limits['daily']), monthly: _str(limits['monthly'])),
    );
  }

  final String currency;
  final String balance;
  final WalletLimits limits;
}

class WalletProfile {
  const WalletProfile({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    required this.status,
    required this.kycLevel,
    required this.sandbox,
    required this.wallets,
  });

  factory WalletProfile.fromJson(Map<String, dynamic> j) {
    final w = j['wallets'];
    return WalletProfile(
      id: _str(j['id']),
      phone: _str(j['phone']),
      name: _str(j['name']),
      email: j['email'] as String?,
      status: _str(j['status']),
      kycLevel: (j['kycLevel'] as num?)?.toInt() ?? 0,
      sandbox: j['sandbox'] == true,
      wallets: (w is List ? w : const <Object?>[]).whereType<Map<String, dynamic>>().map(WalletBalance.fromJson).toList(),
    );
  }

  final String id;
  final String phone;
  final String name;
  final String? email;
  final String status;
  final int kycLevel;
  final bool sandbox;
  final List<WalletBalance> wallets;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  WalletBalance wallet(String currency) => wallets.firstWhere(
        (w) => w.currency == currency,
        orElse: () => WalletBalance(
          currency: currency,
          balance: currency == 'JOD' ? '0.000' : '0.00',
          limits: const WalletLimits(perTx: '-', daily: '-', monthly: '-'),
        ),
      );
}

class WalletParty {
  const WalletParty({required this.name, required this.phone});
  final String name;
  final String phone;
}

class WalletTxn {
  const WalletTxn({
    required this.id,
    required this.type,
    required this.status,
    required this.currency,
    required this.amount,
    required this.fee,
    required this.direction,
    required this.change,
    required this.createdAt,
    this.description,
    this.from,
    this.to,
  });

  factory WalletTxn.fromJson(Map<String, dynamic> j) {
    WalletParty? party(Object? v) =>
        v is Map<String, dynamic> ? WalletParty(name: _str(v['name']), phone: _str(v['phone'])) : null;
    return WalletTxn(
      id: _str(j['id']),
      type: _str(j['type']),
      status: _str(j['status']),
      currency: _str(j['currency']),
      amount: _str(j['amount']),
      fee: _str(j['fee']),
      direction: _str(j['direction']),
      change: _str(j['change']),
      description: j['description'] as String?,
      createdAt: DateTime.tryParse(_str(j['createdAt']))?.toLocal() ?? DateTime.now(),
      from: party(j['from']),
      to: party(j['to']),
    );
  }

  final String id;
  final String type;
  final String status;
  final String currency;
  final String amount;
  final String fee;

  /// 'in' or 'out' for the signed-in user.
  final String direction;

  /// Signed change of the user's balance, e.g. "-120.50".
  final String change;
  final String? description;
  final DateTime createdAt;
  final WalletParty? from;
  final WalletParty? to;

  bool get isIncoming => direction == 'in';
}

class PayRequest {
  const PayRequest({
    required this.id,
    required this.role,
    required this.status,
    required this.currency,
    required this.amount,
    required this.requester,
    required this.payer,
    required this.createdAt,
    this.note,
  });

  factory PayRequest.fromJson(Map<String, dynamic> j) {
    WalletParty party(Object? v) => v is Map<String, dynamic>
        ? WalletParty(name: _str(v['name']), phone: _str(v['phone']))
        : const WalletParty(name: '', phone: '');
    return PayRequest(
      id: _str(j['id']),
      role: _str(j['role']),
      status: _str(j['status']),
      currency: _str(j['currency']),
      amount: _str(j['amount']),
      note: j['note'] as String?,
      requester: party(j['requester']),
      payer: party(j['payer']),
      createdAt: DateTime.tryParse(_str(j['createdAt']))?.toLocal() ?? DateTime.now(),
    );
  }

  final String id;

  /// 'payer' (someone asks me) or 'requester' (I asked).
  final String role;
  final String status;
  final String currency;
  final String amount;
  final String? note;
  final WalletParty requester;
  final WalletParty payer;
  final DateTime createdAt;

  bool get isPending => status == 'pending';
}

/// A card top-up (Stripe Checkout).
class CardTopup {
  const CardTopup({required this.id, required this.status, required this.currency, required this.amount, this.checkoutUrl, this.entryId, this.testMode = true});

  factory CardTopup.fromJson(Map<String, dynamic> j) => CardTopup(
        id: _str(j['id']),
        status: _str(j['status']),
        currency: _str(j['currency']),
        amount: _str(j['amount']),
        checkoutUrl: j['checkoutUrl'] as String?,
        entryId: j['entryId'] as String?,
        testMode: j['testMode'] != false,
      );

  final String id;

  /// pending | paid | failed | expired
  final String status;
  final String currency;
  final String amount;
  final String? checkoutUrl;
  final String? entryId;
  final bool testMode;

  bool get isFinal => status != 'pending';
}

class FeeQuote {
  const FeeQuote({required this.amount, required this.fee, required this.total});
  final String amount;
  final String fee;
  final String total;
}

/// The text inside an Elyvori Pay QR code.
String walletQrPayload(String phone) => 'elyvoripay:$phone';

/// Phone number from a scanned code (our QR, or a plain number).
String? phoneFromQr(String raw) {
  final s = raw.trim();
  if (s.startsWith('elyvoripay:')) return s.substring('elyvoripay:'.length);
  return RegExp(r'^\+?\d{8,15}$').hasMatch(s) ? s : null;
}
