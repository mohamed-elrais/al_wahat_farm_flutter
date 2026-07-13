import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:flutter/material.dart';

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge(this.status, {super.key});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: _statusColor(status).withOpacity(0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _statusColor(status).withOpacity(0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            status.localizedLabel(context.l10n),
            style: TextStyle(
              color: _statusColor(status),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
}

String taskTargetLabel(
  AppLocalizations l10n,
  FarmTask task,
  FarmHierarchy? hierarchy,
) {
  if (task.treeId != null) {
    final tree = hierarchy == null
        ? null
        : _firstWhereOrNull(hierarchy.trees, (item) => item.id == task.treeId);
    return tree == null
        ? l10n.targetTreeGeneric
        : l10n.targetTree(tree.treeCode);
  }
  if (task.irrigationZoneId != null) {
    final zone = hierarchy == null
        ? null
        : _firstWhereOrNull(
            hierarchy.zones,
            (item) => item.id == task.irrigationZoneId,
          );
    return zone == null ? l10n.targetZoneGeneric : l10n.targetZone(zone.code);
  }
  if (task.sectionId != null) {
    final section = hierarchy?.sectionById(task.sectionId!);
    return section == null
        ? l10n.targetSectionGeneric
        : l10n.targetSection(section.code);
  }
  return l10n.targetWholeFarm;
}

String taskScheduleLabel(AppLocalizations l10n, FarmTask task) {
  final scheduled = task.scheduledFor;
  if (scheduled != null) {
    final date = _dateLabel(scheduled);
    final time = task.plannedStartTime;
    return time == null || time.isEmpty ? date : '$date · ${_shortTime(time)}';
  }
  final due = task.dueAt?.toLocal();
  return due == null
      ? l10n.scheduleNotScheduled
      : l10n.scheduleDue(_dateTimeLabel(due));
}

String taskDateTimeLabel(DateTime value) => _dateTimeLabel(value.toLocal());

Color _statusColor(TaskStatus status) => switch (status) {
      TaskStatus.draft => AppColors.muted,
      TaskStatus.assigned => AppColors.waterMain,
      TaskStatus.inProgress => AppColors.orange,
      TaskStatus.completed => AppColors.green,
      TaskStatus.needsEngineerReview => AppColors.issue,
      TaskStatus.approved => AppColors.green,
      TaskStatus.returned => AppColors.issue,
      TaskStatus.cancelled => AppColors.muted,
    };

String _dateLabel(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTimeLabel(DateTime value) => '${_dateLabel(value)} · '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

String _shortTime(String value) =>
    value.length >= 5 ? value.substring(0, 5) : value;

T? _firstWhereOrNull<T>(Iterable<T> values, bool Function(T) matches) {
  for (final value in values) {
    if (matches(value)) return value;
  }
  return null;
}
