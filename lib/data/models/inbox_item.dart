/// ANNOUNCEMENT and NOTIFICATION entities (SDS 2.2.7) shown as one feed in
/// the Inbox (UC014).
enum InboxItemKind { announcement, alert, complaintUpdate, leaveDecision }

InboxItemKind inboxKindFromString(String value) {
  switch (value.toUpperCase()) {
    case 'ALERT':
      return InboxItemKind.alert;
    case 'COMPLAINT_UPDATE':
      return InboxItemKind.complaintUpdate;
    case 'LEAVE_DECISION':
    case 'LATE_ACCESS':
      return InboxItemKind.leaveDecision;
    default:
      return InboxItemKind.announcement;
  }
}

class InboxItem {
  const InboxItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.tag,
    this.notificationId,
    this.sourceType,
    this.sourceId,
  });

  factory InboxItem.fromJson(Map<String, dynamic> json) {
    return InboxItem(
      id: json['id'] as String,
      kind: inboxKindFromString(json['kind'] as String? ?? 'announcement'),
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      tag: json['tag'] as String?,
    );
  }

  final String id;
  final InboxItemKind kind;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  /// Category pill such as SAFETY, FACILITIES or LATE ACCESS.
  final String? tag;

  /// The backend inbox entry to mark as read, when there is one.
  final String? notificationId;

  /// What an alert is about (`leave`, `late_access` or `complaint`) and the id
  /// of that record, so the alert can open it.
  final String? sourceType;
  final String? sourceId;

  /// The screen that shows the record behind an alert, if it has one.
  String? get sourceRoute {
    final id = sourceId;
    if (id == null) return null;
    switch (sourceType) {
      case 'leave':
      case 'late_access':
        return '/passes/$id';
      case 'complaint':
        return '/complaints/$id';
      default:
        return null;
    }
  }

  /// Everything except plain announcements is shown under the Alerts tab.
  bool get isAlert => kind != InboxItemKind.announcement;

  String get displayTag {
    if (tag != null) return tag!;
    switch (kind) {
      case InboxItemKind.announcement:
        return 'ANNOUNCEMENT';
      case InboxItemKind.alert:
        return 'ALERT';
      case InboxItemKind.complaintUpdate:
        return 'COMPLAINT';
      case InboxItemKind.leaveDecision:
        return 'LATE ACCESS';
    }
  }

  InboxItem copyWith({bool? isRead}) {
    return InboxItem(
      id: id,
      kind: kind,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      tag: tag,
      notificationId: notificationId,
      sourceType: sourceType,
      sourceId: sourceId,
    );
  }
}
