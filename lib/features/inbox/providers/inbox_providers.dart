import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../data/models/inbox_item.dart';
import '../../../data/repositories/inbox_repository.dart';

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return MockInboxRepository(clock: ref.watch(clockProvider));
});

enum InboxTab { all, announcements, alerts }

List<InboxItem> itemsForTab(List<InboxItem> items, InboxTab tab) {
  switch (tab) {
    case InboxTab.all:
      return items;
    case InboxTab.announcements:
      return items.where((item) => !item.isAlert).toList();
    case InboxTab.alerts:
      return items.where((item) => item.isAlert).toList();
  }
}

int unreadIn(List<InboxItem> items) => items.where((i) => !i.isRead).length;

class InboxNotifier extends AsyncNotifier<List<InboxItem>> {
  InboxRepository get _repository => ref.read(inboxRepositoryProvider);

  @override
  Future<List<InboxItem>> build() => _repository.fetchItems();

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    state = AsyncData(await _repository.fetchItems());
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    state = AsyncData(await _repository.fetchItems());
  }
}

final inboxProvider = AsyncNotifierProvider<InboxNotifier, List<InboxItem>>(
  InboxNotifier.new,
);

/// Number of unread messages, shown as a dot on the Inbox tab.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).maybeWhen(data: unreadIn, orElse: () => 0);
});

final inboxItemProvider = Provider.family<AsyncValue<InboxItem>, String>((
  ref,
  id,
) {
  return ref
      .watch(inboxProvider)
      .whenData(
        (items) => items.firstWhere(
          (item) => item.id == id,
          orElse: () => throw StateError('Message not found'),
        ),
      );
});
