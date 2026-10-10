import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hostelhive_mobile/app.dart';
import 'package:hostelhive_mobile/core/providers/clock_provider.dart';
import 'package:hostelhive_mobile/data/repositories/auth_repository.dart';
import 'package:hostelhive_mobile/data/repositories/complaint_repository.dart';
import 'package:hostelhive_mobile/data/repositories/inbox_repository.dart';
import 'package:hostelhive_mobile/data/repositories/pass_repository.dart';
import 'package:hostelhive_mobile/data/repositories/session_store.dart';
import 'package:hostelhive_mobile/features/auth/providers/auth_providers.dart';
import 'package:hostelhive_mobile/features/complaints/providers/complaint_providers.dart';
import 'package:hostelhive_mobile/features/inbox/providers/inbox_providers.dart';
import 'package:hostelhive_mobile/features/passes/providers/pass_providers.dart';

/// The moment every harness test treats as "now": Sat 18 Apr 2026, 21:14.
final fixedNow = DateTime(2026, 4, 18, 21, 14);

/// Starts the whole app on a phone-sized screen with instant mock data.
Future<void> pumpApp(
  WidgetTester tester, {
  String? signedInAs = 'STU-0036',
  DateTime? now,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final clock = now ?? fixedNow;
  final store = MemorySessionStore();
  if (signedInAs != null) await store.write(signedInAs);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => clock),
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(store: store, latency: Duration.zero),
        ),
        passRepositoryProvider.overrideWithValue(
          MockPassRepository(clock: () => clock, latency: Duration.zero),
        ),
        complaintRepositoryProvider.overrideWithValue(
          MockComplaintRepository(clock: () => clock, latency: Duration.zero),
        ),
        inboxRepositoryProvider.overrideWithValue(
          MockInboxRepository(clock: () => clock, latency: Duration.zero),
        ),
        ...overrides,
      ],
      child: const HostelHiveApp(),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter routerOf(WidgetTester tester) {
  return GoRouter.of(tester.element(find.byType(Scaffold).first));
}

Future<void> goTo(WidgetTester tester, String location, {Object? extra}) async {
  routerOf(tester).go(location, extra: extra);
  await tester.pumpAndSettle();
}

Future<void> pushTo(WidgetTester tester, String location) async {
  routerOf(tester).push(location);
  await tester.pumpAndSettle();
}
