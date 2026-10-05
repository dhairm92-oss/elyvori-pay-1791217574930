import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/features/wallet/domain/wallet_models.dart';
import '../../lib/features/wallet/presentation/widgets/pin_pad.dart';

void main() {
  group('money', () {
    test('groups digits and keeps decimals', () {
      expect(groupDigits('1234567.50'), '1,234,567.50');
      expect(groupDigits('-1200.000'), '-1,200.000');
      expect(groupDigits('12'), '12');
    });

    test('formats with the currency symbol', () {
      expect(formatMoney('1500.00', 'ILS'), '1,500.00 ₪');
      expect(formatMoney('10.000', 'JOD'), '10.000 JD');
    });

    test('normalizes typed amounts per currency', () {
      expect(normalizeAmount('12', 'ILS'), '12');
      expect(normalizeAmount('12,5', 'USD'), '12.5');
      expect(normalizeAmount('1.234', 'JOD'), '1.234');
      expect(normalizeAmount('1.234', 'ILS'), isNull);
      expect(normalizeAmount('0', 'ILS'), isNull);
      expect(normalizeAmount('-5', 'ILS'), isNull);
      expect(normalizeAmount('abc', 'ILS'), isNull);
    });
  });

  group('qr', () {
    test('round-trips our payload', () {
      expect(phoneFromQr(walletQrPayload('+970591234567')), '+970591234567');
    });

    test('accepts a plain number and rejects junk', () {
      expect(phoneFromQr('0591234567'), '0591234567');
      expect(phoneFromQr('https://example.com'), isNull);
    });
  });

  group('models', () {
    test('profile falls back to an empty wallet', () {
      final p = WalletProfile.fromJson({
        'id': 'u1',
        'phone': '+970591234567',
        'name': 'Sara Ahmad',
        'status': 'active',
        'kycLevel': 1,
        'sandbox': true,
        'wallets': [
          {'currency': 'ILS', 'balance': '250.00', 'limits': {'perTx': '5000.00', 'daily': '10000.00', 'monthly': '50000.00'}},
        ],
      });
      expect(p.firstName, 'Sara');
      expect(p.wallet('ILS').balance, '250.00');
      expect(p.wallet('JOD').balance, '0.000');
      expect(p.wallet('ILS').limits.daily, '10000.00');
    });

    test('card top-up reads the Stripe checkout', () {
      final t = CardTopup.fromJson({'id': 'top_1', 'status': 'pending', 'currency': 'USD', 'amount': '50.00', 'checkoutUrl': 'https://checkout.stripe.com/x', 'testMode': true});
      expect(t.isFinal, isFalse);
      expect(t.checkoutUrl, startsWith('https://'));
      expect(CardTopup.fromJson({'id': 'top_1', 'status': 'paid', 'currency': 'USD', 'amount': '50.00', 'entryId': 'ent_1'}).isFinal, isTrue);
    });

    test('transaction reads parties and direction', () {
      final t = WalletTxn.fromJson({
        'id': 'e1',
        'type': 'transfer',
        'status': 'posted',
        'currency': 'USD',
        'amount': '20.00',
        'fee': '0.00',
        'direction': 'in',
        'change': '20.00',
        'createdAt': '2026-10-01T10:00:00.000Z',
        'from': {'name': 'Ali', 'phone': '+970599000000'},
      });
      expect(t.isIncoming, isTrue);
      expect(t.from?.name, 'Ali');
      expect(t.to, isNull);
    });
  });

  testWidgets('pin pad reports 6 digits', (tester) async {
    String? got;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: PinPad(onCompleted: (pin) async => got = pin))),
    ));
    for (final d in ['1', '9', '7', '3', '5', '2']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    expect(got, '197352');
  });
}
