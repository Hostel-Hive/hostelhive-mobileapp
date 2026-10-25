import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/data/models/student.dart';
import 'package:hostelhive_mobile/features/qr/screens/my_qr_screen.dart';

import '../../helpers/harness.dart';

void main() {
  group('Student.fromProfileJson', () {
    test('given profile_image_url is present, then hasPhoto is true', () {
      final student = Student.fromProfileJson({
        'student_id': 'STU-0001',
        'index_no': 'SE/2021/001',
        'full_name': 'Test Student',
        'email': 'test@example.com',
        'profile_image_url': '/me/student-profile/image',
      });

      expect(student.hasPhoto, isTrue);
    });

    test('given profile_image_url is absent, then hasPhoto is false', () {
      final student = Student.fromProfileJson({
        'student_id': 'STU-0001',
        'index_no': 'SE/2021/001',
        'full_name': 'Test Student',
        'email': 'test@example.com',
      });

      expect(student.hasPhoto, isFalse);
    });

    test(
      'given profile_image_url is an empty string, then hasPhoto is false',
      () {
        final student = Student.fromProfileJson({
          'student_id': 'STU-0001',
          'index_no': 'SE/2021/001',
          'full_name': 'Test Student',
          'email': 'test@example.com',
          'profile_image_url': '',
        });

        expect(student.hasPhoto, isFalse);
      },
    );
  });

  group('Profile screen', () {
    testWidgets('given a signed-in student, then their details show', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Me')),
        findsOneWidget,
      );
      expect(find.text('Sanuthi Perera'), findsOneWidget);
      expect(find.text('SP'), findsOneWidget);
      expect(find.text('SE/2021/036'), findsOneWidget);
      expect(find.text('Year 2 · Computer Science'), findsOneWidget);
      expect(find.text('Block C · Orchid · C-214 (Bed 2)'), findsOneWidget);
      expect(find.text('Mrs. Ramani Perera · +94 77 221 0455'), findsOneWidget);
      expect(
        find.text('sanuthi.p@stu.kln.ac.lk · +94 77 000 0036'),
        findsOneWidget,
      );
    });

    testWidgets('given Show my QR, then the QR screen opens', (tester) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);

      await tester.tap(find.text('Show my QR'));
      await tester.pumpAndSettle();

      expect(find.byType(MyQrScreen), findsOneWidget);
    });

    testWidgets('given sign out is confirmed, then the session ends', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);

      await tester.scrollUntilVisible(find.text('Sign out'), 200);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);

      await tester.tap(find.text('Sign out').last);
      await tester.pumpAndSettle();

      expect(find.text('EMAIL'), findsOneWidget);
    });

    testWidgets(
      'given sign out is declined, then the student stays signed in',
      (tester) async {
        await pumpApp(tester);
        await goTo(tester, AppRoutes.profile);

        await tester.scrollUntilVisible(find.text('Sign out'), 200);
        await tester.tap(find.text('Sign out'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Stay signed in'));
        await tester.pumpAndSettle();

        expect(find.text('Sanuthi Perera'), findsOneWidget);
      },
    );

    testWidgets('given the home button, then the profile opens', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();

      expect(find.text('Sanuthi Perera'), findsOneWidget);
    });

    testWidgets('given a student with no photo, then initials show', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);

      expect(find.text('SP'), findsOneWidget);
    });
  });
}
