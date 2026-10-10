import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/confirmation_screen.dart';

/// Shown after a late access request is sent to the warden.
class LateAccessSubmittedScreen extends StatelessWidget {
  const LateAccessSubmittedScreen({required this.passId, super.key});

  final String passId;

  @override
  Widget build(BuildContext context) {
    return ConfirmationScreen(
      title: 'Request sent',
      subtitle: 'Your late access request is with the warden.',
      description:
          'The warden approves by 22:00. You will be notified in your Inbox '
          'once it has been reviewed.',
      detailLabel: 'Pass ID',
      detailValue: passId,
      primaryLabel: 'View pass',
      onPrimaryPressed: () {
        context.go(AppRoutes.home);
        context.push('/passes/$passId');
      },
      secondaryLabel: 'Back to Home',
      onSecondaryPressed: () => context.go(AppRoutes.home),
    );
  }
}

/// Shown after "Going home" has been recorded.
class GoingHomeRecordedScreen extends StatelessWidget {
  const GoingHomeRecordedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ConfirmationScreen(
      title: 'Going home recorded',
      subtitle: 'Safe travels! You are now marked as OUT.',
      description:
          'When you return, scan your ID card at the gate and your status '
          'will update automatically.',
      primaryLabel: 'Back to Home',
      onPrimaryPressed: () => context.go(AppRoutes.home),
    );
  }
}
