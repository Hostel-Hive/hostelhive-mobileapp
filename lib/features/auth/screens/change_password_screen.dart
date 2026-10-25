import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_strength.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

/// Lets a signed-in student change their password (FR006 / UC002).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
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
        .changeCurrentPassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Password updated')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Change password',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Current password',
                  controller: _current,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.required(v, field: 'Current password'),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'New password',
                  controller: _next,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: _validateNew,
                ),
                const SizedBox(height: 10),
                PasswordStrengthMeter(
                  strength: passwordStrength(_next.text),
                  isEmpty: _next.text.isEmpty,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Confirm new password',
                  controller: _confirm,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: Validators.matches(() => _next.text),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                PrimaryButton(
                  label: 'Update password',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateNew(String? value) {
    final base = Validators.strongPassword(value);
    if (base != null) return base;
    if (!PasswordRules.of(value!).allMet) {
      return 'Use an uppercase letter, a number and a symbol';
    }
    return null;
  }
}
