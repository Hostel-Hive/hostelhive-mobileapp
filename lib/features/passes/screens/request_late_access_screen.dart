import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
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

/// Request an extended leave (UC009) or one early exit / late entry (UC010).
class RequestLateAccessScreen extends ConsumerStatefulWidget {
  const RequestLateAccessScreen({super.key});

  @override
  ConsumerState<RequestLateAccessScreen> createState() =>
      _RequestLateAccessScreenState();
}

class _RequestLateAccessScreenState
    extends ConsumerState<RequestLateAccessScreen> {
  static const _leave = 'Leave';
  static const _lateAccess = 'Late access';

  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late DateTime _departure;
  late DateTime _return;
  String _kind = _leave;
  LateDirection _direction = LateDirection.lateEntry;
  String _requestId = newUuid();
  bool _loading = false;
  String? _error;

  bool get _isLeave => _kind == _leave;

  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider)();
    _departure = DateTime(now.year, now.month, now.day + 1, 9);
    _return = DateTime(now.year, now.month, now.day + 1, 18);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool departure}) async {
    final now = ref.read(clockProvider)();
    final current = departure ? _departure : _return;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(now) ? now : current,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      final merged = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
      if (departure) {
        _departure = merged;
      } else {
        _return = merged;
      }
    });
  }

  Future<void> _pickTime({required bool departure}) async {
    final current = departure ? _departure : _return;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    setState(() {
      final merged = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
      if (departure) {
        _departure = merged;
      } else {
        _return = merged;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notifier = ref.read(passesProvider.notifier);
      final pass = _isLeave
          ? await notifier.requestLeave(
              startsAt: _departure,
              endsAt: _return,
              reason: _reason.text,
              requestId: _requestId,
            )
          : await notifier.requestLateAccess(
              direction: _direction,
              expectedAt: _departure,
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
        // Only a lost connection may have reached the server; anything else
        // is a new attempt and needs a new request id.
        if (e is! NetworkException) _requestId = newUuid();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quota = ref.watch(passQuotaProvider).value;

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
              const Text(
                'By submitting you confirm the information is accurate.',
                style: TextStyle(color: AppColors.mutedLight, fontSize: 11),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Submit to warden',
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
                title: _isLeave
                    ? 'Extended leave needs the warden’s approval'
                    : 'Only needed for entries outside 06:00–20:00',
                description: _isLeave
                    ? 'Check Inbox for the decision.'
                    : 'Warden approves by 22:00. Check Inbox for status.',
              ),
              const SizedBox(height: 20),
              const _Label('Type'),
              const SizedBox(height: 8),
              _SegmentPicker(
                options: const [_leave, _lateAccess],
                selected: _kind,
                onChanged: (value) => setState(() => _kind = value),
              ),
              if (!_isLeave) ...[
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
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      label: _isLeave ? 'Departure date' : 'Date',
                      value: formatDate(_departure),
                      icon: Icons.calendar_today_outlined,
                      onTap: () => _pickDate(departure: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerField(
                      label: _isLeave ? 'Departure time' : 'Time',
                      value: formatTime(_departure),
                      icon: Icons.schedule,
                      onTap: () => _pickTime(departure: true),
                    ),
                  ),
                ],
              ),
              if (_isLeave) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PickerField(
                        label: 'Return date',
                        value: formatDate(_return),
                        icon: Icons.calendar_today_outlined,
                        onTap: () => _pickDate(departure: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerField(
                        label: 'Return time',
                        value: formatTime(_return),
                        icon: Icons.schedule,
                        onTap: () => _pickTime(departure: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DurationChip(
                  departure: _departure,
                  returnAt: _return,
                  remainingDays: quota == null
                      ? null
                      : quota.totalDays - quota.usedDays,
                  totalDays: quota?.totalDays,
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                label: 'Reason',
                hintText: 'Tell the warden why you need this pass',
                controller: _reason,
                maxLines: 3,
                labelColor: AppColors.navy,
                validator: (v) => Validators.required(v, field: 'Reason'),
              ),
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

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.departure,
    required this.returnAt,
    required this.remainingDays,
    required this.totalDays,
  });

  final DateTime departure;
  final DateTime returnAt;
  final int? remainingDays;
  final int? totalDays;

  @override
  Widget build(BuildContext context) {
    final duration = returnAt.difference(departure);
    final invalid = !returnAt.isAfter(departure);
    final days = (duration.inMinutes / (24 * 60)).ceil();
    final exceeds = remainingDays != null && days > remainingDays!;

    late final String text;
    late final Color background;
    late final Color foreground;
    late final IconData icon;

    if (invalid) {
      text = 'Return must be after the departure time';
      background = AppColors.dangerSoft;
      foreground = AppColors.dangerDark;
      icon = Icons.error_outline;
    } else if (exceeds) {
      text =
          'Duration · ${formatDuration(duration)} · exceeds your remaining '
          '$remainingDays-day quota';
      background = AppColors.warningSoft;
      foreground = AppColors.warningDark;
      icon = Icons.warning_amber_rounded;
    } else {
      text =
          'Duration · ${formatDuration(duration)}'
          '${totalDays == null ? '' : ' · within your $totalDays-day annual quota'}';
      background = AppColors.successSoft;
      foreground = AppColors.successDark;
      icon = Icons.check_circle_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
