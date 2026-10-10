import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/primary_app_bar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/complaint.dart';
import '../providers/complaint_providers.dart';

class ComplaintDetailScreen extends ConsumerWidget {
  const ComplaintDetailScreen({required this.complaintId, super.key});

  final String complaintId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaint = ref.watch(complaintByIdProvider(complaintId));

    return Scaffold(
      backgroundColor: AppColors.formBackground,
      appBar: PrimaryAppBar(title: '#$complaintId'),
      body: complaint.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('This complaint was not found.')),
        data: (complaint) =>
            _Detail(complaint: complaint, now: ref.watch(clockProvider)()),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.complaint, required this.now});

  final Complaint complaint;
  final DateTime now;

  Color get _tint {
    switch (complaint.status) {
      case ComplaintStatus.open:
        return AppColors.surfaceTint;
      case ComplaintStatus.ongoing:
        return AppColors.warningBg;
      case ComplaintStatus.resolved:
        return AppColors.successSoft;
    }
  }

  Color get _tintBorder {
    switch (complaint.status) {
      case ComplaintStatus.open:
        return AppColors.border;
      case ComplaintStatus.ongoing:
        return AppColors.warning.withValues(alpha: 0.45);
      case ComplaintStatus.resolved:
        return AppColors.success.withValues(alpha: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = complaint.updates.isEmpty
        ? complaint.submittedAt
        : complaint.updates
              .map((u) => u.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _tint,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _tintBorder, width: 1.5),
          ),
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
                  _SeverityTag(complaint.severity),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                complaint.title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _Progress(
                status: complaint.status,
                openedAt: complaint.submittedAt,
                updatedAt: latest,
                now: now,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          complaint.description,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (complaint.imagePaths.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final path in complaint.imagePaths)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(path),
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 76,
                      height: 76,
                      color: AppColors.surfaceTint,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (complaint.resolutionNote != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              complaint.resolutionNote!,
              style: const TextStyle(
                color: AppColors.successDark,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
        if (complaint.updates.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'UPDATES',
            style: TextStyle(
              color: AppColors.mutedLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          for (final update in complaint.updates) ...[
            _UpdateCard(update: update, now: now),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _SeverityTag extends StatelessWidget {
  const _SeverityTag(this.severity);

  final ComplaintSeverity severity;

  @override
  Widget build(BuildContext context) {
    final critical = severity == ComplaintSeverity.critical;
    final high = severity == ComplaintSeverity.high;
    final background = critical
        ? AppColors.dangerSoft
        : high
        ? AppColors.warningSoft
        : AppColors.successSoft;
    final foreground = critical
        ? AppColors.dangerDark
        : high
        ? AppColors.warningDark
        : AppColors.successDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        severity.label.toUpperCase(),
        style: TextStyle(
          fontFamily: AppFonts.mono,
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.status,
    required this.openedAt,
    required this.updatedAt,
    required this.now,
  });

  final ComplaintStatus status;
  final DateTime openedAt;
  final DateTime updatedAt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final step = status.index;
    final steps = [
      ('Open', relativeTime(openedAt, now: now)),
      ('Ongoing', step >= 1 ? relativeTime(updatedAt, now: now) : null),
      ('Completed', step >= 2 ? relativeTime(updatedAt, now: now) : null),
    ];

    Color colorFor(int i) {
      if (i < step || (i == step && status == ComplaintStatus.resolved)) {
        return AppColors.success;
      }
      if (i == step) {
        return status == ComplaintStatus.open
            ? AppColors.success
            : AppColors.warning;
      }
      return AppColors.border;
    }

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: colorFor(i),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: i == 0
                      ? Alignment.centerLeft
                      : i == steps.length - 1
                      ? Alignment.centerRight
                      : Alignment.center,
                  child: _StepLabel(
                    label: steps[i].$1,
                    time: steps[i].$2,
                    done: i < step,
                    color: i <= step && colorFor(i) != AppColors.border
                        ? (colorFor(i) == AppColors.warning
                              ? AppColors.warningDark
                              : AppColors.successDark)
                        : AppColors.mutedLight,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.update, required this.now});

  final ComplaintUpdate update;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: update.isSystem
                  ? AppColors.cyan.withValues(alpha: 0.18)
                  : AppColors.cyan,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: update.isSystem
                ? const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.cyan,
                  )
                : const Text(
                    'SP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      update.author,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (update.isStudent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'STUDENT',
                          style: TextStyle(
                            fontFamily: AppFonts.mono,
                            color: AppColors.secondary,
                            fontSize: 8,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      relativeTime(update.createdAt, now: now),
                      style: const TextStyle(
                        color: AppColors.mutedLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  update.text,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({
    required this.label,
    required this.time,
    required this.done,
    required this.color,
  });

  final String label;
  final String? time;
  final bool done;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (done) Icon(Icons.check, size: 11, color: color),
        if (time != null)
          Text(
            ' · $time',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
