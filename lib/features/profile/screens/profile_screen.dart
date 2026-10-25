import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/student.dart';
import '../../auth/providers/auth_providers.dart';

/// The Me tab: the student's details and sign out (FR007).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to see your QR.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay signed in'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authControllerProvider).student;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Me',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: student == null
          ? const Center(child: Text('Please sign in again.'))
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(authControllerProvider.notifier).refreshProfile(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _Hero(
                    student: student,
                    onShowQr: () => context.push(AppRoutes.qr),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle('Account'),
                  const SizedBox(height: 12),
                  if (student.roomSummary.isNotEmpty)
                    _InfoTile(
                      icon: Icons.home_outlined,
                      color: AppColors.cyan,
                      title: 'Room assignment',
                      subtitle: student.roomSummary,
                    ),
                  if (student.guardianName != null)
                    _InfoTile(
                      icon: Icons.shield_outlined,
                      color: AppColors.success,
                      title: 'Guardian & emergency',
                      subtitle: [
                        student.guardianName,
                        student.guardianPhone,
                      ].whereType<String>().join(' · '),
                    ),
                  _InfoTile(
                    icon: Icons.mail_outline,
                    color: const Color(0xFF8B5CF6),
                    title: 'Contact details',
                    subtitle: [
                      student.email,
                      student.phone,
                    ].whereType<String>().join(' · '),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Change password',
                    isOutlined: true,
                    onPressed: () => context.push(AppRoutes.changePassword),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Sign out',
                    isOutlined: true,
                    isDestructive: true,
                    onPressed: () => _confirmSignOut(context, ref),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.student, required this.onShowQr});

  final Student student;
  final VoidCallback onShowQr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0, -0.6),
          radius: 0.9,
          colors: [AppColors.navyGlow, AppColors.navy],
        ),
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cyan, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: student.photoUrl != null
                ? Image.network(
                    student.photoUrl!,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Text(
                      student.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                : Text(
                    student.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            student.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  student.indexNo,
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    color: AppColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (student.academicSummary.isNotEmpty)
                Text(
                  student.academicSummary,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.cyan,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onShowQr,
              child: const SizedBox(
                width: double.infinity,
                height: 48,
                child: Center(
                  child: Text(
                    'Show my QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
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
