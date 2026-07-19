import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/sync_scope.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/offline_evidence_queue.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_evidence_service.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_widgets.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({
    required this.taskId,
    this.controller,
    this.workspace,
    this.hierarchy,
    this.role,
    this.userId,
    this.farmId,
    this.assignableMembers,
    super.key,
  });

  final String taskId;
  final TaskDetailController? controller;
  final TaskWorkspaceController? workspace;
  final FarmHierarchy? hierarchy;
  final FarmRole? role;
  final String? userId;
  final String? farmId;
  final List<TaskAssignee>? assignableMembers;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  TaskDetailController? _controller;
  TaskWorkspaceController? _workspace;
  bool _ownsController = false;
  bool _membersRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _workspace ??= widget.workspace ?? TaskWorkspaceScope.maybeOf(context);
    if (_controller == null) {
      final injected = widget.controller;
      if (injected != null) {
        _controller = injected;
      } else {
        final contextData = OperationalContextScope.maybeOf(context);
        final workspace = _workspace;
        final userId = widget.userId ?? contextData?.profile.id;
        final farmId = widget.farmId ?? contextData?.selectedMembership.farm.id;
        if (workspace != null && userId != null && farmId != null) {
          final client = Supabase.instance.client;
          final services = AppServicesScope.maybeOf(context);
          final syncEngine = SyncScope.maybeOf(context);
          final offlineEvidence = services != null && syncEngine != null
              ? OutboxEvidenceQueue(
                  outbox: services.outbox,
                  pendingPhotos: services.pendingPhotos,
                  syncEngine: syncEngine,
                )
              : null;
          _controller = TaskDetailController(
            repository: workspace.repository,
            evidencePicker: DeviceTaskEvidencePicker(),
            evidenceStorage: SupabaseTaskEvidenceStorage(client),
            taskId: widget.taskId,
            farmId: farmId,
            userId: userId,
            onMutated: workspace.refresh,
            connectivity: services?.connectivity,
            offlineEvidence: offlineEvidence,
          );
          _ownsController = true;
        }
      }
      _controller?.load();
    }

    final role = _role;
    if (!_membersRequested &&
        role?.canManageTasks == true &&
        widget.assignableMembers == null &&
        _workspace != null) {
      _membersRequested = true;
      _workspace!.loadAssignableMembers();
    }
  }

  FarmRole? get _role =>
      widget.role ??
      OperationalContextScope.maybeOf(context)?.selectedMembership.role;

  FarmHierarchy? get _hierarchy =>
      widget.hierarchy ?? FarmHierarchyScope.maybeOf(context)?.hierarchy;

  @override
  void dispose() {
    if (_ownsController) _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || _role == null) {
      return Scaffold(
        body: PaperBackground(
          child: Center(child: Text(context.l10n.taskWorkspaceUnavailable)),
        ),
      );
    }
    final workspace = _workspace;
    return Scaffold(
      body: PaperBackground(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => workspace == null
              ? _buildBody(context, controller)
              : ListenableBuilder(
                  listenable: workspace,
                  builder: (context, _) => _buildBody(context, controller),
                ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TaskDetailController controller) {
    if (controller.status == TaskDetailStatus.loading ||
        controller.status == TaskDetailStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    final details = controller.details;
    if (controller.status == TaskDetailStatus.failure || details == null) {
      return _DetailFailure(
        message: controller.message?.call(context.l10n) ??
            context.l10n.unableToLoadTask,
        onRetry: controller.load,
      );
    }
    final task = details.task;
    final role = _role!;
    return ListView(
      key: const Key('task-detail-list'),
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
                  Eyebrow(context.l10n.taskDetailEyebrow),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
            ),
            TaskStatusBadge(task.status),
          ],
        ),
        if (controller.isBusy) ...<Widget>[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 6),
          Text(_stageLabel(context.l10n, controller.stage)),
        ],
        if (controller.message != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            controller.message!.call(context.l10n),
            key: const Key('task-detail-message'),
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 14),
        WahatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _DetailRow(
                icon: Icons.category_outlined,
                label: context.l10n.detailType,
                value: task.type.localizedLabel(context.l10n),
              ),
              _DetailRow(
                icon: Icons.place_outlined,
                label: context.l10n.detailTarget,
                value: taskTargetLabel(context.l10n, task, _hierarchy),
              ),
              _DetailRow(
                icon: Icons.event_outlined,
                label: context.l10n.detailSchedule,
                value: taskScheduleLabel(context.l10n, task),
              ),
              _DetailRow(
                icon: Icons.priority_high,
                label: context.l10n.detailPriority,
                value: task.priority.localizedLabel(context.l10n),
              ),
              if (task.plannedDurationMinutes != null)
                _DetailRow(
                  icon: Icons.timer_outlined,
                  label: context.l10n.detailPlannedDuration,
                  value: context.l10n.durationMinutes(
                    task.plannedDurationMinutes!,
                  ),
                ),
              if (_productLine(context, task.instructions) != null)
                _DetailRow(
                  icon: Icons.science_outlined,
                  label: context.l10n.taskProductTitle,
                  value: _productLine(context, task.instructions)!,
                ),
              if (task.description != null &&
                  task.description!.isNotEmpty) ...<Widget>[
                const Divider(height: 24),
                Text(context.l10n.detailDescription,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(task.description!),
              ],
              if (task.instructions.isNotEmpty) ...<Widget>[
                const Divider(height: 24),
                Text(context.l10n.detailInstructions,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(_instructionsText(task.instructions)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AssignmentsCard(
          details: details,
          members: widget.assignableMembers ??
              _workspace?.assignableMembers ??
              const <TaskAssignee>[],
          canEdit: role.canManageTasks && !task.status.isClosed,
          isLoading: _workspace?.membersLoading ?? false,
          onEdit: () => _editAssignments(controller, details),
        ),
        const SizedBox(height: 12),
        WahatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(context.l10n.actionsTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  if (task.status.canStart)
                    FilledButton.icon(
                      key: const Key('task-start-button'),
                      onPressed:
                          controller.isBusy ? null : () => controller.start(),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(context.l10n.startTask),
                    ),
                  if (task.status.canComplete)
                    FilledButton.icon(
                      key: const Key('task-complete-button'),
                      onPressed: controller.isBusy
                          ? null
                          : () => _showCompleteSheet(controller),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(context.l10n.completeAction),
                    ),
                  if (!task.status.isClosed)
                    OutlinedButton.icon(
                      key: const Key('task-add-evidence-button'),
                      onPressed: controller.isBusy
                          ? null
                          : () => _showEvidenceSheet(controller),
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(context.l10n.addEvidence),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _EvidenceCard(photos: details.photos),
        const SizedBox(height: 12),
        _ActivityCard(activity: details.activity),
      ],
    );
  }

  Future<void> _editAssignments(
    TaskDetailController controller,
    TaskDetails details,
  ) async {
    await _workspace?.loadAssignableMembers();
    if (!mounted) return;
    final members = widget.assignableMembers ??
        _workspace?.assignableMembers ??
        const <TaskAssignee>[];
    final selected = details.assignments
        .where((assignment) => assignment.isActive)
        .map((assignment) => assignment.assigneeProfileId)
        .toSet();
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(context.l10n.editAssignments,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                if (members.isEmpty)
                  Text(context.l10n.noOperationalMembers)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: members
                        .map(
                          (member) => FilterChip(
                            label: Text(member.fullName),
                            selected: selected.contains(member.profileId),
                            onSelected: (value) => setSheetState(() {
                              if (value) {
                                selected.add(member.profileId);
                              } else {
                                selected.remove(member.profileId);
                              }
                            }),
                          ),
                        )
                        .toList(growable: false),
                  ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: Text(context.l10n.saveAssignments),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) {
      await controller.setAssignments(result.toList(growable: false));
    }
  }

  Future<void> _showCompleteSheet(TaskDetailController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CompleteTaskSheet(controller: controller),
    );
  }

  Future<void> _showEvidenceSheet(TaskDetailController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddEvidenceSheet(controller: controller),
    );
  }
}

class _AssignmentsCard extends StatelessWidget {
  const _AssignmentsCard({
    required this.details,
    required this.members,
    required this.canEdit,
    required this.isLoading,
    required this.onEdit,
  });

  final TaskDetails details;
  final List<TaskAssignee> members;
  final bool canEdit;
  final bool isLoading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final active = details.assignments
        .where((assignment) => assignment.isActive)
        .toList(growable: false);
    return WahatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(context.l10n.assignmentsTitle,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              if (canEdit)
                TextButton.icon(
                  key: const Key('task-edit-assignments-button'),
                  onPressed: isLoading ? null : onEdit,
                  icon: const Icon(Icons.group_outlined),
                  label: Text(context.l10n.editAction),
                ),
            ],
          ),
          if (active.isEmpty)
            Text(context.l10n.noActiveAssignees)
          else
            for (final assignment in active)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(_memberName(
                    context.l10n, members, assignment.assigneeProfileId)),
                subtitle: Text(context.l10n
                    .assignedAt(taskDateTimeLabel(assignment.assignedAt))),
              ),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.photos});

  final List<TaskPhoto> photos;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(context.l10n.evidenceCount(photos.length),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (photos.isEmpty)
              Text(context.l10n.noEvidence)
            else
              for (final photo in photos)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.softGreen,
                    child: Icon(Icons.photo_outlined),
                  ),
                  title: Text(photo.caption ??
                      photo.photoType.localizedLabel(context.l10n)),
                  subtitle: Text(
                    '${photo.photoType.localizedLabel(context.l10n)} · ${taskDateTimeLabel(photo.createdAt)}',
                  ),
                ),
          ],
        ),
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final List<TaskActivity> activity;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(context.l10n.activityTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (activity.isEmpty)
              Text(context.l10n.noActivity)
            else
              for (final item in activity)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(item.action.localizedLabel(context.l10n)),
                  subtitle: Text(
                    item.note == null || item.note!.isEmpty
                        ? taskDateTimeLabel(item.createdAt)
                        : '${item.note}\n${taskDateTimeLabel(item.createdAt)}',
                  ),
                ),
          ],
        ),
      );
}

class _CompleteTaskSheet extends StatefulWidget {
  const _CompleteTaskSheet({required this.controller});

  final TaskDetailController controller;

  @override
  State<_CompleteTaskSheet> createState() => _CompleteTaskSheetState();
}

class _CompleteTaskSheetState extends State<_CompleteTaskSheet> {
  final _noteController = TextEditingController();
  final _captionController = TextEditingController();
  bool _requiresReview = false;
  TaskPhotoType _type = TaskPhotoType.after;

  @override
  void dispose() {
    _noteController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(context.l10n.completeTaskTitle,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration:
                      InputDecoration(labelText: context.l10n.completionNote),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.sendForReview),
                  value: _requiresReview,
                  onChanged: widget.controller.isBusy
                      ? null
                      : (value) => setState(() => _requiresReview = value),
                ),
                const Divider(),
                Text(context.l10n.optionalCompletionEvidence,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: widget.controller.isBusy
                          ? null
                          : () => widget.controller
                              .pickEvidence(TaskEvidenceSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(context.l10n.commonCamera),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.controller.isBusy
                          ? null
                          : () => widget.controller
                              .pickEvidence(TaskEvidenceSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(context.l10n.commonGallery),
                    ),
                  ],
                ),
                if (widget.controller.evidence != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(context.l10n
                      .selectedFile(widget.controller.evidence!.filename)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TaskPhotoType>(
                    value: _type,
                    decoration: InputDecoration(
                        labelText: context.l10n.evidenceTypeLabel),
                    items: TaskPhotoType.values
                        .map(
                          (type) => DropdownMenuItem<TaskPhotoType>(
                            value: type,
                            child: Text(type.localizedLabel(context.l10n)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: widget.controller.isBusy
                        ? null
                        : (value) => setState(() => _type = value ?? _type),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _captionController,
                    decoration: InputDecoration(
                        labelText: context.l10n.evidenceCaptionLabel),
                  ),
                ],
                if (widget.controller.message != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(widget.controller.message!.call(context.l10n)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('task-confirm-complete-button'),
                  onPressed: widget.controller.isBusy ? null : _complete,
                  icon: const Icon(Icons.check),
                  label: Text(widget.controller.isBusy
                      ? _stageLabel(context.l10n, widget.controller.stage)
                      : context.l10n.confirmCompletion),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _complete() async {
    final success = await widget.controller.complete(
      note: _noteController.text,
      requiresEngineerReview: _requiresReview,
      evidenceType: _type,
      evidenceCaption: _captionController.text,
    );
    if (success && mounted) Navigator.of(context).pop();
  }
}

class _AddEvidenceSheet extends StatefulWidget {
  const _AddEvidenceSheet({required this.controller});

  final TaskDetailController controller;

  @override
  State<_AddEvidenceSheet> createState() => _AddEvidenceSheetState();
}

class _AddEvidenceSheetState extends State<_AddEvidenceSheet> {
  final _captionController = TextEditingController();
  TaskPhotoType _type = TaskPhotoType.evidence;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(context.l10n.addTaskEvidenceTitle,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: widget.controller.isBusy
                          ? null
                          : () => widget.controller
                              .pickEvidence(TaskEvidenceSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(context.l10n.commonCamera),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.controller.isBusy
                          ? null
                          : () => widget.controller
                              .pickEvidence(TaskEvidenceSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(context.l10n.commonGallery),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(widget.controller.evidence == null
                    ? context.l10n.choosePhotoToContinue
                    : context.l10n
                        .selectedFile(widget.controller.evidence!.filename)),
                const SizedBox(height: 10),
                DropdownButtonFormField<TaskPhotoType>(
                  value: _type,
                  decoration: InputDecoration(
                      labelText: context.l10n.evidenceTypeLabel),
                  items: TaskPhotoType.values
                      .map(
                        (type) => DropdownMenuItem<TaskPhotoType>(
                          value: type,
                          child: Text(type.localizedLabel(context.l10n)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: widget.controller.isBusy
                      ? null
                      : (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _captionController,
                  decoration:
                      InputDecoration(labelText: context.l10n.captionLabel),
                ),
                if (widget.controller.message != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(widget.controller.message!.call(context.l10n)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('task-save-evidence-button'),
                  onPressed: widget.controller.isBusy ||
                          widget.controller.evidence == null
                      ? null
                      : _save,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(widget.controller.isBusy
                      ? _stageLabel(context.l10n, widget.controller.stage)
                      : context.l10n.saveEvidence),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _save() async {
    final success = await widget.controller.addEvidence(
      type: _type,
      caption: _captionController.text,
    );
    if (success && mounted) Navigator.of(context).pop();
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: AppColors.green),
            const SizedBox(width: 10),
            SizedBox(
              width: 105,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _DetailFailure extends StatelessWidget {
  const _DetailFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: WahatCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.sync_problem_outlined, size: 38),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                OutlinedButton(
                    onPressed: onRetry, child: Text(context.l10n.commonRetry)),
              ],
            ),
          ),
        ),
      );
}

String _memberName(
    AppLocalizations l10n, List<TaskAssignee> members, String id) {
  for (final member in members) {
    if (member.profileId == id) return member.fullName;
  }
  return l10n.assignedFarmMember;
}

/// "50 Grams · Fertigation" for plan-generated tasks that carry a
/// consumption spec in their instructions; null otherwise.
String? _productLine(BuildContext context, Map<String, Object?> instructions) {
  final quantity = instructions['required_quantity'];
  if (instructions['inventory_item_id'] == null || quantity == null) {
    return null;
  }
  final l10n = context.l10n;
  String unitLabel = '${instructions['required_unit'] ?? ''}';
  try {
    unitLabel = InventoryUnit.fromJson(unitLabel).localizedLabel(l10n);
  } catch (_) {
    // Unknown unit string: show it raw.
  }
  final line = l10n.taskProductQuantity('$quantity', unitLabel);
  final methodWire = instructions['application_method'];
  if (methodWire == null) return line;
  try {
    final method = ApplicationMethod.fromJson('$methodWire');
    return '$line · ${method.localizedLabel(l10n)}';
  } catch (_) {
    return line;
  }
}

String _instructionsText(Map<String, Object?> instructions) {
  final text = instructions['text'];
  if (text is String && text.trim().isNotEmpty) return text;
  return instructions.entries
      .map((entry) => '${entry.key}: ${entry.value}')
      .join('\n');
}

String _stageLabel(AppLocalizations l10n, TaskMutationStage stage) =>
    switch (stage) {
      TaskMutationStage.idle => l10n.stageReady,
      TaskMutationStage.starting => l10n.stageStarting,
      TaskMutationStage.assigning => l10n.stageAssigning,
      TaskMutationStage.pickingEvidence => l10n.stagePickingEvidence,
      TaskMutationStage.uploadingEvidence => l10n.stageUploadingEvidence,
      TaskMutationStage.registeringEvidence => l10n.stageRegisteringEvidence,
      TaskMutationStage.completing => l10n.stageCompleting,
    };
