import '../../core/utils/password_strength.dart';
import '../models/student.dart';
import 'exceptions.dart';
import 'session_store.dart';

/// Authentication boundary so the UI never talks to HTTP directly
/// (SDS 1.1 Application Layer: JWT, session, RBAC).
abstract class AuthRepository {
  Future<Student> login(String emailOrId, String password);
  Future<void> requestPasswordReset(String email);
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  /// First login: replaces the temporary password of the signed-in student.
  Future<Student> changePassword(String newPassword);

  /// Authenticated password change (FR006/UC002).
  ///
  /// Verifies [currentPassword] before applying [newPassword].
  Future<void> changeCurrentPassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();
  Future<Student?> currentUser();
}

class _Account {
  _Account(this.student, this.password);

  Student student;
  String password;
}

/// In-memory implementation used until the Go backend API is available.
///
/// Demo accounts:
/// * `SE/2021/036` or `sanuthi.p@stu.kln.ac.lk` with `Hostel@123`
/// * `SE/2022/101` or `nethmi.s@stu.kln.ac.lk` with `Temp@1234`
///   (must choose a new password on first login)
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    SessionStore? store,
    this.latency = const Duration(milliseconds: 400),
  }) : _store = store ?? SecureSessionStore() {
    for (final account in _seedAccounts()) {
      _accounts[account.student.studentId] = account;
    }
  }

  static const demoResetToken = 'demo-reset-token';

  final SessionStore _store;
  final Duration latency;
  final Map<String, _Account> _accounts = {};

  static List<_Account> _seedAccounts() => [
    _Account(
      const Student(
        studentId: 'STU-0036',
        indexNo: 'SE/2021/036',
        fullName: 'Sanuthi Perera',
        email: 'sanuthi.p@stu.kln.ac.lk',
        phone: '+94 77 000 0036',
        year: 2,
        department: 'Computer Science',
        blockCode: 'C',
        blockName: 'Orchid',
        roomNo: 'C-214',
        bedNo: 'Bed 2',
        guardianName: 'Mrs. Ramani Perera',
        guardianRelation: 'Mother',
        guardianPhone: '+94 77 221 0455',
      ),
      'Hostel@123',
    ),
    _Account(
      const Student(
        studentId: 'STU-0101',
        indexNo: 'SE/2022/101',
        fullName: 'Nethmi Silva',
        email: 'nethmi.s@stu.kln.ac.lk',
        year: 1,
        department: 'Computer Science',
        blockCode: 'A',
        blockName: 'Jasmine',
        roomNo: 'A-105',
        bedNo: 'Bed 1',
        mustChangePassword: true,
      ),
      'Temp@1234',
    ),
  ];

  Future<void> _wait() => Future<void>.delayed(latency);

  _Account? _find(String identifier) {
    final key = identifier.trim().toLowerCase();
    for (final account in _accounts.values) {
      final s = account.student;
      if ([
        s.email,
        s.indexNo,
        s.studentId,
      ].any((v) => v.toLowerCase() == key)) {
        return account;
      }
    }
    return null;
  }

  @override
  Future<Student> login(String emailOrId, String password) async {
    await _wait();
    if (emailOrId.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Please enter both email/ID and password.');
    }
    final account = _find(emailOrId);
    if (account == null || account.password != password) {
      throw const AuthException('Incorrect email/ID or password.');
    }
    await _store.write(account.student.studentId);
    return account.student;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _wait();
    if (!email.contains('@')) {
      throw const AuthException('Enter a valid registered email address.');
    }
    final account = _find(email);
    if (account == null) {
      throw const AuthException('This email is not registered.');
    }
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _wait();
    if (token != demoResetToken) {
      throw const AuthException(
        'This reset link has expired. Request a new one.',
      );
    }
    if (!PasswordRules.of(newPassword).allMet) {
      throw const AuthException('Choose a stronger password.');
    }
  }

  @override
  Future<Student> changePassword(String newPassword) async {
    await _wait();
    final account = await _signedIn();
    if (account == null) {
      throw const AuthException('Please sign in again.');
    }
    if (!PasswordRules.of(newPassword).allMet) {
      throw const AuthException('Choose a stronger password.');
    }
    account.password = newPassword;
    account.student = account.student.copyWith(mustChangePassword: false);
    return account.student;
  }

  @override
  Future<void> changeCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _wait();
    final account = await _signedIn();
    if (account == null) throw const AuthException('Please sign in again.');
    if (account.password != currentPassword) {
      throw const AuthException('Current password is incorrect.');
    }
    if (!PasswordRules.of(newPassword).allMet) {
      throw const AuthException('Choose a stronger password.');
    }
    account.password = newPassword;
  }

  @override
  Future<void> logout() => _store.clear();

  @override
  Future<Student?> currentUser() async => (await _signedIn())?.student;

  Future<_Account?> _signedIn() async {
    final token = await _store.read();
    return token == null ? null : _accounts[token];
  }
}
