import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/app.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/core/widgets/primary_button.dart';
import 'package:hostelhive_mobile/data/repositories/auth_repository.dart';
import 'package:hostelhive_mobile/data/repositories/inbox_repository.dart';
import 'package:hostelhive_mobile/data/repositories/pass_repository.dart';
import 'package:hostelhive_mobile/data/repositories/session_store.dart';
import 'package:hostelhive_mobile/features/auth/providers/auth_providers.dart';
import 'package:hostelhive_mobile/features/inbox/providers/inbox_providers.dart';
import 'package:hostelhive_mobile/features/passes/providers/pass_providers.dart';

Future<MemorySessionStore> pumpApp(
  WidgetTester tester, {
  String? signedInAs,
}) async {
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
  return store;
}

Future<void> fillAndSubmitLogin(
  WidgetTester tester,
  String id,
  String password,
) async {
  await tester.enterText(find.byType(TextFormField).at(0), id);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.widgetWithText(PrimaryButton, 'Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  group('authRedirect', () {
    const unknown = AuthState();
    const signedOut = AuthState(status: AuthStatus.unauthenticated);

    test('given the session is still loading, then nothing is redirected', () {
      expect(authRedirect(auth: unknown, location: AppRoutes.home), isNull);
    });

    test('given a signed-out student, then protected routes go to login', () {
      expect(
        authRedirect(auth: signedOut, location: AppRoutes.home),
        AppRoutes.login,
      );
      expect(
        authRedirect(auth: signedOut, location: AppRoutes.firstLogin),
        AppRoutes.login,
      );
    });

    test('given a signed-out student, then public routes are allowed', () {
      for (final route in AppRoutes.publicRoutes) {
        expect(authRedirect(auth: signedOut, location: route), isNull);
      }
    });
  });

  group('login screen', () {
    testWidgets('given the app starts signed out, then login is shown', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets(
      'given empty fields, when signing in, then validation errors show',
      (tester) async {
        await pumpApp(tester);

        await tester.tap(find.widgetWithText(PrimaryButton, 'Sign in'));
        await tester.pump();

        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
      },
    );

    testWidgets(
      'given wrong credentials, then an error is shown and login stays',
      (tester) async {
        await pumpApp(tester);

        await fillAndSubmitLogin(tester, 'sanuthi.p@stu.kln.ac.lk', 'wrong');

        expect(find.text('Incorrect email/ID or password.'), findsOneWidget);
        expect(find.text('EMAIL'), findsOneWidget);
      },
    );

    testWidgets('given valid credentials, then the student reaches home', (
      tester,
    ) async {
      await pumpApp(tester);

      await fillAndSubmitLogin(tester, 'sanuthi.p@stu.kln.ac.lk', 'Hostel@123');

      expect(find.text('Hello, Sanuthi'), findsOneWidget);
    });

    testWidgets('given a saved session, then login is skipped', (tester) async {
      await pumpApp(tester, signedInAs: 'STU-0036');

      expect(find.text('Hello, Sanuthi'), findsOneWidget);
    });

    testWidgets('given sign out is tapped, then the student returns to login', (
      tester,
    ) async {
      final store = await pumpApp(tester, signedInAs: 'STU-0036');

      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out').last);
      await tester.pumpAndSettle();

      expect(find.text('EMAIL'), findsOneWidget);
      expect(await store.read(), isNull);
    });

    testWidgets(
      'given the welcome email link is tapped, then a hint is shown',
      (tester) async {
        await pumpApp(tester);

        await tester.tap(find.text('Check your welcome email'));
        await tester.pump();

        expect(find.textContaining('choose your password'), findsOneWidget);
      },
    );
  });

  group('first login', () {
    testWidgets(
      'given a new student signs in, then the first login screen opens',
      (tester) async {
        await pumpApp(tester);

        await fillAndSubmitLogin(tester, 'nethmi.s@stu.kln.ac.lk', 'Temp@1234');

        expect(find.text('FIRST LOGIN · SE/2022/101'), findsOneWidget);
        expect(find.text('Nethmi.'), findsOneWidget);
      },
    );

    testWidgets('given a weak password, then it is rejected', (tester) async {
      await pumpApp(tester);
      await fillAndSubmitLogin(tester, 'nethmi.s@stu.kln.ac.lk', 'Temp@1234');

      await tester.enterText(find.byType(TextFormField).at(0), 'password');
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Activate account'));
      await tester.pump();

      expect(
        find.text('Use an uppercase letter, a number and a symbol'),
        findsOneWidget,
      );
    });

    testWidgets('given mismatched passwords, then it asks to match', (
      tester,
    ) async {
      await pumpApp(tester);
      await fillAndSubmitLogin(tester, 'nethmi.s@stu.kln.ac.lk', 'Temp@1234');

      await tester.enterText(find.byType(TextFormField).at(0), 'Brand#New9');
      await tester.enterText(find.byType(TextFormField).at(1), 'Different#1');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Activate account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets(
      'given a strong matching password, then the account is activated',
      (tester) async {
        await pumpApp(tester);
        await fillAndSubmitLogin(tester, 'nethmi.s@stu.kln.ac.lk', 'Temp@1234');

        await tester.enterText(find.byType(TextFormField).at(0), 'Brand#New9');
        await tester.pump();
        expect(find.text('Strong'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).at(1), 'Brand#New9');
        await tester.tap(
          find.widgetWithText(PrimaryButton, 'Activate account'),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hello, Nethmi'), findsOneWidget);
      },
    );

    testWidgets(
      'given a pending password change, then other routes redirect back',
      (tester) async {
        await pumpApp(tester, signedInAs: 'STU-0101');

        expect(find.text('FIRST LOGIN · SE/2022/101'), findsOneWidget);
      },
    );
  });

  group('forgot and reset password', () {
    Future<void> openForgot(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'given the forgot link is tapped, then the reset request opens',
      (tester) async {
        await openForgot(tester);

        expect(find.text('your password?'), findsOneWidget);
      },
    );

    testWidgets('given an invalid email, then validation fails', (
      tester,
    ) async {
      await openForgot(tester);

      await tester.enterText(find.byType(TextFormField), 'not-an-email');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Send reset link'));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('given an unregistered email, then an error is shown', (
      tester,
    ) async {
      await openForgot(tester);

      await tester.enterText(find.byType(TextFormField), 'ghost@stu.kln.ac.lk');
      await tester.tap(find.widgetWithText(PrimaryButton, 'Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('This email is not registered.'), findsOneWidget);
    });

    testWidgets('given try signing in again, then it returns to login', (
      tester,
    ) async {
      await openForgot(tester);

      await tester.tap(find.text('Try signing in again'));
      await tester.pumpAndSettle();

      expect(find.text('EMAIL'), findsOneWidget);
    });

    testWidgets('given the back button, then it returns to login', (
      tester,
    ) async {
      await openForgot(tester);

      await tester.tap(find.byTooltip('Back to sign in'));
      await tester.pumpAndSettle();

      expect(find.text('EMAIL'), findsOneWidget);
    });

    testWidgets(
      'given the full flow, then the password is reset and sign in is offered',
      (tester) async {
        await openForgot(tester);

        await tester.enterText(
          find.byType(TextFormField),
          'sanuthi.p@stu.kln.ac.lk',
        );
        await tester.tap(find.widgetWithText(PrimaryButton, 'Send reset link'));
        await tester.pumpAndSettle();
        expect(find.text('Set a new password'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField).at(0), 'weak');
        await tester.tap(find.widgetWithText(PrimaryButton, 'Save password'));
        await tester.pump();
        expect(find.text('Use at least 8 characters'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField).at(0), 'Brand#New9');
        await tester.pump();
        expect(find.text('Strong'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField).at(1), 'Brand#New9');
        await tester.tap(find.widgetWithText(PrimaryButton, 'Save password'));
        await tester.pumpAndSettle();

        expect(find.text('Password updated'), findsWidgets);

        await tester.tap(find.text('Back to sign in'));
        await tester.pumpAndSettle();
        expect(find.text('EMAIL'), findsOneWidget);
      },
    );
  });
}
