import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CategoryPill extends StatelessWidget {
  const CategoryPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: InboxTagColors.background(label),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: AppFonts.mono,
          color: InboxTagColors.foreground(label),
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
