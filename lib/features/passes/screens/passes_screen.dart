import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/clock_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/usage_progress_circle.dart';
import '../../../data/models/pass.dart';
import '../providers/pass_providers.dart';
import '../widgets/pass_widgets.dart';

/// The Passes tab: yearly usage, filter tabs and the list of passes.
class PassesScreen extends ConsumerStatefulWidget {
  const PassesScreen({super.key});

  @override
  ConsumerState<PassesScreen> createState() => _PassesScreenState();
}

class _PassesScreenState extends ConsumerState<PassesScreen> {
  PassTab _tab = PassTab.active;

  @override
  Widget build(BuildContext context) {
    final passes = ref.watch(passesProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My passes',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Request late access',
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        highlightElevation: 3,
        onPressed: () => context.push(AppRoutes.requestLateAccess),
        child: const Icon(Icons.add),
      ),
      body: passes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(passesProvider),
            child: const Text('Could not load passes. Tap to retry.'),
          ),
        ),
        data: (all) {
          if (all.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.confirmation_number_outlined,
              title: 'No passes yet',
              description:
                  'Request late access or mark going home and your passes '
                  'will show here',
              buttonLabel: 'Request late access',
              onButtonPressed: () => context.push(AppRoutes.requestLateAccess),
            );
          }
          return _PassesList(
            all: all,
            now: now,
            tab: _tab,
            onTab: (tab) => setState(() => _tab = tab),
          );
        },
      ),
    );
  }
}

class _PassesList extends ConsumerWidget {
  const _PassesList({
    required this.all,
    required this.now,
    required this.tab,
    required this.onTab,
  });

  final List<Pass> all;
  final DateTime now;
  final PassTab tab;
  final ValueChanged<PassTab> onTab;

  void _open(BuildContext context, Pass pass) {
    context.push('/passes/${pass.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = passesIn(all, tab, now);
    final history = passesIn(all, PassTab.history, now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 96),
      children: [
        const _QuotaCard(),
        const SizedBox(height: 20),
        _TabBar(
          tab: tab,
          counts: {
            for (final t in PassTab.values) t: passesIn(all, t, now).length,
          },
          onTab: onTab,
        ),
        const SizedBox(height: 20),
        if (tab == PassTab.history)
          ..._historyRows(context, shown)
        else ...[
          if (shown.isEmpty)
            const _EmptyTab()
          else
            for (final pass in shown) ...[
              PassCard(pass: pass, onView: () => _open(context, pass)),
              const SizedBox(height: 14),
            ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT HISTORY',
                  style: TextStyle(
                    color: AppColors.mutedLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                InkWell(
                  onTap: () => onTab(PassTab.history),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._historyRows(context, history.take(3).toList()),
          ],
        ],
      ],
    );
  }

  List<Widget> _historyRows(BuildContext context, List<Pass> rows) {
    if (rows.isEmpty) return [const _EmptyTab()];
    return [
      for (final pass in rows) ...[
        PassHistoryRow(pass: pass, onTap: () => _open(context, pass)),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Nothing here yet',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
      ),
    );
  }
}

class _QuotaCard extends ConsumerWidget {
  const _QuotaCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quota = ref.watch(passQuotaProvider).value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This year',
                  style: TextStyle(color: AppColors.mutedLight, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${quota?.usedDays ?? 0}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${quota?.totalDays ?? 0} used',
                        style: const TextStyle(
                          color: AppColors.mutedLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          UsageProgressCircle(
            percentage: quota?.fraction ?? 0,
            size: 58,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab, required this.counts, required this.onTab});

  final PassTab tab;
  final Map<PassTab, int> counts;
  final ValueChanged<PassTab> onTab;

  static const _labels = {
    PassTab.active: 'Active',
    PassTab.pending: 'Pending',
    PassTab.history: 'History',
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
          for (final t in PassTab.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: t == tab,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onTab(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: t == tab ? AppColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: t == tab
                          ? const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _labels[t]!,
                          style: TextStyle(
                            color: t == tab
                                ? AppColors.navy
                                : AppColors.secondary,
                            fontSize: 13,
                            fontWeight: t == tab
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${counts[t] ?? 0}',
                          style: const TextStyle(
                            fontFamily: AppFonts.mono,
                            color: AppColors.mutedLight,
                            fontSize: 11,
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
