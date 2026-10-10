import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class UsageProgressCircle extends StatelessWidget {
  const UsageProgressCircle({
    required this.percentage,
    this.size = 56,
    super.key,
  });

  /// Value between 0 and 1.
  final double percentage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = percentage.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 5,
              backgroundColor: AppColors.border,
              color: AppColors.cyan,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
