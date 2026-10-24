import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/confirmation_screen.dart';

class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ConfirmationScreen(
      title: 'Password updated',
      subtitle: 'Your password has been changed successfully.',
      description: 'Use your new password the next time you sign in.',
      detailLabel: 'Last changed',
      detailValue: 'Just now',
      primaryLabel: 'Back to sign in',
      onPrimaryPressed: () => context.go(AppRoutes.login),
    );
  }
}
