import 'package:flutter/material.dart';

/// Design tokens taken from the HostelHive student Figma frames.
class AppColors {
  AppColors._();

  static const Color navy = Color(0xFF181037);
  static const Color cyan = Color(0xFF00AEEF);

  /// Navy with a 20% cyan tint, used as the centre of the hero card glow.
  static const Color navyGlow = Color(0xFF13305C);
  static const Color cyanSoft = Color(0x2900AEEF);

  static const Color background = Color(0xFFF7F8FB);
  static const Color formBackground = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFEEF0FB);

  static const Color ink = Color(0xFF0F172A);
  static const Color muted = Color(0xFF6B7280);
  static const Color mutedLight = Color(0xFF8A93A6);
  static const Color secondary = Color(0xFF5B6478);

  static const Color border = Color(0xFFE5E7EB);
  static const Color cardBorder = Color(0x0F0F0A20);

  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const Color successSoft = Color(0x2610B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFB45309);
  static const Color warningSoft = Color(0x26F59E0B);
  static const Color warningBg = Color(0xFFFFF7EB);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerDark = Color(0xFF991B1B);
  static const Color dangerSoft = Color(0x26EF4444);
  static const Color infoSoft = Color(0x2600AEEF);
}

class AppFonts {
  AppFonts._();

  static const String sans = 'PlusJakartaSans';
  static const String mono = 'JetBrainsMono';
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.cyan,
      primary: AppColors.navy,
      secondary: AppColors.cyan,
      surface: AppColors.surface,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.sans,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.cyan,
        unselectedItemColor: AppColors.mutedLight,
        type: BottomNavigationBarType.fixed,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Status badge colours keyed by pass, complaint and scan status strings.
class StatusColors {
  StatusColors._();

  static const _positive = {
    'APPROVED',
    'RESOLVED',
    'VERIFIED',
    'ACTIVE',
    'COMPLETED',
  };
  static const _pending = {'PENDING', 'IN PROGRESS', 'ONGOING', 'OPEN'};
  static const _negative = {'REJECTED', 'DENIED', 'OVERDUE', 'CANCELLED'};

  static Color background(String status) {
    final s = status.toUpperCase();
    if (_positive.contains(s)) return AppColors.successSoft;
    if (_pending.contains(s)) return AppColors.warningSoft;
    if (_negative.contains(s)) return AppColors.dangerSoft;
    return AppColors.border;
  }

  static Color dot(String status) {
    final s = status.toUpperCase();
    if (_positive.contains(s)) return AppColors.success;
    if (_pending.contains(s)) return AppColors.warning;
    if (_negative.contains(s)) return AppColors.danger;
    return AppColors.mutedLight;
  }

  static Color foreground(String status) {
    final s = status.toUpperCase();
    if (_positive.contains(s)) return AppColors.successDark;
    if (_pending.contains(s)) return AppColors.warningDark;
    if (_negative.contains(s)) return AppColors.dangerDark;
    return AppColors.muted;
  }
}

/// Category tag colours for inbox items.
class InboxTagColors {
  InboxTagColors._();

  static Color background(String tag) {
    switch (tag.toUpperCase()) {
      case 'SAFETY':
      case 'ALERT':
        return AppColors.dangerSoft;
      case 'LATE ACCESS':
        return AppColors.successSoft;
      case 'FACILITIES':
        return AppColors.warningSoft;
      default:
        return AppColors.infoSoft;
    }
  }

  static Color foreground(String tag) {
    switch (tag.toUpperCase()) {
      case 'SAFETY':
      case 'ALERT':
        return AppColors.dangerDark;
      case 'LATE ACCESS':
        return AppColors.successDark;
      case 'FACILITIES':
        return AppColors.warningDark;
      default:
        return const Color(0xFF0077A8);
    }
  }
}
