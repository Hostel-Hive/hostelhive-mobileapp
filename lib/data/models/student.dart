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
    this.isInside = true,
    this.mustChangePassword = false,
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
      isInside: json['is_inside'] as bool? ?? true,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
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
  final bool isInside;
  final bool mustChangePassword;

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

  String? get blockLabel => blockCode == null ? null : 'Block $blockCode';

  /// For example "Block C · Orchid · C-214 (Bed 2)".
  String get roomSummary {
    return [
      blockLabel,
      blockName,
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

  Student copyWith({bool? isInside, bool? mustChangePassword}) {
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
      isInside: isInside ?? this.isInside,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}
