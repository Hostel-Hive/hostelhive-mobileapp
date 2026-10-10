import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/pass.dart';

/// "LA-2418" style identifier shown in monospace.
class PassIdText extends StatelessWidget {
  const PassIdText(this.id, {super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Text(
      id,
      style: const TextStyle(
        fontFamily: AppFonts.mono,
        color: AppColors.mutedLight,
        fontSize: 11,
        letterSpacing: 1,
      ),
    );
  }
}

class PassStatusBadge extends StatelessWidget {
  const PassStatusBadge(this.status, {super.key});

  final PassStatus status;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(status: status.name, label: status.label);
  }
}

/// DEPART and RETURN times with an arrow between them.
class DepartReturnBlock extends StatelessWidget {
  const DepartReturnBlock({
    required this.pass,
    this.compact = false,
    super.key,
  });

  final Pass pass;

  /// Compact shows "Fri 19 · 09:00" on one line, as on the passes list.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final returnAt = pass.returnAt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Time(
              label: 'DEPART',
              time: pass.departureAt,
              compact: compact,
            ),
          ),
          Icon(
            Icons.arrow_forward,
            size: 20,
            color: compact ? AppColors.mutedLight : AppColors.cyan,
          ),
          Expanded(
            child: returnAt == null
                ? const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Open',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  )
                : _Time(
                    label: 'RETURN',
                    time: returnAt,
                    compact: compact,
                    alignEnd: true,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Time extends StatelessWidget {
  const _Time({
    required this.label,
    required this.time,
    required this.compact,
    this.alignEnd = false,
  });

  final String label;
  final DateTime time;
  final bool compact;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final day = compact
        ? '${formatDayMonth(time).split(' ').take(2).join(' ')} · ${formatTime(time)}'
        : formatDayMonth(time);

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.mutedLight,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: const TextStyle(
            fontFamily: AppFonts.mono,
            color: AppColors.navy,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!compact)
          Text(
            formatTime(time),
            style: const TextStyle(
              fontFamily: AppFonts.mono,
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

/// The large highlighted card for an active or pending pass.
class PassCard extends StatelessWidget {
  const PassCard({required this.pass, required this.onView, super.key});

  final Pass pass;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [PassIdText(pass.id), PassStatusBadge(pass.status)],
          ),
          const SizedBox(height: 10),
          Text(
            pass.title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          DepartReturnBlock(pass: pass, compact: true),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View pass details',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact row for the history list.
class PassHistoryRow extends StatelessWidget {
  const PassHistoryRow({required this.pass, required this.onTap, super.key});

  final Pass pass;
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
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pass.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PassIdText(pass.id),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(pass.departureAt),
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        color: AppColors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PassStatusBadge(pass.status),
            ],
          ),
        ),
      ),
    );
  }
}
