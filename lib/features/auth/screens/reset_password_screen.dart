import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_strength.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/info_alert_box.dart';
import '../../../core/widgets/password_checklist.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../../../core/widgets/primary_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({required this.token, super.key});

  final String token;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
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
        .resetPassword(token: widget.token, newPassword: _password.text);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
    if (error == null) context.go(AppRoutes.passwordChanged);
  }

  String? _validatePassword(String? value) {
    final base = Validators.strongPassword(value);
    if (base != null) return base;
    if (!PasswordRules.of(value!).allMet) {
      return 'Use an uppercase letter, a number and a symbol';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final rules = PasswordRules.of(_password.text);

    return Scaffold(
      backgroundColor: AppColors.formBackground,
      appBar: const PrimaryAppBar(title: 'Reset password'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set a new password',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pick something strong — this is your day-to-day login from '
                'now on',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'New password',
                controller: _password,
                isPassword: true,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                validator: _validatePassword,
              ),
              const SizedBox(height: 12),
              PasswordStrengthMeter(
                strength: passwordStrength(_password.text),
                isEmpty: _password.text.isEmpty,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Confirm new password',
                hintText: 'Re-enter password',
                controller: _confirm,
                isPassword: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: Validators.matches(() => _password.text),
              ),
              const SizedBox(height: 16),
              PasswordChecklist(rules: rules),
              const SizedBox(height: 16),
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                label: 'Save password',
                isLoading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              const InfoAlertBox(
                title: 'Need help?',
                description: "Contact the Head Warden's office at ext. 2040",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
