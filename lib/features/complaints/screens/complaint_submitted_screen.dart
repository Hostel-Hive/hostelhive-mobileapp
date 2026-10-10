import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/confirmation_screen.dart';

/// Shown after a complaint has been recorded (UC012).
class ComplaintSubmittedScreen extends StatelessWidget {
  const ComplaintSubmittedScreen({required this.complaintId, super.key});

  final String complaintId;

  @override
  Widget build(BuildContext context) {
    return ConfirmationScreen(
      title: 'Complaint submitted',
      subtitle: 'Your complaint has been recorded.',
      description:
          'We will notify you when the warden responds. Typical response '
          'time depends on how urgent the issue is.',
      detailLabel: 'Ticket ID',
      detailValue: complaintId,
      primaryLabel: 'Back to Home',
      onPrimaryPressed: () => context.go(AppRoutes.home),
      secondaryLabel: 'View complaint',
      onSecondaryPressed: () {
        context.go(AppRoutes.home);
        context.push('/complaints/$complaintId');
      },
    );
  }
}
