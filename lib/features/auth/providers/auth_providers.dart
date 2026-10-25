import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/api/api_providers.dart';
import '../../../data/models/student.dart';
import '../../../data/repositories/api_auth_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/exceptions.dart';
import '../../attendance/providers/attendance_providers.dart';
import '../../complaints/providers/complaint_providers.dart';
import '../../inbox/providers/inbox_providers.dart';
import '../../passes/providers/pass_providers.dart';
import '../../qr/providers/qr_providers.dart';

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

  /// Reloads the profile, for example to pick up a new IN/OUT status. The
  /// current profile stays when the reload fails.
  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;
    try {
      final student = await _repository.currentUser();
      if (student != null) {
        state = AuthState(status: AuthStatus.authenticated, student: student);
      }
    } on RepositoryException {
      return;
    }
  }

  Future<String?> signIn(String emailOrId, String password) async {
    return _run(() async {
      final student = await _repository.login(emailOrId, password);
      state = AuthState(status: AuthStatus.authenticated, student: student);
      _clearPerStudentCaches();
    });
  }

  /// First login: replaces the temporary password.
  Future<String?> activateAccount(String newPassword) async {
    return _run(() async {
      final student = await _repository.changePassword(newPassword);
      state = AuthState(status: AuthStatus.authenticated, student: student);
    });
  }

  Future<String?> updateProfile({
    String? phone,
    String? guardianName,
    String? guardianRelation,
    String? guardianPhone,
  }) {
    return _run(() async {
      final student = await _repository.updateProfile(
        phone: phone,
        guardianName: guardianName,
        guardianRelation: guardianRelation,
        guardianPhone: guardianPhone,
      );
      state = AuthState(status: AuthStatus.authenticated, student: student);
    });
  }

  Future<String?> uploadProfilePhoto({
    required Uint8List bytes,
    required String contentType,
  }) {
    return _run(() async {
      final student = await _repository.uploadProfilePhoto(
        bytes: bytes,
        contentType: contentType,
      );
      state = AuthState(status: AuthStatus.authenticated, student: student);
    });
  }

  Future<String?> removeProfilePhoto() {
    return _run(() async {
      final student = await _repository.removeProfilePhoto();
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
    _clearPerStudentCaches();
  }

  /// Several feature providers (passes, complaints, inbox, attendance, QR)
  /// cache the signed-in student's data for the life of the app and have no
  /// way to notice a different student signing in on the same session, so
  /// they must be invalidated explicitly here or a new sign-in would still
  /// show the previous student's data.
  void _clearPerStudentCaches() {
    // Only invalidate providers that already have state. Invalidating one
    // that was never watched would create it from scratch here, kicking off
    // a fetch nobody asked for.
    if (ref.exists(passesProvider)) ref.invalidate(passesProvider);
    if (ref.exists(passQuotaProvider)) ref.invalidate(passQuotaProvider);
    if (ref.exists(complaintsProvider)) ref.invalidate(complaintsProvider);
    if (ref.exists(inboxProvider)) ref.invalidate(inboxProvider);
    if (ref.exists(attendanceProvider)) ref.invalidate(attendanceProvider);
    if (ref.exists(qrImageProvider)) ref.invalidate(qrImageProvider);
    // profilePhotoProvider is not invalidated here: it already reacts to
    // AuthState via ref.watch(authControllerProvider.select(...)), and
    // invalidating it from inside AuthController itself is a circular
    // dependency (it depends on this very provider).
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

/// The signed-in student's profile photo bytes, fetched with their token.
/// Re-runs whenever [AuthState.student]'s [Student.hasPhoto] flips.
final profilePhotoProvider = FutureProvider.autoDispose<Uint8List?>((
  ref,
) async {
  final student = ref.watch(
    authControllerProvider.select((state) => state.student),
  );
  if (student == null || !student.hasPhoto) return null;
  return ref.read(authRepositoryProvider).fetchProfilePhoto();
});
