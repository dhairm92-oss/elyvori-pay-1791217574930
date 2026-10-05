import '../../../core/l10n/strings.dart';

/// Form checks shared by the sign-in, sign-up and reset screens.
/// Each returns a message to show, or null when the value is fine.
abstract final class AccountValidators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String value) => _email.hasMatch(value.trim()) ? null : S.invalidEmail;

  static String? password(String value) => value.length >= 6 ? null : S.shortPassword;

  static String? name(String value) => value.trim().isEmpty ? S.nameRequired : null;

  static String? confirm(String password, String confirm) => password == confirm ? null : S.passwordsDontMatch;

  static String? code(String value) => RegExp(r'^\d{6}$').hasMatch(value.trim()) ? null : S.codeInvalid;

  /// The first problem in [checks], or null when all pass.
  static String? first(List<String? Function()> checks) {
    for (final check in checks) {
      final message = check();
      if (message != null) return message;
    }
    return null;
  }
}
