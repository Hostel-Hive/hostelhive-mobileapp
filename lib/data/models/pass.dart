import '../../core/utils/formatters.dart';

/// [leave] is an extended leave with start and end dates, [lateAccess] one
/// early exit or late entry, and [goingHome] a same-day declaration.
enum PassType { leave, lateAccess, goingHome }

/// Which way a late-access request moves through the gate.
enum LateDirection { lateEntry, earlyExit }

extension LateDirectionInfo on LateDirection {
  /// The backend value: IN for a late entry, OUT for an early exit.
  String get code => this == LateDirection.lateEntry ? 'IN' : 'OUT';

  String get label =>
      this == LateDirection.lateEntry ? 'Late entry' : 'Early exit';
}

LateDirection lateDirectionFromCode(String? code) {
  return code?.toUpperCase() == 'OUT'
      ? LateDirection.earlyExit
      : LateDirection.lateEntry;
}

/// A timestamp the backend accepts: UTC with an explicit zone.
String toRfc3339(DateTime time) => time.toUtc().toIso8601String();

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

enum PassStatus { pending, approved, rejected, completed, cancelled }

PassStatus passStatusFromString(String value) {
  switch (value.toUpperCase()) {
    case 'APPROVED':
      return PassStatus.approved;
    case 'REJECTED':
      return PassStatus.rejected;
    case 'COMPLETED':
      return PassStatus.completed;
    case 'CANCELLED':
      return PassStatus.cancelled;
    default:
      return PassStatus.pending;
  }
}

extension PassStatusLabel on PassStatus {
  String get label {
    switch (this) {
      case PassStatus.pending:
        return 'Pending';
      case PassStatus.approved:
        return 'Approved';
      case PassStatus.rejected:
        return 'Rejected';
      case PassStatus.completed:
        return 'Completed';
      case PassStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Yearly leave allowance shown on the Passes screen.
class PassQuota {
  const PassQuota({required this.usedDays, required this.totalDays});

  final int usedDays;
  final int totalDays;

  double get fraction {
    if (totalDays <= 0) return 0;
    return (usedDays / totalDays).clamp(0.0, 1.0);
  }
}

/// A leave or late access pass. Both LEAVE and LATE_ACCESS entities
/// (SDS 2.2.7) are presented in one Passes list (UC009, UC010).
class Pass {
  const Pass({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.departureAt,
    required this.submittedAt,
    this.purpose,
    this.returnAt,
    this.destination,
    this.transportMode,
    this.guardianPhone,
    this.direction,
    this.reason,
    this.decidedBy,
    this.decidedAt,
    this.wardenComment,
  });

  factory Pass.fromJson(Map<String, dynamic> json) {
    return Pass(
      id: json['id'] as String,
      type: (json['type'] as String) == 'leave'
          ? PassType.leave
          : PassType.lateAccess,
      status: passStatusFromString(json['status'] as String),
      title: json['title'] as String? ?? 'Pass',
      purpose: json['purpose'] as String?,
      departureAt: DateTime.parse(json['departure_at'] as String),
      returnAt: json['return_at'] == null
          ? null
          : DateTime.parse(json['return_at'] as String),
      destination: json['destination'] as String?,
      transportMode: json['transport_mode'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      reason: json['reason'] as String?,
      decidedBy: json['decided_by'] as String?,
      decidedAt: json['decided_at'] == null
          ? null
          : DateTime.parse(json['decided_at'] as String),
      wardenComment: json['warden_comment'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
    );
  }

  /// Builds a pass from any backend shape: an item of `/me/passes`, or the
  /// detail of a leave or a late-access request. The backend sends no title,
  /// purpose, destination or approver name, so the title comes from the type.
  factory Pass.fromBackendJson(Map<String, dynamic> json) {
    final isLateAccess =
        json['type'] == 'late_access' || json.containsKey('late_access_id');
    final direction = lateDirectionFromCode(json['direction'] as String?);
    final id =
        (json['source_id'] ?? json['leave_id'] ?? json['late_access_id'])
            as String;

    DateTime? time(Object? value) =>
        value == null ? null : DateTime.parse(value as String).toLocal();
    String? text(Object? value) {
      final result = value as String?;
      return result == null || result.isEmpty ? null : result;
    }

    var status = passStatusFromString(json['status'] as String);
    if (status == PassStatus.approved && json['consumed_at'] != null) {
      status = PassStatus.completed;
    }

    return Pass(
      id: id,
      type: isLateAccess ? PassType.lateAccess : PassType.leave,
      status: status,
      title: isLateAccess ? direction.label : 'Leave',
      departureAt: time(json['starts_at'] ?? json['expected_at'])!,
      returnAt: time(json['ends_at']),
      direction: isLateAccess ? direction : null,
      reason: text(json['reason']),
      decidedAt: time(json['decided_at']),
      wardenComment: text(json['decision_note']),
      submittedAt: time(json['created_at'])!,
    );
  }

  final String id;
  final PassType type;
  final PassStatus status;
  final String title;
  final String? purpose;
  final DateTime departureAt;
  final DateTime? returnAt;
  final String? destination;
  final String? transportMode;
  final String? guardianPhone;
  final LateDirection? direction;
  final String? reason;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? wardenComment;
  final DateTime submittedAt;

  /// A readable reference: the id itself, or a short code such as
  /// "LV-3F2A91BC" when the backend id is a long UUID.
  String get displayId {
    if (!_uuidPattern.hasMatch(id)) return id;
    final prefix = switch (type) {
      PassType.leave => 'LV',
      PassType.lateAccess => 'LA',
      PassType.goingHome => 'GH',
    };
    return '$prefix-${id.substring(0, 8).toUpperCase()}';
  }

  /// The backend only lets a student withdraw a request that is still pending.
  bool get canCancel => status == PassStatus.pending;

  Duration? get duration => returnAt?.difference(departureAt);

  String? get durationLabel {
    final value = duration;
    return value == null ? null : formatDuration(value);
  }

  /// Pending and approved passes are the ones still in play.
  bool get isActive =>
      status == PassStatus.pending || status == PassStatus.approved;

  Pass copyWith({PassStatus? status}) {
    return Pass(
      id: id,
      type: type,
      status: status ?? this.status,
      title: title,
      purpose: purpose,
      departureAt: departureAt,
      returnAt: returnAt,
      destination: destination,
      transportMode: transportMode,
      guardianPhone: guardianPhone,
      direction: direction,
      reason: reason,
      decidedBy: decidedBy,
      decidedAt: decidedAt,
      wardenComment: wardenComment,
      submittedAt: submittedAt,
    );
  }
}
