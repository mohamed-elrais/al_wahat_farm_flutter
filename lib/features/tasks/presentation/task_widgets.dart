import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_visuals.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/option_visuals.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter/material.dart';

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge(this.status, {super.key});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusPill(status.visual, status.localizedLabel(context.l10n));
}

/// Priority as rising bars plus its word; urgent is bold.
class TaskPriorityLabel extends StatelessWidget {
  const TaskPriorityLabel(this.priority, {this.fontSize = 12, super.key});

  final TaskPriority priority;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SeverityBars(priority.visual, height: fontSize + 3),
          const SizedBox(width: 6),
          Text(
            priority.localizedLabel(context.l10n),
            style: TextStyle(
              color: AppColors.ink,
              fontSize: fontSize,
              fontWeight: priority == TaskPriority.urgent
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ],
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

/// Label for one target row of a multi-target task, e.g. "Tree TREE-A-001".
String taskTargetChipLabel(
  AppLocalizations l10n,
  TaskTarget target,
  FarmHierarchy? hierarchy,
) {
  if (target.treeId != null) {
    final tree = hierarchy == null
        ? null
        : _firstWhereOrNull(
            hierarchy.trees,
            (item) => item.id == target.treeId,
          );
    return tree == null
        ? l10n.targetTreeGeneric
        : l10n.targetTree(tree.treeCode);
  }
  if (target.irrigationZoneId != null) {
    final zone = hierarchy == null
        ? null
        : _firstWhereOrNull(
            hierarchy.zones,
            (item) => item.id == target.irrigationZoneId,
          );
    return zone == null ? l10n.targetZoneGeneric : l10n.targetZone(zone.code);
  }
  if (target.sectionId != null) {
    final section = hierarchy?.sectionById(target.sectionId!);
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
