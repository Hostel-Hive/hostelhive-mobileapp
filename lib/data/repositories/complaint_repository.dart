import 'dart:typed_data';

import '../models/complaint.dart';
import 'exceptions.dart';

/// Submit Complaint (UC012) and Attach Images (UC013).
abstract class ComplaintRepository {
  Future<List<Complaint>> fetchComplaints();
  Future<Complaint> fetchComplaint(String id);

  /// Creates the complaint, then attaches the photos one by one. Throws a
  /// [PhotoUploadException] when it was saved but a photo failed.
  Future<Complaint> submitComplaint({
    required String category,
    required String description,
    List<String> imagePaths = const [],
    String? requestId,
  });

  /// Adds a student note to an open complaint; [expectedVersion] must be the
  /// latest version the student has seen.
  Future<ComplaintUpdate> addNote({
    required String complaintId,
    required String text,
    required int expectedVersion,
    String? requestId,
  });

  /// The bytes of one attached photo.
  Future<Uint8List> fetchImage({
    required String complaintId,
    required String imageId,
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
        category: 'Maintenance',
        title: 'Emergency exit blocked',
        description:
            'Laundry rack placed at the rear stairwell near rooms C-301 to '
            'C-308 is blocking the fire exit. There is barely 30 cm of '
            'clearance.',
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
            text: 'Routed to the Maintenance team.',
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
    required String description,
    List<String> imagePaths = const [],
    String? requestId,
  }) async {
    await _wait();
    if (category.trim().isEmpty || description.trim().isEmpty) {
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
      title: complaintTitleFrom(description),
      description: description.trim(),
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
          text: 'Routed to the $category team.',
          createdAt: now,
          isSystem: true,
        ),
      ],
    );
    _complaints.add(complaint);
    return complaint;
  }

  @override
  Future<ComplaintUpdate> addNote({
    required String complaintId,
    required String text,
    required int expectedVersion,
    String? requestId,
  }) async {
    await _wait();
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index == -1) {
      throw const RepositoryException('Complaint not found.');
    }
    final complaint = _complaints[index];
    if (text.trim().isEmpty) {
      throw const RepositoryException('Please write a note first.');
    }
    if (complaint.status == ComplaintStatus.resolved) {
      throw const RepositoryException('This complaint is already resolved.');
    }
    if (expectedVersion != complaint.version) {
      throw const RepositoryException(
        'The complaint changed. Refresh and try again.',
      );
    }
    final update = ComplaintUpdate(
      author: 'You',
      text: text.trim(),
      createdAt: _clock(),
      isStudent: true,
    );
    _complaints[index] = complaint.copyWith(
      version: complaint.version + 1,
      updates: [...complaint.updates, update],
    );
    return update;
  }

  @override
  Future<Uint8List> fetchImage({
    required String complaintId,
    required String imageId,
  }) {
    throw const RepositoryException('Photos are not available offline.');
  }
}
