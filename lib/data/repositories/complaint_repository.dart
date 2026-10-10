import '../models/complaint.dart';
import 'exceptions.dart';

/// Submit Complaint (UC012) and Attach Images (UC013).
abstract class ComplaintRepository {
  Future<List<Complaint>> fetchComplaints();
  Future<Complaint> fetchComplaint(String id);
  Future<Complaint> submitComplaint({
    required String category,
    required String title,
    required String description,
    required ComplaintSeverity severity,
    List<String> imagePaths = const [],
  });
}

class MockComplaintRepository implements ComplaintRepository {
  MockComplaintRepository({
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 400),
  }) : _clock = clock ?? DateTime.now {
    final now = _clock();
    _complaints.add(
      Complaint(
        id: 'CMP-0142',
        category: 'Safety',
        title: 'Emergency exit blocked',
        description:
            'Laundry rack placed at the rear stairwell near rooms C-301 to '
            'C-308 is blocking the fire exit. There is barely 30 cm of '
            'clearance.',
        severity: ComplaintSeverity.critical,
        status: ComplaintStatus.ongoing,
        submittedAt: now.subtract(const Duration(hours: 4)),
        updates: [
          ComplaintUpdate(
            author: 'You',
            text: 'Original report with 4 photos.',
            createdAt: now.subtract(const Duration(hours: 4)),
            isStudent: true,
          ),
          ComplaintUpdate(
            author: 'System',
            text: 'Routed to Safety category · SLA 2 hours.',
            createdAt: now.subtract(const Duration(hours: 4)),
            isSystem: true,
          ),
        ],
      ),
    );
  }

  final DateTime Function() _clock;
  final Duration latency;
  final List<Complaint> _complaints = [];
  int _nextId = 143;

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<List<Complaint>> fetchComplaints() async {
    await _wait();
    final sorted = [..._complaints]
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Complaint> fetchComplaint(String id) async {
    await _wait();
    return _complaints.firstWhere(
      (complaint) => complaint.id == id,
      orElse: () => throw const RepositoryException('Complaint not found.'),
    );
  }

  @override
  Future<Complaint> submitComplaint({
    required String category,
    required String title,
    required String description,
    required ComplaintSeverity severity,
    List<String> imagePaths = const [],
  }) async {
    await _wait();
    if (category.trim().isEmpty ||
        title.trim().isEmpty ||
        description.trim().isEmpty) {
      throw const RepositoryException(
        'Please choose a category and describe the issue.',
      );
    }
    if (imagePaths.length > maxComplaintImages) {
      throw const RepositoryException(
        'You can attach up to $maxComplaintImages photos.',
      );
    }
    final now = _clock();
    final number = _nextId++;
    final complaint = Complaint(
      id: 'CMP-${number.toString().padLeft(4, '0')}',
      category: category,
      title: title.trim(),
      description: description.trim(),
      severity: severity,
      status: ComplaintStatus.open,
      submittedAt: now,
      imagePaths: List.unmodifiable(imagePaths),
      updates: [
        ComplaintUpdate(
          author: 'You',
          text: imagePaths.isEmpty
              ? 'Original report.'
              : 'Original report with ${imagePaths.length} photos.',
          createdAt: now,
          isStudent: true,
        ),
        ComplaintUpdate(
          author: 'System',
          text:
              'Routed to $category category · SLA '
              '${severity.responseHours} hours.',
          createdAt: now,
          isSystem: true,
        ),
      ],
    );
    _complaints.add(complaint);
    return complaint;
  }
}
