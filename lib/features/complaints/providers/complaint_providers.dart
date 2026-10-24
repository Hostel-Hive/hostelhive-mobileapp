import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/clock_provider.dart';
import '../../../data/api/api_providers.dart';
import '../../../data/models/complaint.dart';
import '../../../data/repositories/api_complaint_repository.dart';
import '../../../data/repositories/complaint_repository.dart';
import '../../../data/repositories/exceptions.dart';

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  if (ref.watch(appConfigProvider).useBackend) {
    return ApiComplaintRepository(ref.watch(apiClientProvider));
  }
  return MockComplaintRepository(clock: ref.watch(clockProvider));
});

class ComplaintsNotifier extends AsyncNotifier<List<Complaint>> {
  ComplaintRepository get _repository => ref.read(complaintRepositoryProvider);

  @override
  Future<List<Complaint>> build() => _repository.fetchComplaints();

  /// Throws a [RepositoryException] when the complaint is not valid, or a
  /// [PhotoUploadException] when it was saved but a photo failed.
  Future<Complaint> submit({
    required String category,
    required String description,
    List<String> imagePaths = const [],
    String? requestId,
  }) async {
    try {
      final complaint = await _repository.submitComplaint(
        category: category,
        description: description,
        imagePaths: imagePaths,
        requestId: requestId,
      );
      state = AsyncData(await _repository.fetchComplaints());
      return complaint;
    } on PhotoUploadException {
      state = AsyncData(await _repository.fetchComplaints());
      rethrow;
    }
  }

  /// Adds a note, then reloads the list and the open detail.
  Future<void> addNote({
    required String complaintId,
    required String text,
    required int expectedVersion,
    String? requestId,
  }) async {
    await _repository.addNote(
      complaintId: complaintId,
      text: text,
      expectedVersion: expectedVersion,
      requestId: requestId,
    );
    ref.invalidate(complaintDetailProvider(complaintId));
    state = AsyncData(await _repository.fetchComplaints());
  }
}

final complaintsProvider =
    AsyncNotifierProvider<ComplaintsNotifier, List<Complaint>>(
      ComplaintsNotifier.new,
    );

/// One complaint with its timeline and photos.
final complaintDetailProvider = FutureProvider.autoDispose
    .family<Complaint, String>((ref, id) {
      return ref.watch(complaintRepositoryProvider).fetchComplaint(id);
    });

/// The bytes of one private photo, fetched with the student's token.
final complaintImageProvider = FutureProvider.autoDispose
    .family<Uint8List, ({String complaintId, String imageId})>((ref, key) {
      return ref
          .watch(complaintRepositoryProvider)
          .fetchImage(complaintId: key.complaintId, imageId: key.imageId);
    });
