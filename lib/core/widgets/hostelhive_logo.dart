import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The HostelHive wordmark with its cyan "H" mark.
class HostelHiveLogo extends StatelessWidget {
  const HostelHiveLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'HostelHive',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'HostelHive',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 8),
            CustomPaint(size: const Size(24, 26), painter: _MarkPainter()),
          ],
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.cyan;
    final bar = size.width * 0.28;
    final radius = Radius.circular(bar * 0.2);

    canvas.drawRRect(RRect.fromLTRBR(0, 0, bar, size.height, radius), paint);
    canvas.drawRRect(
      RRect.fromLTRBR(size.width - bar, 0, size.width, size.height, radius),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        bar,
        size.height * 0.4,
        size.width - bar,
        size.height * 0.62,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
