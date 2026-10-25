import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../inbox/providers/inbox_providers.dart';

/// Bottom navigation around the four main tabs: Home, Passes, Inbox, Me.
class HomeShell extends ConsumerWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (label: 'Home', icon: Icons.home_outlined, active: Icons.home),
    (label: 'Passes', icon: Icons.badge_outlined, active: Icons.badge),
    (
      label: 'Inbox',
      icon: Icons.notifications_none,
      active: Icons.notifications,
    ),
    (label: 'Me', icon: Icons.person_outline, active: Icons.person),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      key: ValueKey('tab:${_tabs[i].label}'),
                      label: _tabs[i].label,
                      icon: i == navigationShell.currentIndex
                          ? _tabs[i].active
                          : _tabs[i].icon,
                      selected: i == navigationShell.currentIndex,
                      showDot: _tabs[i].label == 'Inbox' && unread > 0,
                      onTap: () => navigationShell.goBranch(
                        i,
                        initialLocation: i == navigationShell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.showDot,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.cyan : AppColors.mutedLight;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.infoSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                if (showDot)
                  Positioned(
                    top: 4,
                    right: 14,
                    child: Semantics(
                      label: 'Unread messages',
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
