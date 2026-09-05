import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route_planner.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_repository_scope.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_route_preview.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InspectionCreateScreen extends StatefulWidget {
  const InspectionCreateScreen({this.initialSectionId, super.key});

  final String? initialSectionId;

  @override
  State<InspectionCreateScreen> createState() => _InspectionCreateScreenState();
}

class _InspectionCreateScreenState extends State<InspectionCreateScreen> {
  final _titleController = TextEditingController();
  String? _sectionId;
  String? _inspectorId;
  bool _requiresReview = true;
  bool _requiresPhoto = false;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _scheduledFor;
  bool _busy = false;
  bool _membersRequested = false;
  bool _initialSectionApplied = false;
  InspectionRoute? _route;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final workspace = TaskWorkspaceScope.maybeOf(context);
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    if (!_initialSectionApplied && hierarchy != null) {
      _initialSectionApplied = true;
      final initial = widget.initialSectionId;
      if (initial != null && hierarchy.sectionById(initial)?.isActive == true) {
        _sectionId = initial;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _preview(hierarchy);
        });
      }
    }
    if (!_membersRequested &&
        workspace != null &&
        workspace.assignableMembers.isEmpty) {
      _membersRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) workspace.loadAssignableMembers();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    final workspace = TaskWorkspaceScope.maybeOf(context);
    final role =
        OperationalContextScope.maybeOf(context)?.selectedMembership.role;
    if (hierarchy == null ||
        workspace == null ||
        role?.canManageTasks != true) {
      return Scaffold(
        body: Center(child: Text(context.l10n.inspectionCreateUnavailable)),
      );
    }
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: workspace,
            builder: (context, _) => LayoutBuilder(
              builder: (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          WahatBackButton(
                            tooltip: context.l10n.commonBack,
                            onPressed: () => context.pop(),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              context.l10n.inspectionCreateTitle,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      WahatCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: context.l10n.inspectionTitleLabel,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _sectionId,
                              decoration: InputDecoration(
                                labelText: context.l10n.inspectionSectionLabel,
                              ),
                              items: hierarchy.sections
                                  .where((section) => section.isActive)
                                  .map(
                                    (section) => DropdownMenuItem<String>(
                                      value: section.id,
                                      child: Text(section.name),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) => setState(() {
                                _sectionId = value;
                                _route = null;
                              }),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _inspectorId,
                              decoration: InputDecoration(
                                labelText:
                                    context.l10n.inspectionInspectorLabel,
                              ),
                              items: workspace.assignableMembers
                                  .map(
                                    (member) => DropdownMenuItem<String>(
                                      value: member.profileId,
                                      child: Text(member.fullName),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) =>
                                  setState(() => _inspectorId = value),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<TaskPriority>(
                              key: const Key('inspection-priority'),
                              value: _priority,
                              decoration: InputDecoration(
                                labelText: context.l10n.priorityField,
                              ),
                              items: TaskPriority.values
                                  .map(
                                    (priority) =>
                                        DropdownMenuItem<TaskPriority>(
                                      value: priority,
                                      child: Text(
                                        priority.localizedLabel(context.l10n),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                              onChanged: (value) => setState(
                                () => _priority = value ?? _priority,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              key: const Key('inspection-scheduled-date'),
                              onPressed: _pickScheduledDate,
                              icon: const Icon(Icons.event_outlined),
                              label: Text(
                                _scheduledFor == null
                                    ? context.l10n.inspectionChooseSchedule
                                    : MaterialLocalizations.of(context)
                                        .formatMediumDate(_scheduledFor!),
                              ),
                            ),
                            if (_scheduledFor == null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Text(
                                  context.l10n.inspectionScheduleRequired,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: _requiresReview,
                              title:
                                  Text(context.l10n.inspectionRequiresReview),
                              onChanged: (value) =>
                                  setState(() => _requiresReview = value),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: _requiresPhoto,
                              title: Text(context.l10n.inspectionRequiresPhoto),
                              subtitle: Text(
                                  context.l10n.inspectionPhotoRequirementHint),
                              onChanged: (value) =>
                                  setState(() => _requiresPhoto = value),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_route == null)
                        OutlinedButton.icon(
                          onPressed: _sectionId == null
                              ? null
                              : () => _preview(hierarchy),
                          icon: const Icon(Icons.route_outlined),
                          label: Text(context.l10n.inspectionBuildRoute),
                        )
                      else
                        _RoutePreview(route: _route!),
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: const TextStyle(color: AppColors.issue)),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        key: const Key('inspection-create-submit'),
                        onPressed: _busy ||
                                _route == null ||
                                _inspectorId == null ||
                                _scheduledFor == null
                            ? null
                            : () => _create(hierarchy),
                        icon: _busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.assignment_add),
                        label: Text(context.l10n.inspectionCreateAction),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _preview(FarmHierarchy hierarchy) {
    if (!hierarchy.trees.any(
      (tree) => tree.sectionId == _sectionId && tree.isActive,
    )) {
      setState(() {
        _route = null;
        _error = context.l10n.inspectionSectionHasNoTrees;
      });
      return;
    }
    try {
      final section = hierarchy.sectionById(_sectionId!)!;
      final route = const InspectionRoutePlanner().plan(
        section: section,
        trees: hierarchy.trees,
      );
      setState(() {
        _route = route;
        _error = null;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text =
              context.l10n.inspectionDefaultTitle(section.code);
        }
      });
    } on InspectionRouteException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _create(FarmHierarchy hierarchy) async {
    final repository = InspectionRepositoryScope.maybeOf(context);
    final workspace = TaskWorkspaceScope.maybeOf(context);
    if (repository == null) return;
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = context.l10n.inspectionTitleRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await repository.create(InspectionCreationDraft(
        farmId: hierarchy.farmId,
        inspectorProfileId: _inspectorId!,
        title: _titleController.text,
        route: _route!,
        scheduledFor: _scheduledFor,
        priority: _priority.name,
        requiresEngineerReview: _requiresReview,
        requiresIssuePhoto: _requiresPhoto,
      ));
      await workspace?.refresh();
      if (!mounted) return;
      if (result.taskId.startsWith('local:')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.inspectionQueuedOffline)),
        );
        context.go('/tasks/${result.taskId}/inspection');
      } else {
        context.go('/tasks/${result.taskId}');
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickScheduledDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _scheduledFor ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() => _scheduledFor = selected);
    }
  }
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview({required this.route});
  final InspectionRoute route;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(context.l10n.inspectionRoutePreview,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(context.l10n.inspectionRouteCounts(
              route.treeCount,
              route.stationCount,
            )),
            Text(context.l10n.inspectionStartsAt(route.items.first.treeCode)),
            const SizedBox(height: 8),
            InspectionRoutePreviewMap(
              route: route,
              semanticsLabel: context.l10n.inspectionRoutePreviewSemantics(
                route.items.first.treeCode,
                route.treeCount,
                route.stationCount,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: <Widget>[
                _Legend(
                  color: AppColors.green,
                  label: context.l10n.inspectionRouteRowsLegend,
                ),
                _Legend(
                  color: AppColors.orange,
                  label: context.l10n.inspectionRoutePathLegend,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.inspectionPhysicalSidesHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: route.items
                  .take(12)
                  .map((item) => Chip(label: Text(item.treeCode)))
                  .toList(growable: false),
            ),
          ],
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 18,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      );
}
