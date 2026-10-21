import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/router/app_router.dart';
import 'package:hostelhive_mobile/data/models/complaint.dart';
import 'package:hostelhive_mobile/data/repositories/complaint_repository.dart';
import 'package:hostelhive_mobile/data/repositories/exceptions.dart';
import 'package:hostelhive_mobile/features/complaints/providers/complaint_providers.dart';

import '../../helpers/harness.dart';

const _tinyPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xFF,
  0xFF,
  0x3F,
  0x00,
  0x05,
  0xFE,
  0x02,
  0xFE,
  0xA7,
  0x35,
  0x81,
  0x84,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

/// A complaint with two photos on the backend, and a note that is refused.
class PhotoComplaintRepository extends MockComplaintRepository {
  PhotoComplaintRepository({this.failImage = false})
    : super(clock: () => fixedNow, latency: Duration.zero);

  final bool failImage;

  @override
  Future<Complaint> fetchComplaint(String id) async {
    final complaint = await super.fetchComplaint(id);
    return complaint.copyWith(imageIds: const ['i1', 'i2']);
  }

  @override
  Future<Uint8List> fetchImage({
    required String complaintId,
    required String imageId,
  }) async {
    if (failImage) throw const RepositoryException('gone');
    return Uint8List.fromList(_tinyPng);
  }

  @override
  Future<ComplaintUpdate> addNote({
    required String complaintId,
    required String text,
    required int expectedVersion,
    String? requestId,
  }) {
    throw const RepositoryException('The complaint changed. Try again.');
  }
}

class PartialUploadRepository extends MockComplaintRepository {
  PartialUploadRepository()
    : super(clock: () => fixedNow, latency: Duration.zero);

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
}

void main() {
  group('Complaint notes', () {
    testWidgets('given an open complaint, then a note can be added', (
      tester,
    ) async {
      await pumpApp(tester);
      await pushTo(tester, '/complaints/CMP-0142');

      await tester.enterText(find.byType(TextField), 'Still blocked');
      await tester.tap(find.byTooltip('Send note'));
      await tester.pumpAndSettle();

      expect(find.text('Still blocked'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    });

    testWidgets('given an empty note, then nothing is sent', (tester) async {
      await pumpApp(tester);
      await pushTo(tester, '/complaints/CMP-0142');

      await tester.tap(find.byTooltip('Send note'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('given the backend refuses the note, then it says why', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          complaintRepositoryProvider.overrideWithValue(
            PhotoComplaintRepository(),
          ),
        ],
      );
      await pushTo(tester, '/complaints/CMP-0142');

      await tester.enterText(find.byType(TextField), 'Still blocked');
      await tester.tap(find.byTooltip('Send note'));
      await tester.pumpAndSettle();

      expect(find.text('The complaint changed. Try again.'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Still blocked',
      );
    });
  });

  group('Complaint photos from the backend', () {
    testWidgets('given photo ids, then each image is downloaded', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          complaintRepositoryProvider.overrideWithValue(
            PhotoComplaintRepository(),
          ),
        ],
      );
      await pushTo(tester, '/complaints/CMP-0142');

      expect(find.byType(Image), findsNWidgets(2));
    });

    testWidgets('given a photo fails to load, then a placeholder shows', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          complaintRepositoryProvider.overrideWithValue(
            PhotoComplaintRepository(failImage: true),
          ),
        ],
      );
      await pushTo(tester, '/complaints/CMP-0142');

      expect(find.byIcon(Icons.broken_image_outlined), findsNWidgets(2));
    });
  });

  group('Partial upload', () {
    testWidgets('given a photo fails, then the saved complaint is confirmed', (
      tester,
    ) async {
      await pumpApp(
        tester,
        overrides: [
          complaintRepositoryProvider.overrideWithValue(
            PartialUploadRepository(),
          ),
        ],
      );
      await pushTo(tester, AppRoutes.newComplaint);

      await tester.tap(find.text('Maintenance'));
      await tester.enterText(find.byType(TextFormField).first, 'Water leak');
      await tester.tap(find.text('Submit complaint'));
      await tester.pumpAndSettle();

      expect(find.text('Complaint submitted'), findsWidgets);
      expect(
        find.text(
          'Your complaint was sent, but 1 photo could not be uploaded.',
        ),
        findsOneWidget,
      );
    });
  });
}
