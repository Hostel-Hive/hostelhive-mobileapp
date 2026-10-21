import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/config/app_config.dart';
import 'package:hostelhive_mobile/core/utils/uuid.dart';
import 'package:hostelhive_mobile/data/api/api_client.dart';
import 'package:hostelhive_mobile/data/api/api_exception.dart';
import 'package:hostelhive_mobile/data/models/pass.dart';
import 'package:hostelhive_mobile/data/repositories/api_pass_repository.dart';
import 'package:hostelhive_mobile/data/repositories/pass_repository.dart';
import 'package:hostelhive_mobile/features/passes/providers/pass_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Token implements TokenSource {
  @override
  Future<String?> idToken({bool forceRefresh = false}) async => 'token';
}

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

const leaveId = '3f2a91bc-0000-4000-8000-000000000001';
const lateId = '9d8c7b6a-0000-4000-8000-000000000002';

Map<String, dynamic> leaveJson({
  String status = 'pending',
  String? note,
  String? decidedAt,
}) => {
  'leave_id': leaveId,
  'request_id': 'r1',
  'student_id': 's1',
  'starts_at': '2026-10-20T03:30:00Z',
  'ends_at': '2026-10-22T12:30:00Z',
  'reason': 'Family wedding',
  'status': status,
  'created_at': '2026-10-15T10:00:00Z',
  'decided_at': decidedAt,
  'decision_note': note ?? '',
};

Map<String, dynamic> lateJson({
  String status = 'approved',
  String? consumedAt,
  String direction = 'IN',
}) => {
  'late_access_id': lateId,
  'request_id': 'r2',
  'student_id': 's1',
  'direction': direction,
  'expected_at': '2026-10-20T16:00:00Z',
  'reason': 'Bus delay',
  'status': status,
  'created_at': '2026-10-15T11:00:00Z',
  'consumed_at': consumedAt,
  'decision_note': '',
};

void main() {
  group('Pass.fromBackendJson', () {
    test('given a leave, then dates, reason and title are mapped', () {
      final pass = Pass.fromBackendJson(
        leaveJson(
          status: 'approved',
          note: 'Safe travels',
          decidedAt: '2026-10-16T08:00:00Z',
        ),
      );

      expect(pass.id, leaveId);
      expect(pass.type, PassType.leave);
      expect(pass.status, PassStatus.approved);
      expect(pass.title, 'Leave');
      expect(pass.reason, 'Family wedding');
      expect(pass.wardenComment, 'Safe travels');
      expect(pass.decidedAt, isNotNull);
      expect(pass.returnAt!.isAfter(pass.departureAt), isTrue);
      expect(pass.durationLabel, isNotNull);
      expect(pass.decidedBy, isNull);
      expect(pass.direction, isNull);
    });

    test('given a pending leave, then an empty note is not a comment', () {
      final pass = Pass.fromBackendJson(leaveJson());

      expect(pass.wardenComment, isNull);
      expect(pass.canCancel, isTrue);
    });

    test('given late access, then the direction names the title', () {
      final entry = Pass.fromBackendJson(lateJson());
      final exit = Pass.fromBackendJson(lateJson(direction: 'OUT'));

      expect(entry.type, PassType.lateAccess);
      expect(entry.title, 'Late entry');
      expect(entry.direction, LateDirection.lateEntry);
      expect(entry.returnAt, isNull);
      expect(exit.title, 'Early exit');
      expect(exit.direction, LateDirection.earlyExit);
      expect(entry.canCancel, isFalse);
    });

    test('given an approved pass already used, then it is completed', () {
      final pass = Pass.fromBackendJson(
        lateJson(consumedAt: '2026-10-20T16:05:00Z'),
      );

      expect(pass.status, PassStatus.completed);
    });

    test(
      'given a combined list item, then the source id and type are used',
      () {
        final pass = Pass.fromBackendJson({
          ...lateJson(),
          'type': 'late_access',
          'source_id': lateId,
        });

        expect(pass.id, lateId);
        expect(pass.type, PassType.lateAccess);
      },
    );

    test('given a UUID, then a short reference is shown', () {
      expect(Pass.fromBackendJson(leaveJson()).displayId, 'LV-3F2A91BC');
      expect(Pass.fromBackendJson(lateJson()).displayId, 'LA-9D8C7B6A');
      expect(
        Pass(
          id: leaveId,
          type: PassType.goingHome,
          status: PassStatus.approved,
          title: 'Going home',
          departureAt: DateTime(2026),
          submittedAt: DateTime(2026),
        ).displayId,
        'GH-3F2A91BC',
      );
    });

    test('given a readable id, then it is shown as it is', () {
      final pass = Pass(
        id: 'LA-2418',
        type: PassType.lateAccess,
        status: PassStatus.approved,
        title: 'x',
        departureAt: DateTime(2026),
        submittedAt: DateTime(2026),
      );

      expect(pass.displayId, 'LA-2418');
    });
  });

  group('helpers', () {
    test('given two UUIDs, then they are valid v4 and different', () {
      final a = newUuid();
      final b = newUuid();

      expect(
        a,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(a, isNot(b));
    });

    test('given a local time, then it is sent in UTC with a Z', () {
      expect(toRfc3339(DateTime.utc(2026, 10, 20, 3, 30)), endsWith('Z'));
      expect(toRfc3339(DateTime(2026, 10, 20, 9)), endsWith('Z'));
    });

    test('given direction codes, then they map both ways', () {
      expect(LateDirection.lateEntry.code, 'IN');
      expect(LateDirection.earlyExit.code, 'OUT');
      expect(lateDirectionFromCode('out'), LateDirection.earlyExit);
      expect(lateDirectionFromCode('IN'), LateDirection.lateEntry);
      expect(lateDirectionFromCode(null), LateDirection.lateEntry);
    });
  });

  group('ApiPassRepository', () {
    late List<http.Request> calls;
    late Future<http.Response> Function(http.Request request) handler;

    ApiPassRepository build() {
      calls = [];
      final api = ApiClient(
        baseUrl: 'https://api.example.invalid/api/v1',
        client: MockClient((request) async {
          calls.add(request);
          return handler(request);
        }),
        tokens: _Token(),
      );
      return ApiPassRepository(api);
    }

    String path(http.Request r) => r.url.path.replaceFirst('/api/v1', '');

    test('given two pages, then every pass is collected', () async {
      handler = (request) async {
        final offset = request.url.queryParameters['offset'];
        return json({
          'items': [
            if (offset == '0')
              {...leaveJson(), 'type': 'leave', 'source_id': leaveId}
            else
              {...lateJson(), 'type': 'late_access', 'source_id': lateId},
          ],
          'has_more': offset == '0',
          'total': 2,
          'limit': 100,
          'offset': int.parse(offset!),
        });
      };

      final passes = await build().fetchPasses();

      expect(passes.map((p) => p.type), [PassType.leave, PassType.lateAccess]);
      expect(calls, hasLength(2));
      expect(calls.first.url.queryParameters['limit'], '100');
    });

    test('given an empty page that claims more, then it stops', () async {
      handler = (request) async =>
          json({'items': <Object>[], 'has_more': true, 'total': 0});

      expect(await build().fetchPasses(), isEmpty);
      expect(calls, hasLength(1));
    });

    test('given a leave id, then the leave is fetched', () async {
      handler = (request) async => json(leaveJson());

      final pass = await build().fetchPass(leaveId);

      expect(pass.type, PassType.leave);
      expect(path(calls.single), '/leaves/$leaveId');
    });

    test('given a late access id, then it falls back to late access', () async {
      handler = (request) async => path(request).startsWith('/leaves')
          ? json({'error': 'not_found'}, 404)
          : json(lateJson());

      final pass = await build().fetchPass(lateId);

      expect(pass.type, PassType.lateAccess);
      expect(calls.map(path), [
        '/leaves/$lateId',
        '/late-access-requests/$lateId',
      ]);
    });

    test('given an unknown id, then not found is raised', () async {
      handler = (request) async => json({'error': 'not_found'}, 404);

      await expectLater(
        build().fetchPass('x'),
        throwsA(isA<ApiException>().having((e) => e.isNotFound, '404', true)),
      );
    });

    test('given another error, then the fallback is not tried', () async {
      handler = (request) async => json({'error': 'forbidden'}, 403);

      await expectLater(build().fetchPass('x'), throwsA(isA<ApiException>()));
      expect(calls, hasLength(1));
    });

    test(
      'given the allowance, then used and total days are returned',
      () async {
        handler = (request) async => json({
          'used_days': 12,
          'total_days': 18,
          'remaining_days': 6,
          'exceeded_days': 0,
          'year': 2026,
        });

        final quota = await build().fetchQuota();

        expect(quota.usedDays, 12);
        expect(quota.totalDays, 18);
        expect(path(calls.single), '/me/leave-allowance');
      },
    );

    test(
      'given a leave request, then the body has UTC times and the id',
      () async {
        handler = (request) async => json(leaveJson(), 201);

        final pass = await build().requestLeave(
          startsAt: DateTime.utc(2026, 10, 20, 3, 30),
          endsAt: DateTime.utc(2026, 10, 22, 12, 30),
          reason: '  Family wedding ',
          requestId: 'fixed-id',
        );

        final body = jsonDecode(calls.single.body) as Map<String, dynamic>;
        expect(path(calls.single), '/leaves');
        expect(body['request_id'], 'fixed-id');
        expect(body['starts_at'], '2026-10-20T03:30:00.000Z');
        expect(body['reason'], 'Family wedding');
        expect(pass.type, PassType.leave);
      },
    );

    test('given no request id, then one is generated', () async {
      handler = (request) async => json(leaveJson(), 201);

      await build().requestLeave(
        startsAt: DateTime.utc(2026, 10, 20),
        endsAt: DateTime.utc(2026, 10, 21),
        reason: 'r',
      );

      expect(jsonDecode(calls.single.body)['request_id'], isNotEmpty);
    });

    test('given a late access request, then the direction is sent', () async {
      handler = (request) async => json(lateJson(status: 'pending'), 201);

      final pass = await build().requestLateAccess(
        direction: LateDirection.earlyExit,
        expectedAt: DateTime.utc(2026, 10, 20, 16),
        reason: 'Bus',
        requestId: 'id-2',
      );

      final body = jsonDecode(calls.single.body) as Map<String, dynamic>;
      expect(path(calls.single), '/late-access-requests');
      expect(body['direction'], 'OUT');
      expect(body['request_id'], 'id-2');
      expect(pass.type, PassType.lateAccess);
    });

    test('given going home, then a declaration pass is returned', () async {
      handler = (request) async => json({
        'going_home_id': leaveId,
        'declared_at': '2026-10-15T14:00:00Z',
        'status': 'declared',
        'request_id': 'g1',
        'student_id': 's1',
        'submitted_by': 'u1',
      }, 201);

      final pass = await build().recordGoingHome(requestId: 'g1');

      expect(path(calls.single), '/going-home');
      expect(jsonDecode(calls.single.body), {'request_id': 'g1'});
      expect(pass.type, PassType.goingHome);
      expect(pass.title, 'Going home');
    });

    test(
      'given the student is already out, then the message explains',
      () async {
        handler = (request) async => json({'error': 'already_outside'}, 409);

        await expectLater(
          build().recordGoingHome(),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'You are already recorded as outside the hostel.',
            ),
          ),
        );
      },
    );

    test('given a leave, then cancelling posts without a body', () async {
      handler = (request) async => json(leaveJson(status: 'cancelled'));

      await build().cancelPass(leaveId);

      expect(path(calls.single), '/leaves/$leaveId/cancel');
      expect(calls.single.method, 'POST');
      expect(calls.single.body, isEmpty);
    });

    test('given late access, then cancelling falls back to it', () async {
      handler = (request) async => path(request).startsWith('/leaves')
          ? json({'error': 'not_found'}, 404)
          : json(lateJson(status: 'cancelled'));

      await build().cancelPass(lateId);

      expect(calls.map(path), [
        '/leaves/$lateId/cancel',
        '/late-access-requests/$lateId/cancel',
      ]);
    });
  });

  group('providers', () {
    test(
      'given the backend settings, then the API pass repository is used',
      () {
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
          container.read(passRepositoryProvider),
          isA<ApiPassRepository>(),
        );
      },
    );

    test('given no settings, then the demo repository is used', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(passRepositoryProvider), isA<MockPassRepository>());
    });
  });
}
