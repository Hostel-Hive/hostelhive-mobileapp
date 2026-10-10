import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../data/models/pass.dart';
import '../../../data/repositories/pass_repository.dart';

final passRepositoryProvider = Provider<PassRepository>((ref) {
  return MockPassRepository(clock: ref.watch(clockProvider));
});

enum PassTab { active, pending, history }

/// Which tab of the Passes screen a pass belongs to.
PassTab tabOf(Pass pass, DateTime now) {
  switch (pass.status) {
    case PassStatus.pending:
      return PassTab.pending;
    case PassStatus.approved:
      final end = pass.returnAt;
      return end == null || end.isAfter(now) ? PassTab.active : PassTab.history;
    case PassStatus.rejected:
    case PassStatus.completed:
    case PassStatus.cancelled:
      return PassTab.history;
  }
}

List<Pass> passesIn(List<Pass> passes, PassTab tab, DateTime now) {
  return passes.where((pass) => tabOf(pass, now) == tab).toList();
}

/// True while an approved "going home" leave is open (UC009).
bool isOutsideOnLeave(List<Pass> passes) {
  return passes.any(
    (pass) => pass.type == PassType.leave && pass.status == PassStatus.approved,
  );
}

class PassesNotifier extends AsyncNotifier<List<Pass>> {
  PassRepository get _repository => ref.read(passRepositoryProvider);

  @override
  Future<List<Pass>> build() => _repository.fetchPasses();

  Future<void> _reload() async {
    state = AsyncData(await _repository.fetchPasses());
    ref.invalidate(passQuotaProvider);
  }

  /// Throws a [RepositoryException] when the request is not valid.
  Future<Pass> requestLateAccess({
    required String title,
    required String purpose,
    required DateTime departureAt,
    required DateTime returnAt,
    required String destination,
    required String reason,
  }) async {
    final pass = await _repository.requestLateAccess(
      title: title,
      purpose: purpose,
      departureAt: departureAt,
      returnAt: returnAt,
      destination: destination,
      reason: reason,
    );
    await _reload();
    return pass;
  }

  /// Throws [AlreadyOutsideException] when the student is already out.
  Future<Pass> recordGoingHome() async {
    final pass = await _repository.recordGoingHome();
    await _reload();
    return pass;
  }

  Future<void> cancelPass(String id) async {
    await _repository.cancelPass(id);
    await _reload();
  }
}

final passesProvider = AsyncNotifierProvider<PassesNotifier, List<Pass>>(
  PassesNotifier.new,
);

final passQuotaProvider = FutureProvider<PassQuota>((ref) {
  return ref.watch(passRepositoryProvider).fetchQuota();
});

/// Looks the pass up in the loaded list so the detail updates after cancel.
final passByIdProvider = Provider.family<AsyncValue<Pass>, String>((ref, id) {
  return ref
      .watch(passesProvider)
      .whenData(
        (passes) => passes.firstWhere(
          (pass) => pass.id == id,
          orElse: () => throw StateError('Pass not found'),
        ),
      );
});
