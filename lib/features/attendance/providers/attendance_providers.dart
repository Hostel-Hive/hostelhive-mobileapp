import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/api/api_providers.dart';
import '../../../data/models/attendance.dart';
import '../../../data/repositories/api_attendance_repository.dart';
import '../../../data/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  if (ref.watch(appConfigProvider).useBackend) {
    return ApiAttendanceRepository(ref.watch(apiClientProvider));
  }
  return MockAttendanceRepository(latency: Duration.zero);
});

final attendanceProvider = FutureProvider.autoDispose<AttendanceSummary>(
  (ref) => ref.watch(attendanceRepositoryProvider).fetchSummary(),
);
