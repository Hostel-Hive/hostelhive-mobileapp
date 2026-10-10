import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'primary_app_bar.dart';
import 'primary_button.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.appBarTitle,
    this.description,
    this.detailLabel,
    this.detailValue,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.icon = Icons.check,
    this.iconColor = AppColors.success,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? appBarTitle;
  final String? description;
  final String? detailLabel;
  final String? detailValue;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.formBackground,
      appBar: PrimaryAppBar(title: appBarTitle ?? title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 24),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
              if (detailValue != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detailLabel ?? '',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        detailValue!,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryButton(label: primaryLabel, onPressed: onPrimaryPressed),
              if (secondaryLabel != null) ...[
                const SizedBox(height: 12),
                PrimaryButton(
                  label: secondaryLabel!,
                  onPressed: onSecondaryPressed,
                  isOutlined: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
