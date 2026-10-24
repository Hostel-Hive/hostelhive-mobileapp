import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/data/models/complaint.dart';
import 'package:hostelhive_mobile/data/models/inbox_item.dart';
import 'package:hostelhive_mobile/data/models/pass.dart';
import 'package:hostelhive_mobile/data/models/student.dart';

Student student({String name = 'Sanuthi Perera'}) => Student(
  studentId: 'STU-0036',
  indexNo: 'SE/2021/036',
  fullName: name,
  email: 'sanuthi.p@stu.kln.ac.lk',
);

void main() {
  group('Student', () {
    test('given a full JSON map, then every field is parsed', () {
      final s = Student.fromJson({
        'student_id': 'STU-1',
        'index_no': 'SE/2021/036',
        'full_name': 'Sanuthi Perera',
        'email': 'a@b.lk',
        'phone': '+94 77',
        'year': 2,
        'department': 'Computer Science',
        'block_code': 'C',
        'block_name': 'Orchid',
        'room_no': 'C-214',
        'bed_no': 'Bed 2',
        'guardian_name': 'Mrs. Perera',
        'guardian_relation': 'Mother',
        'guardian_phone': '+94 71',
        'is_inside': false,
        'must_change_password': true,
      });

      expect(s.isInside, isFalse);
      expect(s.mustChangePassword, isTrue);
      expect(s.roomSummary, 'Block C · Orchid · C-214 (Bed 2)');
      expect(s.academicSummary, 'Year 2 · Computer Science');
      expect(s.blockLabel, 'Block C');
    });

    test('given only required fields, then defaults are applied', () {
      final s = Student.fromJson({
        'student_id': 'STU-1',
        'index_no': 'SE/2021/036',
        'full_name': 'Sanuthi Perera',
        'email': 'a@b.lk',
      });

      expect(s.isInside, isTrue);
      expect(s.mustChangePassword, isFalse);
      expect(s.roomSummary, '');
      expect(s.academicSummary, '');
      expect(s.blockLabel, isNull);
    });

    test('given a room without a bed, then the summary omits the bed', () {
      const s = Student(
        studentId: 'x',
        indexNo: 'y',
        fullName: 'A B',
        email: 'e',
        roomNo: 'C-214',
      );

      expect(s.roomSummary, 'C-214');
    });

    test('given names, then initials are computed safely', () {
      expect(student().initials, 'SP');
      expect(student(name: 'Sanuthi').initials, 'S');
      expect(student(name: '  nethmi   de silva ').initials, 'NS');
      expect(student(name: '').initials, '?');
      expect(student(name: '   ').initials, '?');
    });

    test('given a full name, then firstName is the first word', () {
      expect(student().firstName, 'Sanuthi');
    });

    test('given copyWith, then only the given fields change', () {
      final updated = student().copyWith(
        presence: PresenceStatus.outside,
        mustChangePassword: true,
      );

      expect(updated.isInside, isFalse);
      expect(updated.mustChangePassword, isTrue);
      expect(updated.fullName, 'Sanuthi Perera');
      expect(student().copyWith().isInside, isTrue);
    });
  });

  group('Pass', () {
    final json = {
      'id': 'LA-1',
      'type': 'leave',
      'status': 'APPROVED',
      'title': 'Home visit',
      'departure_at': '2026-04-19T09:00:00.000',
      'return_at': '2026-04-21T18:00:00.000',
      'submitted_at': '2026-04-18T18:00:00.000',
      'decided_at': '2026-04-18T20:00:00.000',
      'decided_by': 'Nisansala R.',
    };

    test('given a JSON map, then it is parsed with a duration label', () {
      final pass = Pass.fromJson(json);

      expect(pass.type, PassType.leave);
      expect(pass.status, PassStatus.approved);
      expect(pass.durationLabel, '2 days 9 hours');
      expect(pass.decidedBy, 'Nisansala R.');
      expect(pass.isActive, isTrue);
    });

    test('given no return time, then duration is null', () {
      final pass = Pass.fromJson({...json}..remove('return_at'));

      expect(pass.duration, isNull);
      expect(pass.durationLabel, isNull);
    });

    test('given missing optional data, then defaults are used', () {
      final pass = Pass.fromJson({
        'id': 'LA-2',
        'type': 'late_access',
        'status': 'unknown',
        'departure_at': '2026-04-19T09:00:00.000',
        'submitted_at': '2026-04-18T18:00:00.000',
      });

      expect(pass.type, PassType.lateAccess);
      expect(pass.status, PassStatus.pending);
      expect(pass.title, 'Pass');
    });

    test('given each status string, then it maps and has a label', () {
      expect(passStatusFromString('rejected'), PassStatus.rejected);
      expect(passStatusFromString('Completed'), PassStatus.completed);
      expect(passStatusFromString('CANCELLED'), PassStatus.cancelled);
      for (final status in PassStatus.values) {
        expect(status.label, isNotEmpty);
      }
    });

    test('given copyWith status, then the pass is updated and inactive', () {
      final pass = Pass.fromJson(json).copyWith(status: PassStatus.cancelled);

      expect(pass.status, PassStatus.cancelled);
      expect(pass.isActive, isFalse);
      expect(pass.id, 'LA-1');
    });
  });

  group('PassQuota', () {
    test('given 12 of 18 days, then the fraction is two thirds', () {
      expect(
        const PassQuota(usedDays: 12, totalDays: 18).fraction,
        closeTo(0.667, 0.001),
      );
    });

    test('given usage above the quota, then the fraction is clamped', () {
      expect(const PassQuota(usedDays: 30, totalDays: 18).fraction, 1);
    });

    test('given a zero quota, then the fraction is zero', () {
      expect(const PassQuota(usedDays: 3, totalDays: 0).fraction, 0);
    });
  });

  group('Complaint', () {
    test('given a JSON map, then it is parsed', () {
      final c = Complaint.fromJson({
        'id': 'CMP-1',
        'category': 'Maintenance',
        'title': 'Exit blocked',
        'description': 'Rack in the way',
        'status': 'in progress',
        'submitted_at': '2026-04-18T10:00:00.000',
        'image_urls': ['a.jpg', 'b.png'],
        'resolution_note': 'Cleared',
      });

      expect(c.status, ComplaintStatus.ongoing);
      expect(c.imagePaths, ['a.jpg', 'b.png']);
      expect(c.resolutionNote, 'Cleared');
    });

    test('given missing optional data, then defaults are used', () {
      final c = Complaint.fromJson({
        'id': 'CMP-2',
        'category': 'Other',
        'title': 't',
        'description': 'd',
        'status': 'whatever',
        'submitted_at': '2026-04-18T10:00:00.000',
      });

      expect(c.status, ComplaintStatus.open);
      expect(c.imagePaths, isEmpty);
    });

    test('given status strings, then they map and have labels', () {
      expect(complaintStatusFromString('COMPLETED'), ComplaintStatus.resolved);
      expect(complaintStatusFromString('resolved'), ComplaintStatus.resolved);
      expect(ComplaintStatus.open.label, 'Open');
      expect(ComplaintStatus.ongoing.label, 'Ongoing');
      expect(ComplaintStatus.resolved.label, 'Completed');
    });

    test('the categories and photo limit match the backend', () {
      expect(complaintCategories, ['Maintenance', 'Disciplinary']);
      expect(complaintCategoryCode('Maintenance'), 'maintenance');
      expect(complaintCategoryLabel('disciplinary'), 'Disciplinary');
      expect(complaintCategoryLabel(''), '');
      expect(maxComplaintImages, 3);
    });

    test('given a long description, then the title is its first line', () {
      expect(complaintTitleFrom('Light broken\nin room C-214'), 'Light broken');
      expect(complaintTitleFrom('  short  '), 'short');
      final long = complaintTitleFrom('x' * 100);
      expect(long.length, 60);
      expect(long, endsWith('...'));
    });

    test('given a backend complaint, then it is mapped', () {
      final c = Complaint.fromBackendJson({
        'complaint_id': '5a1b2c3d-0000-4000-8000-000000000001',
        'category': 'maintenance',
        'description': 'The room light is not working.',
        'status': 'in_progress',
        'version': 3,
        'created_at': '2026-10-15T14:20:00Z',
      });

      expect(c.category, 'Maintenance');
      expect(c.status, ComplaintStatus.ongoing);
      expect(c.version, 3);
      expect(c.title, 'The room light is not working.');
      expect(c.displayId, 'CMP-5A1B2C3D');
    });

    test('given a readable id, then it is shown as it is', () {
      final c = Complaint.fromBackendJson({
        'complaint_id': 'CMP-1',
        'category': 'maintenance',
        'description': 'd',
        'status': 'pending',
        'created_at': '2026-10-15T14:20:00Z',
      });

      expect(c.displayId, 'CMP-1');
      expect(c.version, 1);
      expect(c.status, ComplaintStatus.open);
    });

    test('given copyWith, then only the given fields change', () {
      final c = Complaint.fromBackendJson({
        'complaint_id': 'CMP-1',
        'category': 'maintenance',
        'description': 'd',
        'status': 'pending',
        'created_at': '2026-10-15T14:20:00Z',
      });
      final updated = c.copyWith(version: 4, imageIds: ['i1']);

      expect(updated.version, 4);
      expect(updated.imageIds, ['i1']);
      expect(updated.description, 'd');
      expect(c.copyWith().version, 1);
    });
  });

  group('InboxItem', () {
    final json = {
      'id': 'n1',
      'kind': 'alert',
      'title': 'Return by 22:00',
      'message': 'Curfew reminder',
      'created_at': '2026-04-18T10:00:00.000',
    };

    test('given a JSON map, then it is parsed with defaults', () {
      final item = InboxItem.fromJson(json);

      expect(item.kind, InboxItemKind.alert);
      expect(item.isRead, isFalse);
      expect(item.isAlert, isTrue);
      expect(item.displayTag, 'ALERT');
    });

    test('given no kind, then it is an announcement', () {
      final item = InboxItem.fromJson({...json}..remove('kind'));

      expect(item.kind, InboxItemKind.announcement);
      expect(item.isAlert, isFalse);
      expect(item.displayTag, 'ANNOUNCEMENT');
    });

    test('given an explicit tag, then it is used as the display tag', () {
      final item = InboxItem.fromJson({
        ...json,
        'tag': 'SAFETY',
        'is_read': true,
      });

      expect(item.displayTag, 'SAFETY');
      expect(item.isRead, isTrue);
    });

    test('given kind strings, then they map correctly', () {
      expect(
        inboxKindFromString('complaint_update'),
        InboxItemKind.complaintUpdate,
      );
      expect(inboxKindFromString('LATE_ACCESS'), InboxItemKind.leaveDecision);
      expect(
        inboxKindFromString('leave_decision'),
        InboxItemKind.leaveDecision,
      );
      expect(
        InboxItem.fromJson({...json, 'kind': 'complaint_update'}).displayTag,
        'COMPLAINT',
      );
      expect(
        InboxItem.fromJson({...json, 'kind': 'late_access'}).displayTag,
        'LATE ACCESS',
      );
    });

    test('given copyWith, then isRead changes and the rest is kept', () {
      final read = InboxItem.fromJson(json).copyWith(isRead: true);

      expect(read.isRead, isTrue);
      expect(read.title, 'Return by 22:00');
    });
  });
}
