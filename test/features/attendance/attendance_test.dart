import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/data/models/attendance.dart';
import 'package:hostelhive_mobile/data/repositories/attendance_repository.dart';
import 'package:hostelhive_mobile/features/attendance/providers/attendance_providers.dart';
import 'package:hostelhive_mobile/features/attendance/screens/attendance_screen.dart';

import '../../helpers/harness.dart';

// ---------------------------------------------------------------------------
// Unit tests — AttendanceSummary.fromJson
// ---------------------------------------------------------------------------

void main() {
  group('AttendanceSummary.fromJson', () {
    test('parses IN presence and records', () {
      final json = {
        'presence': 'IN',
        'records': [
          {
            'id': '1',
            'timestamp': '2026-04-18T08:00:00Z',
            'direction': 'IN',
            'flaggedUnapprovedLate': false,
          },
          {'id': '2', 'timestamp': '2026-04-17T22:00:00Z', 'direction': 'OUT'},
        ],
      };
      final summary = AttendanceSummary.fromJson(json);
      expect(summary.presence, AttendancePresence.inside);
      expect(summary.records.length, 2);
      // Newest first
      expect(summary.records.first.direction, AttendanceDirection.inside);
      expect(summary.records.last.direction, AttendanceDirection.outside);
    });

    test('parses ON_LEAVE presence', () {
      final summary = AttendanceSummary.fromJson({
        'presence': 'ON_LEAVE',
        'records': <dynamic>[],
      });
      expect(summary.presence, AttendancePresence.onLeave);
      expect(summary.records, isEmpty);
      expect(summary.lastScan, isNull);
    });

    test('parses OUT presence and flags unapproved late', () {
      final summary = AttendanceSummary.fromJson({
        'presence': 'OUT',
        'records': [
          {
            'id': 'x',
            'timestamp': '2026-04-18T02:30:00Z',
            'direction': 'IN',
            'flaggedUnapprovedLate': true,
          },
        ],
      });
      expect(summary.presence, AttendancePresence.outside);
      expect(summary.records.first.flaggedUnapprovedLate, isTrue);
    });

    test('records are sorted newest first', () {
      final summary = AttendanceSummary.fromJson({
        'presence': 'IN',
        'records': [
          {'id': 'old', 'timestamp': '2026-04-16T08:00:00Z', 'direction': 'IN'},
          {
            'id': 'new',
            'timestamp': '2026-04-18T08:00:00Z',
            'direction': 'OUT',
          },
        ],
      });
      expect(summary.records.first.id, 'new');
    });
  });

  // -------------------------------------------------------------------------
  // Widget tests — AttendanceScreen
  // -------------------------------------------------------------------------

  group('AttendanceScreen', () {
    testWidgets('shows records when data loads', (tester) async {
      await pumpApp(tester);
      await pushTo(tester, AppRoutes.attendance);

      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Current status'), findsOneWidget);
      // Mock repo seeds at least one IN record
      expect(find.text('Entered hostel'), findsWidgets);
      expect(find.text('Left hostel'), findsWidgets);
    });

    testWidgets('shows empty state when no records', (tester) async {
      await pumpApp(
        tester,
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(
            _EmptyAttendanceRepository(),
          ),
        ],
      );
      await pushTo(tester, AppRoutes.attendance);

      expect(find.text('No scans yet'), findsOneWidget);
    });

    testWidgets('shows error and retry on failure', (tester) async {
      await pumpApp(
        tester,
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(
            _BrokenAttendanceRepository(),
          ),
        ],
      );
      await pushTo(tester, AppRoutes.attendance);

      expect(find.text('Could not load attendance.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('home status card has View history link', (tester) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.home);

      expect(find.text('View history'), findsOneWidget);
    });

    testWidgets('tapping View history navigates to attendance screen', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, AppRoutes.home);
      await tester.tap(find.text('View history'));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('late entry flag is shown', (tester) async {
      await pumpApp(tester);
      await pushTo(tester, AppRoutes.attendance);

      // Mock repo seeds a flaggedUnapprovedLate = true record
      expect(find.text('Late entry'), findsOneWidget);
    });
  });
}

class _EmptyAttendanceRepository implements AttendanceRepository {
  @override
  Future<AttendanceSummary> fetchSummary() async =>
      const AttendanceSummary(presence: AttendancePresence.inside, records: []);
}

class _BrokenAttendanceRepository implements AttendanceRepository {
  @override
  Future<AttendanceSummary> fetchSummary() async =>
      throw Exception('network error');
}
