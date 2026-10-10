import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/data/models/complaint.dart';
import 'package:hostelhive_mobile/data/models/inbox_item.dart';
import 'package:hostelhive_mobile/data/models/pass.dart';
import 'package:hostelhive_mobile/data/repositories/auth_repository.dart';
import 'package:hostelhive_mobile/data/repositories/complaint_repository.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/data/repositories/inbox_repository.dart';
import 'package:hostelhive_mobile/data/repositories/pass_repository.dart';
import 'package:hostelhive_mobile/data/repositories/session_store.dart';

final fixedNow = DateTime(2026, 4, 18, 21, 14);
DateTime clock() => fixedNow;

void main() {
  group('SessionStore', () {
    test('memory store saves, reads and clears the token', () async {
      final store = MemorySessionStore();
      expect(await store.read(), isNull);

      await store.write('abc');
      expect(await store.read(), 'abc');

      await store.clear();
      expect(await store.read(), isNull);
    });

    test('secure store saves, reads and clears the token', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      FlutterSecureStorage.setMockInitialValues({});
      final store = SecureSessionStore();

      await store.write('token-1');
      expect(await store.read(), 'token-1');

      await store.clear();
      expect(await store.read(), isNull);
    });
  });

  group('MockAuthRepository', () {
    late MemorySessionStore store;
    late MockAuthRepository repo;

    setUp(() {
      store = MemorySessionStore();
      repo = MockAuthRepository(store: store, latency: Duration.zero);
    });

    test(
      'given valid credentials by index number, then login succeeds',
      () async {
        final student = await repo.login('SE/2021/036', 'Hostel@123');

        expect(student.fullName, 'Sanuthi Perera');
        expect(await store.read(), 'STU-0036');
        expect((await repo.currentUser())?.indexNo, 'SE/2021/036');
      },
    );

    test('given valid credentials by email, then login succeeds', () async {
      final student = await repo.login(
        ' Sanuthi.P@stu.kln.ac.lk ',
        'Hostel@123',
      );

      expect(student.studentId, 'STU-0036');
    });

    test(
      'given a blank identifier or password, then it asks for both',
      () async {
        await expectLater(
          repo.login('', 'x'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('both'),
            ),
          ),
        );
        await expectLater(
          repo.login('SE/2021/036', ''),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test('given a wrong password or unknown user, then login fails', () async {
      await expectLater(
        repo.login('SE/2021/036', 'wrong'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Incorrect'),
          ),
        ),
      );
      await expectLater(
        repo.login('nobody', 'Hostel@123'),
        throwsA(isA<AuthException>()),
      );
      expect(await store.read(), isNull);
    });

    test(
      'given a new student, then login flags a required password change',
      () async {
        final student = await repo.login('SE/2022/101', 'Temp@1234');

        expect(student.mustChangePassword, isTrue);
      },
    );

    test(
      'given a strong password, then changePassword clears the flag',
      () async {
        await repo.login('SE/2022/101', 'Temp@1234');

        final updated = await repo.changePassword('Brand#New9');

        expect(updated.mustChangePassword, isFalse);
        expect((await repo.currentUser())?.mustChangePassword, isFalse);
        await repo.logout();
        expect(
          (await repo.login('SE/2022/101', 'Brand#New9')).fullName,
          'Nethmi Silva',
        );
      },
    );

    test('given a weak password, then changePassword is rejected', () async {
      await repo.login('SE/2022/101', 'Temp@1234');

      await expectLater(
        repo.changePassword('weak'),
        throwsA(isA<AuthException>()),
      );
    });

    test('given nobody is signed in, then changePassword fails', () async {
      await expectLater(
        repo.changePassword('Brand#New9'),
        throwsA(isA<AuthException>()),
      );
    });

    test('given logout, then the session is cleared', () async {
      await repo.login('SE/2021/036', 'Hostel@123');

      await repo.logout();

      expect(await repo.currentUser(), isNull);
      expect(await store.read(), isNull);
    });

    test('given a stale token, then there is no current user', () async {
      await store.write('STU-UNKNOWN');

      expect(await repo.currentUser(), isNull);
    });

    test('given a registered email, then a reset can be requested', () async {
      await repo.requestPasswordReset('sanuthi.p@stu.kln.ac.lk');
    });

    test(
      'given an invalid or unregistered email, then a reset is refused',
      () async {
        await expectLater(
          repo.requestPasswordReset('nope'),
          throwsA(isA<AuthException>()),
        );
        await expectLater(
          repo.requestPasswordReset('ghost@stu.kln.ac.lk'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('not registered'),
            ),
          ),
        );
      },
    );

    test(
      'given a valid token and strong password, then reset succeeds',
      () async {
        await repo.resetPassword(
          token: MockAuthRepository.demoResetToken,
          newPassword: 'Brand#New9',
        );
      },
    );

    test('given an expired token or weak password, then reset fails', () async {
      await expectLater(
        repo.resetPassword(token: 'old', newPassword: 'Brand#New9'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('expired'),
          ),
        ),
      );
      await expectLater(
        repo.resetPassword(
          token: MockAuthRepository.demoResetToken,
          newPassword: 'weak',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('the default repository can be created with the secure store', () {
      expect(MockAuthRepository(), isA<AuthRepository>());
    });
  });

  group('MockPassRepository', () {
    late MockPassRepository repo;

    setUp(
      () => repo = MockPassRepository(clock: clock, latency: Duration.zero),
    );

    test('given seed data, then passes are listed newest first', () async {
      final passes = await repo.fetchPasses();

      expect(passes.first.id, 'LA-2418');
      expect(passes.length, 3);
      expect(() => passes.add(passes.first), throwsUnsupportedError);
    });

    test(
      'given the seeded pass, then it is approved with a 2 day 9 hour trip',
      () async {
        final pass = await repo.fetchPass('LA-2418');

        expect(pass.status, PassStatus.approved);
        expect(pass.durationLabel, '2 days 9 hours');
        expect(pass.decidedBy, 'Nisansala R.');
      },
    );

    test('given an unknown pass id, then fetchPass fails', () async {
      await expectLater(
        repo.fetchPass('nope'),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('the quota is 12 of 18 days', () async {
      final quota = await repo.fetchQuota();

      expect(quota.usedDays, 12);
      expect(quota.totalDays, MockPassRepository.yearlyQuotaDays);
    });

    test(
      'given valid details, then a pending late access pass is created',
      () async {
        final pass = await repo.requestLateAccess(
          title: 'Home visit',
          purpose: 'Family',
          departureAt: fixedNow.add(const Duration(days: 1)),
          returnAt: fixedNow.add(const Duration(days: 2)),
          destination: ' Gampaha ',
          reason: ' Wedding ',
        );

        expect(pass.status, PassStatus.pending);
        expect(pass.id, 'LA-2419');
        expect(pass.destination, 'Gampaha');
        expect((await repo.fetchPasses()).length, 4);
      },
    );

    test(
      'given missing destination or reason, then the request is rejected',
      () async {
        await expectLater(
          repo.requestLateAccess(
            title: 't',
            purpose: 'p',
            departureAt: fixedNow.add(const Duration(days: 1)),
            returnAt: fixedNow.add(const Duration(days: 2)),
            destination: '',
            reason: 'r',
          ),
          throwsA(isA<RepositoryException>()),
        );
      },
    );

    test(
      'given a departure in the past, then the request is rejected',
      () async {
        await expectLater(
          repo.requestLateAccess(
            title: 't',
            purpose: 'p',
            departureAt: fixedNow.subtract(const Duration(hours: 1)),
            returnAt: fixedNow.add(const Duration(days: 1)),
            destination: 'd',
            reason: 'r',
          ),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.message,
              'message',
              contains('past'),
            ),
          ),
        );
      },
    );

    test(
      'given a return before departure, then the request is rejected',
      () async {
        await expectLater(
          repo.requestLateAccess(
            title: 't',
            purpose: 'p',
            departureAt: fixedNow.add(const Duration(days: 2)),
            returnAt: fixedNow.add(const Duration(days: 1)),
            destination: 'd',
            reason: 'r',
          ),
          throwsA(isA<RepositoryException>()),
        );
      },
    );

    test('given going home, then a leave pass is recorded once', () async {
      final pass = await repo.recordGoingHome();

      expect(pass.type, PassType.leave);
      expect(pass.id, 'GH-1001');
      await expectLater(
        repo.recordGoingHome(),
        throwsA(isA<AlreadyOutsideException>()),
      );
    });

    test(
      'given the leave is cancelled, then going home can be recorded again',
      () async {
        final pass = await repo.recordGoingHome();
        await repo.cancelPass(pass.id);

        expect((await repo.recordGoingHome()).id, 'GH-1002');
      },
    );

    test('given an active pass, then it can be cancelled', () async {
      await repo.cancelPass('LA-2418');

      expect((await repo.fetchPass('LA-2418')).status, PassStatus.cancelled);
    });

    test('given an unknown or finished pass, then cancel fails', () async {
      await expectLater(
        repo.cancelPass('nope'),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        repo.cancelPass('LA-2341'),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('the default clock and latency can be used', () async {
      final defaults = MockPassRepository();

      expect((await defaults.fetchPasses()), isNotEmpty);
    });
  });

  group('MockComplaintRepository', () {
    late MockComplaintRepository repo;

    setUp(
      () =>
          repo = MockComplaintRepository(clock: clock, latency: Duration.zero),
    );

    test('given seed data, then CMP-0142 is ongoing and critical', () async {
      final complaint = await repo.fetchComplaint('CMP-0142');

      expect(complaint.status, ComplaintStatus.ongoing);
      expect(complaint.severity, ComplaintSeverity.critical);
      expect(complaint.updates.length, 2);
    });

    test('given an unknown id, then fetchComplaint fails', () async {
      await expectLater(
        repo.fetchComplaint('x'),
        throwsA(isA<RepositoryException>()),
      );
    });

    test(
      'given valid details, then an open complaint is created with updates',
      () async {
        final complaint = await repo.submitComplaint(
          category: 'Facilities',
          title: ' Leaking tap ',
          description: ' Water everywhere ',
          severity: ComplaintSeverity.high,
          imagePaths: const ['a.jpg', 'b.png'],
        );

        expect(complaint.id, 'CMP-0143');
        expect(complaint.status, ComplaintStatus.open);
        expect(complaint.title, 'Leaking tap');
        expect(complaint.imagePaths.length, 2);
        expect(complaint.updates.first.text, 'Original report with 2 photos.');
        expect(complaint.updates.last.text, contains('SLA 12 hours'));
        expect((await repo.fetchComplaints()).first.id, 'CMP-0143');
      },
    );

    test(
      'given no photos, then the first update says original report',
      () async {
        final complaint = await repo.submitComplaint(
          category: 'Other',
          title: 't',
          description: 'd',
          severity: ComplaintSeverity.normal,
        );

        expect(complaint.updates.first.text, 'Original report.');
      },
    );

    test('given blank fields, then the complaint is rejected', () async {
      for (final args in [
        ('', 't', 'd'),
        ('Other', ' ', 'd'),
        ('Other', 't', '  '),
      ]) {
        await expectLater(
          repo.submitComplaint(
            category: args.$1,
            title: args.$2,
            description: args.$3,
            severity: ComplaintSeverity.normal,
          ),
          throwsA(isA<RepositoryException>()),
        );
      }
    });

    test(
      'given more than five photos, then the complaint is rejected',
      () async {
        await expectLater(
          repo.submitComplaint(
            category: 'Other',
            title: 't',
            description: 'd',
            severity: ComplaintSeverity.normal,
            imagePaths: List.generate(6, (i) => 'p$i.jpg'),
          ),
          throwsA(isA<RepositoryException>()),
        );
      },
    );

    test('the default clock and latency can be used', () async {
      expect(await MockComplaintRepository().fetchComplaints(), isNotEmpty);
    });
  });

  group('MockInboxRepository', () {
    late MockInboxRepository repo;

    setUp(
      () => repo = MockInboxRepository(clock: clock, latency: Duration.zero),
    );

    test(
      'given seed data, then items are newest first with three unread',
      () async {
        final items = await repo.fetchItems();

        expect(items.first.id, 'n1');
        expect(items.where((i) => !i.isRead).length, 3);
        expect(items.where((i) => i.isAlert).length, 2);
      },
    );

    test(
      'given an id, then fetchItem returns it and unknown ids fail',
      () async {
        expect((await repo.fetchItem('n3')).tag, 'FACILITIES');
        await expectLater(
          repo.fetchItem('zzz'),
          throwsA(isA<RepositoryException>()),
        );
      },
    );

    test('given markAsRead, then only that item becomes read', () async {
      await repo.markAsRead('n1');

      final items = await repo.fetchItems();
      expect(items.firstWhere((i) => i.id == 'n1').isRead, isTrue);
      expect(items.where((i) => !i.isRead).length, 2);
    });

    test('given an unknown id, then markAsRead changes nothing', () async {
      await repo.markAsRead('zzz');

      expect((await repo.fetchItems()).where((i) => !i.isRead).length, 3);
    });

    test('given markAllAsRead, then nothing is unread', () async {
      await repo.markAllAsRead();

      expect((await repo.fetchItems()).any((i) => !i.isRead), isFalse);
    });

    test('the default clock and latency can be used', () async {
      expect(await MockInboxRepository().fetchItems(), isNotEmpty);
    });

    test('item kinds cover announcements and alerts', () async {
      final kinds = (await repo.fetchItems()).map((i) => i.kind).toSet();

      expect(
        kinds,
        containsAll([InboxItemKind.announcement, InboxItemKind.alert]),
      );
    });
  });

  test('exception messages are used as their string form', () {
    expect(const RepositoryException('x').toString(), 'x');
    expect(const AlreadyOutsideException().message, contains('already'));
  });
}
