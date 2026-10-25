import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/core/widgets/primary_button.dart';
import 'package:hostelhive_mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:hostelhive_mobile/features/profile/screens/profile_screen.dart';

import '../../helpers/harness.dart';

// Change password reuses ForgotPasswordScreen (FR006/UC002): Firebase has no
// endpoint to verify a typed current password against a bearer token, so a
// signed-in student also goes through the emailed reset link.
void main() {
  group('Change password (via the shared reset-link flow)', () {
    testWidgets('Change password button is visible on profile screen', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);

      expect(find.text('Change password'), findsOneWidget);
    });

    testWidgets('Change password button opens the reset-link screen', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);

      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('your password'), findsOneWidget);
    });

    testWidgets('the email field is prefilled and locked', (tester) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);
      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(field.controller!.text, 'sanuthi.p@stu.kln.ac.lk');
      expect(field.enabled, isFalse);
    });

    testWidgets(
      'given Send reset link, then a confirmation shows and it returns to Me',
      (tester) async {
        await pumpApp(tester);
        await goTo(tester, AppRoutes.profile);
        await tester.tap(find.text('Change password'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(PrimaryButton, 'Send reset link'));
        await tester.pumpAndSettle();

        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(
          find.text(
            'Reset link sent. Check your email to set your new password.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('given Cancel, then it returns without sending', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);
      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
