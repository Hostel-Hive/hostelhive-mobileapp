import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/primary_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/pass.dart';
import '../../../data/repositories/exceptions.dart';
import '../providers/pass_providers.dart';
import '../widgets/pass_widgets.dart';

class PassDetailScreen extends ConsumerWidget {
  const PassDetailScreen({required this.passId, super.key});

  final String passId;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this pass?'),
        content: const Text('The warden will no longer see this request.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep pass'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel pass'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(passesProvider.notifier).cancelPass(passId);
    } on RepositoryException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pass = ref.watch(passByIdProvider(passId));

    return Scaffold(
      backgroundColor: AppColors.formBackground,
      appBar: PrimaryAppBar(
        title: 'Pass $passId',
        actions: [
          IconButton(
            tooltip: 'About passes',
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('About passes'),
                content: const Text(
                  'Late access and going home passes tell the warden and the '
                  'gate system when you are away.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: pass.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('This pass was not found.')),
        data: (pass) => _Detail(
          pass: pass,
          now: ref.watch(clockProvider)(),
          onCancel: () => _cancel(context, ref),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.pass,
    required this.now,
    required this.onCancel,
  });

  final Pass pass;
  final DateTime now;
  final VoidCallback onCancel;

  Color get _accent {
    switch (pass.status) {
      case PassStatus.approved:
      case PassStatus.completed:
        return AppColors.success;
      case PassStatus.pending:
        return AppColors.warning;
      case PassStatus.rejected:
      case PassStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final decidedBy = pass.decidedBy;
    final decidedAt = pass.decidedAt;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _accent, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PassIdText(pass.id),
                        PassStatusBadge(pass.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      pass.title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (decidedBy != null && decidedAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${pass.status == PassStatus.rejected ? 'Rejected' : 'Approved'} '
                        'by $decidedBy · ${relativeTime(decidedAt, now: now)}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    DepartReturnBlock(pass: pass),
                    if (pass.durationLabel != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'DURATION',
                            style: TextStyle(
                              color: AppColors.mutedLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            pass.durationLabel!,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DetailsCard(pass: pass),
              if (pass.wardenComment != null) ...[
                const SizedBox(height: 16),
                _WardenNote(
                  initials: _initials(decidedBy),
                  comment: pass.wardenComment!,
                ),
              ],
            ],
          ),
        ),
        if (pass.isActive)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'Cancel pass',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (pass.status == PassStatus.approved)
                  Expanded(
                    child: PrimaryButton(
                      label: 'Show my QR',
                      onPressed: () => context.push(AppRoutes.qr),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return 'W';
    final parts = name.split(RegExp(r'[\s.]+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.pass});

  final Pass pass;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, bool)>[
      if (pass.purpose != null) ('PURPOSE', pass.purpose!, false),
      if (pass.destination != null) ('DESTINATION', pass.destination!, false),
      if (pass.transportMode != null) ('MODE', pass.transportMode!, false),
      if (pass.guardianPhone != null)
        ('GUARDIAN PHONE', pass.guardianPhone!, true),
      if (pass.reason != null) ('REASON', pass.reason!, false),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pass details',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        color: AppColors.mutedLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: row.$3 ? AppColors.cyan : AppColors.navy,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

class _WardenNote extends StatelessWidget {
  const _WardenNote({required this.initials, required this.comment});

  final String initials;
  final String comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Note from warden',
                style: TextStyle(
                  color: AppColors.successDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
