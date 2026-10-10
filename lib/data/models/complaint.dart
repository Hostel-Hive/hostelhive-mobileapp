enum ComplaintStatus { open, ongoing, resolved }

ComplaintStatus complaintStatusFromString(String value) {
  switch (value.toUpperCase()) {
    case 'ONGOING':
    case 'IN PROGRESS':
      return ComplaintStatus.ongoing;
    case 'RESOLVED':
    case 'COMPLETED':
      return ComplaintStatus.resolved;
    default:
      return ComplaintStatus.open;
  }
}

extension ComplaintStatusLabel on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.open:
        return 'Open';
      case ComplaintStatus.ongoing:
        return 'Ongoing';
      case ComplaintStatus.resolved:
        return 'Completed';
    }
  }
}

enum ComplaintSeverity { normal, high, critical }

ComplaintSeverity complaintSeverityFromString(String value) {
  switch (value.toUpperCase()) {
    case 'CRITICAL':
      return ComplaintSeverity.critical;
    case 'HIGH':
      return ComplaintSeverity.high;
    default:
      return ComplaintSeverity.normal;
  }
}

extension ComplaintSeverityInfo on ComplaintSeverity {
  String get label {
    switch (this) {
      case ComplaintSeverity.normal:
        return 'Normal';
      case ComplaintSeverity.high:
        return 'High';
      case ComplaintSeverity.critical:
        return 'Critical';
    }
  }

  /// Response targets from the system configuration (SLA hours).
  int get responseHours {
    switch (this) {
      case ComplaintSeverity.normal:
        return 48;
      case ComplaintSeverity.high:
        return 12;
      case ComplaintSeverity.critical:
        return 2;
    }
  }
}

const List<String> complaintCategories = [
  'Safety',
  'Facilities',
  'Food & Mess',
  'People',
  'Wi-Fi / IT',
  'Other',
];

/// Photos that can be attached to one complaint (UC013).
const int maxComplaintImages = 5;

class ComplaintUpdate {
  const ComplaintUpdate({
    required this.author,
    required this.text,
    required this.createdAt,
    this.isStudent = false,
    this.isSystem = false,
  });

  final String author;
  final String text;
  final DateTime createdAt;
  final bool isStudent;
  final bool isSystem;
}

/// COMPLAINT, COMPLAINT_UPDATE and COMPLAINT_IMAGE entities (SDS 2.2.7).
class Complaint {
  const Complaint({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.submittedAt,
    this.imagePaths = const [],
    this.updates = const [],
    this.resolutionNote,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: complaintSeverityFromString(
        json['severity'] as String? ?? 'normal',
      ),
      status: complaintStatusFromString(json['status'] as String),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      imagePaths: (json['image_urls'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      resolutionNote: json['resolution_note'] as String?,
    );
  }

  final String id;
  final String category;
  final String title;
  final String description;
  final ComplaintSeverity severity;
  final ComplaintStatus status;
  final DateTime submittedAt;
  final List<String> imagePaths;
  final List<ComplaintUpdate> updates;
  final String? resolutionNote;
}
