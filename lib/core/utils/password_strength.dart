enum PasswordStrength { weak, medium, strong }

class PasswordRules {
  const PasswordRules({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasNumber,
    required this.hasSymbol,
  });

  factory PasswordRules.of(String password) {
    return PasswordRules(
      hasMinLength: password.length >= 8,
      hasUppercase: password.contains(RegExp('[A-Z]')),
      hasNumber: password.contains(RegExp('[0-9]')),
      hasSymbol: password.contains(RegExp(r'[^A-Za-z0-9\s]')),
    );
  }

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasNumber;
  final bool hasSymbol;

  int get score => [
    hasMinLength,
    hasUppercase,
    hasNumber,
    hasSymbol,
  ].where((rule) => rule).length;

  bool get allMet => score == 4;
}

PasswordStrength passwordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.weak;
  final score = PasswordRules.of(password).score;
  if (score >= 4) return PasswordStrength.strong;
  if (score >= 2) return PasswordStrength.medium;
  return PasswordStrength.weak;
}
