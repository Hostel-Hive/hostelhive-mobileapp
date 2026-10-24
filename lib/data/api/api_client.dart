import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Supplies the Firebase ID token sent with every request.
abstract class TokenSource {
  /// The current token, or null when nobody is signed in. [forceRefresh]
  /// asks for a new one after the backend rejected the old token.
  Future<String?> idToken({bool forceRefresh = false});
}

/// Calls the HostelHive backend (`<base>/<path>`) with the student's token.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this._client,
    required this._tokens,
    this.timeout = const Duration(seconds: 60),
  }) : _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl;

  final String _baseUrl;
  final http.Client _client;
  final TokenSource _tokens;
  final Duration timeout;

  /// GET returning decoded JSON.
  Future<dynamic> getJson(String path, {Map<String, String>? query}) async {
    final response = await _send('GET', path, query: query);
    return _decode(response);
  }

  /// POST with an optional JSON body (no body when [body] is null).
  Future<dynamic> postJson(String path, {Object? body}) async {
    final response = await _send('POST', path, jsonBody: body);
    return _decode(response);
  }

  /// PUT with a JSON body.
  Future<dynamic> putJson(String path, {required Object body}) async {
    final response = await _send('PUT', path, jsonBody: body);
    return _decode(response);
  }

  /// PUT raw bytes, for photo uploads.
  Future<dynamic> putBytes(
    String path, {
    required Uint8List bytes,
    required String contentType,
  }) async {
    final response = await _send(
      'PUT',
      path,
      rawBody: bytes,
      contentType: contentType,
    );
    return _decode(response);
  }

  /// DELETE returning decoded JSON, or null for an empty reply.
  Future<dynamic> delete(String path) async {
    final response = await _send('DELETE', path);
    return _decode(response);
  }

  /// GET returning raw bytes, for the QR code and photos.
  Future<Uint8List> getBytes(String path) async {
    final response = await _send('GET', path, accept: 'image/png, image/jpeg');
    return response.bodyBytes;
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? jsonBody,
    Uint8List? rawBody,
    String? contentType,
    String accept = 'application/json',
  }) async {
    var response = await _once(
      method,
      path,
      query: query,
      jsonBody: jsonBody,
      rawBody: rawBody,
      contentType: contentType,
      accept: accept,
      forceRefresh: false,
    );
    if (response.statusCode == 401) {
      response = await _once(
        method,
        path,
        query: query,
        jsonBody: jsonBody,
        rawBody: rawBody,
        contentType: contentType,
        accept: accept,
        forceRefresh: true,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }
    throw ApiException(
      statusCode: response.statusCode,
      code: _errorCode(response),
    );
  }

  Future<http.Response> _once(
    String method,
    String path, {
    required Map<String, String>? query,
    required Object? jsonBody,
    required Uint8List? rawBody,
    required String? contentType,
    required String accept,
    required bool forceRefresh,
  }) async {
    final token = await _tokens.idToken(forceRefresh: forceRefresh);
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Accept'] = accept
      ..headers['Authorization'] = 'Bearer ${token ?? ''}';

    if (jsonBody != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(jsonBody);
    } else if (rawBody != null) {
      request.headers['Content-Type'] =
          contentType ?? 'application/octet-stream';
      request.bodyBytes = rawBody;
    }

    try {
      final streamed = await _client.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const NetworkException();
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode == 204 || response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String? _errorCode(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['error'] is String) {
        return body['error'] as String;
      }
    } on FormatException {
      // The proxy may reply with plain text; the status alone is enough.
    }
    return null;
  }
}
