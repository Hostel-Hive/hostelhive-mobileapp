import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/data/models/pass.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/data/repositories/pass_repository.dart';
import 'package:hostelhive_mobile/features/passes/providers/pass_providers.dart';

import '../../helpers/harness.dart';

Pass makePass({
  required PassStatus status,
  PassType type = PassType.lateAccess,
  DateTime? returnAt,
}) {
  return Pass(
    id: 'X-1',
    type: type,
    status: status,
    title: 'Trip',
    departureAt: fixedNow,
    returnAt: returnAt,
    submittedAt: fixedNow,
  );
}

ProviderContainer makeContainer() {
  final container = ProviderContainer(
    overrides: [
      passRepositoryProvider.overrideWithValue(
        MockPassRepository(clock: () => fixedNow, latency: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('tabOf', () {
    final future = fixedNow.add(const Duration(days: 1));
    final past = fixedNow.subtract(const Duration(days: 1));

    test('given a pending pass, then it is in the pending tab', () {
      expect(
        tabOf(makePass(status: PassStatus.pending), fixedNow),
        PassTab.pending,
      );
    });

    test('given an approved pass that has not ended, then it is active', () {
      expect(
        tabOf(
          makePass(status: PassStatus.approved, returnAt: future),
          fixedNow,
        ),
        PassTab.active,
      );
      expect(
        tabOf(makePass(status: PassStatus.approved), fixedNow),
        PassTab.active,
      );
    });

    test('given an approved pass that has ended, then it is history', () {
      expect(
        tabOf(makePass(status: PassStatus.approved, returnAt: past), fixedNow),
        PassTab.history,
      );
    });

    test('given a finished pass, then it is history', () {
      for (final status in [
        PassStatus.completed,
        PassStatus.rejected,
        PassStatus.cancelled,
      ]) {
        expect(tabOf(makePass(status: status), fixedNow), PassTab.history);
      }
    });

    test('passesIn keeps only the passes for the tab', () {
      final passes = [
        makePass(status: PassStatus.pending),
        makePass(status: PassStatus.completed),
      ];

      expect(passesIn(passes, PassTab.pending, fixedNow).length, 1);
      expect(passesIn(passes, PassTab.active, fixedNow), isEmpty);
    });
  });

  group('isOutsideOnLeave', () {
    test('given an approved going-home leave, then the student is outside', () {
      expect(
        isOutsideOnLeave([
          makePass(status: PassStatus.approved, type: PassType.leave),
        ]),
        isTrue,
      );
    });

    test(
      'given no leave, a cancelled leave or only late access, then not outside',
      () {
        expect(isOutsideOnLeave([]), isFalse);
        expect(
          isOutsideOnLeave([
            makePass(status: PassStatus.cancelled, type: PassType.leave),
          ]),
          isFalse,
        );
        expect(
          isOutsideOnLeave([makePass(status: PassStatus.approved)]),
          isFalse,
        );
      },
    );
  });

  group('PassesNotifier', () {
    test('given the repository, then passes load newest first', () async {
      final container = makeContainer();

      final passes = await container.read(passesProvider.future);

      expect(passes.first.id, 'LA-2418');
    });

    test('given a valid request, then the list and quota refresh', () async {
      final container = makeContainer();
      await container.read(passesProvider.future);

      final pass = await container
          .read(passesProvider.notifier)
          .requestLateAccess(
            title: 'Home visit',
            purpose: 'Family',
            departureAt: fixedNow.add(const Duration(days: 1)),
            returnAt: fixedNow.add(const Duration(days: 2)),
            destination: 'Gampaha',
            reason: 'Wedding',
          );

      expect(pass.status, PassStatus.pending);
      expect(container.read(passesProvider).value!.length, 4);
    });

    test(
      'given an invalid request, then the repository error is thrown',
      () async {
        final container = makeContainer();
        await container.read(passesProvider.future);

        await expectLater(
          container
              .read(passesProvider.notifier)
              .requestLateAccess(
                title: 't',
                purpose: 'p',
                departureAt: fixedNow.subtract(const Duration(hours: 1)),
                returnAt: fixedNow.add(const Duration(days: 1)),
                destination: 'd',
                reason: 'r',
              ),
          throwsA(isA<RepositoryException>()),
        );
      },
    );

    test(
      'given going home twice, then the second attempt is refused',
      () async {
        final container = makeContainer();
        await container.read(passesProvider.future);
        final notifier = container.read(passesProvider.notifier);

        await notifier.recordGoingHome();

        expect(isOutsideOnLeave(container.read(passesProvider).value!), isTrue);
        await expectLater(
          notifier.recordGoingHome(),
          throwsA(isA<AlreadyOutsideException>()),
        );
      },
    );

    test('given cancelPass, then the pass is cancelled in the list', () async {
      final container = makeContainer();
      await container.read(passesProvider.future);

      await container.read(passesProvider.notifier).cancelPass('LA-2418');

      final pass = container.read(passByIdProvider('LA-2418')).value!;
      expect(pass.status, PassStatus.cancelled);
    });
  });

  group('providers', () {
    test('the quota provider returns 12 of 18 days', () async {
      final container = makeContainer();

      final quota = await container.read(passQuotaProvider.future);

      expect(quota.usedDays, 12);
    });

    test('passByIdProvider errors for an unknown id', () async {
      final container = makeContainer();
      await container.read(passesProvider.future);

      expect(container.read(passByIdProvider('nope')).hasError, isTrue);
    });

    test('the default repository provider can be created', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(passRepositoryProvider), isA<PassRepository>());
    });
  });
}
