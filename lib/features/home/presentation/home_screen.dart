import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/section_refresh.dart';
import 'package:al_wahat_farm_flutter/core/widgets/storage_status.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_widgets.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({this.today, super.key});

  /// The date shown above the title; tests pin it, the app uses the clock.
  final DateTime? today;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SectionReturnAware {
  /// The dashboard summarizes the shared task workspace; returning to Home
  /// re-pulls it so today's counts reflect work done in other sections.
  @override
  void onSectionReturn() {
    TaskWorkspaceScope.maybeOf(context)?.refresh();
  }

  @override
  Widget build(BuildContext context) => PaperBackground(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final tablet = constraints.maxWidth >= AppBreakpoints.tablet;
            final wide = constraints.maxWidth >= AppBreakpoints.wide;
            final intro = _Intro(
              today: widget.today ?? DateTime.now(),
              onScan: () => context.go('/scan'),
            );
            const operations = _OperationsPanel();

            late final Widget content;
            if (wide) {
              content = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 300, child: intro),
                  const SizedBox(width: 18),
                  const Expanded(child: _FarmOverview()),
                  const SizedBox(width: 18),
                  const SizedBox(width: 330, child: operations),
                ],
              );
            } else if (tablet) {
              content = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 300, child: intro),
                  const SizedBox(width: 18),
                  const Expanded(
                    child: Column(
                      children: <Widget>[
                        _FarmOverview(),
                        SizedBox(height: 18),
                        _OperationsPanel(),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              content = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  intro,
                  const SizedBox(height: 18),
                  const _FarmOverview(),
                  const SizedBox(height: 18),
                  operations,
                ],
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                tablet ? 28 : 16,
                24,
                tablet ? 28 : 16,
                110,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1380),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const StorageWarningBanner(),
                      content,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}

class _Intro extends StatelessWidget {
  const _Intro({required this.today, required this.onScan});
  final DateTime today;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Eyebrow(_dateLabel(context, today)),
          const SizedBox(height: 7),
          Text(
            context.l10n.homeHeroTitle,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 14),
          Container(
            width: 65,
            height: 3,
            color: AppColors.orange,
            alignment: AlignmentDirectional.centerStart,
          ),
          const SizedBox(height: 16),
          Text(context.l10n.homeHeroLede),
          const SizedBox(height: 18),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFC55C31), Color(0xFFDA7542)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x339A4923),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: InkWell(
              onTap: onScan,
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 70,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.qr_code_scanner,
                          color: Colors.white, size: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          context.l10n.homeScanTreeQr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class _FarmOverview extends StatelessWidget {
  const _FarmOverview();

  @override
  Widget build(BuildContext context) {
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    return WahatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Eyebrow(context.l10n.homeLiveMapData),
          const SizedBox(height: 8),
          Text(
            context.l10n.homeFarmOverview,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _Metric(
                value: hierarchy?.trees.length.toString() ?? '—',
                label: context.l10n.homeMappedTrees,
                icon: Icons.park_outlined,
              ),
              _Metric(
                value: hierarchy?.sections.length.toString() ?? '—',
                label: context.l10n.homeSections,
                icon: Icons.grid_view_outlined,
              ),
              _Metric(
                value: hierarchy?.zones.length.toString() ?? '—',
                label: context.l10n.homeIrrigationZones,
                icon: Icons.water_drop_outlined,
              ),
              _Metric(
                value: hierarchy?.plantingPits.length.toString() ?? '—',
                label: context.l10n.homePlantingPits,
                icon: Icons.add_location_alt_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.go('/map'),
            icon: const Icon(Icons.map_outlined),
            label: Text(context.l10n.homeOpenMap),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (context) {
              final issues = IssueWorkspaceScope.maybeOf(context);
              return OutlinedButton.icon(
                onPressed: () => context.go('/issues'),
                icon: const Icon(Icons.report_problem_outlined),
                label: Text(
                  context.l10n.homeActiveIssues(issues?.activeCount ?? 0),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.softGreen,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: AppColors.green),
            const SizedBox(height: 10),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class _OperationsPanel extends StatelessWidget {
  const _OperationsPanel();

  @override
  Widget build(BuildContext context) {
    final controller = TaskWorkspaceScope.maybeOf(context);
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    return WahatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(context.l10n.homeTodaysTasks,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          if (controller == null)
            Text(context.l10n.homeWorkspaceUnavailable)
          else
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final tasks = controller
                    .tasksForDay(DateTime.now())
                    .take(3)
                    .toList(growable: false);
                if (controller.snapshot.status == TaskWorkspaceStatus.loading &&
                    controller.snapshot.tasks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (tasks.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(context.l10n.homeNoTasksToday),
                  );
                }
                return Column(
                  children: tasks
                      .map(
                        (task) => _TaskPreview(
                          task: task,
                          target:
                              taskTargetLabel(context.l10n, task, hierarchy),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/tasks'),
            child: Text(context.l10n.homeViewAllTasks),
          ),
        ],
      ),
    );
  }
}

class _TaskPreview extends StatelessWidget {
  const _TaskPreview({required this.task, required this.target});
  final FarmTask task;
  final String target;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: AppColors.softGreen,
          foregroundColor: AppColors.green,
          child: Icon(Icons.water_drop_outlined),
        ),
        title: Text(task.title),
        subtitle: Text('$target · ${task.status.localizedLabel(context.l10n)}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/tasks/${task.id}'),
      );
}

/// "Sunday · 12 July" in the app's language.
String _dateLabel(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return context.l10n.homeDateEyebrow(
    DateFormat.EEEE(locale).format(date),
    DateFormat('d MMMM', locale).format(date),
  );
}
