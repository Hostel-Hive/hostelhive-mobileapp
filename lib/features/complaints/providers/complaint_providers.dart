import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../data/models/complaint.dart';
import '../../../data/repositories/complaint_repository.dart';

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  return MockComplaintRepository(clock: ref.watch(clockProvider));
});

class ComplaintsNotifier extends AsyncNotifier<List<Complaint>> {
  ComplaintRepository get _repository => ref.read(complaintRepositoryProvider);

  @override
  Future<List<Complaint>> build() => _repository.fetchComplaints();

  /// Throws a [RepositoryException] when the complaint is not valid.
  Future<Complaint> submit({
    required String category,
    required String title,
    required String description,
    required ComplaintSeverity severity,
    List<String> imagePaths = const [],
  }) async {
    final complaint = await _repository.submitComplaint(
      category: category,
      title: title,
      description: description,
      severity: severity,
      imagePaths: imagePaths,
    );
    state = AsyncData(await _repository.fetchComplaints());
    return complaint;
  }
}

final complaintsProvider =
    AsyncNotifierProvider<ComplaintsNotifier, List<Complaint>>(
      ComplaintsNotifier.new,
    );

final complaintByIdProvider = Provider.family<AsyncValue<Complaint>, String>((
  ref,
  id,
) {
  return ref
      .watch(complaintsProvider)
      .whenData(
        (all) => all.firstWhere(
          (complaint) => complaint.id == id,
          orElse: () => throw StateError('Complaint not found'),
        ),
      );
});
