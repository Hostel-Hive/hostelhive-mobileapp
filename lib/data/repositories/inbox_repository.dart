import '../models/inbox_item.dart';
import 'exceptions.dart';

/// Announcements and notifications (FR028 to FR032, UC014).
abstract class InboxRepository {
  Future<List<InboxItem>> fetchItems();
  Future<InboxItem> fetchItem(String id);
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class MockInboxRepository implements InboxRepository {
  MockInboxRepository({
    DateTime Function()? clock,
    this.latency = const Duration(milliseconds: 300),
  }) : _clock = clock ?? DateTime.now {
    final now = _clock();
    _items.addAll([
      InboxItem(
        id: 'n1',
        kind: InboxItemKind.announcement,
        tag: 'SAFETY',
        title: 'Curfew drill — Saturday night',
        message:
            '10-minute evacuation drill this Saturday at 22:05. '
            'Gather at courtyard.',
        createdAt: now.subtract(const Duration(minutes: 2)),
      ),
      InboxItem(
        id: 'n2',
        kind: InboxItemKind.leaveDecision,
        tag: 'LATE ACCESS',
        title: 'Your LA-2418 was approved',
        message: 'Warden Nisansala approved your home visit request. Enjoy!',
        createdAt: now.subtract(const Duration(minutes: 22)),
      ),
      InboxItem(
        id: 'n3',
        kind: InboxItemKind.announcement,
        tag: 'FACILITIES',
        title: 'Laundry schedule change',
        message: 'Block A laundry now available Tue/Fri only.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      InboxItem(
        id: 'n4',
        kind: InboxItemKind.announcement,
        title: 'Mess menu update',
        message: 'Friday dinner: chicken curry + kottu.',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      InboxItem(
        id: 'n5',
        kind: InboxItemKind.alert,
        title: 'Return by 22:00',
        message:
            'Curfew is at 22:00. Late entries without an approved pass '
            'are flagged to the warden.',
        createdAt: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ]);
  }

  final DateTime Function() _clock;
  final Duration latency;
  final List<InboxItem> _items = [];

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<List<InboxItem>> fetchItems() async {
    await _wait();
    final sorted = [..._items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

  @override
  Future<InboxItem> fetchItem(String id) async {
    await _wait();
    return _items.firstWhere(
      (item) => item.id == id,
      orElse: () => throw const RepositoryException('Message not found.'),
    );
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(isRead: true);
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
  }
}
