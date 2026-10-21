import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/api/api_providers.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/api_auth_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/exceptions.dart';

export '../../../data/api/api_providers.dart' show sessionStoreProvider;

/// The real backend when `API_BASE_URL` and `FIREBASE_API_KEY` are set,
/// otherwise the built-in demo accounts.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(appConfigProvider).useBackend) {
    return ApiAuthRepository(
      auth: ref.watch(firebaseAuthServiceProvider),
      api: ref.watch(apiClientProvider),
    );
  }
  return MockAuthRepository(store: ref.watch(sessionStoreProvider));
});

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.student});

  final AuthStatus status;
  final Student? student;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get mustChangePassword => student?.mustChangePassword ?? false;
}

/// Holds the signed-in student. Every action returns an error message to show
/// to the student, or null when it succeeded.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future<void>.microtask(_restoreSession);
    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _restoreSession() async {
    final student = await _repository.currentUser();
    state = AuthState(
      status: student == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated,
      student: student,
    );
  }

  Future<String?> signIn(String emailOrId, String password) async {
    return _run(() async {
      final student = await _repository.login(emailOrId, password);
      state = AuthState(status: AuthStatus.authenticated, student: student);
    });
  }

  /// First login: replaces the temporary password.
  Future<String?> activateAccount(String newPassword) async {
    return _run(() async {
      final student = await _repository.changePassword(newPassword);
      state = AuthState(status: AuthStatus.authenticated, student: student);
    });
  }

  Future<String?> requestPasswordReset(String email) {
    return _run(() => _repository.requestPasswordReset(email.trim()));
  }

  Future<String?> resetPassword({
    required String token,
    required String newPassword,
  }) {
    return _run(
      () => _repository.resetPassword(token: token, newPassword: newPassword),
    );
  }

  Future<void> signOut() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on RepositoryException catch (e) {
      return e.message;
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
