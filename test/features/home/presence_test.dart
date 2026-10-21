import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/config/app_config.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/data/models/student.dart';
import 'package:hostelhive_mobile/data/repositories/auth_repository.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/data/repositories/session_store.dart';
import 'package:hostelhive_mobile/features/auth/providers/auth_providers.dart';
import 'package:hostelhive_mobile/features/qr/providers/qr_providers.dart';

import '../../helpers/harness.dart';

/// Signs in as the demo student but reports a chosen gate status.
class PresenceAuthRepository extends MockAuthRepository {
  PresenceAuthRepository(this.presence, {MemorySessionStore? store})
    : super(store: store ?? MemorySessionStore(), latency: Duration.zero);

  PresenceStatus presence;
  bool failNext = false;

  @override
  Future<Student?> currentUser() async {
    if (failNext) throw const RepositoryException('offline');
    final student = await super.currentUser();
    return student?.copyWith(presence: presence);
  }
}

void main() {
  Future<PresenceAuthRepository> openHome(
    WidgetTester tester,
    PresenceStatus presence,
  ) async {
    final store = MemorySessionStore();
    await store.write('STU-0036');
    final repository = PresenceAuthRepository(presence, store: store);
    await pumpApp(
      tester,
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    return repository;
  }

  group('Home status from the gate scans', () {
    testWidgets('given IN, then the student is signed in', (tester) async {
      await openHome(tester, PresenceStatus.inside);

      expect(find.text('SIGNED IN'), findsOneWidget);
      expect(find.text('Room C-214.'), findsOneWidget);
    });

    testWidgets('given OUT, then the student is shown as out', (tester) async {
      await openHome(tester, PresenceStatus.outside);

      expect(find.text('OUT'), findsOneWidget);
      expect(find.text('You’re out of the hostel.'), findsOneWidget);
    });

    testWidgets('given UNKNOWN, then it is not shown as out', (tester) async {
      await openHome(tester, PresenceStatus.unknown);

      expect(find.text('STATUS UNKNOWN'), findsOneWidget);
      expect(find.text('Your status is unknown.'), findsOneWidget);
      expect(find.text('OUT'), findsNothing);
    });

    testWidgets('given UNKNOWN, then going home asks to scan first', (
      tester,
    ) async {
      await openHome(tester, PresenceStatus.unknown);

      await tester.tap(find.text('Going home'));
      await tester.pump();

      expect(
        find.text('Your status is unknown. Scan your ID at the gate first.'),
        findsOneWidget,
      );
      expect(find.text('Confirm going home'), findsNothing);
    });

    testWidgets('given the screen is pulled down, then the status reloads', (
      tester,
    ) async {
      final repository = await openHome(tester, PresenceStatus.inside);
      expect(find.text('SIGNED IN'), findsOneWidget);

      repository.presence = PresenceStatus.outside;
      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(find.text('OUT'), findsOneWidget);
    });
  });

  group('refreshProfile', () {
    ProviderContainer containerFor(PresenceAuthRepository repository) {
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<void> settle(ProviderContainer container) async {
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);
    }

    test('given a changed status, then the profile is updated', () async {
      final store = MemorySessionStore();
      await store.write('STU-0036');
      final repository = PresenceAuthRepository(
        PresenceStatus.inside,
        store: store,
      );
      final container = containerFor(repository);
      await settle(container);

      repository.presence = PresenceStatus.outside;
      await container.read(authControllerProvider.notifier).refreshProfile();

      expect(
        container.read(authControllerProvider).student?.presence,
        PresenceStatus.outside,
      );
    });

    test('given the reload fails, then the old profile stays', () async {
      final store = MemorySessionStore();
      await store.write('STU-0036');
      final repository = PresenceAuthRepository(
        PresenceStatus.inside,
        store: store,
      );
      final container = containerFor(repository);
      await settle(container);

      repository.failNext = true;
      await container.read(authControllerProvider.notifier).refreshProfile();

      expect(
        container.read(authControllerProvider).student?.presence,
        PresenceStatus.inside,
      );
    });

    test('given nobody is signed in, then nothing happens', () async {
      final container = containerFor(
        PresenceAuthRepository(PresenceStatus.inside),
      );
      await settle(container);

      await container.read(authControllerProvider.notifier).refreshProfile();

      expect(container.read(authControllerProvider).student, isNull);
    });
  });

  group('My QR from the backend', () {
    const backend = AppConfig(
      apiBaseUrl: 'https://api.example.invalid/api/v1',
      firebaseApiKey: 'KEY',
    );

    testWidgets('given the backend image, then it is shown', (tester) async {
      await pumpApp(
        tester,
        overrides: [
          appConfigProvider.overrideWithValue(backend),
          qrImageProvider.overrideWith(
            (ref) async => Uint8List.fromList(_tinyPng),
          ),
        ],
      );

      await goTo(tester, AppRoutes.qr);

      expect(find.byKey(const ValueKey('qr-image')), findsOneWidget);
      expect(find.byKey(const ValueKey('qr:STU-0036')), findsNothing);
      expect(find.text('SANUTHI PERERA'), findsOneWidget);
    });

    testWidgets('given the image fails, then a retry is offered', (
      tester,
    ) async {
      var calls = 0;
      await pumpApp(
        tester,
        overrides: [
          appConfigProvider.overrideWithValue(backend),
          qrImageProvider.overrideWith((ref) async {
            calls++;
            throw const RepositoryException('x');
          }),
        ],
      );
      await goTo(tester, AppRoutes.qr);

      expect(
        find.text('Could not load your QR code. Tap to retry.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Could not load your QR code. Tap to retry.'));
      await tester.pumpAndSettle();

      expect(calls, 2);
    });

    testWidgets('given the demo data, then the QR is drawn from the ID', (
      tester,
    ) async {
      await pumpApp(tester);

      await goTo(tester, AppRoutes.qr);

      expect(find.byKey(const ValueKey('qr:STU-0036')), findsOneWidget);
    });

    test('given the demo data, then no image is requested', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(qrImageProvider.future), isNull);
    });
  });
}

// A valid 1x1 PNG.
const _tinyPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xFF,
  0xFF,
  0x3F,
  0x00,
  0x05,
  0xFE,
  0x02,
  0xFE,
  0xA7,
  0x35,
  0x81,
  0x84,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
