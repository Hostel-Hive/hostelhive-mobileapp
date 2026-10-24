import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/data/repositories/auth_repository.dart';
import 'package:hostelhive_mobile/data/repositories/session_store.dart';
import 'package:hostelhive_mobile/features/auth/providers/auth_providers.dart';

ProviderContainer makeContainer(MemorySessionStore store) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        MockAuthRepository(store: store, latency: Duration.zero),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AuthState> settle(ProviderContainer container) async {
  container.read(authControllerProvider);
  await Future<void>.delayed(Duration.zero);
  return container.read(authControllerProvider);
}

void main() {
  test(
    'given no saved session, then the state becomes unauthenticated',
    () async {
      final container = makeContainer(MemorySessionStore());

      expect(container.read(authControllerProvider).status, AuthStatus.unknown);
      final state = await settle(container);

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.student, isNull);
      expect(state.isAuthenticated, isFalse);
    },
  );

  test('given a saved session, then the student is restored', () async {
    final store = MemorySessionStore();
    await store.write('STU-0036');
    final container = makeContainer(store);

    final state = await settle(container);

    expect(state.isAuthenticated, isTrue);
    expect(state.student?.firstName, 'Sanuthi');
    expect(state.mustChangePassword, isFalse);
  });

  test(
    'given valid credentials, then signIn authenticates and returns null',
    () async {
      final container = makeContainer(MemorySessionStore());
      await settle(container);

      final error = await container
          .read(authControllerProvider.notifier)
          .signIn('SE/2021/036', 'Hostel@123');

      expect(error, isNull);
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
    },
  );

  test('given wrong credentials, then signIn returns the message and stays signed out', () async {
    final container = makeContainer(MemorySessionStore());
    await settle(container);

    final error = await container
        .read(authControllerProvider.notifier)
        .signIn('SE/2021/036', 'nope');

    expect(error, 'Incorrect email/ID or password.');
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
  });

  test(
    'given a first-time student, then signIn flags the password change',
    () async {
      final container = makeContainer(MemorySessionStore());
      await settle(container);

      await container
          .read(authControllerProvider.notifier)
          .signIn('SE/2022/101', 'Temp@1234');

      expect(container.read(authControllerProvider).mustChangePassword, isTrue);
    },
  );

  test(
    'given a strong password, then activateAccount clears the flag',
    () async {
      final container = makeContainer(MemorySessionStore());
      await settle(container);
      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn('SE/2022/101', 'Temp@1234');

      final error = await controller.activateAccount('Brand#New9');

      expect(error, isNull);
      expect(
        container.read(authControllerProvider).mustChangePassword,
        isFalse,
      );
    },
  );

  test(
    'given a weak password, then activateAccount returns an error',
    () async {
      final container = makeContainer(MemorySessionStore());
      await settle(container);
      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn('SE/2022/101', 'Temp@1234');

      final error = await controller.activateAccount('weak');

      expect(error, isNotNull);
      expect(container.read(authControllerProvider).mustChangePassword, isTrue);
    },
  );

  test(
    'given a registered email, then requestPasswordReset succeeds',
    () async {
      final container = makeContainer(MemorySessionStore());
      await settle(container);

      final controller = container.read(authControllerProvider.notifier);

      expect(
        await controller.requestPasswordReset(' sanuthi.p@stu.kln.ac.lk '),
        isNull,
      );
      expect(
        await controller.requestPasswordReset('ghost@stu.kln.ac.lk'),
        contains('not registered'),
      );
    },
  );

  test('given a token, then resetPassword validates it', () async {
    final container = makeContainer(MemorySessionStore());
    await settle(container);
    final controller = container.read(authControllerProvider.notifier);

    expect(
      await controller.resetPassword(
        token: MockAuthRepository.demoResetToken,
        newPassword: 'Brand#New9',
      ),
      isNull,
    );
    expect(
      await controller.resetPassword(token: 'old', newPassword: 'Brand#New9'),
      contains('expired'),
    );
  });

  test('given signOut, then the session ends', () async {
    final store = MemorySessionStore();
    await store.write('STU-0036');
    final container = makeContainer(store);
    await settle(container);

    await container.read(authControllerProvider.notifier).signOut();

    expect(
      container.read(authControllerProvider).status,
      AuthStatus.unauthenticated,
    );
    expect(await store.read(), isNull);
  });

  test('the default session store and repository can be created', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(sessionStoreProvider), isA<SessionStore>());
    expect(container.read(authRepositoryProvider), isA<AuthRepository>());
  });
}
