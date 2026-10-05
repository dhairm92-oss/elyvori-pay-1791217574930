import 'package:flutter_test/flutter_test.dart';

import '../../lib/features/account/domain/account_validators.dart';
import '../../lib/features/account/domain/entities/app_user.dart';

void main() {
  test('validators accept good input and reject bad input', () {
    expect(AccountValidators.email('sara@example.com'), isNull);
    expect(AccountValidators.email('nope'), isNotNull);
    expect(AccountValidators.password('123456'), isNull);
    expect(AccountValidators.password('123'), isNotNull);
    expect(AccountValidators.name('  '), isNotNull);
    expect(AccountValidators.confirm('abcdef', 'abcdef'), isNull);
    expect(AccountValidators.confirm('abcdef', 'abcdeg'), isNotNull);
    expect(AccountValidators.code('123456'), isNull);
    expect(AccountValidators.code('12a456'), isNotNull);
    expect(AccountValidators.first([() => null, () => 'second', () => 'third']), 'second');
  });

  test('user names, initials and json round trip', () {
    const user = AppUser(id: '1', email: 'sara.ahmad@example.com', name: 'Sara Ahmad', provider: 'google');
    expect(user.firstName, 'Sara');
    expect(user.initials, 'SA');
    expect(AppUser.fromJson(user.toJson()), user);
    const noName = AppUser(id: '2', email: 'omar@example.com');
    expect(noName.displayName, 'omar');
    expect(noName.initials, 'O');
  });
}
