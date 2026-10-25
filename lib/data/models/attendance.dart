/// Direction the student passed through the hostel gate.
enum AttendanceDirection { inside, outside }

/// A single gate-scan record.
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.timestamp,
    required this.direction,
    this.flaggedUnapprovedLate = false,
  });

  final String id;
  final DateTime timestamp;
  final AttendanceDirection direction;

  /// True when the scan was an unapproved late entry (UC008).
  final bool flaggedUnapprovedLate;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'].toString(),
        timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
        direction: (json['direction'] as String).toUpperCase() == 'IN'
            ? AttendanceDirection.inside
            : AttendanceDirection.outside,
        flaggedUnapprovedLate: json['flaggedUnapprovedLate'] as bool? ?? false,
      );

  /// Builds a record from `GET /me/attendance/events`, which has no
  /// unapproved-late flag.
  factory AttendanceRecord.fromMovementJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['event_id'] as String,
        timestamp: DateTime.parse(json['occurred_at'] as String).toLocal(),
        direction: (json['direction'] as String).toUpperCase() == 'IN'
            ? AttendanceDirection.inside
            : AttendanceDirection.outside,
      );
}

/// Current presence + the student's recent gate-scan records (FR012-013).
class AttendanceSummary {
  const AttendanceSummary({required this.presence, required this.records});

  final AttendancePresence presence;

  /// Newest first.
  final List<AttendanceRecord> records;

  AttendanceRecord? get lastScan => records.isEmpty ? null : records.first;

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    final presence = switch ((json['presence'] as String).toUpperCase()) {
      'IN' => AttendancePresence.inside,
      'ON_LEAVE' => AttendancePresence.onLeave,
      _ => AttendancePresence.outside,
    };
    final raw =
        (json['records'] as List<dynamic>? ?? [])
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return AttendanceSummary(presence: presence, records: raw);
  }

  /// Combines `GET /me/student-profile`'s presence (IN/OUT/UNKNOWN) with
  /// `GET /me/attendance/events`'s movements; the backend has no "on leave"
  /// presence value.
  factory AttendanceSummary.fromBackendJson({
    required String presenceStatus,
    required List<dynamic> movements,
  }) {
    final presence = presenceStatus.toUpperCase() == 'IN'
        ? AttendancePresence.inside
        : AttendancePresence.outside;
    final records =
        movements
            .map(
              (e) =>
                  AttendanceRecord.fromMovementJson(e as Map<String, dynamic>),
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return AttendanceSummary(presence: presence, records: records);
  }
}

/// Where the backend last recorded the student (FR013).
enum AttendancePresence { inside, outside, onLeave }
