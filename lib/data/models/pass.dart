import '../../core/utils/formatters.dart';

enum PassType { leave, lateAccess }

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
  final String? reason;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? wardenComment;
  final DateTime submittedAt;

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
      reason: reason,
      decidedBy: decidedBy,
      decidedAt: decidedAt,
      wardenComment: wardenComment,
      submittedAt: submittedAt,
    );
  }
}
