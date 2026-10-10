import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/exceptions.dart';
import '../providers/pass_providers.dart';

/// Record Leave Status (UC009): the student confirms they are going home.
class GoingHomeScreen extends ConsumerStatefulWidget {
  const GoingHomeScreen({super.key});

  @override
  ConsumerState<GoingHomeScreen> createState() => _GoingHomeScreenState();
}

class _GoingHomeScreenState extends ConsumerState<GoingHomeScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(passesProvider.notifier).recordGoingHome();
      if (!mounted) return;
      context.pushReplacement(AppRoutes.goingHomeRecorded);
    } on RepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.formBackground,
      appBar: const PrimaryAppBar(title: 'Going home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 34,
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mark yourself as going home?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const _Point('You will be recorded as OUT on the dashboard.'),
              const _Point('No warden approval is needed during normal hours.'),
              const _Point('Scan your ID card at the gate when you return.'),
              if (_error != null) ...[
                const SizedBox(height: 16),
                ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Confirm going home',
                isLoading: _loading,
                onPressed: _confirm,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Cancel',
                isOutlined: true,
                onPressed: _loading ? null : () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 16, color: AppColors.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
