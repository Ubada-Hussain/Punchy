import 'package:flutter_test/flutter_test.dart';
import 'package:punchy_app/core/validation/password_policy.dart';

void main() {
  test('signup checklist exposes exactly the existing password rules', () {
    expect(
      PasswordPolicy.requirements.map((requirement) => requirement.label),
      [
        'At least 8 characters',
        'One uppercase letter',
        'One lowercase letter',
        'One number',
      ],
    );
  });

  test('each requirement updates independently as password text changes', () {
    expect(PasswordRequirement.minimumLength.isSatisfiedBy('Abc123'), isFalse);
    expect(PasswordRequirement.minimumLength.isSatisfiedBy('Abcdef12'), isTrue);
    expect(PasswordRequirement.uppercase.isSatisfiedBy('abcdef12'), isFalse);
    expect(PasswordRequirement.uppercase.isSatisfiedBy('Abcdef12'), isTrue);
    expect(PasswordRequirement.lowercase.isSatisfiedBy('ABCDEF12'), isFalse);
    expect(PasswordRequirement.lowercase.isSatisfiedBy('Abcdef12'), isTrue);
    expect(PasswordRequirement.number.isSatisfiedBy('Abcdefgh'), isFalse);
    expect(PasswordRequirement.number.isSatisfiedBy('Abcdefg1'), isTrue);
  });

  test('form validation is derived from the same checklist requirements', () {
    for (final password in [
      '',
      'short1A',
      'abcdefgh1',
      'ABCDEFGH1',
      'Abcdefgh',
      'Password1',
      'Password1!',
    ]) {
      expect(
        PasswordPolicy.isValid(password),
        PasswordPolicy.requirements.every(
          (requirement) => requirement.isSatisfiedBy(password),
        ),
      );
    }

    expect(PasswordPolicy.isValid('Password1'), isTrue);
    expect(
      PasswordPolicy.requirements.any(
        (requirement) => requirement.label.toLowerCase().contains('special'),
      ),
      isFalse,
    );
  });
}
