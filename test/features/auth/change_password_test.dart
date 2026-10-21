import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/data/repositories/auth_repository.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/data/repositories/session_store.dart';
import 'package:hostelhive_mobile/features/auth/screens/change_password_screen.dart';

import '../../helpers/harness.dart';

// ---------------------------------------------------------------------------
// Unit tests — MockAuthRepository.changeCurrentPassword
// ---------------------------------------------------------------------------

void main() {
  group('MockAuthRepository.changeCurrentPassword', () {
    late MockAuthRepository repo;
    late MemorySessionStore store;

    setUp(() async {
      store = MemorySessionStore();
      await store.write('STU-0036');
      repo = MockAuthRepository(store: store, latency: Duration.zero);
    });

    test(
      'succeeds with correct current password and strong new password',
      () async {
        await expectLater(
          repo.changeCurrentPassword(
            currentPassword: 'Hostel@123',
            newPassword: 'NewPass@456',
          ),
          completes,
        );
      },
    );

    test('throws when current password is wrong', () async {
      await expectLater(
        repo.changeCurrentPassword(
          currentPassword: 'WrongPass!1',
          newPassword: 'NewPass@456',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws when new password fails strength rules', () async {
      await expectLater(
        repo.changeCurrentPassword(
          currentPassword: 'Hostel@123',
          newPassword: 'weak',
        ),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('throws when not signed in', () async {
      await store.clear();
      await expectLater(
        repo.changeCurrentPassword(
          currentPassword: 'Hostel@123',
          newPassword: 'NewPass@456',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Widget tests — ChangePasswordScreen
  // -------------------------------------------------------------------------

  group('ChangePasswordScreen', () {
    testWidgets('shows three password fields', (tester) async {
      await pumpApp(tester);
      await pushTo(tester, AppRoutes.changePassword);

      expect(find.text('CURRENT PASSWORD'), findsOneWidget);
      expect(find.text('NEW PASSWORD'), findsOneWidget);
      expect(find.text('CONFIRM NEW PASSWORD'), findsOneWidget);
    });

    testWidgets('shows validation error when fields are empty', (tester) async {
      await pumpApp(tester);
      await pushTo(tester, AppRoutes.changePassword);

      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is required'), findsOneWidget);
    });

    testWidgets('shows error when current password is wrong', (tester) async {
      await pumpApp(tester);
      await pushTo(tester, AppRoutes.changePassword);

      await tester.enterText(
        find.widgetWithText(TextFormField, '').first,
        'WrongPass!1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '').at(1),
        'NewPass@456',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '').last,
        'NewPass@456',
      );
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is incorrect.'), findsOneWidget);
    });

    testWidgets('pops on success and shows snackbar', (tester) async {
      await pumpApp(tester);
      await pushTo(tester, AppRoutes.changePassword);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, '').first,
        'Hostel@123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '').at(1),
        'NewPass@456',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '').last,
        'NewPass@456',
      );
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordScreen), findsNothing);
      expect(find.text('Password updated'), findsOneWidget);
    });

    testWidgets('Change password button is visible on profile screen', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);

      expect(find.text('Change password'), findsOneWidget);
    });

    testWidgets('Change password button navigates to ChangePasswordScreen', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);

      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });
  });
}
