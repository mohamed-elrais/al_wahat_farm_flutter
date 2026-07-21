import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_controller.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScheduleDetailScreen extends StatefulWidget {
  const ScheduleDetailScreen({
    required this.planId,
    this.controller,
    super.key,
  });

  final String planId;
  final SchedulesController? controller;

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  SchedulesController? _controller;
  bool _owns = false;
  List<PlanInventoryCheck>? _checks;
  bool _checksRequested = false;

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
      _controller?.load();
    }
    _controller?.addListener(_maybeLoadChecks);
    _maybeLoadChecks();
  }

  Future<void> _maybeLoadChecks() async {
    if (_checksRequested) return;
    final plan = _controller?.planById(widget.planId);
    if (plan == null || plan.inventoryItemId == null) return;
    _checksRequested = true;
    try {
      final rows = await _controller!.checkInventory(widget.planId);
      if (mounted) setState(() => _checks = rows);
    } catch (_) {
      // Coverage is advisory; the detail stays usable without it.
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_maybeLoadChecks);
    if (_owns) _controller?.dispose();
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
                listenable: controller,
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
    return ListView(
      key: const Key('schedule-detail'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              tooltip: l10n.commonBack,
              onPressed: () => context.go('/more/schedules'),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 4),
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
              Text(
                '${plan.status.localizedLabel(l10n)} · '
                '${scheduleSummary(context, l10n, plan)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text('${l10n.scheduleStartsOn}: ${_date(plan.startsOn)}'
                  '${plan.endsOn == null ? '' : ' → ${_date(plan.endsOn!)}'}'),
              if (plan.plannedDurationMinutes != null)
                Text('${l10n.scheduleDurationField}: '
                    '${plan.plannedDurationMinutes}'),
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
                Text(
                  '${formatRate(plan)}'
                  '${plan.applicationMethod == null ? '' : ' · ${plan.applicationMethod!.localizedLabel(l10n)}'}',
                ),
                if (firstCheck != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    l10n.schedulePerOccurrence(
                      _quantity(firstCheck.requiredTotal),
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
        if (occurrences.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(l10n.scheduleNextOccurrences,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                for (final date in occurrences) Text('• ${_date(date)}'),
              ],
            ),
          ),
        ],
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
              FilledButton.icon(
                key: const Key('schedule-activate'),
                onPressed: controller.isBusy
                    ? null
                    : () => controller.setStatus(
                        plan.id, OperationPlanStatus.active),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text(l10n.scheduleActivate),
              ),
            OutlinedButton.icon(
              key: const Key('schedule-archive'),
              onPressed: controller.isBusy
                  ? null
                  : () async {
                      await controller.setStatus(
                          plan.id, OperationPlanStatus.archived);
                      if (context.mounted) context.go('/more/schedules');
                    },
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: Text(l10n.scheduleArchive),
            ),
            if (plan.status == OperationPlanStatus.active)
              OutlinedButton.icon(
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
    return l10n.targetTreeGeneric;
  }
}

String formatRate(OperationPlan plan) {
  final rate = plan.applicationRate;
  if (rate == null) return '';
  final basisText = plan.rateBasis?.wireValue ?? '';
  return '${_quantity(rate)} / $basisText';
}

String _quantity(double value) => value
    .toStringAsFixed(3)
    .replaceFirst(RegExp(r'0+$'), '')
    .replaceFirst(RegExp(r'\.$'), '');

String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';
