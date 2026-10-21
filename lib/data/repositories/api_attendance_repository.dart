import '../api/api_client.dart';
import '../models/attendance.dart';
import 'attendance_repository.dart';

class ApiAttendanceRepository implements AttendanceRepository {
  ApiAttendanceRepository(this._api);

  final ApiClient _api;

  @override
  Future<AttendanceSummary> fetchSummary() async {
    final body = await _api.getJson(
      '/students/me/attendance',
      query: {'limit': '100'},
    ) as Map<String, dynamic>;
    return AttendanceSummary.fromJson(body);
  }
}
