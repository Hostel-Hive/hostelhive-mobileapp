import '../models/attendance.dart';

abstract class AttendanceRepository {
  Future<AttendanceSummary> fetchSummary();
}

class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;

  @override
  Future<AttendanceSummary> fetchSummary() async {
    await Future<void>.delayed(latency);
    final now = DateTime.now();
    return AttendanceSummary(
      presence: AttendancePresence.inside,
      records: [
        AttendanceRecord(
          id: 'a1',
          timestamp: now.subtract(const Duration(hours: 3)),
          direction: AttendanceDirection.inside,
        ),
        AttendanceRecord(
          id: 'a2',
          timestamp: now.subtract(const Duration(hours: 8)),
          direction: AttendanceDirection.outside,
        ),
        AttendanceRecord(
          id: 'a3',
          timestamp: now.subtract(const Duration(days: 1, hours: 2)),
          direction: AttendanceDirection.inside,
          flaggedUnapprovedLate: true,
        ),
        AttendanceRecord(
          id: 'a4',
          timestamp: now.subtract(const Duration(days: 1, hours: 9)),
          direction: AttendanceDirection.outside,
        ),
        AttendanceRecord(
          id: 'a5',
          timestamp: now.subtract(const Duration(days: 2, hours: 4)),
          direction: AttendanceDirection.inside,
        ),
        AttendanceRecord(
          id: 'a6',
          timestamp: now.subtract(const Duration(days: 2, hours: 11)),
          direction: AttendanceDirection.outside,
        ),
      ],
    );
  }
}
