import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/features/qr/screens/my_qr_screen.dart';

import '../../helpers/harness.dart';

void main() {
  group('Profile screen', () {
    testWidgets('given a signed-in student, then their details show', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.profile);

      expect(find.text('Me'), findsOneWidget);
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

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);

      await tester.tap(find.text('Sign out').last);
      await tester.pumpAndSettle();

      expect(find.text('EMAIL OR STUDENT ID'), findsOneWidget);
    });

    testWidgets(
      'given sign out is declined, then the student stays signed in',
      (tester) async {
        await pumpApp(tester);
        await goTo(tester, AppRoutes.profile);

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
  });
}
