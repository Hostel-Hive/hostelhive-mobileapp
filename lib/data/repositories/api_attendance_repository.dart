import '../api/api_client.dart';
import '../models/attendance.dart';
import 'attendance_repository.dart';

class ApiAttendanceRepository implements AttendanceRepository {
  ApiAttendanceRepository(this._api);

  final ApiClient _api;

  @override
  Future<AttendanceSummary> fetchSummary() async {
    final profile =
        await _api.getJson('/me/student-profile') as Map<String, dynamic>;
    final events = await _api.getJson(
      '/me/attendance/events',
      query: {'limit': '100'},
    ) as Map<String, dynamic>;
    final presence =
        (profile['presence'] as Map<String, dynamic>?)?['status'] as String?;
    return AttendanceSummary.fromBackendJson(
      presenceStatus: presence ?? 'UNKNOWN',
      movements: events['items'] as List<dynamic>? ?? const [],
    );
  }
}
