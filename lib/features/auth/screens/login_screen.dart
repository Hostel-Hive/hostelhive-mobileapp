import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/hostelhive_logo.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
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
        .signIn(_identifier.text, _password.text);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  void _showWelcomeEmailHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your welcome email has the link to choose your password.',
        ),
      ),
    );
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
              child: Column(
                children: [
                  _Header(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'Email',
                            labelColor: AppColors.navy,
                            hintText: 'you@stu.kln.ac.lk',
                            controller: _identifier,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            label: 'Password',
                            labelColor: AppColors.navy,
                            hintText: 'Your password',
                            controller: _password,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) =>
                                Validators.required(v, field: 'Password'),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.forgotPassword),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            ErrorBanner(message: _error!),
                            const SizedBox(height: 12),
                          ],
                          PrimaryButton(
                            label: 'Sign in',
                            isLoading: _loading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _Footer(onWelcomeEmail: _showWelcomeEmailHint),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 56),
      child: const Column(
        children: [
          HostelHiveLogo(),
          SizedBox(height: 28),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Welcome,\u2009',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: 'resident.',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, letterSpacing: -0.8),
          ),
          SizedBox(height: 20),
          Text(
            'Sign in with your university email.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onWelcomeEmail});

  final VoidCallback onWelcomeEmail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'New student? ',
                style: TextStyle(color: AppColors.secondary, fontSize: 14),
              ),
              InkWell(
                onTap: onWelcomeEmail,
                child: const Text(
                  'Check your welcome email',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Bulugaha Girls' Hostel · University of Kelaniya",
            style: TextStyle(color: AppColors.mutedLight, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
