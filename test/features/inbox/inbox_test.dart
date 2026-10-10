import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/data/models/inbox_item.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/data/repositories/inbox_repository.dart';
import 'package:hostelhive_mobile/features/inbox/providers/inbox_providers.dart';

import '../../helpers/harness.dart';

class EmptyInboxRepository extends MockInboxRepository {
  EmptyInboxRepository() : super(clock: () => fixedNow, latency: Duration.zero);

  @override
  Future<List<InboxItem>> fetchItems() async => [];
}

class AnnouncementsOnlyRepository extends MockInboxRepository {
  AnnouncementsOnlyRepository()
    : super(clock: () => fixedNow, latency: Duration.zero);

  @override
  Future<List<InboxItem>> fetchItems() async => [
    InboxItem(
      id: 'a1',
      kind: InboxItemKind.announcement,
      title: 'Only unread message',
      message: 'Hello',
      createdAt: fixedNow,
    ),
  ];
}

class BrokenInboxRepository extends MockInboxRepository {
  BrokenInboxRepository()
    : super(clock: () => fixedNow, latency: Duration.zero);

  @override
  Future<List<InboxItem>> fetchItems() async =>
      throw const RepositoryException('x');
}

final unreadDots = find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == 'Unread',
);

InboxItem item(String id, InboxItemKind kind, {bool read = false}) {
  return InboxItem(
    id: id,
    kind: kind,
    title: id,
    message: 'm',
    createdAt: fixedNow,
    isRead: read,
  );
}

void main() {
  group('inbox helpers', () {
    final items = [
      item('a', InboxItemKind.announcement),
      item('b', InboxItemKind.alert),
      item('c', InboxItemKind.leaveDecision, read: true),
      item('d', InboxItemKind.complaintUpdate),
    ];

    test('given each tab, then the matching items are returned', () {
      expect(itemsForTab(items, InboxTab.all).length, 4);
      expect(itemsForTab(items, InboxTab.announcements).map((i) => i.id), [
        'a',
      ]);
      expect(itemsForTab(items, InboxTab.alerts).map((i) => i.id), [
        'b',
        'c',
        'd',
      ]);
    });

    test('unreadIn counts only unread items', () {
      expect(unreadIn(items), 3);
      expect(unreadIn([]), 0);
    });
  });

  group('providers', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer(
        overrides: [
          inboxRepositoryProvider.overrideWithValue(
            MockInboxRepository(clock: () => fixedNow, latency: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('given the repository, then three messages are unread', () async {
      final container = makeContainer();
      await container.read(inboxProvider.future);

      expect(container.read(unreadCountProvider), 3);
    });

    test(
      'given markAsRead and markAllAsRead, then the unread count drops',
      () async {
        final container = makeContainer();
        await container.read(inboxProvider.future);

        await container.read(inboxProvider.notifier).markAsRead('n1');
        expect(container.read(unreadCountProvider), 2);

        await container.read(inboxProvider.notifier).markAllAsRead();
        expect(container.read(unreadCountProvider), 0);
      },
    );

    test('given the inbox has not loaded, then the unread count is zero', () {
      final container = makeContainer();

      expect(container.read(unreadCountProvider), 0);
    });

    test('given an id, then inboxItemProvider finds it or errors', () async {
      final container = makeContainer();
      await container.read(inboxProvider.future);

      expect(container.read(inboxItemProvider('n3')).value!.tag, 'FACILITIES');
      expect(container.read(inboxItemProvider('zzz')).hasError, isTrue);
    });

    test('the default repository can be created', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(inboxRepositoryProvider), isA<InboxRepository>());
    });
  });

  group('Inbox screen', () {
    testWidgets('given messages, then tab counts, banner and cards show', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.inbox);

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Inbox')),
        findsOneWidget,
      );
      expect(
        find.text('3 new messages since you last checked'),
        findsOneWidget,
      );
      expect(find.text('Curfew drill — Saturday night'), findsOneWidget);
      expect(find.text('2m ago'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(unreadDots, findsNWidgets(3));
    });

    testWidgets('given the Alerts tab, then only alerts show', (tester) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.inbox);

      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      expect(find.text('Return by 22:00'), findsOneWidget);
      expect(find.text('Your LA-2418 was approved'), findsOneWidget);
      expect(find.text('Mess menu update'), findsNothing);
    });

    testWidgets('given the Announcements tab, then alerts are hidden', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.inbox);

      await tester.tap(find.text('Announcements'));
      await tester.pumpAndSettle();

      expect(find.text('Mess menu update'), findsOneWidget);
      expect(find.text('Return by 22:00'), findsNothing);
    });

    testWidgets('given a message is opened, then it is marked read and shown', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.inbox);

      await tester.tap(find.text('Curfew drill — Saturday night'));
      await tester.pumpAndSettle();

      expect(find.text('Message'), findsOneWidget);
      expect(find.textContaining('evacuation drill'), findsOneWidget);
      expect(find.text('Sent 2m ago · Hostel office'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(
        find.text('2 new messages since you last checked'),
        findsOneWidget,
      );
    });

    testWidgets('given Mark all as read, then the banner disappears', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.inbox);

      await tester.tap(find.byTooltip('Mark all as read'));
      await tester.pumpAndSettle();

      expect(find.textContaining('new message'), findsNothing);
      expect(unreadDots, findsNothing);
    });

    testWidgets('given a single unread message, then the banner is singular', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          inboxRepositoryProvider.overrideWithValue(
            AnnouncementsOnlyRepository(),
          ),
        ],
      );
      await goTo(tester, AppRoutes.inbox);

      expect(find.text('1 new message since you last checked'), findsOneWidget);
    });

    testWidgets('given an empty tab, then the tabs stay and a message shows', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          inboxRepositoryProvider.overrideWithValue(
            AnnouncementsOnlyRepository(),
          ),
        ],
      );
      await goTo(tester, AppRoutes.inbox);

      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      expect(find.text('No messages here yet'), findsOneWidget);
      expect(find.text('Announcements'), findsOneWidget);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('Only unread message'), findsOneWidget);
    });

    testWidgets('given no messages at all, then the empty state shows', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          inboxRepositoryProvider.overrideWithValue(EmptyInboxRepository()),
        ],
      );
      await goTo(tester, AppRoutes.inbox);

      expect(find.text('Inbox is empty'), findsOneWidget);
      expect(find.text('All'), findsNothing);
    });

    testWidgets('given loading fails, then a retry message shows', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          inboxRepositoryProvider.overrideWithValue(BrokenInboxRepository()),
        ],
      );
      await goTo(tester, AppRoutes.inbox);

      expect(
        find.text('Could not load your inbox. Tap to retry.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Could not load your inbox. Tap to retry.'));
      await tester.pumpAndSettle();
      expect(
        find.text('Could not load your inbox. Tap to retry.'),
        findsOneWidget,
      );
    });

    testWidgets('given the home button, then the inbox opens', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();

      expect(
        find.text('3 new messages since you last checked'),
        findsOneWidget,
      );
    });
  });

  group('Message detail', () {
    testWidgets('given an unknown message, then a not found message shows', (
      tester,
    ) async {
      await pumpApp(tester);
      await pushTo(tester, '/inbox/zzz');

      expect(find.text('This message was not found.'), findsOneWidget);
    });

    testWidgets('given a direct visit, then Got it goes home', (tester) async {
      await pumpApp(tester);
      await goTo(tester, '/inbox/n2');

      expect(find.text('Your LA-2418 was approved'), findsOneWidget);
      expect(find.text('LATE ACCESS'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text('Hello, Sanuthi'), findsOneWidget);
    });
  });
}
