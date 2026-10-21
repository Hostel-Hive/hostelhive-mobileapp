import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/attendance.dart';
import '../providers/attendance_providers.dart';

/// Attendance history screen — gate IN/OUT records with timestamps (FR012-013).
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(attendanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            _ErrorBody(onRetry: () => ref.invalidate(attendanceProvider)),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(attendanceProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              _PresenceCard(presence: summary.presence),
              const SizedBox(height: 24),
              if (summary.records.isEmpty)
                const _EmptyHistory()
              else
                ..._grouped(summary.records),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _grouped(List<AttendanceRecord> records) {
    final widgets = <Widget>[];
    String? currentDay;
    for (final r in records) {
      final day = _dayLabel(r.timestamp);
      if (day != currentDay) {
        currentDay = day;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              day,
              style: const TextStyle(
                color: AppColors.mutedLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RecordTile(record: r),
        ),
      );
    }
    return widgets;
  }

  String _dayLabel(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return formatDate(t);
  }
}

class _PresenceCard extends StatelessWidget {
  const _PresenceCard({required this.presence});

  final AttendancePresence presence;

  @override
  Widget build(BuildContext context) {
    final (label, dotColor, bgColor, textColor) = switch (presence) {
      AttendancePresence.inside => (
        'INSIDE',
        AppColors.success,
        AppColors.successSoft,
        AppColors.successDark,
      ),
      AttendancePresence.onLeave => (
        'ON LEAVE',
        AppColors.cyan,
        AppColors.cyanSoft,
        AppColors.cyan,
      ),
      AttendancePresence.outside => (
        'OUTSIDE',
        AppColors.warning,
        AppColors.warningSoft,
        AppColors.warningDark,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Current status',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    color: textColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
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

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final isIn = record.direction == AttendanceDirection.inside;
    final (accentColor, bgColor, icon) = isIn
        ? (AppColors.success, AppColors.successSoft, Icons.login_rounded)
        : (AppColors.warning, AppColors.warningSoft, Icons.logout_rounded);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIn ? 'Entered hostel' : 'Left hostel',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatTime(record.timestamp),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (record.flaggedUnapprovedLate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Late entry',
                style: TextStyle(
                  color: AppColors.dangerDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isIn ? AppColors.successSoft : AppColors.warningSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isIn ? 'IN' : 'OUT',
                style: TextStyle(
                  color: isIn ? AppColors.successDark : AppColors.warningDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: AppColors.mutedLight),
            SizedBox(height: 12),
            Text(
              'No scans yet',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your entries and exits will appear here.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.mutedLight,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load attendance.',
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
