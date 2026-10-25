import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/info_alert_box.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

/// Requests a Firebase password reset email. Also used as "Change password"
/// for a signed-in student (FR006/UC002): Firebase has no endpoint to verify
/// a typed current password against a bearer token, so the only trustworthy
/// way to change it is the same emailed reset link used when signed out.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({this.isChangePassword = false, super.key});

  final bool isChangePassword;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  bool _loading = false;
  String? _error;

  bool get _isChange => widget.isChangePassword;

  @override
  void initState() {
    super.initState();
    final knownEmail = ref.read(authControllerProvider).student?.email;
    _email = TextEditingController(text: _isChange ? knownEmail : null);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(_email.text);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
    if (error != null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _isChange
                ? 'Reset link sent. Check your email to set your new password.'
                : 'Reset link sent. Check your email to set a new password.',
          ),
        ),
      );
    if (_isChange) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.formBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Tooltip(
                          message: _isChange ? 'Back' : 'Back to sign in',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => context.pop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 20,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isChange ? 'Back' : 'Back to sign in',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 28),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.mail_outline,
                                color: AppColors.cyan,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _isChange ? 'Change' : 'Forgot',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                letterSpacing: -0.8,
                              ),
                            ),
                            Text(
                              _isChange ? 'your password' : 'your password?',
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                fontStyle: FontStyle.italic,
                                height: 1.15,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AppTextField(
                              label: 'Registered email',
                              labelColor: AppColors.navy,
                              hintText: 'you@stu.kln.ac.lk',
                              controller: _email,
                              enabled: !_isChange,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 16),
                            if (_error != null) ...[
                              ErrorBanner(message: _error!),
                              const SizedBox(height: 12),
                            ],
                            PrimaryButton(
                              label: 'Send reset link',
                              isLoading: _loading,
                              onPressed: _submit,
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: () => context.pop(),
                                child: Text(
                                  _isChange ? 'Cancel' : 'Try signing in again',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    const InfoAlertBox(
                      icon: Icons.warning_amber_rounded,
                      title: 'Can’t access your email?',
                      description:
                          "Contact the Head Warden's office at ext. 2040 or "
                          'email support@stu.kln.ac.lk',
                      type: AlertType.warning,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
