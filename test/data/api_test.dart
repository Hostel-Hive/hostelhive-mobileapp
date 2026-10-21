import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/config/app_config.dart';
import 'package:hostelhive_mobile/data/api/api_client.dart';
import 'package:hostelhive_mobile/data/api/api_exception.dart';
import 'package:hostelhive_mobile/data/api/firebase_auth_service.dart';
import 'package:hostelhive_mobile/data/models/student.dart';
import 'package:hostelhive_mobile/data/repositories/api_auth_repository.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/data/repositories/auth_repository.dart';
import 'package:hostelhive_mobile/data/repositories/session_store.dart';
import 'package:hostelhive_mobile/features/auth/providers/auth_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeTokens implements TokenSource {
  FakeTokens({this.token = 'token-1', this.refreshed = 'token-2'});

  String? token;
  final String refreshed;
  final List<bool> requests = [];

  @override
  Future<String?> idToken({bool forceRefresh = false}) async {
    requests.add(forceRefresh);
    return forceRefresh ? refreshed : token;
  }
}

http.Response json(Object body, [int status = 200]) {
  return http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

ApiClient clientFor(
  Future<http.Response> Function(http.Request request) handler, {
  FakeTokens? tokens,
}) {
  return ApiClient(
    baseUrl: 'https://api.example.invalid/api/v1/',
    client: MockClient(handler),
    tokens: tokens ?? FakeTokens(),
  );
}

const profile = {
  'student_id': '11111111-1111-4111-8111-111111111111',
  'index_no': 'SE/2021/036',
  'full_name': 'Sanuthi Perera',
  'email': 'sanuthi.p@stu.kln.ac.lk',
  'contact_phone': '+94 77 000 0036',
  'faculty': 'Faculty of Science',
  'year': 2,
  'accommodation': {
    'block_name': 'Block C',
    'room_no': 'C-214',
    'bed_no': 'Bed 2',
  },
  'guardians': [
    {
      'name': 'Mrs. Ramani Perera',
      'relationship': 'Mother',
      'contact_phone': '+94 77 221 0455',
    },
  ],
  'presence': {'status': 'IN', 'updated_at': '2026-10-15T10:00:00Z'},
};

void main() {
  group('ApiException', () {
    test('given known codes, then plain messages are used', () {
      expect(
        ApiException(statusCode: 409, code: 'already_outside').message,
        'You are already recorded as outside the hostel.',
      );
      expect(
        ApiException(statusCode: 400, code: 'invalid_input').message,
        contains('not valid'),
      );
    });

    test('given unknown codes, then the status decides the message', () {
      expect(ApiException(statusCode: 401).message, contains('sign in'));
      expect(ApiException(statusCode: 403).message, contains('access'));
      expect(ApiException(statusCode: 404).message, contains('find'));
      expect(ApiException(statusCode: 429).message, contains('Too many'));
      expect(ApiException(statusCode: 502).message, contains('busy'));
      expect(
        ApiException(statusCode: 418, code: 'teapot').message,
        'Something went wrong. Please try again.',
      );
    });

    test('given the status, then the helper flags are set', () {
      expect(ApiException(statusCode: 401).isUnauthorized, isTrue);
      expect(ApiException(statusCode: 404).isNotFound, isTrue);
      expect(ApiException(statusCode: 500).isNotFound, isFalse);
    });
  });

  group('AppConfig', () {
    test('given no settings, then the demo data is used', () {
      expect(const AppConfig().useBackend, isFalse);
      expect(const AppConfig(apiBaseUrl: 'https://x').useBackend, isFalse);
    });

    test('given both settings, then the backend is used', () {
      const config = AppConfig(apiBaseUrl: 'https://x', firebaseApiKey: 'k');
      expect(config.useBackend, isTrue);
    });

    test('given no build flags, then the environment config is empty', () {
      expect(AppConfig.fromEnvironment().useBackend, isFalse);
    });
  });

  group('ApiClient', () {
    test('given a GET, then the token and path are sent', () async {
      late http.Request seen;
      final client = clientFor((request) async {
        seen = request;
        return json({'ok': true});
      });

      final result = await client.getJson('/me', query: {'a': '1'});

      expect(result, {'ok': true});
      expect(seen.url.toString(), 'https://api.example.invalid/api/v1/me?a=1');
      expect(seen.headers['Authorization'], 'Bearer token-1');
      expect(seen.headers['Accept'], 'application/json');
      expect(seen.headers.containsKey('Content-Type'), isFalse);
    });

    test('given a POST body, then it is sent as JSON', () async {
      late http.Request seen;
      final client = clientFor((request) async {
        seen = request;
        return json({'id': 1}, 201);
      });

      await client.postJson('/leaves', body: {'reason': 'x'});

      expect(seen.method, 'POST');
      expect(seen.headers['Content-Type'], 'application/json');
      expect(jsonDecode(seen.body), {'reason': 'x'});
    });

    test('given a POST without a body, then none is sent', () async {
      late http.Request seen;
      final client = clientFor((request) async {
        seen = request;
        return json({'ok': true});
      });

      await client.postJson('/me/setup/complete');

      expect(seen.body, isEmpty);
      expect(seen.headers.containsKey('Content-Type'), isFalse);
    });

    test('given PUT json, bytes and DELETE, then each is sent', () async {
      final seen = <http.Request>[];
      final client = clientFor((request) async {
        seen.add(request);
        return request.method == 'DELETE'
            ? http.Response('', 204)
            : json({'ok': true});
      });

      await client.putJson('/x', body: {'a': 1});
      await client.putBytes(
        '/img',
        bytes: Uint8List.fromList([1, 2, 3]),
        contentType: 'image/png',
      );
      final deleted = await client.delete('/img');

      expect(seen[0].headers['Content-Type'], 'application/json');
      expect(seen[1].headers['Content-Type'], 'image/png');
      expect(seen[1].bodyBytes, [1, 2, 3]);
      expect(deleted, isNull);
    });

    test('given image bytes, then they are returned untouched', () async {
      final client = clientFor(
        (request) async => http.Response.bytes([9, 8, 7], 200),
      );

      expect(await client.getBytes('/me/qr'), [9, 8, 7]);
    });

    test('given a 401, then the token is refreshed and retried once', () async {
      final tokens = FakeTokens();
      var calls = 0;
      final client = clientFor((request) async {
        calls++;
        if (request.headers['Authorization'] == 'Bearer token-1') {
          return json({'error': 'unauthorized'}, 401);
        }
        return json({'ok': true});
      }, tokens: tokens);

      expect(await client.getJson('/me'), {'ok': true});
      expect(calls, 2);
      expect(tokens.requests, [false, true]);
    });

    test('given a persistent 401, then the error is raised', () async {
      final client = clientFor(
        (request) async => json({'error': 'unauthorized'}, 401),
      );

      await expectLater(
        client.getJson('/me'),
        throwsA(
          isA<ApiException>().having((e) => e.isUnauthorized, '401', true),
        ),
      );
    });

    test('given an error body, then the code is mapped to a message', () async {
      final client = clientFor(
        (request) async => json({'error': 'going_home_pending'}, 409),
      );

      await expectLater(
        client.postJson('/going-home', body: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('already declared'),
          ),
        ),
      );
    });

    test('given a plain text error, then the status still maps', () async {
      final client = clientFor(
        (request) async => http.Response('Bad gateway', 502),
      );

      await expectLater(
        client.getJson('/me'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', isNull)),
      );
    });

    test(
      'given the connection fails, then a network error is raised',
      () async {
        final client = clientFor(
          (request) async => throw http.ClientException('offline'),
        );

        await expectLater(
          client.getJson('/me'),
          throwsA(isA<NetworkException>()),
        );
      },
    );

    test(
      'given no token, then the header is empty but the call is made',
      () async {
        late http.Request seen;
        final client = clientFor((request) async {
          seen = request;
          return json({});
        }, tokens: FakeTokens(token: null));

        await client.getJson('/me');

        expect(seen.headers['Authorization'], 'Bearer ');
      },
    );
  });

  group('FirebaseAuthService', () {
    late MemorySessionStore store;
    late DateTime now;
    late List<http.Request> calls;

    FirebaseAuthService build(
      Future<http.Response> Function(http.Request request) handler,
    ) {
      calls = [];
      return FirebaseAuthService(
        apiKey: 'KEY',
        store: store,
        client: MockClient((request) async {
          calls.add(request);
          return handler(request);
        }),
        clock: () => now,
      );
    }

    setUp(() {
      store = MemorySessionStore();
      now = DateTime(2026, 10, 15, 12);
    });

    http.Response signedIn() => json({
      'idToken': 'id-1',
      'refreshToken': 'refresh-1',
      'expiresIn': '3600',
    });

    test('given valid credentials, then tokens are kept', () async {
      final auth = build((request) async => signedIn());

      await auth.signIn(email: ' a@b.lk ', password: 'pw');

      expect(calls.single.url.path, endsWith('accounts:signInWithPassword'));
      expect(calls.single.url.queryParameters['key'], 'KEY');
      expect(jsonDecode(calls.single.body)['email'], 'a@b.lk');
      expect(await store.read(), 'refresh-1');
      expect(await auth.idToken(), 'id-1');
      expect(calls, hasLength(1));
      expect(await auth.hasSession(), isTrue);
    });

    test('given a wrong password, then a friendly error is raised', () async {
      final auth = build(
        (request) async => json({
          'error': {'message': 'INVALID_LOGIN_CREDENTIALS'},
        }, 400),
      );

      await expectLater(
        auth.signIn(email: 'a@b.lk', password: 'x'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Incorrect email or password.',
          ),
        ),
      );
      expect(await store.read(), isNull);
    });

    test('given special Firebase errors, then each has its message', () async {
      Future<String> messageFor(String code) async {
        final auth = build(
          (request) async => json({
            'error': {'message': code},
          }, 400),
        );
        try {
          await auth.signIn(email: 'a@b.lk', password: 'x');
        } on AuthException catch (e) {
          return e.message;
        }
        return '';
      }

      expect(
        await messageFor('TOO_MANY_ATTEMPTS_TRY_LATER : x'),
        contains('Too many'),
      );
      expect(await messageFor('USER_DISABLED'), contains('disabled'));
      expect(await messageFor('TOKEN_EXPIRED'), contains('session has ended'));
    });

    test('given an expired token, then it is refreshed with the key', () async {
      var step = 0;
      final auth = build((request) async {
        step++;
        if (step == 1) return signedIn();
        return json({
          'id_token': 'id-2',
          'refresh_token': 'refresh-2',
          'expires_in': '3600',
        });
      });
      await auth.signIn(email: 'a@b.lk', password: 'pw');

      now = now.add(const Duration(hours: 2));
      final token = await auth.idToken();

      expect(token, 'id-2');
      expect(calls.last.url.path, endsWith('/token'));
      expect(calls.last.body, contains('refresh_token=refresh-1'));
      expect(await store.read(), 'refresh-2');
    });

    test('given a forced refresh, then a new token is fetched', () async {
      var step = 0;
      final auth = build((request) async {
        step++;
        if (step == 1) return signedIn();
        return json({
          'id_token': 'id-9',
          'refresh_token': 'refresh-1',
          'expires_in': '3600',
        });
      });
      await auth.signIn(email: 'a@b.lk', password: 'pw');

      expect(await auth.idToken(forceRefresh: true), 'id-9');
      expect(await store.read(), 'refresh-1');
    });

    test('given no saved session, then there is no token', () async {
      final auth = build((request) async => signedIn());

      expect(await auth.idToken(), isNull);
      expect(await auth.hasSession(), isFalse);
      expect(calls, isEmpty);
    });

    test(
      'given a rejected refresh token, then the session is cleared',
      () async {
        await store.write('old');
        final auth = build(
          (request) async => json({
            'error': {'message': 'INVALID_REFRESH_TOKEN'},
          }, 400),
        );

        expect(await auth.idToken(), isNull);
        expect(await store.read(), isNull);
      },
    );

    test('given sign out, then everything is cleared', () async {
      final auth = build((request) async => signedIn());
      await auth.signIn(email: 'a@b.lk', password: 'pw');

      await auth.signOut();

      expect(await store.read(), isNull);
      expect(await auth.idToken(), isNull);
    });

    test('given a reset request, then the email is sent', () async {
      final auth = build((request) async => json({'email': 'a@b.lk'}));

      await auth.sendPasswordReset(' a@b.lk ');

      expect(calls.single.url.path, endsWith('accounts:sendOobCode'));
      expect(jsonDecode(calls.single.body), {
        'requestType': 'PASSWORD_RESET',
        'email': 'a@b.lk',
      });
    });

    test(
      'given an unknown email, then the reset still looks successful',
      () async {
        final auth = build(
          (request) async => json({
            'error': {'message': 'EMAIL_NOT_FOUND'},
          }, 400),
        );

        await auth.sendPasswordReset('nobody@b.lk');
      },
    );

    test('given the network fails, then a network error is raised', () async {
      final auth = build((request) async => throw http.ClientException('x'));

      await expectLater(
        auth.signIn(email: 'a@b.lk', password: 'pw'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('Student.fromProfileJson', () {
    test('given a full profile, then every detail is mapped', () {
      final student = Student.fromProfileJson(profile);

      expect(student.studentId, profile['student_id']);
      expect(student.indexNo, 'SE/2021/036');
      expect(student.department, 'Faculty of Science');
      expect(student.phone, '+94 77 000 0036');
      expect(student.year, 2);
      expect(student.roomSummary, 'Block C · C-214 (Bed 2)');
      expect(student.blockLabel, 'Block C');
      expect(student.guardianName, 'Mrs. Ramani Perera');
      expect(student.guardianRelation, 'Mother');
      expect(student.guardianPhone, '+94 77 221 0455');
      expect(student.presence, PresenceStatus.inside);
    });

    test('given IN, OUT, UNKNOWN or nothing, then presence is mapped', () {
      expect(presenceFromString('IN'), PresenceStatus.inside);
      expect(presenceFromString('out'), PresenceStatus.outside);
      expect(presenceFromString('UNKNOWN'), PresenceStatus.unknown);
      expect(presenceFromString(null), PresenceStatus.unknown);
      expect(
        Student.fromProfileJson({...profile, 'presence': null}).presence,
        PresenceStatus.unknown,
      );
    });

    test('given no accommodation or guardians, then they stay empty', () {
      final student = Student.fromProfileJson({
        ...profile,
        'accommodation': null,
        'guardians': <Object>[],
        'contact_phone': '',
        'faculty': '',
        'presence': {'status': 'OUT', 'updated_at': '2026-10-15T10:00:00Z'},
      });

      expect(student.roomSummary, isEmpty);
      expect(student.blockLabel, isNull);
      expect(student.guardianName, isNull);
      expect(student.phone, isNull);
      expect(student.department, isNull);
      expect(student.presence, PresenceStatus.outside);
    });
  });

  group('ApiAuthRepository', () {
    late MemorySessionStore store;
    late Map<String, http.Response> routes;
    late List<String> seen;

    ApiAuthRepository build() {
      final tokenClient = MockClient((request) async {
        if (request.url.path.endsWith('signInWithPassword')) {
          return json({
            'idToken': 'id-1',
            'refreshToken': 'refresh-1',
            'expiresIn': '3600',
          });
        }
        return json({
          'id_token': 'id-1',
          'refresh_token': 'refresh-1',
          'expires_in': '3600',
        });
      });
      final auth = FirebaseAuthService(
        apiKey: 'KEY',
        store: store,
        client: tokenClient,
      );
      final api = ApiClient(
        baseUrl: 'https://api.example.invalid/api/v1',
        client: MockClient((request) async {
          seen.add('${request.method} ${request.url.path}');
          final key = request.url.path.replaceFirst('/api/v1', '');
          return routes[key] ?? json({'error': 'not_found'}, 404);
        }),
        tokens: auth,
      );
      return ApiAuthRepository(auth: auth, api: api);
    }

    setUp(() {
      store = MemorySessionStore();
      seen = [];
      routes = {
        '/me': json({
          'user_id': 'u1',
          'firebase_uid': 'f1',
          'email': 'sanuthi.p@stu.kln.ac.lk',
          'role': 'student',
          'is_active': true,
        }),
        '/me/student-profile': json(profile),
        '/me/setup/complete': json({'setup_required': false}),
      };
    });

    test('given a student account, then the profile is returned', () async {
      final student = await build().login('sanuthi.p@stu.kln.ac.lk', 'pw');

      expect(student.fullName, 'Sanuthi Perera');
      expect(seen, ['GET /api/v1/me', 'GET /api/v1/me/student-profile']);
      expect(await store.read(), 'refresh-1');
    });

    test('given setup is required, then it is completed first', () async {
      routes['/me'] = json({
        'user_id': 'u1',
        'firebase_uid': 'f1',
        'email': 'a@b.lk',
        'role': 'student',
        'is_active': true,
        'setup_required': true,
      });

      await build().login('a@b.lk', 'pw');

      expect(seen, [
        'GET /api/v1/me',
        'POST /api/v1/me/setup/complete',
        'GET /api/v1/me/student-profile',
      ]);
    });

    test('given a staff account, then it is refused and signed out', () async {
      routes['/me'] = json({
        'user_id': 'u1',
        'firebase_uid': 'f1',
        'email': 'w@b.lk',
        'role': 'warden',
        'is_active': true,
      });

      await expectLater(
        build().login('w@b.lk', 'pw'),
        throwsA(isA<AuthException>()),
      );
      expect(await store.read(), isNull);
    });

    test('given no student profile, then the student is told so', () async {
      routes['/me/student-profile'] = json({'error': 'not_found'}, 404);

      await expectLater(
        build().login('a@b.lk', 'pw'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('profile is not set up'),
          ),
        ),
      );
      expect(await store.read(), isNull);
    });

    test('given an inactive student, then the message says so', () async {
      routes['/me/student-profile'] = json({
        'error': 'active_student_required',
      }, 409);

      await expectLater(
        build().login('a@b.lk', 'pw'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('not active'),
          ),
        ),
      );
    });

    test('given a saved session, then the student is restored', () async {
      await store.write('refresh-1');

      final student = await build().currentUser();

      expect(student?.indexNo, 'SE/2021/036');
    });

    test('given no saved session, then there is no student', () async {
      expect(await build().currentUser(), isNull);
      expect(seen, isEmpty);
    });

    test('given a rejected session, then it is cleared', () async {
      await store.write('refresh-1');
      routes['/me'] = json({'error': 'forbidden'}, 403);

      expect(await build().currentUser(), isNull);
      expect(await store.read(), isNull);
    });

    test(
      'given a student without access, then the session is cleared',
      () async {
        await store.write('refresh-1');
        routes['/me'] = json({
          'user_id': 'u1',
          'firebase_uid': 'f1',
          'email': 'w@b.lk',
          'role': 'warden',
          'is_active': true,
        });

        expect(await build().currentUser(), isNull);
        expect(await store.read(), isNull);
      },
    );

    test('given the server is down, then the session is kept', () async {
      await store.write('refresh-1');
      routes['/me'] = json({'error': 'service_unavailable'}, 503);

      await expectLater(build().currentUser(), throwsA(isA<ApiException>()));
      expect(await store.read(), 'refresh-1');
    });

    test('given logout, then the session is cleared', () async {
      final repo = build();
      await repo.login('a@b.lk', 'pw');

      await repo.logout();

      expect(await store.read(), isNull);
    });

    test('given password changes, then the email link is explained', () async {
      final repo = build();

      expect(
        () => repo.changePassword('New#Pass1'),
        throwsA(isA<RepositoryException>()),
      );
      expect(
        () => repo.resetPassword(token: 't', newPassword: 'New#Pass1'),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('given a reset request, then Firebase is asked', () async {
      await build().requestPasswordReset('a@b.lk');
    });
  });

  group('providers', () {
    test('given no settings, then the demo accounts are used', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authRepositoryProvider), isA<MockAuthRepository>());
    });

    test('given the backend settings, then the API repository is used', () {
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              apiBaseUrl: 'https://api.example.invalid/api/v1',
              firebaseApiKey: 'KEY',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(authRepositoryProvider), isA<ApiAuthRepository>());
    });
  });
}
