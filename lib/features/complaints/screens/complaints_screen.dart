import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/complaint.dart';
import '../providers/complaint_providers.dart';

/// Complaints list screen (UC012): shows all submitted complaints with status.
class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaints = ref.watch(complaintsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My complaints',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Report an issue',
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        highlightElevation: 3,
        onPressed: () => context.push(AppRoutes.newComplaint),
        child: const Icon(Icons.add),
      ),
      body: complaints.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(complaintsProvider),
            child: const Text('Could not load complaints. Tap to retry.'),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.report_problem_outlined,
              title: 'No complaints yet',
              description:
                  'Report a maintenance or disciplinary issue and it will '
                  'appear here.',
              buttonLabel: 'Report an issue',
              onButtonPressed: () => context.push(AppRoutes.newComplaint),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(complaintsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 96),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ComplaintRow(
                complaint: list[i],
                now: ref.watch(clockProvider)(),
                onTap: () => context.push('/complaints/${list[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ComplaintRow extends StatelessWidget {
  const _ComplaintRow({
    required this.complaint,
    required this.now,
    required this.onTap,
  });

  final Complaint complaint;
  final DateTime now;
  final VoidCallback onTap;

  Color get _borderColor {
    switch (complaint.status) {
      case ComplaintStatus.open:
        return AppColors.cardBorder;
      case ComplaintStatus.ongoing:
        return AppColors.warning.withValues(alpha: 0.45);
      case ComplaintStatus.resolved:
        return AppColors.success.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(
                          status: complaint.status.name,
                          label: complaint.status.label,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          complaint.category.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: AppFonts.mono,
                            color: AppColors.mutedLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      complaint.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${complaint.displayId} · ${relativeTime(complaint.submittedAt, now: now)}',
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        color: AppColors.mutedLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right,
                color: AppColors.mutedLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
