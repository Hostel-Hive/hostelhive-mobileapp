import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hostelhive_mobile/app.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/data/repositories/auth_repository.dart';
import 'package:hostelhive_mobile/data/repositories/inbox_repository.dart';
import 'package:hostelhive_mobile/data/repositories/pass_repository.dart';
import 'package:hostelhive_mobile/data/repositories/session_store.dart';
import 'package:hostelhive_mobile/features/auth/providers/auth_providers.dart';
import 'package:hostelhive_mobile/features/inbox/providers/inbox_providers.dart';
import 'package:hostelhive_mobile/features/passes/providers/pass_providers.dart';
import 'package:hostelhive_mobile/features/qr/models/scan_result.dart';
import 'package:hostelhive_mobile/features/qr/screens/my_qr_screen.dart';
import 'package:hostelhive_mobile/features/qr/screens/scan_result_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

const success = ScanResult.success(
  title: 'Recorded IN at 21:14',
  subtitle: 'Saturday, 19 April 2026',
  studentName: 'Sanuthi',
  studentDetails: 'SE/2021/036 · Block B Room 204',
);

const failure = ScanResult.failure(
  title: 'Scan failed',
  subtitle: 'Please see security at the gate',
  errorCode: 'ERR-NET-01',
);

Future<void> pumpApp(WidgetTester tester, {String? signedInAs}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final store = MemorySessionStore();
  if (signedInAs != null) await store.write(signedInAs);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(store: store, latency: Duration.zero),
        ),
        passRepositoryProvider.overrideWithValue(
          MockPassRepository(latency: Duration.zero),
        ),
        inboxRepositoryProvider.overrideWithValue(
          MockInboxRepository(latency: Duration.zero),
        ),
      ],
      child: const HostelHiveApp(),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter routerOf(WidgetTester tester) {
  return GoRouter.of(tester.element(find.byType(Scaffold).first));
}

void main() {
  group('ScanResult', () {
    test(
      'given a success, then student details are kept and no error code',
      () {
        expect(success.isSuccess, isTrue);
        expect(success.studentName, 'Sanuthi');
        expect(success.errorCode, isNull);
      },
    );

    test('given a failure, then the error code is kept and no student', () {
      expect(failure.isSuccess, isFalse);
      expect(failure.errorCode, 'ERR-NET-01');
      expect(failure.studentName, isNull);
    });
  });

  group('MyQrScreen', () {
    testWidgets(
      'given a signed-in student, then the QR encodes their student ID',
      (tester) async {
        await pumpApp(tester, signedInAs: 'STU-0036');

        routerOf(tester).push(AppRoutes.qr);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('qr:STU-0036')), findsOneWidget);
        expect(find.text('READY TO SCAN'), findsOneWidget);
        expect(find.text('SANUTHI PERERA'), findsOneWidget);
        expect(find.text('SE/2021/036 · Room C-214'), findsOneWidget);
      },
    );

    testWidgets(
      'given the home button, then it opens the QR from the home screen',
      (tester) async {
        await pumpApp(tester, signedInAs: 'STU-0036');

        await tester.tap(find.text('Show my QR'));
        await tester.pumpAndSettle();

        expect(find.byType(MyQrScreen), findsOneWidget);
      },
    );

    testWidgets(
      'given close is tapped, then it returns to the previous screen',
      (tester) async {
        await pumpApp(tester, signedInAs: 'STU-0036');
        await tester.tap(find.text('Show my QR'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Close QR · back to Home'));
        await tester.pumpAndSettle();

        expect(find.byType(MyQrScreen), findsNothing);
        expect(find.text('Hello, Sanuthi'), findsOneWidget);
      },
    );

    testWidgets('given the back button on a direct visit, then it goes home', (
      tester,
    ) async {
      await pumpApp(tester, signedInAs: 'STU-0036');
      routerOf(tester).go(AppRoutes.qr);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Hello, Sanuthi'), findsOneWidget);
    });

    testWidgets('given the info button, then an explanation is shown', (
      tester,
    ) async {
      await pumpApp(tester, signedInAs: 'STU-0036');
      await tester.tap(find.text('Show my QR'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('About your QR code'));
      await tester.pumpAndSettle();
      expect(find.textContaining('unique to you'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.textContaining('unique to you'), findsNothing);
    });

    testWidgets(
      'given no student, then a safe fallback is shown instead of a code',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                MockAuthRepository(
                  store: MemorySessionStore(),
                  latency: Duration.zero,
                ),
              ),
            ],
            child: const MaterialApp(home: MyQrScreen()),
          ),
        );
        await tester.pump();

        expect(find.byType(QrImageView), findsNothing);
        expect(find.textContaining('not available'), findsOneWidget);
      },
    );
  });

  group('ScanResultScreen', () {
    testWidgets(
      'given a success result, then the details and a Done button show',
      (tester) async {
        await pumpApp(tester, signedInAs: 'STU-0036');

        routerOf(tester).push(AppRoutes.scanResult, extra: success);
        await tester.pumpAndSettle();

        expect(find.text('Recorded IN at 21:14'), findsOneWidget);
        expect(find.text('Welcome back, Sanuthi'), findsOneWidget);
        expect(find.text('SE/2021/036 · Block B Room 204'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(find.byType(ScanResultScreen), findsNothing);
      },
    );

    testWidgets(
      'given a failure result, then the error code and Try again show',
      (tester) async {
        await pumpApp(tester, signedInAs: 'STU-0036');

        routerOf(tester).push(AppRoutes.scanResult, extra: failure);
        await tester.pumpAndSettle();

        expect(find.text('Scan failed'), findsOneWidget);
        expect(find.text('ERR-NET-01'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);

        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.byType(ScanResultScreen), findsNothing);
      },
    );

    testWidgets(
      'given a failure without an error code, then no code pill shows',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(
            home: ScanResultScreen(
              result: ScanResult.failure(
                title: 'Scan failed',
                subtitle: 'Try again',
              ),
            ),
          ),
        );

        expect(find.text('Scan failed'), findsOneWidget);
        expect(find.text('ERR-NET-01'), findsNothing);
      },
    );

    testWidgets(
      'given the result is closed on a direct visit, then it goes home',
      (tester) async {
        await pumpApp(tester, signedInAs: 'STU-0036');
        routerOf(tester).go(AppRoutes.scanResult);
        await tester.pumpAndSettle();

        expect(find.text('Hello, Sanuthi'), findsOneWidget);
      },
    );

    testWidgets('given a direct visit with a result, then Done goes home', (
      tester,
    ) async {
      await pumpApp(tester, signedInAs: 'STU-0036');
      routerOf(tester).go(AppRoutes.scanResult, extra: success);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Hello, Sanuthi'), findsOneWidget);
    });
  });
}
