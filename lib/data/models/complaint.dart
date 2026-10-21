enum ComplaintStatus { open, ongoing, resolved }

ComplaintStatus complaintStatusFromString(String value) {
  switch (value.toUpperCase().replaceAll('_', ' ')) {
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

/// The two categories the backend accepts, as the student sees them.
const List<String> complaintCategories = ['Maintenance', 'Disciplinary'];

/// The backend value for a category label: `maintenance` or `disciplinary`.
String complaintCategoryCode(String label) => label.trim().toLowerCase();

/// The label shown for a backend category code.
String complaintCategoryLabel(String code) {
  if (code.isEmpty) return code;
  return code[0].toUpperCase() + code.substring(1).toLowerCase();
}

/// Photos that can be attached to one complaint (UC013).
const int maxComplaintImages = 3;

/// The backend has no title, so the first line of the description is used.
String complaintTitleFrom(String description) {
  final line = description.trim().split(RegExp(r'\r?\n')).first.trim();
  return line.length <= 60 ? line : '${line.substring(0, 57).trimRight()}...';
}

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
    required this.status,
    required this.submittedAt,
    this.version = 1,
    this.imageIds = const [],
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
      status: complaintStatusFromString(json['status'] as String),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      imagePaths: (json['image_urls'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      resolutionNote: json['resolution_note'] as String?,
    );
  }

  /// Builds a complaint from the backend. Updates and photos come from
  /// separate calls, so they start empty.
  factory Complaint.fromBackendJson(Map<String, dynamic> json) {
    final description = json['description'] as String;
    return Complaint(
      id: json['complaint_id'] as String,
      category: complaintCategoryLabel(json['category'] as String),
      title: complaintTitleFrom(description),
      description: description,
      status: complaintStatusFromString(json['status'] as String),
      submittedAt: DateTime.parse(json['created_at'] as String).toLocal(),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  final String id;
  final String category;
  final String title;
  final String description;
  final ComplaintStatus status;
  final DateTime submittedAt;

  /// Changes whenever the complaint does; a note must quote the latest one.
  final int version;
  final List<String> imageIds;
  final List<String> imagePaths;
  final List<ComplaintUpdate> updates;
  final String? resolutionNote;

  /// A short reference when the id is a long UUID, such as "CMP-5A1B2C3D".
  String get displayId {
    final uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (!uuid.hasMatch(id)) return id;
    return 'CMP-${id.substring(0, 8).toUpperCase()}';
  }

  Complaint copyWith({
    int? version,
    List<String>? imageIds,
    List<ComplaintUpdate>? updates,
  }) {
    return Complaint(
      id: id,
      category: category,
      title: title,
      description: description,
      status: status,
      submittedAt: submittedAt,
      version: version ?? this.version,
      imageIds: imageIds ?? this.imageIds,
      imagePaths: imagePaths,
      updates: updates ?? this.updates,
      resolutionNote: resolutionNote,
    );
  }
}
