/// Where the gate scans last recorded the student (IN, OUT or UNKNOWN).
enum PresenceStatus { inside, outside, unknown }

PresenceStatus presenceFromString(String? value) {
  switch (value?.toUpperCase()) {
    case 'IN':
      return PresenceStatus.inside;
    case 'OUT':
      return PresenceStatus.outside;
    default:
      return PresenceStatus.unknown;
  }
}

/// Student profile, combining the STUDENT, USER, BED and GUARDIAN entities
/// (SDS 2.2.7).
class Student {
  const Student({
    required this.studentId,
    required this.indexNo,
    required this.fullName,
    required this.email,
    this.phone,
    this.year,
    this.department,
    this.blockCode,
    this.blockName,
    this.roomNo,
    this.bedNo,
    this.guardianName,
    this.guardianRelation,
    this.guardianPhone,
    this.presence = PresenceStatus.inside,
    this.mustChangePassword = false,
    this.photoUrl,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'] as String,
      indexNo: json['index_no'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      year: json['year'] as int?,
      department: json['department'] as String?,
      blockCode: json['block_code'] as String?,
      blockName: json['block_name'] as String?,
      roomNo: json['room_no'] as String?,
      bedNo: json['bed_no'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianRelation: json['guardian_relation'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      presence: json['is_inside'] == false
          ? PresenceStatus.outside
          : PresenceStatus.inside,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
    );
  }

  /// Builds a student from `GET /me/student-profile`. The backend sends the
  /// faculty (shown as the department), the first guardian and the bed in the
  /// current accommodation; fields it does not send stay empty.
  factory Student.fromProfileJson(Map<String, dynamic> json) {
    final accommodation = json['accommodation'] as Map<String, dynamic>?;
    final guardians = json['guardians'] as List<dynamic>? ?? const [];
    final guardian = guardians.isEmpty
        ? null
        : guardians.first as Map<String, dynamic>;
    final presence =
        (json['presence'] as Map<String, dynamic>?)?['status'] as String?;

    String? nonEmpty(Object? value) {
      final text = value as String?;
      return text == null || text.isEmpty ? null : text;
    }

    return Student(
      studentId: json['student_id'] as String,
      indexNo: json['index_no'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: nonEmpty(json['contact_phone']),
      year: json['year'] as int?,
      department: nonEmpty(json['faculty']),
      blockName: nonEmpty(accommodation?['block_name']),
      roomNo: nonEmpty(accommodation?['room_no']),
      bedNo: nonEmpty(accommodation?['bed_no']),
      guardianName: nonEmpty(guardian?['name']),
      guardianRelation: nonEmpty(guardian?['relationship']),
      guardianPhone: nonEmpty(guardian?['contact_phone']),
      presence: presenceFromString(presence),
      photoUrl: nonEmpty(json['photo_url']),
    );
  }

  final String studentId;
  final String indexNo;
  final String fullName;
  final String email;
  final String? phone;
  final int? year;
  final String? department;
  final String? blockCode;
  final String? blockName;
  final String? roomNo;
  final String? bedNo;
  final String? guardianName;
  final String? guardianRelation;
  final String? guardianPhone;
  final PresenceStatus presence;
  final bool mustChangePassword;
  final String? photoUrl;

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.first;
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// "Block C" from a block code, otherwise the block name from the backend.
  String? get blockLabel => blockCode == null ? blockName : 'Block $blockCode';

  /// For example "Block C · Orchid · C-214 (Bed 2)".
  String get roomSummary {
    return [
      blockLabel,
      if (blockCode != null) blockName,
      if (roomNo != null) bedNo == null ? roomNo : '$roomNo ($bedNo)',
    ].whereType<String>().join(' · ');
  }

  /// For example "Year 2 · Computer Science".
  String get academicSummary {
    return [
      if (year != null) 'Year $year',
      department,
    ].whereType<String>().join(' · ');
  }

  bool get isInside => presence == PresenceStatus.inside;

  Student copyWith({
    PresenceStatus? presence,
    bool? mustChangePassword,
    String? photoUrl,
  }) {
    return Student(
      studentId: studentId,
      indexNo: indexNo,
      fullName: fullName,
      email: email,
      phone: phone,
      year: year,
      department: department,
      blockCode: blockCode,
      blockName: blockName,
      roomNo: roomNo,
      bedNo: bedNo,
      guardianName: guardianName,
      guardianRelation: guardianRelation,
      guardianPhone: guardianPhone,
      presence: presence ?? this.presence,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
