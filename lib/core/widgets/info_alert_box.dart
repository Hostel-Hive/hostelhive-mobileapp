import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AlertType { info, warning }

class InfoAlertBox extends StatelessWidget {
  const InfoAlertBox({
    required this.title,
    required this.description,
    this.type = AlertType.info,
    this.icon,
    super.key,
  });

  final String title;
  final String description;
  final AlertType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isWarning = type == AlertType.warning;
    final accent = isWarning ? AppColors.warningDark : AppColors.navy;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning ? AppColors.warningBg : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: isWarning ? Border.all(color: AppColors.warningSoft) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
