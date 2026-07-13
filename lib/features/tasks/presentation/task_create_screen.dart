import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
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
  String? _targetId;
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
    final hierarchy = _hierarchy;
    if (!_initialTargetApplied && treeId != null && hierarchy != null) {
      _initialTargetApplied = true;
      if (hierarchy.trees.any((tree) => tree.id == treeId)) {
        _scope = _TaskScope.tree;
        _targetId = treeId;
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
      return const _CreateUnavailable(
        message: 'Your farm role cannot create or assign tasks.',
      );
    }
    if (hierarchy == null || controller == null || _farmId == null) {
      return const _CreateUnavailable(
        message: 'The farm task workspace is not ready.',
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
                tooltip: 'Back to tasks',
                onPressed: () => context.go('/tasks'),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Eyebrow('Plan field work'),
                    Text(
                      'Create task',
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
                  decoration: const InputDecoration(labelText: 'Task title *'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a task title'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskType>(
                  key: const Key('task-type-field'),
                  value: _type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Task type'),
                  items: TaskType.values
                      .map(
                        (type) => DropdownMenuItem<TaskType>(
                          value: type,
                          child: Text(type.label),
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
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _instructionsController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Worker instructions',
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
                Text('Target', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                DropdownButtonFormField<_TaskScope>(
                  key: const Key('task-scope-field'),
                  value: _scope,
                  decoration: const InputDecoration(labelText: 'Scope'),
                  items: const <DropdownMenuItem<_TaskScope>>[
                    DropdownMenuItem(
                      value: _TaskScope.farm,
                      child: Text('Whole farm'),
                    ),
                    DropdownMenuItem(
                      value: _TaskScope.section,
                      child: Text('Section'),
                    ),
                    DropdownMenuItem(
                      value: _TaskScope.zone,
                      child: Text('Irrigation zone'),
                    ),
                    DropdownMenuItem(
                      value: _TaskScope.tree,
                      child: Text('Tree'),
                    ),
                  ],
                  onChanged: controller.isSubmitting
                      ? null
                      : (value) => setState(() {
                            _scope = value ?? _scope;
                            _targetId = null;
                          }),
                ),
                if (_scope != _TaskScope.farm) ...<Widget>[
                  const SizedBox(height: 12),
                  _TargetField(
                    scope: _scope,
                    hierarchy: hierarchy,
                    value: _targetId,
                    enabled: !controller.isSubmitting,
                    onChanged: (value) => setState(() => _targetId = value),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Schedule', style: Theme.of(context).textTheme.titleLarge),
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
                          ? 'Scheduled date'
                          : _formatDate(_scheduledFor!)),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.isSubmitting
                          ? null
                          : () => _pickTime(isDue: false),
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(_plannedStart == null
                          ? 'Start time'
                          : _plannedStart!.format(context)),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.isSubmitting
                          ? null
                          : () => _pickDate(isDue: true),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text(_dueDate == null
                          ? 'Due date'
                          : _formatDate(_dueDate!)),
                    ),
                    if (_dueDate != null)
                      OutlinedButton.icon(
                        onPressed: controller.isSubmitting
                            ? null
                            : () => _pickTime(isDue: true),
                        icon: const Icon(Icons.timer_outlined),
                        label: Text(_dueTime == null
                            ? 'Due time'
                            : _dueTime!.format(context)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('task-duration-field'),
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Planned duration (minutes)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final minutes = int.tryParse(value.trim());
                    return minutes == null || minutes <= 0
                        ? 'Enter a positive number of minutes'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TaskPriority>(
                  value: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: TaskPriority.values
                      .map(
                        (priority) => DropdownMenuItem<TaskPriority>(
                          value: priority,
                          child: Text(priority.label),
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
                  title: const Text('Require engineer review'),
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
                Text('Assignments',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                if (membersLoading)
                  const LinearProgressIndicator()
                else if (membersError != null)
                  Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text('Assignable farm members could not load.'),
                      ),
                      TextButton(
                        onPressed: _workspace?.loadAssignableMembers,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                else if (members.isEmpty)
                  const Text('No active operational members are available.')
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
              controller.message!,
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
            label: Text(controller.isSubmitting ? 'Creating…' : 'Create task'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scope != _TaskScope.farm && _targetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a target for this task.')),
      );
      return;
    }
    final instructions = _instructionsController.text.trim();
    final draft = TaskDraft(
      farmId: _farmId!,
      type: _type,
      title: _titleController.text,
      description: _optionalText(_descriptionController.text),
      sectionId: _scope == _TaskScope.section ? _targetId : null,
      irrigationZoneId: _scope == _TaskScope.zone ? _targetId : null,
      treeId: _scope == _TaskScope.tree ? _targetId : null,
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

class _TargetField extends StatelessWidget {
  const _TargetField({
    required this.scope,
    required this.hierarchy,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final _TaskScope scope;
  final FarmHierarchy hierarchy;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = switch (scope) {
      _TaskScope.section => hierarchy.sections
          .map((item) => MapEntry(item.id, '${item.code} · ${item.name}')),
      _TaskScope.zone => hierarchy.zones
          .map((item) => MapEntry(item.id, '${item.code} · ${item.name}')),
      _TaskScope.tree =>
        hierarchy.trees.map((item) => MapEntry(item.id, item.treeCode)),
      _TaskScope.farm => const Iterable<MapEntry<String, String>>.empty(),
    };
    return DropdownButtonFormField<String>(
      key: const Key('task-target-field'),
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: _scopeLabel(scope)),
      items: items
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: enabled ? onChanged : null,
      validator: (selected) => selected == null ? 'Choose a target' : null,
    );
  }
}

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
                    child: const Text('Back to tasks'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

String _scopeLabel(_TaskScope scope) => switch (scope) {
      _TaskScope.farm => 'Whole farm',
      _TaskScope.section => 'Section',
      _TaskScope.zone => 'Irrigation zone',
      _TaskScope.tree => 'Tree',
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
