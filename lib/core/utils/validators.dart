class Validators {
  Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final empty = required(value, field: 'Email');
    if (empty != null) return empty;
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(value!.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? strongPassword(String? value) {
    final empty = required(value, field: 'Password');
    if (empty != null) return empty;
    if (value!.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? Function(String?) matches(String Function() other) {
    return (value) {
      if (value == null || value.isEmpty) return 'Please confirm your password';
      if (value != other()) return 'Passwords do not match';
      return null;
    };
  }
}
