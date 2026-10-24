import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/category_pill.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../data/models/inbox_item.dart';
import '../providers/inbox_providers.dart';

/// The Inbox tab: announcements and alerts (UC014).
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  InboxTab _tab = InboxTab.all;

  Future<void> _open(InboxItem item) async {
    await ref.read(inboxProvider.notifier).markAsRead(item.id);
    if (mounted) context.push('/inbox/${item.id}');
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(inboxProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: inbox.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(inboxProvider),
            child: const Text('Could not load your inbox. Tap to retry.'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_none,
              title: 'Inbox is empty',
              description:
                  'Announcements from the warden and updates on your '
                  'requests will show up here',
            );
          }
          final shown = itemsForTab(items, _tab);
          final unread = unreadIn(items);

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            children: [
              _Tabs(
                tab: _tab,
                counts: {
                  for (final t in InboxTab.values)
                    t: itemsForTab(items, t).length,
                },
                onTab: (tab) => setState(() => _tab = tab),
              ),
              if (unread > 0) ...[
                const SizedBox(height: 14),
                _UnreadBanner(count: unread),
              ],
              const SizedBox(height: 16),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No messages here yet',
                      style: TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                  ),
                )
              else
                for (final item in shown) ...[
                  _InboxCard(item: item, now: now, onTap: () => _open(item)),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.counts, required this.onTab});

  final InboxTab tab;
  final Map<InboxTab, int> counts;
  final ValueChanged<InboxTab> onTab;

  static const _labels = {
    InboxTab.all: 'All',
    InboxTab.announcements: 'Announcements',
    InboxTab.alerts: 'Alerts',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final t in InboxTab.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: t == tab,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onTab(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: t == tab ? AppColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          Text(
                            _labels[t]!,
                            style: TextStyle(
                              color: t == tab
                                  ? AppColors.navy
                                  : AppColors.secondary,
                              fontSize: 12,
                              fontWeight: t == tab
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${counts[t] ?? 0}',
                            style: const TextStyle(
                              fontFamily: AppFonts.mono,
                              color: AppColors.mutedLight,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnreadBanner extends StatelessWidget {
  const _UnreadBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.cyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            count == 1
                ? '1 new message since you last checked'
                : '$count new messages since you last checked',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.item,
    required this.now,
    required this.onTap,
  });

  final InboxItem item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? AppColors.cardBorder
                  : AppColors.cyan.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryPill(label: item.displayTag),
                  if (!item.isRead) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      label: 'Unread',
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.cyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    relativeTime(item.createdAt, now: now),
                    style: const TextStyle(
                      fontFamily: AppFonts.mono,
                      color: AppColors.mutedLight,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
