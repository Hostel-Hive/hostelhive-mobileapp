import '../models/pass.dart';
import 'exceptions.dart';

/// Leave (UC009) and late access (UC010) passes in one feature, as in the
/// student app flow (SDS Figure 26).
abstract class PassRepository {
  Future<List<Pass>> fetchPasses();
  Future<Pass> fetchPass(String id);
  Future<PassQuota> fetchQuota();

  /// An extended leave between two dates.
  Future<Pass> requestLeave({
    required DateTime startsAt,
    required DateTime endsAt,
    required String reason,
    String? requestId,
  });

  /// One early exit or late entry at a given time.
  Future<Pass> requestLateAccess({
    required LateDirection direction,
    required DateTime expectedAt,
    required String reason,
    String? requestId,
  });

  /// Declares going home. [requestId] makes a retried call safe.
  Future<Pass> recordGoingHome({String? requestId});
  Future<void> cancelPass(String passId);
}

class MockPassRepository implements PassRepository {
  MockPassRepository({
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 300),
  }) : _clock = clock ?? DateTime.now {
    _passes.addAll(_seed());
  }

  static const int yearlyQuotaDays = 18;

  final DateTime Function() _clock;
  final Duration latency;
  final List<Pass> _passes = [];
  int _nextLateAccess = 2419;
  int _nextLeave = 3001;
  int _nextGoingHome = 1001;

  List<Pass> _seed() {
    final now = _clock();
    final departure = DateTime(now.year, now.month, now.day + 1, 9);
    return [
      Pass(
        id: 'LA-2341',
        type: PassType.lateAccess,
        status: PassStatus.completed,
        title: 'Bookshop',
        departureAt: now.subtract(const Duration(days: 40)),
        returnAt: now.subtract(const Duration(days: 40, hours: -3)),
        submittedAt: now.subtract(const Duration(days: 41)),
      ),
      Pass(
        id: 'LA-2390',
        type: PassType.lateAccess,
        status: PassStatus.completed,
        title: 'Doctor appointment',
        departureAt: now.subtract(const Duration(days: 20)),
        returnAt: now.subtract(const Duration(days: 20, hours: -4)),
        submittedAt: now.subtract(const Duration(days: 21)),
      ),
      Pass(
        id: 'LA-2418',
        type: PassType.leave,
        status: PassStatus.approved,
        title: 'Home visit',
        purpose: 'Family wedding',
        departureAt: departure,
        returnAt: departure.add(const Duration(days: 2, hours: 9)),
        destination: 'Gampaha',
        transportMode: 'Parent pickup',
        guardianPhone: '+94 77 221 0455',
        reason: "Cousin's wedding on Saturday in Gampaha.",
        decidedBy: 'Nisansala R.',
        decidedAt: now.subtract(const Duration(minutes: 22)),
        wardenComment:
            'Approved. Please sign in at Gate A before 20:00 Sunday. '
            'Safe travels!',
        submittedAt: now.subtract(const Duration(hours: 3)),
      ),
    ];
  }

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<List<Pass>> fetchPasses() async {
    await _wait();
    final sorted = [..._passes]
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<Pass> fetchPass(String id) async {
    await _wait();
    return _passes.firstWhere(
      (pass) => pass.id == id,
      orElse: () => throw const RepositoryException('Pass not found.'),
    );
  }

  @override
  Future<PassQuota> fetchQuota() async {
    await _wait();
    return const PassQuota(usedDays: 12, totalDays: yearlyQuotaDays);
  }

  @override
  Future<Pass> requestLeave({
    required DateTime startsAt,
    required DateTime endsAt,
    required String reason,
    String? requestId,
  }) async {
    await _wait();
    if (reason.trim().isEmpty) {
      throw const RepositoryException('Please enter the reason.');
    }
    if (startsAt.isBefore(_clock())) {
      throw const RepositoryException(
        'Departure date and time cannot be in the past.',
      );
    }
    if (!endsAt.isAfter(startsAt)) {
      throw const RepositoryException(
        'Return must be after the departure time.',
      );
    }
    final pass = Pass(
      id: 'LV-${_nextLeave++}',
      type: PassType.leave,
      status: PassStatus.pending,
      title: 'Leave',
      departureAt: startsAt,
      returnAt: endsAt,
      reason: reason.trim(),
      submittedAt: _clock(),
    );
    _passes.add(pass);
    return pass;
  }

  @override
  Future<Pass> requestLateAccess({
    required LateDirection direction,
    required DateTime expectedAt,
    required String reason,
    String? requestId,
  }) async {
    await _wait();
    if (reason.trim().isEmpty) {
      throw const RepositoryException('Please enter the reason.');
    }
    if (expectedAt.isBefore(_clock())) {
      throw const RepositoryException('The time cannot be in the past.');
    }
    final pass = Pass(
      id: 'LA-${_nextLateAccess++}',
      type: PassType.lateAccess,
      status: PassStatus.pending,
      title: direction.label,
      departureAt: expectedAt,
      direction: direction,
      reason: reason.trim(),
      submittedAt: _clock(),
    );
    _passes.add(pass);
    return pass;
  }

  @override
  Future<Pass> recordGoingHome({String? requestId}) async {
    await _wait();
    final alreadyOut = _passes.any(
      (pass) =>
          pass.type == PassType.goingHome && pass.status == PassStatus.approved,
    );
    if (alreadyOut) throw const AlreadyOutsideException();

    final now = _clock();
    final pass = Pass(
      id: 'GH-${_nextGoingHome++}',
      type: PassType.goingHome,
      status: PassStatus.approved,
      title: 'Going home',
      departureAt: now,
      submittedAt: now,
    );
    _passes.add(pass);
    return pass;
  }

  @override
  Future<void> cancelPass(String passId) async {
    await _wait();
    final index = _passes.indexWhere((pass) => pass.id == passId);
    if (index == -1) throw const RepositoryException('Pass not found.');
    if (!_passes[index].canCancel) {
      throw const RepositoryException('This pass can no longer be cancelled.');
    }
    _passes[index] = _passes[index].copyWith(status: PassStatus.cancelled);
  }
}
