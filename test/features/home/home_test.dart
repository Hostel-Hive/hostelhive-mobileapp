import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/data/models/pass.dart';
import 'package:hostelhive_mobile/data/models/complaint.dart';
import 'package:hostelhive_mobile/data/repositories/complaint_repository.dart';
import 'package:hostelhive_mobile/data/repositories/pass_repository.dart';
import 'package:hostelhive_mobile/features/complaints/providers/complaint_providers.dart';
import 'package:hostelhive_mobile/features/home/screens/home_screen.dart';
import 'package:hostelhive_mobile/features/home/utils/curfew.dart';
import 'package:hostelhive_mobile/features/passes/providers/pass_providers.dart';
import 'package:hostelhive_mobile/features/qr/screens/my_qr_screen.dart';

import '../../helpers/harness.dart';

class EmptyComplaintRepository extends MockComplaintRepository {
  EmptyComplaintRepository()
    : super(clock: () => fixedNow, latency: Duration.zero);

  @override
  Future<List<Complaint>> fetchComplaints() async => [];
}

class NoPassesRepository extends MockPassRepository {
  NoPassesRepository() : super(clock: () => fixedNow, latency: Duration.zero);

  @override
  Future<List<Pass>> fetchPasses() async => [];
}

Pass pass(String id, PassStatus status, {PassType type = PassType.lateAccess}) {
  return Pass(
    id: id,
    type: type,
    status: status,
    title: id,
    departureAt: fixedNow,
    returnAt: fixedNow.add(const Duration(hours: 5)),
    submittedAt: fixedNow,
  );
}

final unreadDot = find.byWidgetPredicate(
  (widget) =>
      widget is Semantics && widget.properties.label == 'Unread messages',
);

Finder tab(String label) => find.byKey(ValueKey('tab:$label'));

void main() {
  group('curfew', () {
    test('given an evening time, then the time until 22:00 is returned', () {
      expect(
        timeUntilCurfew(DateTime(2026, 4, 18, 21, 14)),
        const Duration(minutes: 46),
      );
    });

    test('given 22:00 or later, then there is no time left', () {
      expect(timeUntilCurfew(DateTime(2026, 4, 18, 22)), isNull);
      expect(timeUntilCurfew(DateTime(2026, 4, 18, 23, 30)), isNull);
    });

    test('given different times, then the message reads naturally', () {
      expect(
        curfewMessage(DateTime(2026, 4, 18, 21, 14)),
        'Curfew at 22:00 · in 46 min',
      );
      expect(
        curfewMessage(DateTime(2026, 4, 18, 19, 55)),
        'Curfew at 22:00 · in 2 h 5 min',
      );
      expect(
        curfewMessage(DateTime(2026, 4, 18, 20)),
        'Curfew at 22:00 · in 2 h',
      );
      expect(curfewMessage(DateTime(2026, 4, 18, 22, 1)), 'Curfew has passed');
    });

    test('given the time of day, then the right greeting is used', () {
      expect(greetingFor(DateTime(2026, 4, 18, 8)), 'Good morning');
      expect(greetingFor(DateTime(2026, 4, 18, 13)), 'Good afternoon');
      expect(greetingFor(DateTime(2026, 4, 18, 21)), 'Good evening');
    });
  });

  group('activeRequest', () {
    test('given no passes, then there is none', () {
      expect(activeRequest([], fixedNow), isNull);
    });

    test('given pending and approved passes, then pending wins', () {
      final passes = [
        pass('approved', PassStatus.approved),
        pass('pending', PassStatus.pending),
      ];

      expect(activeRequest(passes, fixedNow)!.id, 'pending');
    });

    test('given only finished or going home passes, then there is none', () {
      final passes = [
        pass('done', PassStatus.completed),
        pass('no', PassStatus.rejected),
        pass('out', PassStatus.approved, type: PassType.goingHome),
      ];

      expect(activeRequest(passes, fixedNow), isNull);
    });
  });

  group('Home dashboard', () {
    testWidgets('given a signed-in student, then status shows', (tester) async {
      await pumpApp(tester);

      expect(find.text('Good evening,'), findsOneWidget);
      expect(find.text('Hello, Sanuthi'), findsOneWidget);
      expect(find.text('SIGNED IN'), findsOneWidget);
      expect(find.text('You’re in Block C,'), findsOneWidget);
      expect(find.text('Room C-214.'), findsOneWidget);
    });

    testWidgets('given an active pass, then its card is shown', (tester) async {
      await pumpApp(tester);

      expect(find.text('ACTIVE REQUEST'), findsOneWidget);
      expect(find.text('Home visit'), findsOneWidget);
      expect(find.text('View pass details'), findsOneWidget);
    });

    testWidgets('given the card is opened, then the pass detail shows', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View pass details'));
      await tester.pumpAndSettle();

      expect(find.text('Pass LA-2418'), findsOneWidget);
    });

    testWidgets('given no passes, then the active request card is hidden', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          passRepositoryProvider.overrideWithValue(NoPassesRepository()),
        ],
      );

      expect(find.text('ACTIVE REQUEST'), findsNothing);
      expect(find.text('View pass details'), findsNothing);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
    });

    testWidgets('given Show my QR, then the QR screen opens', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Show my QR'));
      await tester.pumpAndSettle();

      expect(find.byType(MyQrScreen), findsOneWidget);
    });

    testWidgets('given Request a pass, then the form opens', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Request a pass'));
      await tester.pumpAndSettle();

      expect(find.text('Submit to warden'), findsOneWidget);
    });

    testWidgets('given My complaints, then the form opens via the FAB', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          complaintRepositoryProvider.overrideWithValue(
            EmptyComplaintRepository(),
          ),
        ],
      );

      await tester.tap(find.text('My complaints'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Report an issue'));
      await tester.pumpAndSettle();

      expect(find.text('Submit complaint'), findsOneWidget);
    });

    testWidgets('given unread messages, then the bell and tab show a dot', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(unreadDot, findsNWidgets(2));
    });

    testWidgets('given the bell is tapped, then the inbox tab opens', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();

      expect(
        find.text('3 new messages since you last checked'),
        findsOneWidget,
      );
    });
  });

  group('Going home from the dashboard', () {
    Future<void> goHome(WidgetTester tester) async {
      await tester.tap(find.text('Going home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm going home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'given the declaration is confirmed, then the student still shows as '
      'signed in with a reminder to scan out',
      (tester) async {
        await pumpApp(tester);

        await goHome(tester);

        // Declaring going home only records intent; only a gate scan moves
        // the student OUT, so the badge must not jump ahead of that.
        expect(find.text('SIGNED IN'), findsOneWidget);
        expect(find.text('OUT'), findsNothing);
        expect(find.textContaining('have not scanned out yet'), findsOneWidget);
      },
    );

    testWidgets(
      'given a declaration already exists, then confirming again is refused',
      (tester) async {
        await pumpApp(tester);
        await goHome(tester);

        // Presence is still "inside", so the dashboard lets the student try
        // again; the repository is what refuses the duplicate declaration.
        await tester.tap(find.text('Going home'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm going home'));
        await tester.pumpAndSettle();

        expect(
          find.text('You are already recorded as outside the hostel.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Tab navigation', () {
    testWidgets('given each tab is tapped, then its screen opens', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(tab('Passes'));
      await tester.pumpAndSettle();
      expect(find.text('My passes'), findsOneWidget);

      await tester.tap(tab('Inbox'));
      await tester.pumpAndSettle();
      expect(
        find.text('3 new messages since you last checked'),
        findsOneWidget,
      );

      await tester.tap(tab('Me'));
      await tester.pumpAndSettle();
      expect(find.text('Sanuthi Perera'), findsOneWidget);

      await tester.tap(tab('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('given all messages are read, then the dots go away', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(tab('Inbox'));
      await tester.pumpAndSettle();

      for (final title in [
        'Curfew drill — Saturday night',
        'Your LA-2418 was approved',
        'Laundry schedule change',
      ]) {
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
      }

      expect(unreadDot, findsNothing);
    });

    testWidgets('given the current tab is tapped again, then it stays open', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(tab('Inbox'));
      await tester.pumpAndSettle();

      await tester.tap(tab('Inbox'));
      await tester.pumpAndSettle();

      expect(
        find.text('3 new messages since you last checked'),
        findsOneWidget,
      );
    });

    testWidgets('given a pass is opened, then the tab bar is hidden', (
      tester,
    ) async {
      await pumpApp(tester);
      await pushTo(tester, '/passes/LA-2418');

      expect(tab('Passes'), findsNothing);
    });

    testWidgets('given a signed-in start, then home is the first location', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(
        routerOf(tester).routeInformationProvider.value.uri.path,
        AppRoutes.home,
      );
    });
  });
}
