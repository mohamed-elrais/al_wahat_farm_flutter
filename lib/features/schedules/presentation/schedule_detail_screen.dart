import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_visuals.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/option_visuals.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_controller.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/plan_run.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_controller.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScheduleDetailScreen extends StatefulWidget {
  const ScheduleDetailScreen({
    required this.planId,
    this.controller,
    this.inventoryController,
    super.key,
  });

  final String planId;
  final SchedulesController? controller;
  final InventoryController? inventoryController;

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  SchedulesController? _controller;
  InventoryController? _inventory;
  bool _owns = false;
  bool _ownsInventory = false;
  List<PlanInventoryCheck>? _checks;
  bool _checksRequested = false;
  List<PlanRunDay>? _runs;
  bool _runsRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final injected = widget.controller;
    if (injected != null) {
      _controller = injected;
      if (injected.status == SchedulesStatus.idle) injected.load();
    } else {
      _controller = buildSchedulesController(context);
      _owns = true;
      // Archived schedules open from the list's "Show archived" too.
      _controller?.setShowArchived(true);
    }
    _inventory =
        widget.inventoryController ?? buildInventoryController(context);
    _ownsInventory = widget.inventoryController == null;
    if (_inventory?.status == InventoryStatus.idle) _inventory?.load();
    TaskWorkspaceScope.maybeOf(context)?.loadAssignableMembers();
    _controller?.addListener(_loadExtras);
    _loadExtras();
  }

  /// Stock coverage and run history, once the plan is known. Both are
  /// advisory: the page stays usable without them.
  Future<void> _loadExtras() async {
    final plan = _controller?.planById(widget.planId);
    if (plan == null) return;
    if (!_runsRequested) {
      _runsRequested = true;
      try {
        final runs = await _controller!.listRuns(widget.planId);
        if (mounted) setState(() => _runs = runs);
      } catch (_) {}
    }
    if (!_checksRequested && plan.inventoryItemId != null) {
      _checksRequested = true;
      try {
        final rows = await _controller!.checkInventory(widget.planId);
        if (mounted) setState(() => _checks = rows);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_loadExtras);
    if (_owns) _controller?.dispose();
    if (_ownsInventory) _inventory?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // The app shell owns the safe areas; a nested Scaffold/SafeArea would
    // double the top inset below the shell's top bar.
    return PaperBackground(
      child: Material(
        type: MaterialType.transparency,
        child: controller == null
            ? Center(child: Text(context.l10n.schedulesLoadFailed))
            : ListenableBuilder(
                listenable: Listenable.merge(
                  <Listenable?>[controller, _inventory],
                ),
                builder: (context, _) => _body(context, controller),
              ),
      ),
    );
  }

  Widget _body(BuildContext context, SchedulesController controller) {
    final l10n = context.l10n;
    final plan = controller.planById(widget.planId);
    if (plan == null) {
      return controller.status == SchedulesStatus.loading ||
              controller.status == SchedulesStatus.idle
          ? const Center(child: CircularProgressIndicator())
          : Center(child: Text(l10n.schedulesLoadFailed));
    }
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    final occurrences = plan.nextOccurrences(DateTime.now());
    final firstCheck = _checks?.isEmpty ?? true ? null : _checks!.first;
    final members =
        TaskWorkspaceScope.maybeOf(context)?.assignableMembers ?? const [];
    final workerNames = members
        .where(
          (member) => plan.defaultAssigneeProfileIds.contains(member.profileId),
        )
        .map((member) => member.fullName)
        .toList(growable: false);
    final product = plan.inventoryItemId == null
        ? null
        : _inventory?.itemById(plan.inventoryItemId!);
    final muted =
        Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted);

    Widget line(String label, String value, {Key? key}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 2, child: Text(label, style: muted)),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  key: key,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

    return ListView(
      key: const Key('schedule-detail'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            WahatBackButton(
              tooltip: l10n.commonBack,
              onPressed: () => context.go('/more/schedules'),
            ),
            const SizedBox(width: 4),
            OptionBadge(plan.type.visual, size: 44),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Eyebrow(plan.type.localizedLabel(l10n)),
                  Text(plan.title,
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        WahatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  StatusPill(
                    plan.status.visual,
                    plan.status.localizedLabel(l10n),
                  ),
                  Text(
                    scheduleSummary(context, l10n, plan),
                    key: const Key('schedule-detail-summary'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              line(
                l10n.scheduleStartsOn,
                '${_date(plan.startsOn)}'
                '${plan.endsOn == null ? '' : ' → ${_date(plan.endsOn!)}'}',
              ),
              if (plan.plannedDurationMinutes != null)
                line(
                  l10n.scheduleDurationField,
                  l10n.durationMinutes(plan.plannedDurationMinutes!),
                  key: const Key('schedule-detail-duration'),
                ),
              line(
                l10n.scheduleAssigneesTitle,
                plan.defaultAssigneeProfileIds.isEmpty
                    ? l10n.scheduleAllWorkers
                    : workerNames.isEmpty
                        ? '${plan.defaultAssigneeProfileIds.length}'
                        : workerNames.join('، '),
                key: const Key('schedule-detail-workers'),
              ),
              if (plan.taskGrouping == TaskGrouping.combined &&
                  plan.targets.length > 1)
                line(
                  l10n.scheduleGroupingTitle,
                  l10n.scheduleGroupingCombined,
                  key: const Key('schedule-detail-grouping'),
                ),
              if (plan.description != null &&
                  plan.description!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(plan.description!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        WahatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.scheduleTargetsTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: plan.targets
                    .map(
                      (target) => Chip(
                        label: Text(_targetLabel(l10n, target, hierarchy)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
        if (plan.inventoryItemId != null) ...<Widget>[
          const SizedBox(height: 10),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l10n.scheduleProductTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                if (product != null)
                  Text(
                    product.name,
                    key: const Key('schedule-detail-product'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                Text(
                  formatDose(l10n, plan),
                  key: const Key('schedule-detail-dose'),
                ),
                if (plan.applicationMethod != null)
                  Text(plan.applicationMethod!.localizedLabel(l10n)),
                if (firstCheck != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    l10n.schedulePerOccurrence(
                      formatQuantity(firstCheck.requiredTotal),
                      plan.rateUnit?.localizedLabel(l10n) ?? '',
                    ),
                  ),
                  if (firstCheck.applicationsCovered != null)
                    Text(
                      l10n.scheduleCoverage(firstCheck.applicationsCovered!),
                      key: const Key('schedule-detail-coverage'),
                      style: TextStyle(
                        color: firstCheck.sufficient
                            ? AppColors.green
                            : AppColors.issue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (!firstCheck.sufficient)
                    Text(
                      l10n.scheduleInsufficient,
                      key: const Key('schedule-detail-insufficient'),
                      style: const TextStyle(color: AppColors.issue),
                    ),
                ],
              ],
            ),
          ),
        ],
        if (occurrences.isNotEmpty &&
            plan.status != OperationPlanStatus.completed) ...<Widget>[
          const SizedBox(height: 10),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l10n.scheduleNextOccurrences,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (final date in occurrences)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(_date(date)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        _History(runs: _runs),
        if (controller.message != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            controller.message!.call(l10n),
            key: const Key('schedule-detail-message'),
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (plan.status == OperationPlanStatus.archived)
              FilledButton.icon(
                key: const Key('schedule-restore'),
                onPressed: controller.isBusy
                    ? null
                    : () => controller.setStatus(
                          plan.id,
                          OperationPlanStatus.paused,
                        ),
                icon: const Icon(Icons.unarchive_outlined, size: 18),
                label: Text(l10n.scheduleRestore),
              ),
            if (plan.status != OperationPlanStatus.completed &&
                plan.status != OperationPlanStatus.archived)
              FilledButton.icon(
                key: const Key('schedule-edit'),
                onPressed: controller.isBusy
                    ? null
                    : () => context.go('/more/schedules/${plan.id}/edit'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.scheduleEdit),
              ),
            OutlinedButton.icon(
              key: const Key('schedule-copy'),
              onPressed: controller.isBusy
                  ? null
                  : () => context.go('/more/schedules/new?copy=${plan.id}'),
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: Text(l10n.scheduleCopy),
            ),
            if (plan.status == OperationPlanStatus.active)
              OutlinedButton.icon(
                key: const Key('schedule-pause'),
                onPressed: controller.isBusy
                    ? null
                    : () => controller.setStatus(
                        plan.id, OperationPlanStatus.paused),
                icon: const Icon(Icons.pause, size: 18),
                label: Text(l10n.schedulePause),
              )
            else if (plan.status == OperationPlanStatus.paused ||
                plan.status == OperationPlanStatus.draft)
              OutlinedButton.icon(
                key: const Key('schedule-activate'),
                onPressed: controller.isBusy
                    ? null
                    : () => controller.setStatus(
                        plan.id, OperationPlanStatus.active),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(l10n.scheduleActivate),
              ),
            if (plan.status != OperationPlanStatus.archived)
              OutlinedButton.icon(
                key: const Key('schedule-archive'),
                onPressed: controller.isBusy
                    ? null
                    : () => _confirmArchive(context, controller, plan),
                icon: const Icon(Icons.archive_outlined, size: 18),
                label: Text(l10n.scheduleArchive),
              ),
            if (plan.status == OperationPlanStatus.active)
              TextButton.icon(
                key: const Key('schedule-generate-now'),
                onPressed: controller.isBusy
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final count = await controller.generateNow();
                        if (count != null && context.mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.scheduleGenerated(count)),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.bolt_outlined, size: 18),
                label: Text(l10n.scheduleGenerateNow),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    SchedulesController controller,
    OperationPlan plan,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.scheduleArchiveConfirmTitle),
        content: Text(l10n.scheduleArchiveConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('schedule-archive-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.scheduleArchive),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await controller.setStatus(plan.id, OperationPlanStatus.archived);
    if (context.mounted) context.go('/more/schedules');
  }

  String _targetLabel(
    AppLocalizations l10n,
    PlanTarget target,
    FarmHierarchy? hierarchy,
  ) {
    if (target.isFarmWide) return l10n.scheduleTargetFarm;
    if (target.sectionId != null) {
      final code = hierarchy?.sectionById(target.sectionId!)?.code;
      return l10n.mapSectionName(code ?? '?');
    }
    if (target.irrigationZoneId != null) {
      String? code;
      if (hierarchy != null) {
        for (final zone in hierarchy.zones) {
          if (zone.id == target.irrigationZoneId) {
            code = zone.code;
            break;
          }
        }
      }
      return code ?? l10n.scheduleTargetZones;
    }
    String? treeCode;
    if (hierarchy != null) {
      for (final tree in hierarchy.trees) {
        if (tree.id == target.treeId) {
          treeCode = tree.treeCode;
          break;
        }
      }
    }
    return treeCode == null
        ? l10n.targetTreeGeneric
        : l10n.targetTree(treeCode);
  }
}

/// The schedule's past run dates: each date's task status (tap to open the
/// task) or why no task was created.
class _History extends StatelessWidget {
  const _History({required this.runs});

  final List<PlanRunDay>? runs;

  static const _shown = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = runs;
    return WahatCard(
      child: Column(
        key: const Key('schedule-history'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(l10n.scheduleHistoryTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          if (days == null)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (days.isEmpty)
            Text(l10n.scheduleHistoryEmpty)
          else
            for (final day in days.take(_shown))
              Padding(
                key: Key('schedule-history-${_date(day.date)}'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 96,
                      child: Text(
                        _date(day.date),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final task in day.tasks)
                            InkWell(
                              borderRadius: BorderRadius.circular(99),
                              onTap: () => context.go('/tasks/${task.taskId}'),
                              child: StatusPill(
                                task.status.visual,
                                task.status.localizedLabel(l10n),
                              ),
                            ),
                          if (day.blockedForStock)
                            StatusPill(
                              const OptionVisual(
                                Icons.inventory_2,
                                OptionColors.problem,
                              ),
                              l10n.scheduleSkippedStock,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// "100 Grams · Per feddan" for a plan's dose.
String formatDose(AppLocalizations l10n, OperationPlan plan) {
  final rate = plan.applicationRate;
  if (rate == null) return '';
  return l10n.scheduleDose(
    formatQuantity(rate),
    plan.rateUnit?.localizedLabel(l10n) ?? '',
    plan.rateBasis?.localizedLabel(l10n) ?? '',
  );
}

String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
