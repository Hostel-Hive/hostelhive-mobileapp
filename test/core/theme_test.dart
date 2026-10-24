import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/theme/app_theme.dart';

void main() {
  group('StatusColors', () {
    test('given a positive status, then success colours are used', () {
      for (final status in ['approved', 'RESOLVED', 'Verified', 'ACTIVE']) {
        expect(StatusColors.background(status), AppColors.successSoft);
        expect(StatusColors.dot(status), AppColors.success);
        expect(StatusColors.foreground(status), AppColors.successDark);
      }
    });

    test('given a pending status, then warning colours are used', () {
      for (final status in ['PENDING', 'in progress', 'ONGOING', 'open']) {
        expect(StatusColors.background(status), AppColors.warningSoft);
        expect(StatusColors.dot(status), AppColors.warning);
        expect(StatusColors.foreground(status), AppColors.warningDark);
      }
    });

    test('given a negative status, then danger colours are used', () {
      for (final status in ['REJECTED', 'denied', 'OVERDUE', 'CANCELLED']) {
        expect(StatusColors.background(status), AppColors.dangerSoft);
        expect(StatusColors.dot(status), AppColors.danger);
        expect(StatusColors.foreground(status), AppColors.dangerDark);
      }
    });

    test('given an unknown status, then neutral colours are used', () {
      expect(StatusColors.background('whatever'), AppColors.border);
      expect(StatusColors.dot('whatever'), AppColors.mutedLight);
      expect(StatusColors.foreground('whatever'), AppColors.muted);
    });
  });

  group('InboxTagColors', () {
    test('given each known tag, then it has its own colours', () {
      expect(InboxTagColors.background('SAFETY'), AppColors.dangerSoft);
      expect(InboxTagColors.foreground('alert'), AppColors.dangerDark);
      expect(InboxTagColors.background('LATE ACCESS'), AppColors.successSoft);
      expect(InboxTagColors.foreground('LATE ACCESS'), AppColors.successDark);
      expect(InboxTagColors.background('FACILITIES'), AppColors.warningSoft);
      expect(InboxTagColors.foreground('FACILITIES'), AppColors.warningDark);
    });

    test('given an announcement tag, then the info colours are used', () {
      expect(InboxTagColors.background('ANNOUNCEMENT'), AppColors.infoSoft);
      expect(InboxTagColors.foreground('ANNOUNCEMENT'), isA<Color>());
    });
  });

  test('AppTheme.light uses Material 3 and the brand font', () {
    final theme = AppTheme.light;

    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.textTheme.bodyMedium?.fontFamily, AppFonts.sans);
  });
}
