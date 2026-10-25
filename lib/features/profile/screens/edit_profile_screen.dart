import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';

/// Lets a signed-in student edit their contact phone and guardian details.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late final TextEditingController _guardianName;
  late final TextEditingController _guardianRelation;
  late final TextEditingController _guardianPhone;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final student = ref.read(authControllerProvider).student;
    _phone = TextEditingController(text: student?.phone ?? '');
    _guardianName = TextEditingController(text: student?.guardianName ?? '');
    _guardianRelation = TextEditingController(
      text: student?.guardianRelation ?? '',
    );
    _guardianPhone = TextEditingController(text: student?.guardianPhone ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _guardianName.dispose();
    _guardianRelation.dispose();
    _guardianPhone.dispose();
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
        .updateProfile(
          phone: _phone.text.trim(),
          guardianName: _guardianName.text.trim(),
          guardianRelation: _guardianRelation.text.trim(),
          guardianPhone: _guardianPhone.text.trim(),
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
        .showSnackBar(const SnackBar(content: Text('Profile updated')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit profile',
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
                  label: 'Phone number',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 24),
                const Text(
                  'GUARDIAN & EMERGENCY CONTACT',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Guardian name',
                  controller: _guardianName,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.required(v, field: 'Guardian name'),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Relationship',
                  controller: _guardianRelation,
                  hintText: 'e.g. Mother, Father, Guardian',
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.required(v, field: 'Relationship'),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Guardian phone',
                  controller: _guardianPhone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  ErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                PrimaryButton(
                  label: 'Save changes',
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
}
