import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/password_strength.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    required this.strength,
    this.isEmpty = false,
    super.key,
  });

  final PasswordStrength strength;
  final bool isEmpty;

  int get _filled {
    if (isEmpty) return 0;
    switch (strength) {
      case PasswordStrength.weak:
        return 1;
      case PasswordStrength.medium:
        return 2;
      case PasswordStrength.strong:
        return 3;
    }
  }

  Color get _color {
    switch (strength) {
      case PasswordStrength.weak:
        return AppColors.danger;
      case PasswordStrength.medium:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.success;
    }
  }

  String get _label {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                decoration: BoxDecoration(
                  color: i < _filled ? _color : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Strength',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isEmpty)
              Text(
                _label,
                style: TextStyle(
                  color: _color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
