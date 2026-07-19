import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_create_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum _TaskScope { farm, section, zone, tree }

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({
    this.initialTreeId,
    this.initialZoneId,
    this.initialSectionId,
    this.controller,
    this.workspace,
    this.hierarchy,
    this.role,
    this.farmId,
    this.assignableMembers,
    this.onCreated,
    super.key,
  });

  final String? initialTreeId;
  final String? initialZoneId;
  final String? initialSectionId;
  final TaskCreateController? controller;
  final TaskWorkspaceController? workspace;
  final FarmHierarchy? hierarchy;
  final FarmRole? role;
  final String? farmId;
  final List<TaskAssignee>? assignableMembers;
  final ValueChanged<String>? onCreated;

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _durationController = TextEditingController();
  TaskCreateController? _controller;
  TaskWorkspaceController? _workspace;
  bool _ownsController = false;
  bool _membersRequested = false;
  bool _initialTargetApplied = false;
  TaskType _type = TaskType.general;
  TaskPriority _priority = TaskPriority.medium;
  _TaskScope _scope = _TaskScope.farm;
  // Insertion-ordered: the first selection becomes the primary target.
  final List<String> _targetIds = <String>[];
  DateTime? _scheduledFor;
  TimeOfDay? _plannedStart;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _requiresReview = false;
  final Set<String> _assigneeIds = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _workspace ??= widget.workspace ?? TaskWorkspaceScope.maybeOf(context);
    if (_controller == null) {
      final injected = widget.controller;
      if (injected != null) {
        _controller = injected;
      } else if (_workspace != null) {
        _controller = TaskCreateController(
          repository: _workspace!.repository,
          onCreated: _workspace!.refresh,
        );
        _ownsController = true;
      }
    }

    final role = _role;
    if (!_membersRequested &&
        role?.canManageTasks == true &&
        widget.assignableMembers == null &&
        _workspace != null) {
      _membersRequested = true;
      _workspace!.loadAssignableMembers();
    }

    final treeId = widget.initialTreeId;
    final zoneId = widget.initialZoneId;
    final sectionId = widget.initialSectionId;
    final hierarchy = _hierarchy;
    if (!_initialTargetApplied &&
        hierarchy != null &&
        (treeId != null || zoneId != null || sectionId != null)) {
      _initialTargetApplied = true;
      if (treeId != null && hierarchy.trees.any((tree) => tree.id == treeId)) {
        _scope = _TaskScope.tree;
        _targetIds.add(treeId);
      } else if (zoneId != null &&
          hierarchy.zones.any((zone) => zone.id == zoneId)) {
        _scope = _TaskScope.zone;
        _targetIds.add(zoneId);
      } else if (sectionId != null &&
          hierarchy.sections.any((section) => section.id == sectionId)) {
        _scope = _TaskScope.section;
        _targetIds.add(sectionId);
      }
    }
  }

  FarmRole? get _role =>
      widget.role ??
      OperationalContextScope.maybeOf(context)?.selectedMembership.role;

  String? get _farmId =>
      widget.farmId ??
      OperationalContextScope.maybeOf(context)?.selectedMembership.farm.id;

  FarmHierarchy? get _hierarchy =>
      widget.hierarchy ?? FarmHierarchyScope.maybeOf(context)?.hierarchy;

  @override
  void dispose() {
    if (_ownsController) _controller?.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    final hierarchy = _hierarchy;
    final controller = _controller;
    if (role?.canManageTasks != true) {
      return _CreateUnavailable(
        message: context.l10n.createUnavailableRole,
      );
    }
    if (hierarchy == null || controller == null || _farmId == null) {
      return _CreateUnavailable(
        message: context.l10n.createUnavailableWorkspace,
      );
    }

    final workspace = _workspace;
    return PaperBackground(
      child: Material(
        type: MaterialType.transparency,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => workspace == null
              ? _buildForm(context, controller, hierarchy)
              : ListenableBuilder(
                  listenable: workspace,
                  builder: (context, _) =>
                      _buildForm(context, controller, hierarchy),
                ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    TaskCreateController controller,
    FarmHierarchy hierarchy,
  ) {
    final members = widget.assignableMembers ??
        _workspace?.assignableMembers ??
        const <TaskAssignee>[];
    final membersLoading = widget.assignableMembers == null &&
        (_workspace?.membersLoading ?? false);
    final membersError =
        widget.assignableMembers == null ? _workspace?.membersError : null;
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('task-create-form'),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                tooltip: context.l10n.backToTasks,
                onPressed: () => context.go('/tasks'),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Eyebrow(context.l10n.createEyebrow),
                    Text(
                      context.l10n.createTitle,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  key: const Key('task-title-field'),
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration:
                      InputDecoration(labelText: context.l10n.taskTitleField),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.l10n.enterTaskTitle
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskType>(
                  key: const Key('task-type-field'),
                  value: _type,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: context.l10n.taskTypeField),
                  items: TaskType.values
                      .map(
                        (type) => DropdownMenuItem<TaskType>(
                          value: type,
                          child: Text(type.localizedLabel(context.l10n)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.isSubmitting
                      ? null
                      : (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration:
                      InputDecoration(labelText: context.l10n.descriptionField),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructionsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: context.l10n.workerInstructionsField,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(context.l10n.targetTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                DropdownButtonFormField<_TaskScope>(
                  key: const Key('task-scope-field'),
                  value: _scope,
                  decoration:
                      InputDecoration(labelText: context.l10n.scopeField),
                  items: <DropdownMenuItem<_TaskScope>>[
                    DropdownMenuItem(
                      value: _TaskScope.farm,
                      child: Text(context.l10n.scopeWholeFarm),
                    ),
                    DropdownMenuItem(
                      value: _TaskScope.section,
                      child: Text(context.l10n.scopeSection),
                    ),
                    DropdownMenuItem(
                      value: _TaskScope.zone,
                      child: Text(context.l10n.scopeZone),
                    ),
                    DropdownMenuItem(
                      value: _TaskScope.tree,
                      child: Text(context.l10n.scopeTree),
                    ),
                  ],
                  onChanged: controller.isSubmitting
                      ? null
                      : (value) => setState(() {
                            // Changing the kind resets the selection — all
                            // targets of one task share a single kind.
                            _scope = value ?? _scope;
                            _targetIds.clear();
                          }),
                ),
                if (_scope != _TaskScope.farm) ...<Widget>[
                  const SizedBox(height: 12),
                  _TargetField(
                    scope: _scope,
                    hierarchy: hierarchy,
                    selectedIds: _targetIds,
                    enabled: !controller.isSubmitting,
                    onAdded: (value) => setState(() {
                      if (value != null && !_targetIds.contains(value)) {
                        _targetIds.add(value);
                      }
                    }),
                  ),
                  if (_targetIds.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final id in _targetIds)
                          InputChip(
                            key: Key('task-target-chip-$id'),
                            label: Text(
                              _targetChipLabel(hierarchy, _scope, id),
                            ),
                            onDeleted: controller.isSubmitting
                                ? null
                                : () => setState(() => _targetIds.remove(id)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.scheduleTargetCount(_targetIds.length),
                      key: const Key('task-target-count'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(context.l10n.scheduleTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    OutlinedButton.icon(
                      key: const Key('task-scheduled-date'),
                      onPressed: controller.isSubmitting
                          ? null
                          : () => _pickDate(isDue: false),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_scheduledFor == null
                          ? context.l10n.scheduledDate
                          : _formatDate(_scheduledFor!)),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.isSubmitting
                          ? null
                          : () => _pickTime(isDue: false),
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(_plannedStart == null
                          ? context.l10n.startTimeLabel
                          : _plannedStart!.format(context)),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.isSubmitting
                          ? null
                          : () => _pickDate(isDue: true),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text(_dueDate == null
                          ? context.l10n.dueDateLabel
                          : _formatDate(_dueDate!)),
                    ),
                    if (_dueDate != null)
                      OutlinedButton.icon(
                        onPressed: controller.isSubmitting
                            ? null
                            : () => _pickTime(isDue: true),
                        icon: const Icon(Icons.timer_outlined),
                        label: Text(_dueTime == null
                            ? context.l10n.dueTimeLabel
                            : _dueTime!.format(context)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('task-duration-field'),
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.l10n.plannedDurationField,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final minutes = int.tryParse(value.trim());
                    return minutes == null || minutes <= 0
                        ? context.l10n.enterPositiveMinutes
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskPriority>(
                  value: _priority,
                  decoration:
                      InputDecoration(labelText: context.l10n.priorityField),
                  items: TaskPriority.values
                      .map(
                        (priority) => DropdownMenuItem<TaskPriority>(
                          value: priority,
                          child: Text(priority.localizedLabel(context.l10n)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.isSubmitting
                      ? null
                      : (value) =>
                          setState(() => _priority = value ?? _priority),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.requireEngineerReview),
                  value: _requiresReview,
                  onChanged: controller.isSubmitting
                      ? null
                      : (value) => setState(() => _requiresReview = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(context.l10n.assignmentsTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                if (membersLoading)
                  const LinearProgressIndicator()
                else if (membersError != null)
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(context.l10n.membersLoadFailed),
                      ),
                      TextButton(
                        onPressed: _workspace?.loadAssignableMembers,
                        child: Text(context.l10n.commonRetry),
                      ),
                    ],
                  )
                else if (members.isEmpty)
                  Text(context.l10n.noOperationalMembers)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: members
                        .map(
                          (member) => FilterChip(
                            key: Key('assignee-${member.profileId}'),
                            label: Text('${member.fullName} · ${member.role}'),
                            selected: _assigneeIds.contains(member.profileId),
                            onSelected: controller.isSubmitting
                                ? null
                                : (selected) => setState(() {
                                      if (selected) {
                                        _assigneeIds.add(member.profileId);
                                      } else {
                                        _assigneeIds.remove(member.profileId);
                                      }
                                    }),
                          ),
                        )
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
          if (controller.message != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              controller.message!.call(context.l10n),
              key: const Key('task-create-message'),
              style: TextStyle(
                color: controller.status == TaskCreateStatus.failure
                    ? Theme.of(context).colorScheme.error
                    : AppColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('task-submit-button'),
            onPressed: controller.isSubmitting ? null : _submit,
            icon: controller.isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.task_alt),
            label: Text(controller.isSubmitting
                ? context.l10n.creatingTask
                : context.l10n.createTaskButton),
          ),
        ],
      ),
    );
  }

  String _targetChipLabel(
    FarmHierarchy hierarchy,
    _TaskScope scope,
    String id,
  ) {
    for (final entry in _targetEntries(hierarchy, scope)) {
      if (entry.key == id) return entry.value;
    }
    return id;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scope != _TaskScope.farm && _targetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chooseTargetSnack)),
      );
      return;
    }
    final instructions = _instructionsController.text.trim();
    final draft = TaskDraft(
      farmId: _farmId!,
      type: _type,
      title: _titleController.text,
      description: _optionalText(_descriptionController.text),
      targets: _scope == _TaskScope.farm
          ? const <TaskTarget>[]
          : List<TaskTarget>.unmodifiable(
              _targetIds.map(
                (id) => TaskTarget(
                  sectionId: _scope == _TaskScope.section ? id : null,
                  irrigationZoneId: _scope == _TaskScope.zone ? id : null,
                  treeId: _scope == _TaskScope.tree ? id : null,
                ),
              ),
            ),
      scheduledFor: _scheduledFor,
      plannedStartTime:
          _plannedStart == null ? null : _databaseTime(_plannedStart!),
      plannedDurationMinutes: int.tryParse(_durationController.text.trim()),
      dueAt: _combineDueDate(),
      priority: _priority,
      instructions: instructions.isEmpty
          ? const <String, Object?>{}
          : <String, Object?>{'text': instructions},
      requiresEngineerReview: _requiresReview,
      assigneeProfileIds: _assigneeIds.toList(growable: false),
    );
    final taskId = await _controller!.submit(draft);
    if (!mounted) return;
    if (taskId == null) return;
    final callback = widget.onCreated;
    if (callback != null) {
      callback(taskId);
    } else if (taskId.startsWith(localTaskIdPrefix)) {
      // Queued offline: there is no server detail to open yet — return to the
      // list, where the task shows as pending sync.
      context.go('/tasks');
    } else {
      context.go('/tasks/$taskId');
    }
  }

  Future<void> _pickDate({required bool isDue}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: isDue ? (_dueDate ?? now) : (_scheduledFor ?? now),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isDue) {
        _dueDate = selected;
      } else {
        _scheduledFor = selected;
      }
    });
  }

  Future<void> _pickTime({required bool isDue}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isDue
          ? (_dueTime ?? const TimeOfDay(hour: 17, minute: 0))
          : (_plannedStart ?? TimeOfDay.now()),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (isDue) {
        _dueTime = selected;
      } else {
        _plannedStart = selected;
      }
    });
  }

  DateTime? _combineDueDate() {
    final date = _dueDate;
    if (date == null) return null;
    final time = _dueTime ?? const TimeOfDay(hour: 17, minute: 0);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

/// Add-one-more picker for the target list: already-selected entities are
/// hidden, and picking an entry appends it (the dropdown resets so another
/// can be added).
class _TargetField extends StatelessWidget {
  const _TargetField({
    required this.scope,
    required this.hierarchy,
    required this.selectedIds,
    required this.enabled,
    required this.onAdded,
  });

  final _TaskScope scope;
  final FarmHierarchy hierarchy;
  final List<String> selectedIds;
  final bool enabled;
  final ValueChanged<String?> onAdded;

  @override
  Widget build(BuildContext context) {
    final items = _targetEntries(hierarchy, scope)
        .where((entry) => !selectedIds.contains(entry.key));
    return DropdownButtonFormField<String>(
      // Recreated after every add so the picker clears for the next one.
      key: ValueKey<String>('task-target-field-${selectedIds.length}'),
      value: null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: selectedIds.isEmpty
            ? _scopeLabel(context.l10n, scope)
            : context.l10n.addAnotherTarget,
      ),
      items: items
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: enabled ? onAdded : null,
      validator: (_) =>
          selectedIds.isEmpty ? context.l10n.chooseTargetValidator : null,
    );
  }
}

Iterable<MapEntry<String, String>> _targetEntries(
  FarmHierarchy hierarchy,
  _TaskScope scope,
) =>
    switch (scope) {
      _TaskScope.section => hierarchy.sections
          .map((item) => MapEntry(item.id, '${item.code} · ${item.name}')),
      _TaskScope.zone => hierarchy.zones
          .map((item) => MapEntry(item.id, '${item.code} · ${item.name}')),
      _TaskScope.tree =>
        hierarchy.trees.map((item) => MapEntry(item.id, item.treeCode)),
      _TaskScope.farm => const Iterable<MapEntry<String, String>>.empty(),
    };

class _CreateUnavailable extends StatelessWidget {
  const _CreateUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PaperBackground(
          child: Center(
            child: WahatCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.lock_outline, size: 38),
                  const SizedBox(height: 10),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: () => context.go('/tasks'),
                    child: Text(context.l10n.backToTasks),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

String _scopeLabel(AppLocalizations l10n, _TaskScope scope) => switch (scope) {
      _TaskScope.farm => l10n.scopeWholeFarm,
      _TaskScope.section => l10n.scopeSection,
      _TaskScope.zone => l10n.scopeZone,
      _TaskScope.tree => l10n.scopeTree,
    };

String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String _databaseTime(TimeOfDay value) =>
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}:00';

String? _optionalText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
