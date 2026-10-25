import 'dart:io';
import 'dart:typed_data';

import '../../core/utils/uuid.dart';
import '../api/api_client.dart';
import '../models/complaint.dart';
import 'complaint_repository.dart';
import 'exceptions.dart';

/// Reads a photo from the phone; replaced in tests.
typedef FileReader = Future<Uint8List> Function(String path);

Future<Uint8List> _readFromDisk(String path) => File(path).readAsBytes();

/// Complaints, notes and photos on the backend. Creating a complaint and
/// uploading each photo are separate calls, so a photo can fail after the
/// complaint was saved.
class ApiComplaintRepository implements ComplaintRepository {
  ApiComplaintRepository(this._api, {FileReader? readFile})
    : _readFile = readFile ?? _readFromDisk;

  static const _pageSize = 100;
  static const _maxPages = 10;

  final ApiClient _api;
  final FileReader _readFile;

  @override
  Future<List<Complaint>> fetchComplaints() async {
    final items = await _pages('/complaints');
    return items
        .map((item) => Complaint.fromBackendJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Complaint> fetchComplaint(String id) async {
    final body = await _api.getJson('/complaints/$id') as Map<String, dynamic>;
    final submittedBy = body['submitted_by'] as String?;
    final updates = await _pages('/complaints/$id/updates');
    final images =
        await _api.getJson('/complaints/$id/images') as Map<String, dynamic>;

    return Complaint.fromBackendJson(body).copyWith(
      updates: [
        for (final update in updates)
          _toUpdate(update as Map<String, dynamic>, submittedBy),
      ],
      imageIds: [
        for (final image in images['items'] as List<dynamic>)
          (image as Map<String, dynamic>)['image_id'] as String,
      ],
    );
  }

  @override
  Future<Complaint> submitComplaint({
    required String category,
    required String description,
    List<String> imagePaths = const [],
    String? requestId,
  }) async {
    final body = await _api.postJson(
      '/complaints',
      body: {
        'request_id': requestId ?? newUuid(),
        'category': complaintCategoryCode(category),
        'description': description.trim(),
      },
    ) as Map<String, dynamic>;
    final complaint = Complaint.fromBackendJson(body);

    var failed = 0;
    for (final path in imagePaths) {
      try {
        await _api.putBytes(
          '/complaints/${complaint.id}/images/${newUuid()}',
          bytes: await _readFile(path),
          contentType: path.toLowerCase().endsWith('.png')
              ? 'image/png'
              : 'image/jpeg',
        );
      } on Exception {
        failed++;
      }
    }
    if (failed > 0) {
      throw PhotoUploadException(complaintId: complaint.id, failed: failed);
    }
    return complaint;
  }

  @override
  Future<ComplaintUpdate> addNote({
    required String complaintId,
    required String text,
    required int expectedVersion,
    String? requestId,
  }) async {
    final body = await _api.postJson(
      '/complaints/$complaintId/notes',
      body: {
        'request_id': requestId ?? newUuid(),
        'expected_version': expectedVersion,
        'text': text.trim(),
      },
    ) as Map<String, dynamic>;
    return _toUpdate(body, body['actor_id'] as String?);
  }

  @override
  Future<Uint8List> fetchImage({
    required String complaintId,
    required String imageId,
  }) {
    return _api.getBytes('/complaints/$complaintId/images/$imageId');
  }

  Future<List<dynamic>> _pages(String path) async {
    final items = <dynamic>[];
    for (var page = 0; page < _maxPages; page++) {
      final body = await _api.getJson(
        path,
        query: {'limit': '$_pageSize', 'offset': '${page * _pageSize}'},
      ) as Map<String, dynamic>;
      final batch = body['items'] as List<dynamic>;
      items.addAll(batch);
      if (body['has_more'] != true || batch.isEmpty) break;
    }
    return items;
  }

  ComplaintUpdate _toUpdate(Map<String, dynamic> json, String? submittedBy) {
    final action = json['action'] as String;
    final isStudent = json['actor_id'] == submittedBy;
    final text = (json['text'] as String?) ?? '';
    final newStatus = complaintStatusFromString(
      (json['new_status'] as String?) ?? '',
    );

    final shown = text.isNotEmpty
        ? text
        : switch (action) {
            'created' => 'Complaint submitted.',
            'status' => 'Status changed to ${newStatus.label}.',
            'image_added' => 'A photo was added.',
            'image_removed' => 'A photo was removed.',
            _ => 'Updated.',
          };

    return ComplaintUpdate(
      author: isStudent ? 'You' : 'Hostel staff',
      text: shown,
      createdAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
      isStudent: isStudent,
      isSystem: action == 'created' || action.startsWith('image_'),
    );
  }
}
