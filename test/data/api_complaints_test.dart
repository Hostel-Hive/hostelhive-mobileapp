import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/config/app_config.dart';
import 'package:hostelhive_mobile/data/api/api_client.dart';
import 'package:hostelhive_mobile/data/models/complaint.dart';
import 'package:hostelhive_mobile/data/repositories/api_complaint_repository.dart';
import 'package:hostelhive_mobile/data/repositories/complaint_repository.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/features/complaints/providers/complaint_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Token implements TokenSource {
  @override
  Future<String?> idToken({bool forceRefresh = false}) async => 'token';
}

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

const complaintId = '5a1b2c3d-0000-4000-8000-000000000001';
const studentUser = 'user-student';

Map<String, dynamic> complaintJson({String status = 'pending'}) => {
  'complaint_id': complaintId,
  'request_id': 'r1',
  'student_id': 's1',
  'submitted_by': studentUser,
  'category': 'maintenance',
  'description': 'The room light is not working.',
  'status': status,
  'version': 2,
  'created_at': '2026-10-15T14:20:00Z',
  'updated_at': '2026-10-15T14:25:00Z',
};

Map<String, dynamic> updateJson(
  String action, {
  String actor = studentUser,
  String text = '',
  String newStatus = 'pending',
}) => {
  'update_id': 'u-$action',
  'complaint_id': complaintId,
  'request_id': 'r',
  'actor_id': actor,
  'action': action,
  'previous_status': 'pending',
  'new_status': newStatus,
  'text': text,
  'previous_version': 1,
  'version': 2,
  'occurred_at': '2026-10-15T14:25:00Z',
};

void main() {
  late List<http.Request> calls;
  late Future<http.Response> Function(http.Request request) handler;
  late Set<String> unreadable;

  ApiComplaintRepository build() {
    calls = [];
    final api = ApiClient(
      baseUrl: 'https://api.example.invalid/api/v1',
      client: MockClient((request) async {
        calls.add(request);
        return handler(request);
      }),
      tokens: _Token(),
    );
    return ApiComplaintRepository(
      api,
      readFile: (path) async {
        if (unreadable.contains(path)) {
          throw const RepositoryException('unreadable');
        }
        return Uint8List.fromList([1, 2, 3]);
      },
    );
  }

  String path(http.Request r) => r.url.path.replaceFirst('/api/v1', '');

  setUp(() => unreadable = {});

  group('ApiComplaintRepository', () {
    test('given two pages, then every complaint is listed', () async {
      handler = (request) async {
        final offset = request.url.queryParameters['offset'];
        return json({
          'items': [complaintJson()],
          'has_more': offset == '0',
          'total': 2,
        });
      };

      final list = await build().fetchComplaints();

      expect(list, hasLength(2));
      expect(list.first.category, 'Maintenance');
      expect(calls, hasLength(2));
    });

    test('given a complaint, then updates and photos are loaded too', () async {
      handler = (request) async {
        final p = path(request);
        if (p == '/complaints/$complaintId') return json(complaintJson());
        if (p.endsWith('/updates')) {
          return json({
            'items': [
              updateJson('created'),
              updateJson('note', text: 'Still broken'),
              updateJson('status', actor: 'warden', newStatus: 'in_progress'),
              updateJson('image_added', actor: 'warden'),
              updateJson('image_removed'),
              updateJson('other', actor: 'warden'),
              updateJson('note', actor: 'warden', text: 'We are on it'),
            ],
            'has_more': false,
          });
        }
        return json({
          'items': [
            {'image_id': 'img-1'},
            {'image_id': 'img-2'},
          ],
          'version': 2,
        });
      };

      final complaint = await build().fetchComplaint(complaintId);

      expect(complaint.version, 2);
      expect(complaint.imageIds, ['img-1', 'img-2']);
      final texts = complaint.updates.map((u) => u.text).toList();
      expect(texts, [
        'Complaint submitted.',
        'Still broken',
        'Status changed to Ongoing.',
        'A photo was added.',
        'A photo was removed.',
        'Updated.',
        'We are on it',
      ]);
      expect(complaint.updates[1].author, 'You');
      expect(complaint.updates[1].isStudent, isTrue);
      expect(complaint.updates[2].author, 'Hostel staff');
      expect(complaint.updates[0].isSystem, isTrue);
      expect(complaint.updates[3].isSystem, isTrue);
      expect(complaint.updates[1].isSystem, isFalse);
    });

    test(
      'given a complaint with photos, then they upload one by one',
      () async {
        handler = (request) async => request.method == 'POST'
            ? json(complaintJson(), 201)
            : json({'image': {}, 'version': 3, 'replayed': false}, 201);

        final complaint = await build().submitComplaint(
          category: 'Maintenance',
          description: '  The room light is not working. ',
          imagePaths: const ['/a.jpg', '/b.PNG'],
          requestId: 'fixed',
        );

        expect(complaint.id, complaintId);
        final create = calls.first;
        expect(path(create), '/complaints');
        expect(jsonDecode(create.body), {
          'request_id': 'fixed',
          'category': 'maintenance',
          'description': 'The room light is not working.',
        });
        final uploads = calls.skip(1).toList();
        expect(uploads, hasLength(2));
        expect(uploads.every((r) => r.method == 'PUT'), isTrue);
        expect(uploads[0].headers['Content-Type'], 'image/jpeg');
        expect(uploads[1].headers['Content-Type'], 'image/png');
        expect(
          path(uploads[0]),
          startsWith('/complaints/$complaintId/images/'),
        );
        expect(uploads[0].bodyBytes, [1, 2, 3]);
      },
    );

    test(
      'given no request id or photos, then only the create call is made',
      () async {
        handler = (request) async => json(complaintJson(), 201);

        await build().submitComplaint(
          category: 'Disciplinary',
          description: 'Noise',
        );

        expect(calls, hasLength(1));
        expect(jsonDecode(calls.single.body)['request_id'], isNotEmpty);
        expect(jsonDecode(calls.single.body)['category'], 'disciplinary');
      },
    );

    test('given a photo fails, then the saved complaint is reported', () async {
      unreadable = {'/b.jpg'};
      handler = (request) async => request.method == 'POST'
          ? json(complaintJson(), 201)
          : json({'error': 'complaint_images_unavailable'}, 503);

      await expectLater(
        build().submitComplaint(
          category: 'Maintenance',
          description: 'd',
          imagePaths: const ['/a.jpg', '/b.jpg'],
        ),
        throwsA(
          isA<PhotoUploadException>()
              .having((e) => e.complaintId, 'id', complaintId)
              .having((e) => e.failed, 'failed', 2)
              .having((e) => e.message, 'message', contains('2 photos')),
        ),
      );
    });

    test('given one failed photo, then the message is singular', () {
      final e = PhotoUploadException(complaintId: 'c', failed: 1);

      expect(e.message, contains('1 photo could not'));
    });

    test('given a note, then it is posted with the version', () async {
      handler = (request) async =>
          json(updateJson('note', text: 'Still broken'));

      final update = await build().addNote(
        complaintId: complaintId,
        text: ' Still broken ',
        expectedVersion: 2,
        requestId: 'n1',
      );

      expect(path(calls.single), '/complaints/$complaintId/notes');
      expect(jsonDecode(calls.single.body), {
        'request_id': 'n1',
        'expected_version': 2,
        'text': 'Still broken',
      });
      expect(update.isStudent, isTrue);
      expect(update.text, 'Still broken');
    });

    test('given no request id, then a note still gets one', () async {
      handler = (request) async => json(updateJson('note', text: 'x'));

      await build().addNote(
        complaintId: complaintId,
        text: 'x',
        expectedVersion: 1,
      );

      expect(jsonDecode(calls.single.body)['request_id'], isNotEmpty);
    });

    test('given a stale version, then the conflict is explained', () async {
      handler = (request) async => json({'error': 'complaint_conflict'}, 409);

      await expectLater(
        build().addNote(
          complaintId: complaintId,
          text: 'x',
          expectedVersion: 1,
        ),
        throwsA(
          isA<RepositoryException>().having(
            (e) => e.message,
            'message',
            contains('changed'),
          ),
        ),
      );
    });

    test('given a photo id, then its bytes are downloaded', () async {
      handler = (request) async => http.Response.bytes([7, 8, 9], 200);

      final bytes = await build().fetchImage(
        complaintId: complaintId,
        imageId: 'img-1',
      );

      expect(bytes, [7, 8, 9]);
      expect(path(calls.single), '/complaints/$complaintId/images/img-1');
    });
  });

  group('providers', () {
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

      expect(
        container.read(complaintRepositoryProvider),
        isA<ApiComplaintRepository>(),
      );
    });

    test(
      'given a failed photo, then the list still shows the complaint',
      () async {
        final repository = _PhotoFailureRepository();
        final container = ProviderContainer(
          overrides: [
            complaintRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        await container.read(complaintsProvider.future);

        await expectLater(
          container
              .read(complaintsProvider.notifier)
              .submit(category: 'Maintenance', description: 'd'),
          throwsA(isA<PhotoUploadException>()),
        );

        expect(container.read(complaintsProvider).value, hasLength(2));
      },
    );

    test('given a photo id, then the image provider downloads it', () async {
      final container = ProviderContainer(
        overrides: [
          complaintRepositoryProvider.overrideWithValue(
            _PhotoFailureRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final bytes = await container.read(
        complaintImageProvider((complaintId: 'c', imageId: 'i')).future,
      );

      expect(bytes, [4, 5, 6]);
    });
  });
}

class _PhotoFailureRepository extends MockComplaintRepository {
  _PhotoFailureRepository() : super(latency: Duration.zero);

  @override
  Future<Complaint> submitComplaint({
    required String category,
    required String description,
    List<String> imagePaths = const [],
    String? requestId,
  }) async {
    final complaint = await super.submitComplaint(
      category: category,
      description: description,
    );
    throw PhotoUploadException(complaintId: complaint.id, failed: 1);
  }

  @override
  Future<Uint8List> fetchImage({
    required String complaintId,
    required String imageId,
  }) async => Uint8List.fromList([4, 5, 6]);
}
