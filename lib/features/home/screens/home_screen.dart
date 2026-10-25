import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/pass.dart';
import '../../../data/models/student.dart';
import '../../auth/providers/auth_providers.dart';
import '../../inbox/providers/inbox_providers.dart';
import '../../passes/providers/pass_providers.dart';
import '../../passes/widgets/pass_widgets.dart';
import '../../profile/widgets/student_avatar.dart';
import '../utils/curfew.dart';

/// The pass shown on the dashboard: a pending request first, otherwise an
/// approved pass that has not ended yet. Going home leaves are excluded
/// because they are shown as the student's OUT status instead.
Pass? activeRequest(List<Pass> passes, DateTime now) {
  final candidates = passes.where((pass) => pass.type != PassType.goingHome);
  for (final tab in [PassTab.pending, PassTab.active]) {
    for (final pass in candidates) {
      if (tabOf(pass, now) == tab) return pass;
    }
  }
  return null;
}

/// The Home tab: status, quick actions and the active request (UC001, UC009).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _goingHome(BuildContext context, PresenceStatus status) {
    final blocked = switch (status) {
      PresenceStatus.outside => 'You are already marked as out.',
      PresenceStatus.unknown =>
        'Your status is unknown. Scan your ID at the gate first.',
      PresenceStatus.inside => null,
    };
    if (blocked != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(blocked)));
      return;
    }
    context.push(AppRoutes.goingHome);
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(passesProvider);
    ref.invalidate(inboxProvider);
    await ref.read(authControllerProvider.notifier).refreshProfile();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authControllerProvider).student;
    final now = ref.watch(clockProvider)();
    final passes = ref.watch(passesProvider).valueOrNull ?? const <Pass>[];
    final unread = ref.watch(unreadCountProvider);
    // The presence badge always reflects the backend's actual gate-scan
    // status, never the declaration itself — a "Going home" confirmation
    // only records intent and does not move the student OUT (SDS: only a
    // gate scan does). When a declaration is still open and the student is
    // still recorded as inside, a separate reminder nudges them to scan.
    final status = student?.presence ?? PresenceStatus.unknown;
    final pendingGoingHome =
        status == PresenceStatus.inside && isOutsideOnLeave(passes);
    final active = activeRequest(passes, now);

    if (student == null) {
      return const Center(child: Text('Please sign in again.'));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              _Header(
                student: student,
                greeting: greetingFor(now),
                hasUnread: unread > 0,
                onBell: () => context.go(AppRoutes.inbox),
              ),
              const SizedBox(height: 20),
              _StatusCard(
                student: student,
                now: now,
                status: status,
                onHistory: () => context.push(AppRoutes.attendance),
              ),
              if (pendingGoingHome) ...[
                const SizedBox(height: 12),
                _GoingHomeReminder(onScan: () => context.push(AppRoutes.qr)),
              ],
              const SizedBox(height: 24),
              const _SectionTitle('Quick actions'),
              const SizedBox(height: 12),
              _QuickActions(onGoingHome: () => _goingHome(context, status)),
              if (active != null) ...[
                const SizedBox(height: 24),
                const _SectionTitle('Active request'),
                const SizedBox(height: 12),
                PassCard(
                  pass: active,
                  onView: () => context.push('/passes/${active.id}'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.student,
    required this.greeting,
    required this.hasUnread,
    required this.onBell,
  });

  final Student student;
  final String greeting;
  final bool hasUnread;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StudentAvatar(student: student, size: 44, fontSize: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              Text(
                'Hello, ${student.firstName}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                fixedSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
              icon: const Icon(
                Icons.notifications_none,
                size: 22,
                color: AppColors.ink,
              ),
              onPressed: onBell,
            ),
            if (hasUnread)
              Positioned(
                top: 10,
                right: 11,
                child: Semantics(
                  label: 'Unread messages',
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Shown on Home when the student declared Going Home but is still recorded
/// as inside — they have not scanned out at the gate yet.
class _GoingHomeReminder extends StatelessWidget {
  const _GoingHomeReminder({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onScan,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.warningSoft),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 20,
                color: AppColors.warningDark,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You declared Going Home but have not scanned out yet. '
                  'Scan your QR at the gate when you leave.',
                  style: TextStyle(
                    color: AppColors.warningDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppColors.warningDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.student,
    required this.now,
    required this.status,
    required this.onHistory,
  });

  final Student student;
  final DateTime now;
  final PresenceStatus status;
  final VoidCallback onHistory;

  static const _headline = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final accent = switch (status) {
      PresenceStatus.inside => AppColors.success,
      PresenceStatus.outside => AppColors.warning,
      PresenceStatus.unknown => AppColors.mutedLight,
    };
    final room = student.roomNo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.3, -0.2),
          radius: 0.9,
          colors: [AppColors.navyGlow, AppColors.navy],
        ),
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BULUGAHA GIRLS' HOSTEL · UNIVERSITY OF KELANIYA",
            style: TextStyle(
              fontFamily: AppFonts.mono,
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  switch (status) {
                    PresenceStatus.inside => 'SIGNED IN',
                    PresenceStatus.outside => 'OUT',
                    PresenceStatus.unknown => 'STATUS UNKNOWN',
                  },
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    color: accent,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (status == PresenceStatus.outside) ...[
            const Text('You’re out of the hostel.', style: _headline),
            const SizedBox(height: 6),
            const Text(
              'Scan your ID at the gate when you return.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ] else if (status == PresenceStatus.unknown) ...[
            const Text('Your status is unknown.', style: _headline),
            const SizedBox(height: 6),
            const Text(
              'Scan your ID at the gate to update it.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ] else ...[
            Text(
              student.blockLabel == null
                  ? 'You’re in your room.'
                  : 'You’re in ${student.blockLabel},',
              style: _headline,
            ),
            if (room != null)
              Text(
                'Room $room.',
                style: _headline.copyWith(
                  color: AppColors.cyan,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onHistory,
              child: Text(
                'View history',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.mutedLight,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onGoingHome});

  final VoidCallback onGoingHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                label: 'Show my QR',
                icon: Icons.qr_code_2,
                primary: true,
                onTap: () => context.push(AppRoutes.qr),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                label: 'Request a pass',
                icon: Icons.event_available_outlined,
                onTap: () => context.push(AppRoutes.requestLateAccess),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                label: 'Going home',
                icon: Icons.home_outlined,
                onTap: onGoingHome,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                label: 'My complaints',
                icon: Icons.warning_amber_rounded,
                danger: true,
                onTap: () => context.push(AppRoutes.complaints),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final foreground = primary
        ? Colors.white
        : danger
        ? AppColors.danger
        : AppColors.ink;

    return Material(
      color: primary ? AppColors.cyan : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: primary ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 24, color: foreground),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
