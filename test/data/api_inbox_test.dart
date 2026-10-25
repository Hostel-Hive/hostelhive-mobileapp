import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/config/app_config.dart';
import 'package:hostelhive_mobile/data/api/api_client.dart';
import 'package:hostelhive_mobile/data/models/inbox_item.dart';
import 'package:hostelhive_mobile/data/repositories/api_inbox_repository.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/data/repositories/inbox_repository.dart';
import 'package:hostelhive_mobile/features/inbox/providers/inbox_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/harness.dart';

class _Token implements TokenSource {
  @override
  Future<String?> idToken({bool forceRefresh = false}) async => 'token';
}

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

const annOne = 'a1111111-0000-4000-8000-000000000001';
const annTwo = 'a2222222-0000-4000-8000-000000000002';
const leaveId = 'l1111111-0000-4000-8000-000000000001';
const lateId = 'l2222222-0000-4000-8000-000000000002';
const complaintId = 'c1111111-0000-4000-8000-000000000001';

Map<String, dynamic> announcement(String id, String title, String at) => {
  'announcement_id': id,
  'title': title,
  'content': 'Full text of $title',
  'audience': 'all_students',
  'priority': 'normal',
  'published_at': at,
};

Map<String, dynamic> notification(
  String id,
  String source, {
  String? readAt,
  Map<String, String> ids = const {},
  String occurredAt = '2026-10-15T10:00:00Z',
}) => {
  'notification_id': id,
  'source_type': source,
  'kind': 'x',
  'status': 'approved',
  'title': 'Title of $id',
  'occurred_at': occurredAt,
  'created_at': occurredAt,
  'read_at': readAt,
  ...ids,
};

void main() {
  late List<http.Request> calls;
  late List<Map<String, dynamic>> announcements;
  late List<Map<String, dynamic>> notifications;
  late Future<http.Response> Function(http.Request request)? override;

  ApiInboxRepository build() {
    calls = [];
    final api = ApiClient(
      baseUrl: 'https://api.example.invalid/api/v1',
      client: MockClient((request) async {
        calls.add(request);
        final custom = override;
        if (custom != null) return custom(request);
        final path = request.url.path.replaceFirst('/api/v1', '');
        if (path == '/announcements') {
          return json({'items': announcements, 'has_more': false});
        }
        if (path == '/notifications') {
          return json({'items': notifications, 'has_more': false});
        }
        return json({'ok': true});
      }),
      tokens: _Token(),
    );
    return ApiInboxRepository(api);
  }

  setUp(() {
    override = null;
    announcements = [
      announcement(annOne, 'Water cut', '2026-10-15T09:00:00Z'),
      announcement(annTwo, 'Old notice', '2026-10-01T09:00:00Z'),
    ];
    notifications = [
      notification('n-ann', 'announcement', ids: {'announcement_id': annOne}),
      notification('n-leave', 'leave', ids: {'leave_id': leaveId}),
      notification(
        'n-late',
        'late_access',
        readAt: '2026-10-15T11:00:00Z',
        ids: {'late_access_id': lateId},
        occurredAt: '2026-10-14T10:00:00Z',
      ),
      notification(
        'n-cmp',
        'complaint',
        ids: {'complaint_id': complaintId},
        occurredAt: '2026-10-13T10:00:00Z',
      ),
      notification('n-staff', 'attendance_incident'),
    ];
  });

  group('ApiInboxRepository', () {
    test(
      'given announcements and notifications, then one feed is built',
      () async {
        final items = await build().fetchItems();

        expect(items.map((i) => i.title), [
          'Title of n-leave',
          'Water cut',
          'Title of n-late',
          'Title of n-cmp',
          'Old notice',
        ]);
      },
    );

    test('given an announcement, then it carries its full text', () async {
      final items = await build().fetchItems();
      final item = items.firstWhere((i) => i.title == 'Water cut');

      expect(item.id, 'ann-$annOne');
      expect(item.kind, InboxItemKind.announcement);
      expect(item.message, 'Full text of Water cut');
      expect(item.isAlert, isFalse);
      expect(item.isRead, isFalse);
      expect(item.notificationId, 'n-ann');
    });

    test(
      'given an announcement without an inbox entry, then it is read',
      () async {
        final items = await build().fetchItems();

        expect(items.last.title, 'Old notice');
        expect(items.last.isRead, isTrue);
        expect(items.last.notificationId, isNull);
      },
    );

    test(
      'given a notification about an announcement, then it is not repeated',
      () async {
        final items = await build().fetchItems();

        expect(items.where((i) => i.title == 'Title of n-ann'), isEmpty);
      },
    );

    test('given alerts, then each points at its record', () async {
      final items = await build().fetchItems();
      final byTitle = {for (final i in items) i.title: i};

      final leave = byTitle['Title of n-leave']!;
      expect(leave.tag, 'LEAVE');
      expect(leave.kind, InboxItemKind.leaveDecision);
      expect(leave.sourceRoute, '/passes/$leaveId');
      expect(leave.message, contains('leave request'));
      expect(leave.isRead, isFalse);

      final late = byTitle['Title of n-late']!;
      expect(late.tag, 'LATE ACCESS');
      expect(late.sourceRoute, '/passes/$lateId');
      expect(late.isRead, isTrue);

      final complaint = byTitle['Title of n-cmp']!;
      expect(complaint.kind, InboxItemKind.complaintUpdate);
      expect(complaint.sourceRoute, '/complaints/$complaintId');
    });

    test('given staff-only notifications, then they are left out', () async {
      final items = await build().fetchItems();

      expect(items.where((i) => i.title == 'Title of n-staff'), isEmpty);
    });

    test('given an item, then it can be found by id', () async {
      final item = await build().fetchItem('n-leave');

      expect(item.title, 'Title of n-leave');
    });

    test('given an unknown id, then not found is raised', () async {
      await expectLater(
        build().fetchItem('zzz'),
        throwsA(isA<RepositoryException>()),
      );
    });

    test(
      'given an alert, then marking it read posts its notification',
      () async {
        final repo = build();
        await repo.fetchItems();

        await repo.markAsRead('n-leave');

        final post = calls.last;
        expect(post.method, 'POST');
        expect(post.url.path, endsWith('/notifications/n-leave/read'));
        expect(post.body, isEmpty);
      },
    );

    test(
      'given an announcement, then its notification is marked read',
      () async {
        final repo = build();
        await repo.fetchItems();

        await repo.markAsRead('ann-$annOne');

        expect(calls.last.url.path, endsWith('/notifications/n-ann/read'));
      },
    );

    test('given nothing to mark, then no call is made', () async {
      final repo = build();
      await repo.fetchItems();
      final before = calls.length;

      await repo.markAsRead('ann-$annTwo');
      await repo.markAsRead('unknown');

      expect(calls.length, before);
    });

    test('given more than one page, then every page is read', () async {
      override = (request) async {
        final offset = request.url.queryParameters['offset'];
        final isAnn = request.url.path.endsWith('/announcements');
        return json({
          'items': isAnn
              ? [
                  announcement(
                    offset == '0' ? annOne : annTwo,
                    'A$offset',
                    '2026-10-15T09:00:00Z',
                  ),
                ]
              : <Object>[],
          'has_more': isAnn && offset == '0',
        });
      };

      final items = await build().fetchItems();

      expect(items.map((i) => i.title).toSet(), {'A0', 'A100'});
    });

    test(
      'given the server is down, then the error reaches the caller',
      () async {
        override = (request) async =>
            json({'error': 'service_unavailable'}, 503);

        await expectLater(
          build().fetchItems(),
          throwsA(isA<RepositoryException>()),
        );
      },
    );
  });

  group('InboxItem source', () {
    InboxItem item(String? type, String? id) => InboxItem(
      id: 'x',
      kind: InboxItemKind.alert,
      title: 't',
      message: 'm',
      createdAt: DateTime(2026),
      sourceType: type,
      sourceId: id,
    );

    test('given no source or an unknown one, then there is no route', () {
      expect(item(null, null).sourceRoute, isNull);
      expect(item('leave', null).sourceRoute, isNull);
      expect(item('mystery', 'id').sourceRoute, isNull);
    });

    test('given copyWith, then the source details are kept', () {
      final copy = item('leave', 'abc').copyWith(isRead: true);

      expect(copy.sourceRoute, '/passes/abc');
      expect(copy.isRead, isTrue);
    });
  });

  group('providers', () {
    test('given the backend settings, then the API inbox is used', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              apiBaseUrl: 'https://api.example.invalid/api/v1',
              firebaseApiKey: 'KEY',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(inboxRepositoryProvider),
        isA<ApiInboxRepository>(),
      );
    });
  });

  group('Inbox alert detail', () {
    testWidgets('given an alert, then View details opens the record', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          inboxRepositoryProvider.overrideWithValue(_AlertRepository()),
        ],
      );
      await pushTo(tester, '/inbox/alert-1');

      expect(find.text('View details'), findsOneWidget);
      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();

      expect(find.text('Pass LA-2418'), findsOneWidget);
    });

    testWidgets('given an announcement, then there is no View details', (
      tester,
    ) async {
      await pumpApp(tester);
      await pushTo(tester, '/inbox/n1');

      expect(find.text('View details'), findsNothing);
      expect(find.text('Got it'), findsOneWidget);
    });
  });
}

class _AlertRepository extends MockInboxRepository {
  _AlertRepository() : super(clock: () => fixedNow, latency: Duration.zero);

  @override
  Future<List<InboxItem>> fetchItems() async => [
    InboxItem(
      id: 'alert-1',
      kind: InboxItemKind.leaveDecision,
      title: 'Your request was approved',
      message: 'Open it',
      createdAt: fixedNow,
      tag: 'LEAVE',
      sourceType: 'leave',
      sourceId: 'LA-2418',
    ),
  ];
}
