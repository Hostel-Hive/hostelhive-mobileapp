import 'dart:typed_data';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../api/firebase_auth_service.dart';
import '../models/student.dart';
import 'auth_repository.dart';
import 'exceptions.dart';

/// Signs students in with Firebase and loads their records from the backend
/// (`/me`, `/me/setup/complete`, `/me/student-profile`).
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required this._auth, required this._api});

  final FirebaseAuthService _auth;
  final ApiClient _api;
  String? _email;
  Student? _student;

  @override
  Future<Student> login(String emailOrId, String password) async {
    await _auth.signIn(email: emailOrId, password: password);
    try {
      return await _loadStudent();
    } on Object {
      await _auth.signOut();
      rethrow;
    }
  }

  @override
  Future<Student?> currentUser() async {
    if (!await _auth.hasSession()) return null;
    try {
      return await _loadStudent();
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.statusCode == 403) {
        await _auth.signOut();
        return null;
      }
      rethrow;
    } on AuthException {
      await _auth.signOut();
      return null;
    }
  }

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Future<void> requestPasswordReset(String email) {
    return _auth.sendPasswordReset(email);
  }

  /// Passwords are chosen and reset on Firebase's own page from the email
  /// link, so the app has nothing to submit.
  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) {
    throw const RepositoryException(
      'Use the link in your email to choose a new password.',
    );
  }

  @override
  Future<Student> changePassword(String newPassword) {
    throw const RepositoryException(
      'Use the link in your email to choose a new password.',
    );
  }

  @override
  Future<void> changeCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _email;
    if (email == null) throw const AuthException('Please sign in again.');
    await _auth.reauthenticate(email: email, password: currentPassword);
    await _auth.updatePassword(newPassword);
  }

  @override
  Future<Student> updateProfile({
    String? phone,
    String? guardianName,
    String? guardianRelation,
    String? guardianPhone,
  }) async {
    final hasGuardianEdit =
        guardianName != null ||
        guardianRelation != null ||
        guardianPhone != null;
    if (hasGuardianEdit &&
        (guardianName == null ||
            guardianRelation == null ||
            guardianPhone == null)) {
      throw const RepositoryException(
        'Enter the guardian\'s name, relationship and phone together.',
      );
    }
    final body = <String, dynamic>{
      if (phone != null) 'contact_phone': phone.trim(),
      if (hasGuardianEdit)
        'guardians': [
          {
            'name': guardianName!.trim(),
            'relationship': guardianRelation!.trim(),
            'contact_phone': guardianPhone!.trim(),
          },
        ],
    };
    final profile = await _api.patchJson(
      '/me/student-profile',
      body: body,
    ) as Map<String, dynamic>;
    final student = Student.fromProfileJson(profile);
    _email = student.email;
    _student = student;
    return student;
  }

  @override
  Future<Uint8List> fetchProfilePhoto() =>
      _api.getBytes('/me/student-profile/image');

  @override
  Future<Student> uploadProfilePhoto({
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _api.putBytes(
      '/me/student-profile/image',
      bytes: bytes,
      contentType: contentType,
    );
    return _withPhoto(true);
  }

  @override
  Future<Student> removeProfilePhoto() async {
    await _api.delete('/me/student-profile/image');
    return _withPhoto(false);
  }

  Student _withPhoto(bool hasPhoto) {
    final student = _student;
    if (student == null) throw const AuthException('Please sign in again.');
    final updated = student.copyWith(hasPhoto: hasPhoto);
    _student = updated;
    return updated;
  }

  Future<Student> _loadStudent() async {
    final me = await _api.getJson('/me') as Map<String, dynamic>;
    if (me['role'] != 'student') {
      throw const AuthException('This app is for students only.');
    }
    if (me['setup_required'] == true) {
      // The student has just signed in with the password they chose on the
      // invitation page, which is what the backend needs to confirm setup.
      await _api.postJson('/me/setup/complete');
    }
    try {
      final profile =
          await _api.getJson('/me/student-profile') as Map<String, dynamic>;
      final student = Student.fromProfileJson(profile);
      _email = student.email;
      _student = student;
      return student;
    } on ApiException catch (e) {
      if (e.isNotFound) {
        throw const AuthException(
          'Your student profile is not set up yet. '
          'Please contact the hostel office.',
        );
      }
      rethrow;
    }
  }
}
