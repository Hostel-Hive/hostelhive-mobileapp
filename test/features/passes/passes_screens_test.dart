import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/core/widgets/primary_button.dart';
import 'package:hostelhive_mobile/data/models/pass.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/data/repositories/pass_repository.dart';
import 'package:hostelhive_mobile/features/passes/providers/pass_providers.dart';
import 'package:hostelhive_mobile/features/qr/screens/my_qr_screen.dart';

import '../../helpers/harness.dart';

class EmptyPassRepository extends MockPassRepository {
  EmptyPassRepository() : super(clock: () => fixedNow, latency: Duration.zero);

  @override
  Future<List<Pass>> fetchPasses() async => [];
}

class BrokenPassRepository extends MockPassRepository {
  BrokenPassRepository() : super(clock: () => fixedNow, latency: Duration.zero);

  @override
  Future<List<Pass>> fetchPasses() async =>
      throw const RepositoryException('x');
}

class UncancellablePassRepository extends MockPassRepository {
  UncancellablePassRepository()
    : super(clock: () => fixedNow, latency: Duration.zero);

  @override
  Future<void> cancelPass(String passId) async {
    throw const RepositoryException('Cancelling is not possible right now.');
  }
}

void main() {
  group('Passes screen', () {
    testWidgets(
      'given passes exist, then quota, counts and the active pass show',
      (tester) async {
        await pumpApp(tester);
        await goTo(tester, AppRoutes.passes);

        expect(find.text('My passes'), findsOneWidget);
        expect(
          find.textContaining('/ 18 used', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('67%'), findsOneWidget);
        expect(find.text('Home visit'), findsOneWidget);
        expect(find.text('LA-2418'), findsOneWidget);
        expect(find.text('View pass details'), findsOneWidget);
        expect(find.text('RECENT HISTORY'), findsOneWidget);
        expect(find.text('Doctor appointment'), findsOneWidget);
      },
    );

    testWidgets('given the pending tab, then an empty message shows', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.passes);

      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.text('View pass details'), findsNothing);
    });

    testWidgets(
      'given See all, then the history tab lists every finished pass',
      (tester) async {
        await pumpApp(tester);
        await goTo(tester, AppRoutes.passes);

        await tester.tap(find.text('See all'));
        await tester.pumpAndSettle();

        expect(find.text('Doctor appointment'), findsOneWidget);
        expect(find.text('Bookshop'), findsOneWidget);
        expect(find.text('RECENT HISTORY'), findsNothing);
      },
    );

    testWidgets('given View pass details, then the pass detail opens', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.passes);

      await tester.tap(find.text('View pass details'));
      await tester.pumpAndSettle();

      expect(find.text('Pass LA-2418'), findsOneWidget);
    });

    testWidgets('given a history row is tapped, then its detail opens', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.passes);

      await tester.tap(find.text('Bookshop'));
      await tester.pumpAndSettle();

      expect(find.text('Pass LA-2341'), findsOneWidget);
      expect(find.text('Cancel pass'), findsNothing);
    });

    testWidgets('given the add button, then the request form opens', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.passes);

      await tester.tap(find.byTooltip('Request late access'));
      await tester.pumpAndSettle();

      expect(find.text('Submit to warden'), findsOneWidget);
    });

    testWidgets('given no passes, then the empty state offers a request', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          passRepositoryProvider.overrideWithValue(EmptyPassRepository()),
        ],
      );
      await goTo(tester, AppRoutes.passes);

      expect(find.text('No passes yet'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(PrimaryButton, 'Request late access'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Submit to warden'), findsOneWidget);
    });

    testWidgets('given loading fails, then a retry message is shown', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          passRepositoryProvider.overrideWithValue(BrokenPassRepository()),
        ],
      );
      await goTo(tester, AppRoutes.passes);

      expect(find.text('Could not load passes. Tap to retry.'), findsOneWidget);

      await tester.tap(find.text('Could not load passes. Tap to retry.'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load passes. Tap to retry.'), findsOneWidget);
    });
  });

  group('Pass detail', () {
    testWidgets(
      'given an approved pass, then details and the warden note show',
      (tester) async {
        await pumpApp(tester);
        await pushTo(tester, '/passes/LA-2418');

        expect(find.text('Approved by Nisansala R. · 22m ago'), findsOneWidget);
        expect(find.text('2 days 9 hours'), findsOneWidget);
        expect(find.text('Family wedding'), findsOneWidget);
        expect(find.text('Gampaha'), findsOneWidget);
        expect(find.text('Parent pickup'), findsOneWidget);
        expect(find.text('+94 77 221 0455'), findsOneWidget);
        expect(find.text('Cancel pass'), findsOneWidget);
      },
    );

    testWidgets('given Show my QR, then the QR screen opens', (tester) async {
      await pumpApp(tester);
      await pushTo(tester, '/passes/LA-2418');

      await tester.tap(find.text('Show my QR'));
      await tester.pumpAndSettle();

      expect(find.byType(MyQrScreen), findsOneWidget);
    });

    testWidgets('given the info button, then an explanation shows', (
      tester,
    ) async {
      await pumpApp(tester);
      await pushTo(tester, '/passes/LA-2418');

      await tester.tap(find.byTooltip('About passes'));
      await tester.pumpAndSettle();
      expect(find.text('About passes'), findsWidgets);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets(
      'given a cancel is confirmed, then the pass becomes cancelled',
      (tester) async {
        await pumpApp(tester);
        await pushTo(tester, '/passes/LA-2418');

        await tester.tap(find.text('Cancel pass'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Cancel pass'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CANCELLED'), findsOneWidget);
        expect(find.text('Cancel pass'), findsNothing);
        expect(find.text('Show my QR'), findsNothing);
      },
    );

    testWidgets(
      'given the dialog is dismissed with Keep pass, then nothing changes',
      (tester) async {
        await pumpApp(tester);
        await pushTo(tester, '/passes/LA-2418');

        await tester.tap(find.text('Cancel pass'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Keep pass'));
        await tester.pumpAndSettle();

        expect(find.text('APPROVED'), findsOneWidget);
      },
    );

    testWidgets('given cancelling fails, then the reason is shown', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          passRepositoryProvider.overrideWithValue(
            UncancellablePassRepository(),
          ),
        ],
      );
      await pushTo(tester, '/passes/LA-2418');

      await tester.tap(find.text('Cancel pass'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel pass'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Cancelling is not possible right now.'),
        findsOneWidget,
      );
      expect(find.text('APPROVED'), findsOneWidget);
    });

    testWidgets('given an unknown pass, then a not found message shows', (
      tester,
    ) async {
      await pumpApp(tester);
      await pushTo(tester, '/passes/NOPE');

      expect(find.text('This pass was not found.'), findsOneWidget);
    });
  });

  group('Request late access', () {
    Future<void> openForm(WidgetTester tester) async {
      await pumpApp(tester);
      await pushTo(tester, AppRoutes.requestLateAccess);
    }

    testWidgets(
      'given the form is empty, then destination and reason are required',
      (tester) async {
        await openForm(tester);

        await tester.tap(find.text('Submit to warden'));
        await tester.pump();

        expect(find.text('Destination is required'), findsOneWidget);
        expect(find.text('Reason is required'), findsOneWidget);
      },
    );

    testWidgets(
      'given valid details, then the request is sent and can be viewed',
      (tester) async {
        await openForm(tester);

        await tester.tap(find.text('Medical'));
        await tester.pump();
        await tester.enterText(find.byType(TextFormField).at(0), 'Colombo');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Dentist appointment',
        );
        await tester.tap(find.text('Submit to warden'));
        await tester.pumpAndSettle();

        expect(find.text('Request sent'), findsWidgets);
        expect(find.text('LA-2419'), findsOneWidget);

        await tester.tap(find.text('View pass'));
        await tester.pumpAndSettle();

        expect(find.text('Pass LA-2419'), findsOneWidget);
        expect(find.text('Medical visit'), findsOneWidget);
        expect(find.text('PENDING'), findsOneWidget);
      },
    );

    testWidgets('given Back to Home on the confirmation, then home opens', (
      tester,
    ) async {
      await openForm(tester);
      await tester.enterText(find.byType(TextFormField).at(0), 'Colombo');
      await tester.enterText(find.byType(TextFormField).at(1), 'Dentist');
      await tester.tap(find.text('Submit to warden'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();

      expect(find.text('Hello, Sanuthi'), findsOneWidget);
    });

    testWidgets(
      'given a departure in the past, then the repository error shows',
      (tester) async {
        await pumpApp(
          tester,
          overrides: [
            passRepositoryProvider.overrideWithValue(
              MockPassRepository(
                clock: () => fixedNow.add(const Duration(days: 3)),
                latency: Duration.zero,
              ),
            ),
          ],
        );
        await pushTo(tester, AppRoutes.requestLateAccess);
        await tester.enterText(find.byType(TextFormField).at(0), 'Colombo');
        await tester.enterText(find.byType(TextFormField).at(1), 'Dentist');

        await tester.tap(find.text('Submit to warden'));
        await tester.pumpAndSettle();

        expect(find.textContaining('cannot be in the past'), findsOneWidget);
        expect(find.text('Request sent'), findsNothing);
      },
    );

    testWidgets(
      'given the default dates, then the duration is within the quota',
      (tester) async {
        await openForm(tester);

        expect(find.text('19 Apr 2026'), findsNWidgets(2));
        expect(find.text('09:00'), findsOneWidget);
        expect(find.text('18:00'), findsOneWidget);
        expect(
          find.textContaining(
            'Duration · 9 hours · within your 18-day annual quota',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('given a return date far ahead, then a quota warning shows', (
      tester,
    ) async {
      await openForm(tester);

      await tester.tap(find.text('19 Apr 2026').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('30'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('30 Apr 2026'), findsOneWidget);
      expect(
        find.textContaining('exceeds your remaining 6-day quota'),
        findsOneWidget,
      );
    });

    testWidgets('given a departure after the return, then the form flags it', (
      tester,
    ) async {
      await openForm(tester);

      await tester.tap(find.text('19 Apr 2026').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('25'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        find.text('Return must be after the departure time'),
        findsOneWidget,
      );
    });

    testWidgets(
      'given the date picker is cancelled, then the date is unchanged',
      (tester) async {
        await openForm(tester);

        await tester.tap(find.text('19 Apr 2026').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('19 Apr 2026'), findsNWidgets(2));
      },
    );

    testWidgets(
      'given the time pickers are confirmed, then the times are kept',
      (tester) async {
        await openForm(tester);

        await tester.tap(find.text('09:00'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('18:00'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.text('09:00'), findsOneWidget);
        expect(find.text('18:00'), findsOneWidget);
      },
    );

    testWidgets(
      'given a time picker is cancelled, then the time is unchanged',
      (tester) async {
        await openForm(tester);

        await tester.tap(find.text('09:00'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('09:00'), findsOneWidget);
      },
    );
  });

  group('Going home', () {
    testWidgets('given the student confirms, then going home is recorded', (
      tester,
    ) async {
      await pumpApp(tester);
      await pushTo(tester, AppRoutes.goingHome);

      expect(find.text('Mark yourself as going home?'), findsOneWidget);

      await tester.tap(find.text('Confirm going home'));
      await tester.pumpAndSettle();

      expect(find.text('Going home recorded'), findsWidgets);
      expect(find.textContaining('marked as OUT'), findsOneWidget);

      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      expect(find.text('Hello, Sanuthi'), findsOneWidget);
    });

    testWidgets('given the student is already out, then an error is shown', (
      tester,
    ) async {
      await pumpApp(tester);
      await pushTo(tester, AppRoutes.goingHome);
      await tester.tap(find.text('Confirm going home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();

      await pushTo(tester, AppRoutes.goingHome);
      await tester.tap(find.text('Confirm going home'));
      await tester.pumpAndSettle();

      expect(
        find.text('You are already recorded as outside the hostel.'),
        findsOneWidget,
      );
      expect(find.text('Going home recorded'), findsNothing);
    });

    testWidgets('given Cancel, then the student returns without recording', (
      tester,
    ) async {
      await pumpApp(tester);
      await pushTo(tester, AppRoutes.goingHome);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Hello, Sanuthi'), findsOneWidget);
    });
  });
}
