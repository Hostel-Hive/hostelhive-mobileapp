import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/confirmation_screen.dart';
import '../providers/pass_providers.dart';

/// Shown after a leave or late access request is sent to the warden.
class LateAccessSubmittedScreen extends ConsumerWidget {
  const LateAccessSubmittedScreen({required this.passId, super.key});

  final String passId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pass = ref.watch(passByIdProvider(passId)).valueOrNull;
    return ConfirmationScreen(
      title: 'Request sent',
      subtitle: 'Your request is with the warden.',
      description:
          'The warden approves by 22:00. You will be notified in your Inbox '
          'once it has been reviewed.',
      detailLabel: 'Pass ID',
      detailValue: pass?.displayId ?? passId,
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
      subtitle: 'Safe travels! Your declaration is recorded.',
      description:
          'Scan your ID card at the gate when you leave and your status '
          'becomes OUT. Scan again when you return.',
      primaryLabel: 'Back to Home',
      onPrimaryPressed: () => context.go(AppRoutes.home),
    );
  }
}
