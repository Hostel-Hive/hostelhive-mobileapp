import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/password_strength.dart';

class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({required this.rules, super.key});

  final PasswordRules rules;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _RuleRow(label: 'At least 8 characters', met: rules.hasMinLength),
          _RuleRow(label: 'One uppercase letter', met: rules.hasUppercase),
          _RuleRow(label: 'One number', met: rules.hasNumber),
          _RuleRow(label: 'One symbol', met: rules.hasSymbol),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: met ? AppColors.success : Colors.transparent,
              shape: BoxShape.circle,
              border: met
                  ? null
                  : Border.all(color: AppColors.border, width: 1.5),
            ),
            child: met
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: met ? AppColors.ink : AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
