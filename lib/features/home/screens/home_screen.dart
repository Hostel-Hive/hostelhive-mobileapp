import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';

/// Temporary landing screen. Replaced by the dashboard and tab navigation in
/// the home shell feature.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(authControllerProvider).student;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Hello, ${student?.firstName ?? 'resident'}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Show my QR',
                onPressed: () => context.push(AppRoutes.qr),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'My passes',
                onPressed: () => context.push(AppRoutes.passes),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Going home',
                onPressed: () => context.push(AppRoutes.goingHome),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Report an issue',
                onPressed: () => context.push(AppRoutes.newComplaint),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Sign out',
                isOutlined: true,
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
