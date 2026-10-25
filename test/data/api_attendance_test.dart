import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/data/api/api_client.dart';
import 'package:hostelhive_mobile/data/models/attendance.dart';
import 'package:hostelhive_mobile/data/repositories/api_attendance_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Token implements TokenSource {
  @override
  Future<String?> idToken({bool forceRefresh = false}) async => 'token';
}

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  group('ApiAttendanceRepository', () {
    late List<http.Request> calls;
    late Future<http.Response> Function(http.Request request) handler;

    ApiAttendanceRepository build() {
      calls = [];
      final api = ApiClient(
        baseUrl: 'https://api.example.invalid/api/v1',
        client: MockClient((request) async {
          calls.add(request);
          return handler(request);
        }),
        tokens: _Token(),
      );
      return ApiAttendanceRepository(api);
    }

    String path(http.Request r) => r.url.path.replaceFirst('/api/v1', '');

    test(
      'given the profile and movements, then presence and records are combined',
      () async {
        handler = (request) async {
          if (path(request) == '/me/student-profile') {
            return json({
              'student_id': 's1',
              'index_no': 'SE/2021/036',
              'full_name': 'Sanuthi Perera',
              'email': 'sanuthi.p@stu.kln.ac.lk',
              'presence': {'status': 'IN'},
            });
          }
          return json({
            'items': [
              {
                'event_id': 'e2',
                'movement_id': 'm2',
                'direction': 'IN',
                'occurred_at': '2026-10-20T09:00:00Z',
              },
              {
                'event_id': 'e1',
                'movement_id': 'm1',
                'direction': 'OUT',
                'occurred_at': '2026-10-19T08:00:00Z',
              },
            ],
            'has_more': false,
            'total': 2,
            'limit': 100,
            'offset': 0,
            'timezone': 'Asia/Colombo',
            'from': null,
            'to': null,
          });
        };

        final summary = await build().fetchSummary();

        expect(summary.presence, AttendancePresence.inside);
        expect(summary.records, hasLength(2));
        expect(summary.records.first.id, 'e2');
        expect(summary.records.first.direction, AttendanceDirection.inside);
        expect(summary.records.last.direction, AttendanceDirection.outside);
        expect(
          calls.map(path),
          containsAll(['/me/student-profile', '/me/attendance/events']),
        );
      },
    );

    test('given OUT presence, then the student is outside', () async {
      handler = (request) async {
        if (path(request) == '/me/student-profile') {
          return json({
            'student_id': 's1',
            'index_no': 'SE/2021/036',
            'full_name': 'Sanuthi Perera',
            'email': 'sanuthi.p@stu.kln.ac.lk',
            'presence': {'status': 'OUT'},
          });
        }
        return json({'items': <dynamic>[], 'has_more': false});
      };

      final summary = await build().fetchSummary();

      expect(summary.presence, AttendancePresence.outside);
      expect(summary.records, isEmpty);
    });
  });
}
