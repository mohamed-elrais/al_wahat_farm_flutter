import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/schedules/data/schedule_repository.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SchedulesController? buildSchedulesController(BuildContext context) {
  final operational = OperationalContextScope.maybeOf(context);
  if (operational == null) return null;
  return SchedulesController(
    repository: SupabaseScheduleRepository(Supabase.instance.client),
    farmId: operational.selectedMembership.farm.id,
  );
}

/// "Weekly · Mon, Fri · 08:00" style summary for a plan.
String scheduleSummary(
  BuildContext context,
  AppLocalizations l10n,
  OperationPlan plan,
) {
  final parts = <String>[plan.scheduleType.localizedLabel(l10n)];
  if (plan.scheduleType == PlanScheduleType.weekly &&
      (plan.daysOfWeek?.isNotEmpty ?? false)) {
    parts.add(
      plan.daysOfWeek!.map((day) => weekdayShortLabel(context, day)).join('، '),
    );
  }
  final time = plan.scheduledStartTime;
  if (time != null && time.length >= 5) parts.add(time.substring(0, 5));
  return parts.join(' · ');
}

/// Localized short weekday name for an ISO weekday number (1 = Monday).
String weekdayShortLabel(BuildContext context, int isoWeekday) {
  // 2024-01-01 was a Monday.
  final anchor = DateTime(2024, 1, 1).add(Duration(days: isoWeekday - 1));
  return DateFormat.E(Localizations.localeOf(context).toString())
      .format(anchor);
}

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({this.controller, super.key});

  final SchedulesController? controller;

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  SchedulesController? _controller;
  bool _owns = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final injected = widget.controller;
    if (injected != null) {
      _controller = injected;
      if (injected.status == SchedulesStatus.idle) injected.load();
      return;
    }
    _controller = buildSchedulesController(context);
    _owns = true;
    _controller?.load();
  }

  @override
  void dispose() {
    if (_owns) _controller?.dispose();
    super.dispose();
  }

  bool get _canManage =>
      OperationalContextScope.maybeOf(context)
          ?.selectedMembership
          .role
          .canManageSchedules ??
      false;

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: controller == null || !_canManage
              ? Center(child: Text(context.l10n.schedulesLoadFailed))
              : ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => _body(context, controller),
                ),
        ),
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              key: const Key('schedule-new'),
              onPressed: () => context.go('/more/schedules/new'),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.scheduleNew),
            )
          : null,
    );
  }

  Widget _body(BuildContext context, SchedulesController controller) {
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        key: const Key('schedules-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                tooltip: l10n.commonBack,
                onPressed: () => context.go('/more'),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Eyebrow(l10n.schedulesEyebrow),
                    Text(
                      l10n.schedulesTitle,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.message != null) ...<Widget>[
            Text(
              controller.message!.call(l10n),
              key: const Key('schedules-message'),
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (controller.status == SchedulesStatus.loading &&
              controller.plans.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (controller.status == SchedulesStatus.failure &&
              controller.plans.isEmpty)
            WahatCard(
              child: Column(
                children: <Widget>[
                  const Icon(Icons.sync_problem_outlined,
                      size: 38, color: AppColors.green),
                  const SizedBox(height: 10),
                  Text(l10n.schedulesLoadFailed, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: controller.load,
                    child: Text(l10n.commonRetry),
                  ),
                ],
              ),
            )
          else if (controller.plans.isEmpty)
            WahatCard(
              child: Column(
                children: <Widget>[
                  const Icon(Icons.event_repeat_outlined,
                      size: 38, color: AppColors.green),
                  const SizedBox(height: 10),
                  Text(l10n.schedulesEmptyTitle,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(l10n.schedulesEmptyMessage, textAlign: TextAlign.center),
                ],
              ),
            )
          else
            for (final plan in controller.plans) ...<Widget>[
              _PlanTile(
                plan: plan,
                onTap: () => context.go('/more/schedules/${plan.id}'),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.onTap});

  final OperationPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return WahatCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        key: Key('schedule-${plan.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: AppColors.softGreen,
                foregroundColor: AppColors.green,
                child: Icon(planTypeIcon(plan.type)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(plan.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${plan.type.localizedLabel(l10n)} · '
                      '${scheduleSummary(context, l10n, plan)} · '
                      '${l10n.scheduleTargetCount(plan.targets.length)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusChip(status: plan.status),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OperationPlanStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OperationPlanStatus.active => AppColors.green,
      OperationPlanStatus.paused => AppColors.orange,
      OperationPlanStatus.draft => AppColors.muted,
      OperationPlanStatus.completed => AppColors.waterMain,
      OperationPlanStatus.archived => AppColors.muted,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          status.localizedLabel(context.l10n),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

IconData planTypeIcon(OperationPlanType type) => switch (type) {
      OperationPlanType.irrigation => Icons.water_drop_outlined,
      OperationPlanType.fertilization => Icons.compost_outlined,
      OperationPlanType.harmfulWeedControl => Icons.grass_outlined,
      OperationPlanType.pestControl => Icons.pest_control_outlined,
      OperationPlanType.diseaseControl => Icons.coronavirus_outlined,
    };
