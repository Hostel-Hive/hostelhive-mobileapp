import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/student.dart';
import '../../auth/providers/auth_providers.dart';

/// Shows the signed-in student's uploaded profile photo when available,
/// falling back to their initials. Used anywhere the app shows "the
/// student" rather than a specific other person (e.g. a warden's initials
/// on a pass decision).
class StudentAvatar extends ConsumerWidget {
  const StudentAvatar({
    required this.student,
    this.size = 44,
    this.backgroundColor = AppColors.navy,
    this.textColor = Colors.white,
    this.fontSize,
    super.key,
  });

  final Student student;
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final double? fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(profilePhotoProvider);
    final initialsText = Text(
      student.initials,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize ?? size * 0.32,
        fontWeight: FontWeight.w700,
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: photo.when(
        loading: () => initialsText,
        error: (_, _) => initialsText,
        data: (bytes) => bytes == null
            ? initialsText
            : Image.memory(
                bytes,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initialsText,
              ),
      ),
    );
  }
}
