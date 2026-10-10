import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/utils/password_strength.dart';
import 'package:hostelhive_mobile/core/utils/validators.dart';

void main() {
  group('passwordStrength', () {
    test('given an empty password, then it is weak', () {
      expect(passwordStrength(''), PasswordStrength.weak);
    });

    test('given only lowercase letters, then it is weak', () {
      expect(passwordStrength('abc'), PasswordStrength.weak);
    });

    test('given length and an uppercase letter, then it is medium', () {
      expect(passwordStrength('Abcdefgh'), PasswordStrength.medium);
    });

    test('given all four rules are met, then it is strong', () {
      expect(passwordStrength('Abcdefg1!'), PasswordStrength.strong);
    });
  });

  group('PasswordRules', () {
    test('given a mixed password, then each rule is evaluated', () {
      final rules = PasswordRules.of('Abcdefg1');

      expect(rules.hasMinLength, isTrue);
      expect(rules.hasUppercase, isTrue);
      expect(rules.hasNumber, isTrue);
      expect(rules.hasSymbol, isFalse);
      expect(rules.score, 3);
      expect(rules.allMet, isFalse);
    });

    test('given a short password, then the length rule fails', () {
      expect(PasswordRules.of('Ab1!').hasMinLength, isFalse);
    });

    test('given all rules are satisfied, then allMet is true', () {
      expect(PasswordRules.of('Abcdefg1!').allMet, isTrue);
    });
  });

  group('Validators', () {
    test('required rejects null, empty and blank values', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   ', field: 'Name'), 'Name is required');
    });

    test('required accepts a value', () {
      expect(Validators.required('Sanuthi'), isNull);
    });

    test('email rejects empty and malformed addresses', () {
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });

    test('email accepts a valid address', () {
      expect(Validators.email('student@stu.kln.ac.lk'), isNull);
    });

    test('strongPassword rejects empty and short passwords', () {
      expect(Validators.strongPassword(''), isNotNull);
      expect(Validators.strongPassword('Ab1!'), 'Use at least 8 characters');
    });

    test('strongPassword accepts a long enough password', () {
      expect(Validators.strongPassword('Abcdefg1!'), isNull);
    });

    test('matches rejects empty and different values', () {
      final validator = Validators.matches(() => 'secret123');

      expect(validator(''), 'Please confirm your password');
      expect(validator(null), 'Please confirm your password');
      expect(validator('other'), 'Passwords do not match');
    });

    test('matches accepts the same value', () {
      expect(Validators.matches(() => 'secret123')('secret123'), isNull);
    });
  });
}
