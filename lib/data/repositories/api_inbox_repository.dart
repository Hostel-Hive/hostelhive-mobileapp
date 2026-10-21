import '../api/api_client.dart';
import '../models/inbox_item.dart';
import 'exceptions.dart';
import 'inbox_repository.dart';

/// Announcements and notifications from the backend, shown as one feed.
///
/// Announcements carry the full text. Notifications only have a title and
/// point at a leave, late-access or complaint record, so they become alerts
/// that open that record. The notification about an announcement is not shown
/// twice; it only decides whether the announcement counts as read.
class ApiInboxRepository implements InboxRepository {
  ApiInboxRepository(this._api);

  static const _pageSize = 100;
  static const _maxPages = 10;
  static const _announcementPrefix = 'ann-';

  final ApiClient _api;

  /// Inbox entry to mark read for each feed item, from the latest fetch.
  final Map<String, String> _notificationIds = {};

  @override
  Future<List<InboxItem>> fetchItems() async {
    final announcements = await _pages('/announcements');
    final notifications = await _pages('/notifications');

    final readState = <String, ({String id, bool read})>{};
    final alerts = <InboxItem>[];
    for (final raw in notifications) {
      final json = raw as Map<String, dynamic>;
      final sourceType = json['source_type'] as String;
      if (sourceType == 'announcement') {
        final announcementId = json['announcement_id'] as String?;
        if (announcementId != null) {
          readState[announcementId] = (
            id: json['notification_id'] as String,
            read: json['read_at'] != null,
          );
        }
      } else if (const {
        'leave',
        'late_access',
        'complaint',
      }.contains(sourceType)) {
        alerts.add(_alert(json, sourceType));
      }
    }

    final items = <InboxItem>[
      for (final raw in announcements)
        _announcement(raw as Map<String, dynamic>, readState),
      ...alerts,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _notificationIds
      ..clear()
      ..addEntries(
        items
            .where((item) => item.notificationId != null)
            .map((item) => MapEntry(item.id, item.notificationId!)),
      );
    return items;
  }

  @override
  Future<InboxItem> fetchItem(String id) async {
    final items = await fetchItems();
    return items.firstWhere(
      (item) => item.id == id,
      orElse: () => throw const RepositoryException('Message not found.'),
    );
  }

  @override
  Future<void> markAsRead(String id) async {
    final notificationId = _notificationIds[id];
    if (notificationId == null) return;
    await _api.postJson('/notifications/$notificationId/read');
  }

  InboxItem _announcement(
    Map<String, dynamic> json,
    Map<String, ({String id, bool read})> readState,
  ) {
    final announcementId = json['announcement_id'] as String;
    final state = readState[announcementId];
    return InboxItem(
      id: '$_announcementPrefix$announcementId',
      kind: InboxItemKind.announcement,
      title: json['title'] as String,
      message: json['content'] as String,
      createdAt: DateTime.parse(json['published_at'] as String).toLocal(),
      // An announcement without an inbox entry was never delivered to this
      // student, so there is nothing for them to read-track.
      isRead: state?.read ?? true,
      notificationId: state?.id,
    );
  }

  InboxItem _alert(Map<String, dynamic> json, String sourceType) {
    final (tag, message, kind, sourceId) = switch (sourceType) {
      'leave' => (
        'LEAVE',
        'Open your leave request to see the decision.',
        InboxItemKind.leaveDecision,
        json['leave_id'] as String?,
      ),
      'late_access' => (
        'LATE ACCESS',
        'Open your late access request to see the decision.',
        InboxItemKind.leaveDecision,
        json['late_access_id'] as String?,
      ),
      _ => (
        'COMPLAINT',
        'Open your complaint to see the update.',
        InboxItemKind.complaintUpdate,
        json['complaint_id'] as String?,
      ),
    };

    final notificationId = json['notification_id'] as String;
    return InboxItem(
      id: notificationId,
      kind: kind,
      title: json['title'] as String,
      message: message,
      createdAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
      isRead: json['read_at'] != null,
      tag: tag,
      notificationId: notificationId,
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }

  Future<List<dynamic>> _pages(String path) async {
    final items = <dynamic>[];
    for (var page = 0; page < _maxPages; page++) {
      final body = await _api.getJson(
        path,
        query: {'limit': '$_pageSize', 'offset': '${page * _pageSize}'},
      ) as Map<String, dynamic>;
      final batch = body['items'] as List<dynamic>;
      items.addAll(batch);
      if (body['has_more'] != true || batch.isEmpty) break;
    }
    return items;
  }
}
