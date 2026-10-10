/// Outcome of a gate scan, as shown to the student (UC005).
class ScanResult {
  const ScanResult.success({
    required this.title,
    required this.subtitle,
    required this.studentName,
    required this.studentDetails,
  }) : isSuccess = true,
       errorCode = null;

  const ScanResult.failure({
    required this.title,
    required this.subtitle,
    this.errorCode,
  }) : isSuccess = false,
       studentName = null,
       studentDetails = null;

  final bool isSuccess;
  final String title;
  final String subtitle;
  final String? studentName;
  final String? studentDetails;
  final String? errorCode;
}
