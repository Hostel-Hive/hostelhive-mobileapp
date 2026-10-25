import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../repositories/exceptions.dart';
import '../repositories/session_store.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Email and password sign-in with Firebase Authentication through its REST
/// API, so no native Firebase setup is needed. The refresh token is kept in
/// the [SessionStore]; the short-lived ID token stays in memory.
class FirebaseAuthService implements TokenSource {
  FirebaseAuthService({
    required this._apiKey,
    required this._store,
    required this._client,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const _identity = 'https://identitytoolkit.googleapis.com/v1';
  static const _secureToken = 'https://securetoken.googleapis.com/v1';

  final String _apiKey;
  final SessionStore _store;
  final http.Client _client;
  final DateTime Function() _clock;

  String? _idToken;
  DateTime? _expiresAt;

  Future<bool> hasSession() async => await _store.read() != null;

  Future<void> signIn({required String email, required String password}) async {
    final body = await _post(
      '$_identity/accounts:signInWithPassword',
      jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
      'application/json',
    );
    _remember(
      idToken: body['idToken'] as String,
      expiresIn: body['expiresIn'] as String,
    );
    await _store.write(body['refreshToken'] as String);
  }

  /// Asks Firebase to email a reset link. An unknown address is treated as
  /// success so the screen never reveals which emails have accounts.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _post(
        '$_identity/accounts:sendOobCode',
        jsonEncode({'requestType': 'PASSWORD_RESET', 'email': email.trim()}),
        'application/json',
      );
    } on AuthException {
      return;
    }
  }

  Future<void> signOut() async {
    _idToken = null;
    _expiresAt = null;
    await _store.clear();
  }

  /// Confirms [password] is still correct for [email] without changing the
  /// stored session. Throws [AuthException] when it is not.
  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    await _post(
      '$_identity/accounts:signInWithPassword',
      jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
      'application/json',
    );
  }

  /// Changes the password for the currently signed-in user (FR006).
  ///
  /// Firebase issues a new token pair on success; the stored session is
  /// updated so the next request uses the fresh tokens without re-login.
  Future<void> updatePassword(String newPassword) async {
    final token = await idToken();
    if (token == null) throw const AuthException('Please sign in again.');
    final body = await _post(
      '$_identity/accounts:update',
      jsonEncode({
        'idToken': token,
        'password': newPassword,
        'returnSecureToken': true,
      }),
      'application/json',
    );
    _remember(
      idToken: body['idToken'] as String,
      expiresIn: body['expiresIn'] as String,
    );
    final rotated = body['refreshToken'] as String?;
    if (rotated != null) await _store.write(rotated);
  }

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    final expiresAt = _expiresAt;
    if (!forceRefresh &&
        _idToken != null &&
        expiresAt != null &&
        expiresAt.isAfter(_clock().add(const Duration(seconds: 60)))) {
      return _idToken;
    }

    final refreshToken = await _store.read();
    if (refreshToken == null) return null;

    try {
      final body = await _post(
        '$_secureToken/token',
        'grant_type=refresh_token&refresh_token=${Uri.encodeQueryComponent(refreshToken)}',
        'application/x-www-form-urlencoded',
      );
      _remember(
        idToken: body['id_token'] as String,
        expiresIn: body['expires_in'] as String,
      );
      final rotated = body['refresh_token'] as String?;
      if (rotated != null && rotated != refreshToken) {
        await _store.write(rotated);
      }
      return _idToken;
    } on AuthException {
      await signOut();
      return null;
    }
  }

  void _remember({required String idToken, required String expiresIn}) {
    _idToken = idToken;
    _expiresAt = _clock().add(Duration(seconds: int.parse(expiresIn)));
  }

  Future<Map<String, dynamic>> _post(
    String url,
    String body,
    String contentType,
  ) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$url${url.contains('?') ? '&' : '?'}key=$_apiKey'),
            headers: {'Content-Type': contentType},
            body: body,
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const NetworkException();
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded as Map<String, dynamic>;
    }
    throw AuthException(_messageFor(decoded));
  }

  String _messageFor(Object? decoded) {
    var code = '';
    if (decoded is Map && decoded['error'] is Map) {
      code = '${(decoded['error'] as Map)['message']}';
    }
    if (code.startsWith('TOO_MANY_ATTEMPTS')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (code == 'USER_DISABLED') {
      return 'This account has been disabled. Contact the hostel office.';
    }
    if (code == 'TOKEN_EXPIRED' ||
        code == 'INVALID_REFRESH_TOKEN' ||
        code == 'USER_NOT_FOUND') {
      return 'Your session has ended. Please sign in again.';
    }
    return 'Incorrect email or password.';
  }
}
