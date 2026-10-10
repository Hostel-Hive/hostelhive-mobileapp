import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../models/scan_result.dart';

/// Full-screen outcome of a gate scan (UC005): green when the entry or exit
/// was recorded, red when it failed.
class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({required this.result, super.key});

  final ScanResult result;

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = result.isSuccess ? AppColors.success : AppColors.danger;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _StatusIcon(isSuccess: result.isSuccess),
              const SizedBox(height: 40),
              Text(
                result.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                result.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 28),
              if (result.isSuccess)
                _InfoPill(
                  title: 'Welcome back, ${result.studentName}',
                  detail: result.studentDetails,
                )
              else if (result.errorCode != null)
                _InfoPill(title: result.errorCode!, mono: true),
              const Spacer(flex: 3),
              result.isSuccess
                  ? _ActionButton(
                      label: 'Done',
                      color: Colors.white.withValues(alpha: 0.22),
                      textColor: Colors.white,
                      onPressed: () => _close(context),
                    )
                  : _ActionButton(
                      label: 'Try again',
                      color: Colors.white,
                      textColor: AppColors.danger,
                      onPressed: () => _close(context),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.isSuccess});

  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSuccess ? Icons.check : Icons.close,
          size: 88,
          color: Colors.white,
          semanticLabel: isSuccess ? 'Success' : 'Failed',
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.title, this.detail, this.mono = false});

  final String title;
  final String? detail;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: mono ? 200 : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(mono ? 999 : 16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: mono ? AppFonts.mono : null,
              color: Colors.white,
              fontSize: mono ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
