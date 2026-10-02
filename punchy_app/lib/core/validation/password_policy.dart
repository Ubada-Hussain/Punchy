enum PasswordRequirement {
  minimumLength('At least 8 characters'),
  uppercase('One uppercase letter'),
  lowercase('One lowercase letter'),
  number('One number');

  const PasswordRequirement(this.label);

  final String label;

  bool isSatisfiedBy(String value) => switch (this) {
    PasswordRequirement.minimumLength => value.length >= 8,
    PasswordRequirement.uppercase => RegExp(r'[A-Z]').hasMatch(value),
    PasswordRequirement.lowercase => RegExp(r'[a-z]').hasMatch(value),
    PasswordRequirement.number => RegExp(r'\d').hasMatch(value),
  };
}

class PasswordPolicy {
  const PasswordPolicy._();

  static const requirements = PasswordRequirement.values;

  static bool isValid(String value) =>
      requirements.every((requirement) => requirement.isSatisfiedBy(value));

  static const message =
      'Use 8+ characters with uppercase, lowercase and number';
}
