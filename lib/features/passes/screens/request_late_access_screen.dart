import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/uuid.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/info_alert_box.dart';
import '../../../core/widgets/primary_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/api/api_exception.dart';
import '../../../data/models/pass.dart';
import '../../../data/repositories/exceptions.dart';
import '../providers/pass_providers.dart';

/// Request a late-access pass (UC010) or declare going home (UC009).
class RequestLateAccessScreen extends ConsumerStatefulWidget {
  const RequestLateAccessScreen({super.key});

  @override
  ConsumerState<RequestLateAccessScreen> createState() =>
      _RequestLateAccessScreenState();
}

class _RequestLateAccessScreenState
    extends ConsumerState<RequestLateAccessScreen> {
  static const _goingHome = 'Going home';
  static const _lateAccess = 'Late access';

  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late DateTime _expectedAt;
  String _kind = _lateAccess;
  LateDirection _direction = LateDirection.lateEntry;
  String _requestId = newUuid();
  bool _loading = false;
  String? _error;

  bool get _isGoingHome => _kind == _goingHome;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _expectedAt = DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedAt.isBefore(now) ? now : _expectedAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      _expectedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _expectedAt.hour,
        _expectedAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expectedAt),
    );
    if (picked == null) return;
    setState(() {
      _expectedAt = DateTime(
        _expectedAt.year,
        _expectedAt.month,
        _expectedAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_isGoingHome) {
      await _submitGoingHome();
    } else {
      await _submitLateAccess();
    }
  }

  Future<void> _submitGoingHome() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(passesProvider.notifier)
          .recordGoingHome(requestId: _requestId);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.goingHomeRecorded);
    } on RepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        if (e is! NetworkException) _requestId = newUuid();
      });
    }
  }

  Future<void> _submitLateAccess() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pass = await ref
          .read(passesProvider.notifier)
          .requestLateAccess(
            direction: _direction,
            expectedAt: _expectedAt,
            reason: _reason.text,
            requestId: _requestId,
          );
      if (!mounted) return;
      context.pushReplacement('/passes/${pass.id}/submitted');
    } on RepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        if (e is! NetworkException) _requestId = newUuid();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.formBackground,
      appBar: const PrimaryAppBar(title: 'Request a pass'),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isGoingHome)
                const Text(
                  'By submitting you confirm the information is accurate.',
                  style: TextStyle(color: AppColors.mutedLight, fontSize: 11),
                ),
              if (!_isGoingHome) const SizedBox(height: 10),
              PrimaryButton(
                label: _isGoingHome ? 'Confirm going home' : 'Submit to warden',
                isLoading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoAlertBox(
                icon: Icons.info_outline,
                title: _isGoingHome
                    ? 'Your declaration is recorded immediately'
                    : 'Only needed for entries outside 06:00–20:00',
                description: _isGoingHome
                    ? 'No warden approval needed. Scan your ID at the gate.'
                    : 'Warden approves by 22:00. Check Inbox for status.',
              ),
              const SizedBox(height: 20),
              const _Label('Type'),
              const SizedBox(height: 8),
              _SegmentPicker(
                options: const [_goingHome, _lateAccess],
                selected: _kind,
                onChanged: (value) => setState(() => _kind = value),
              ),
              if (_isGoingHome) ...[
                const SizedBox(height: 20),
                const _GoingHomePoints(),
              ] else ...[
                const SizedBox(height: 18),
                const _Label('Movement'),
                const SizedBox(height: 8),
                _SegmentPicker(
                  options: [for (final d in LateDirection.values) d.label],
                  selected: _direction.label,
                  onChanged: (value) => setState(
                    () => _direction = LateDirection.values.firstWhere(
                      (d) => d.label == value,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _PickerField(
                        label: 'Date',
                        value: formatDate(_expectedAt),
                        icon: Icons.calendar_today_outlined,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerField(
                        label: 'Time',
                        value: formatTime(_expectedAt),
                        icon: Icons.schedule,
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Reason',
                  hintText: 'Tell the warden why you need this pass',
                  controller: _reason,
                  maxLines: 3,
                  labelColor: AppColors.navy,
                  validator: (v) => Validators.required(v, field: 'Reason'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                ErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GoingHomePoints extends StatelessWidget {
  const _GoingHomePoints();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          _Point('Your declaration is recorded for the hostel.'),
          _Point('No warden approval is needed during normal hours.'),
          _Point('Scan your ID card at the gate when you leave and return.'),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 16, color: AppColors.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SegmentPicker extends StatelessWidget {
  const _SegmentPicker({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: option == selected,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == selected
                          ? AppColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: option == selected
                            ? AppColors.navy
                            : AppColors.secondary,
                        fontSize: 13,
                        fontWeight: option == selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 6),
        Semantics(
          button: true,
          label: '$label $value',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
