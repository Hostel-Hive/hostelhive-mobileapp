import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/data/models/complaint.dart';
import 'package:hostelhive_mobile/data/models/pass.dart';
import 'package:hostelhive_mobile/data/repositories/auth_repository.dart';
import 'package:hostelhive_mobile/data/repositories/complaint_repository.dart';
import 'package:hostelhive_mobile/data/repositories/pass_repository.dart';
import 'package:hostelhive_mobile/data/repositories/session_store.dart';
import 'package:hostelhive_mobile/features/auth/providers/auth_providers.dart';
import 'package:hostelhive_mobile/features/complaints/providers/complaint_providers.dart';
import 'package:hostelhive_mobile/features/passes/providers/pass_providers.dart';

/// Returns whatever [current] holds at call time, so a test can simulate a
/// backend whose answer depends on which student is signed in.
class _PerStudentPassRepository extends MockPassRepository {
  _PerStudentPassRepository(this.current)
    : super(clock: () => DateTime(2026, 10, 20), latency: Duration.zero);

  final String? Function() current;

  @override
  Future<List<Pass>> fetchPasses() async {
    final owner = current();
    if (owner == null) return [];
    return [
      Pass(
        id: 'pass-for-$owner',
        type: PassType.lateAccess,
        status: PassStatus.pending,
        title: 'Late access',
        departureAt: DateTime(2026, 10, 20, 18),
        submittedAt: DateTime(2026, 10, 20, 9),
      ),
    ];
  }
}

class _PerStudentComplaintRepository extends MockComplaintRepository {
  _PerStudentComplaintRepository(this.current)
    : super(clock: () => DateTime(2026, 10, 20), latency: Duration.zero);

  final String? Function() current;

  @override
  Future<List<Complaint>> fetchComplaints() async {
    final owner = current();
    if (owner == null) return [];
    return [
      Complaint(
        id: 'complaint-for-$owner',
        category: 'maintenance',
        title: 'Issue for $owner',
        description: 'Reported by $owner',
        status: ComplaintStatus.open,
        submittedAt: DateTime(2026, 10, 20, 9),
      ),
    ];
  }
}

void main() {
  test('given a different student signs in, then passes and complaints do not leak from the previous session', () async {
    String? currentId;
    final store = MemorySessionStore();

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          MockAuthRepository(store: store, latency: Duration.zero),
        ),
        passRepositoryProvider.overrideWithValue(
          _PerStudentPassRepository(() => currentId),
        ),
        complaintRepositoryProvider.overrideWithValue(
          _PerStudentComplaintRepository(() => currentId),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(authControllerProvider.notifier);

    // Sanuthi signs in: her pass and complaint load.
    currentId = 'STU-0036';
    await controller.signIn('sanuthi.p@stu.kln.ac.lk', 'Hostel@123');
    final sanuthiPasses = await container.read(passesProvider.future);
    final sanuthiComplaints = await container.read(complaintsProvider.future);
    expect(sanuthiPasses.single.id, 'pass-for-STU-0036');
    expect(sanuthiComplaints.single.id, 'complaint-for-STU-0036');

    // She signs out; Nethmi signs in on the same app session.
    await controller.signOut();
    currentId = 'STU-0101';
    await controller.signIn('nethmi.s@stu.kln.ac.lk', 'Temp@1234');

    final nethmiPasses = await container.read(passesProvider.future);
    final nethmiComplaints = await container.read(complaintsProvider.future);

    expect(nethmiPasses.single.id, 'pass-for-STU-0101');
    expect(nethmiComplaints.single.id, 'complaint-for-STU-0101');
    expect(nethmiPasses, isNot(contains(sanuthiPasses.single)));
  });
}
