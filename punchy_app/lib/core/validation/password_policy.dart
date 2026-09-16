class PasswordPolicy {
  const PasswordPolicy._();

  static final RegExp pattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
  );

  static bool isValid(String value) => pattern.hasMatch(value);

  static const message =
      'Use 8+ characters with uppercase, lowercase and number';
}
