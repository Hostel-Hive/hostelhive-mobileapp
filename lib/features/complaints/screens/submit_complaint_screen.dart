import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/primary_app_bar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/complaint.dart';
import '../../../data/repositories/exceptions.dart';
import '../providers/complaint_providers.dart';
import '../services/image_picker_service.dart';

/// Submit Complaint (UC012) with optional photos (UC013).
class SubmitComplaintScreen extends ConsumerStatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  ConsumerState<SubmitComplaintScreen> createState() =>
      _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends ConsumerState<SubmitComplaintScreen> {
  static const _icons = {
    'Safety': Icons.gpp_bad_outlined,
    'Facilities': Icons.home_outlined,
    'Food & Mess': Icons.folder_outlined,
    'People': Icons.people_outline,
    'Wi-Fi / IT': Icons.signal_cellular_alt,
    'Other': Icons.filter_list,
  };

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final List<String> _photos = [];
  String? _category;
  bool _categoryMissing = false;
  ComplaintSeverity _severity = ComplaintSeverity.normal;
  bool _loading = false;
  String? _error;
  String? _photoError;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<PhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ref.read(imagePickerServiceProvider).pick(source);
    if (picked == null || !mounted) return;

    final problem = validateComplaintImage(
      path: picked.path,
      sizeBytes: picked.sizeBytes,
    );
    setState(() {
      _photoError = problem;
      if (problem == null) _photos.add(picked.path);
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _categoryMissing = _category == null);
    if (!valid || _category == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final complaint = await ref
          .read(complaintsProvider.notifier)
          .submit(
            category: _category!,
            title: _title.text,
            description: _description.text,
            severity: _severity,
            imagePaths: _photos,
          );
      if (!mounted) return;
      context.pushReplacement('/complaints/${complaint.id}/submitted');
    } on RepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.formBackground,
      appBar: const PrimaryAppBar(title: 'Report an issue'),
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
              Text(
                '${_severity.label} · responded within '
                '${_severity.responseHours} hours',
                style: TextStyle(
                  color: _severity == ComplaintSeverity.critical
                      ? AppColors.dangerDark
                      : AppColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Submit complaint',
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
              const _SectionLabel('Category'),
              const SizedBox(height: 10),
              _CategoryGrid(
                icons: _icons,
                selected: _category,
                onSelected: (value) => setState(() {
                  _category = value;
                  _categoryMissing = false;
                }),
              ),
              if (_categoryMissing)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Choose a category',
                    style: TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              const _SectionLabel('Severity'),
              const SizedBox(height: 10),
              _SeverityPicker(
                selected: _severity,
                onChanged: (value) => setState(() => _severity = value),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Short title',
                hintText: 'e.g. Emergency exit blocked by laundry rack',
                controller: _title,
                labelColor: AppColors.navy,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, field: 'Title'),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                hintText: 'Describe what is wrong and where',
                controller: _description,
                maxLines: 4,
                labelColor: AppColors.navy,
                validator: (v) => Validators.required(v, field: 'Description'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionLabel('Photos · optional'),
                  Text(
                    '${_photos.length} / $maxComplaintImages added',
                    style: const TextStyle(
                      fontFamily: AppFonts.mono,
                      color: AppColors.mutedLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PhotoStrip(
                photos: _photos,
                onAdd: _addPhoto,
                onRemove: (index) => setState(() => _photos.removeAt(index)),
              ),
              if (_photoError != null) ...[
                const SizedBox(height: 10),
                ErrorBanner(message: _photoError!),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

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

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.icons,
    required this.selected,
    required this.onSelected,
  });

  final Map<String, IconData> icons;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        for (final entry in icons.entries)
          Semantics(
            button: true,
            selected: entry.key == selected,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelected(entry.key),
              child: Container(
                decoration: BoxDecoration(
                  color: entry.key == selected
                      ? AppColors.dangerSoft
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: entry.key == selected
                        ? AppColors.danger.withValues(alpha: 0.6)
                        : AppColors.cardBorder,
                    width: entry.key == selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      entry.value,
                      size: 20,
                      color: entry.key == selected
                          ? AppColors.danger
                          : AppColors.navy,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: entry.key == selected
                            ? AppColors.dangerDark
                            : AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

class _SeverityPicker extends StatelessWidget {
  const _SeverityPicker({required this.selected, required this.onChanged});

  final ComplaintSeverity selected;
  final ValueChanged<ComplaintSeverity> onChanged;

  static const _dots = {
    ComplaintSeverity.normal: AppColors.success,
    ComplaintSeverity.high: AppColors.warning,
    ComplaintSeverity.critical: AppColors.danger,
  };

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
          for (final severity in ComplaintSeverity.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: severity == selected,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(severity),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: severity == selected
                          ? AppColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _dots[severity],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          severity.label,
                          style: TextStyle(
                            color: severity == selected
                                ? AppColors.navy
                                : AppColors.secondary,
                            fontSize: 13,
                            fontWeight: severity == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
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

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < photos.length; i++)
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(photos[i]),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceTint,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Tooltip(
                    message: 'Remove photo ${i + 1}',
                    child: InkWell(
                      onTap: () => onRemove(i),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.navy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (photos.length < maxComplaintImages)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onAdd,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppColors.secondary),
                  SizedBox(height: 2),
                  Text(
                    'Add',
                    style: TextStyle(color: AppColors.secondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
