import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/category_pill.dart';
import '../../../core/widgets/primary_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/inbox_item.dart';
import '../providers/inbox_providers.dart';

/// A single announcement or alert. Opening it marks it as read.
class AnnouncementDetailScreen extends ConsumerStatefulWidget {
  const AnnouncementDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  ConsumerState<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState
    extends ConsumerState<AnnouncementDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(inboxProvider.notifier).markAsRead(widget.itemId),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(inboxItemProvider(widget.itemId));
    final now = ref.watch(clockProvider)();

    return Scaffold(
      backgroundColor: AppColors.formBackground,
      appBar: const PrimaryAppBar(title: 'Message'),
      body: item.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('This message was not found.')),
        data: (item) => _Detail(item: item, now: now, onClose: _close),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.item, required this.now, required this.onClose});

  final InboxItem item;
  final DateTime now;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryPill(label: item.displayTag),
                  const Spacer(),
                  Text(
                    '${formatDate(item.createdAt)} · ${formatTime(item.createdAt)}',
                    style: const TextStyle(
                      fontFamily: AppFonts.mono,
                      color: AppColors.mutedLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.message,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Sent ${relativeTime(item.createdAt, now: now)} · Hostel office',
                style: const TextStyle(
                  color: AppColors.mutedLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Got it', onPressed: onClose),
      ],
    );
  }
}
