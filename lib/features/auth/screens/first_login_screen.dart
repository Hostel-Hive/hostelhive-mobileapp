import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_strength.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/password_strength_meter.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class FirstLoginScreen extends ConsumerStatefulWidget {
  const FirstLoginScreen({super.key});

  @override
  ConsumerState<FirstLoginScreen> createState() => _FirstLoginScreenState();
}

class _FirstLoginScreenState extends ConsumerState<FirstLoginScreen> {
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
        .activateAccount(_password.text);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(authControllerProvider).student;

    return Scaffold(
      backgroundColor: AppColors.formBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _Hero(
                firstName: student?.firstName ?? 'resident',
                indexNo: student?.indexNo ?? '',
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: 'New password',
                        labelColor: AppColors.navy,
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
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Confirm password',
                        labelColor: AppColors.navy,
                        hintText: 'Re-enter password',
                        controller: _confirm,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: Validators.matches(() => _password.text),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        ErrorBanner(message: _error!),
                        const SizedBox(height: 12),
                      ],
                      PrimaryButton(
                        label: 'Activate account',
                        trailingIcon: Icons.arrow_forward,
                        isLoading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                      const _QrReadyCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePassword(String? value) {
    final base = Validators.strongPassword(value);
    if (base != null) return base;
    if (!PasswordRules.of(value!).allMet) {
      return 'Use an uppercase letter, a number and a symbol';
    }
    return null;
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.firstName, required this.indexNo});

  final String firstName;
  final String indexNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        gradient: RadialGradient(
          center: Alignment(-0.6, 0.7),
          radius: 0.6,
          colors: [AppColors.navyGlow, AppColors.navy],
          stops: [0, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'FIRST LOGIN · $indexNo',
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    color: AppColors.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome,',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          Text(
            '$firstName.',
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Set a password to activate your account and scan in at the gate.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _QrReadyCard extends StatelessWidget {
  const _QrReadyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.cyan),
              SizedBox(width: 8),
              Text(
                'Your QR is ready',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'After activation, scan at Gate A to sign in tonight. '
            'The warden on duty will be notified.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
