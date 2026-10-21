import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/data/models/complaint.dart';
import 'package:hostelhive_mobile/data/repositories/complaint_repository.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/features/complaints/providers/complaint_providers.dart';
import 'package:hostelhive_mobile/features/complaints/services/image_picker_service.dart';

import '../../helpers/harness.dart';

class FakeImagePicker implements ImagePickerService {
  FakeImagePicker(this.results);

  final List<PickedImage?> results;
  final List<PhotoSource> requested = [];

  @override
  Future<PickedImage?> pick(PhotoSource source) async {
    requested.add(source);
    return results.isEmpty ? null : results.removeAt(0);
  }
}

class RejectingComplaintRepository extends MockComplaintRepository {
  RejectingComplaintRepository()
    : super(clock: () => fixedNow, latency: Duration.zero);

  @override
  Future<Complaint> submitComplaint({
    required String category,
    required String description,
    List<String> imagePaths = const [],
    String? requestId,
  }) async {
    throw const RepositoryException('The warden office is closed.');
  }
}

class ResolvedComplaintRepository extends MockComplaintRepository {
  ResolvedComplaintRepository()
    : super(clock: () => fixedNow, latency: Duration.zero);

  static final _items = [
    Complaint(
      id: 'CMP-0001',
      category: 'Maintenance',
      title: 'Leaking tap',
      description: 'Tap in the corridor leaks.',
      status: ComplaintStatus.resolved,
      submittedAt: fixedNow.subtract(const Duration(days: 3)),
      imagePaths: const ['/missing/photo.jpg'],
      resolutionNote: 'Plumber replaced the tap.',
    ),
    Complaint(
      id: 'CMP-0002',
      category: 'Disciplinary',
      title: 'Loose handle',
      description: 'Door handle is loose.',
      status: ComplaintStatus.open,
      submittedAt: fixedNow.subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  Future<List<Complaint>> fetchComplaints() async => _items;

  @override
  Future<Complaint> fetchComplaint(String id) async =>
      _items.firstWhere((c) => c.id == id);
}

const jpg = PickedImage(path: '/photos/a.jpg', sizeBytes: 1000);

void main() {
  group('validateComplaintImage', () {
    test('given jpg, jpeg and png under 5 MB, then they are accepted', () {
      for (final name in ['a.jpg', 'a.JPEG', 'dir/b.png']) {
        expect(validateComplaintImage(path: name, sizeBytes: 100), isNull);
      }
    });

    test('given another file type, then it is rejected', () {
      expect(
        validateComplaintImage(path: 'a.gif', sizeBytes: 100),
        'Please use a JPG or PNG photo.',
      );
      expect(
        validateComplaintImage(path: 'noextension', sizeBytes: 100),
        isNotNull,
      );
    });

    test('given a photo over 5 MB, then it is rejected', () {
      expect(
        validateComplaintImage(path: 'a.jpg', sizeBytes: maxImageBytes + 1),
        contains('larger than 5 MB'),
      );
      expect(
        validateComplaintImage(path: 'a.jpg', sizeBytes: maxImageBytes),
        isNull,
      );
    });
  });

  group('providers', () {
    test('submit adds the complaint to the list', () async {
      final container = ProviderContainer(
        overrides: [
          complaintRepositoryProvider.overrideWithValue(
            MockComplaintRepository(
              clock: () => fixedNow,
              latency: Duration.zero,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(complaintsProvider.future);

      final created = await container
          .read(complaintsProvider.notifier)
          .submit(
            category: 'Maintenance',
            description: 'Water leak\nin the hall',
          );

      expect(created.id, 'CMP-0143');
      expect(container.read(complaintsProvider).value!.length, 2);
      final detail = await container.read(
        complaintDetailProvider('CMP-0143').future,
      );
      expect(detail.title, 'Water leak');
      await expectLater(
        container.read(complaintDetailProvider('nope').future),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('the default providers can be created', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(complaintRepositoryProvider),
        isA<ComplaintRepository>(),
      );
      expect(
        container.read(imagePickerServiceProvider),
        isA<ImagePickerService>(),
      );
    });
  });

  group('Submit complaint', () {
    Future<FakeImagePicker> openForm(
      WidgetTester tester, {
      List<PickedImage?> photos = const [],
      List<Override> overrides = const [],
    }) async {
      final picker = FakeImagePicker([...photos]);
      await pumpApp(
        tester,
        overrides: [
          complaintRepositoryProvider.overrideWithValue(
            MockComplaintRepository(
              clock: () => fixedNow,
              latency: Duration.zero,
            ),
          ),
          imagePickerServiceProvider.overrideWithValue(picker),
          ...overrides,
        ],
      );
      await pushTo(tester, AppRoutes.newComplaint);
      return picker;
    }

    Future<void> fillText(WidgetTester tester) async {
      await tester.enterText(
        find.byType(TextFormField).first,
        'Water on the floor',
      );
    }

    testWidgets(
      'given the form is empty, then category and description are required',
      (tester) async {
        await openForm(tester);

        await tester.tap(find.text('Submit complaint'));
        await tester.pump();

        expect(find.text('Choose a category'), findsOneWidget);
        expect(find.text('Description is required'), findsOneWidget);
      },
    );

    testWidgets('given the form, then both categories are offered', (
      tester,
    ) async {
      await openForm(tester);

      expect(find.text('Maintenance'), findsOneWidget);
      expect(find.text('Disciplinary'), findsOneWidget);
      expect(find.text('Severity'), findsNothing);
      expect(find.text('Short title'), findsNothing);
    });

    testWidgets(
      'given a valid complaint, then it is submitted and can be viewed',
      (tester) async {
        await openForm(tester);

        await tester.tap(find.text('Maintenance'));
        await fillText(tester);
        await tester.tap(find.text('Submit complaint'));
        await tester.pumpAndSettle();

        expect(find.text('Complaint submitted'), findsWidgets);
        expect(find.text('CMP-0143'), findsOneWidget);

        await tester.tap(find.text('View complaint'));
        await tester.pumpAndSettle();

        expect(find.text('#CMP-0143'), findsOneWidget);
        expect(find.text('Water on the floor'), findsWidgets);
        expect(find.text('Routed to the Maintenance team.'), findsOneWidget);
      },
    );

    testWidgets('given Back to Home on the confirmation, then home opens', (
      tester,
    ) async {
      await openForm(tester);
      await tester.tap(find.text('Disciplinary'));
      await fillText(tester);
      await tester.tap(find.text('Submit complaint'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();

      expect(find.text('Hello, Sanuthi'), findsOneWidget);
    });

    testWidgets('given a gallery photo, then it is added and can be removed', (
      tester,
    ) async {
      final picker = await openForm(tester, photos: [jpg]);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

      expect(picker.requested, [PhotoSource.gallery]);
      expect(find.text('1 / 3 added'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove photo 1'));
      await tester.pump();
      expect(find.text('0 / 3 added'), findsOneWidget);
    });

    testWidgets('given a camera photo, then the camera source is used', (
      tester,
    ) async {
      final picker = await openForm(tester, photos: [jpg]);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();

      expect(picker.requested, [PhotoSource.camera]);
      expect(find.text('1 / 3 added'), findsOneWidget);
    });

    testWidgets('given the photo choice is cancelled, then nothing is added', (
      tester,
    ) async {
      final picker = await openForm(tester);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

      expect(picker.requested.length, 1);
      expect(find.text('0 / 3 added'), findsOneWidget);
    });

    testWidgets(
      'given the photo sheet is dismissed, then the picker is not used',
      (tester) async {
        final picker = await openForm(tester, photos: [jpg]);

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(picker.requested, isEmpty);
      },
    );

    testWidgets(
      'given an unsupported photo, then an error shows and it is not added',
      (tester) async {
        await openForm(
          tester,
          photos: [const PickedImage(path: '/photos/a.gif', sizeBytes: 100)],
        );

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose from gallery'));
        await tester.pumpAndSettle();

        expect(find.text('Please use a JPG or PNG photo.'), findsOneWidget);
        expect(find.text('0 / 3 added'), findsOneWidget);
      },
    );

    testWidgets('given an oversized photo, then an error shows', (
      tester,
    ) async {
      await openForm(
        tester,
        photos: [
          const PickedImage(
            path: '/photos/a.jpg',
            sizeBytes: maxImageBytes + 1,
          ),
        ],
      );

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();

      expect(find.textContaining('larger than 5 MB'), findsOneWidget);
    });

    testWidgets('given three photos, then the add tile disappears', (
      tester,
    ) async {
      await openForm(
        tester,
        photos: [
          for (var i = 0; i < 3; i++)
            PickedImage(path: '/p/$i.png', sizeBytes: 10),
        ],
      );

      for (var i = 0; i < 3; i++) {
        await tester.ensureVisible(find.text('Add'));
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choose from gallery'));
        await tester.pumpAndSettle();
      }

      expect(find.text('3 / 3 added'), findsOneWidget);
      expect(find.text('Add'), findsNothing);
    });

    testWidgets(
      'given the repository rejects the complaint, then its message shows',
      (tester) async {
        await openForm(
          tester,
          overrides: [
            complaintRepositoryProvider.overrideWithValue(
              RejectingComplaintRepository(),
            ),
          ],
        );
        await tester.tap(find.text('Maintenance'));
        await fillText(tester);

        await tester.tap(find.text('Submit complaint'));
        await tester.pumpAndSettle();

        expect(find.text('The warden office is closed.'), findsOneWidget);
        expect(find.text('Complaint submitted'), findsNothing);
      },
    );

    testWidgets('given the home button, then the form opens', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Report an issue'));
      await tester.pumpAndSettle();

      expect(find.text('Submit complaint'), findsOneWidget);
    });
  });

  group('Complaint detail', () {
    testWidgets(
      'given the seeded complaint, then status, updates and progress show',
      (tester) async {
        await pumpApp(
          tester,
          overrides: [
            complaintRepositoryProvider.overrideWithValue(
              MockComplaintRepository(
                clock: () => fixedNow,
                latency: Duration.zero,
              ),
            ),
          ],
        );
        await pushTo(tester, '/complaints/CMP-0142');

        expect(find.text('#CMP-0142'), findsOneWidget);
        expect(find.text('Emergency exit blocked'), findsOneWidget);
        expect(find.text('ONGOING'), findsOneWidget);
        expect(find.text('UPDATES'), findsOneWidget);
        expect(find.text('STUDENT'), findsOneWidget);
        expect(find.text('Original report with 4 photos.'), findsOneWidget);
        expect(find.text('Routed to the Maintenance team.'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      },
    );

    testWidgets('given a resolved complaint, then the note and photos show', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          complaintRepositoryProvider.overrideWithValue(
            ResolvedComplaintRepository(),
          ),
        ],
      );
      await pushTo(tester, '/complaints/CMP-0001');

      expect(find.text('Plumber replaced the tap.'), findsOneWidget);
      expect(find.text('Leaking tap'), findsOneWidget);
      expect(find.text('UPDATES'), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('given an open complaint, then only the first step is done', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          complaintRepositoryProvider.overrideWithValue(
            ResolvedComplaintRepository(),
          ),
        ],
      );
      await pushTo(tester, '/complaints/CMP-0002');

      expect(find.text('OPEN'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('given an unknown complaint, then a not found message shows', (
      tester,
    ) async {
      await pumpApp(tester);
      await pushTo(tester, '/complaints/NOPE');

      expect(find.text('This complaint was not found.'), findsOneWidget);
    });

    testWidgets('given the complaints list path, then it redirects home', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, '/complaints');

      expect(find.text('Hello, Sanuthi'), findsOneWidget);
    });
  });
}
