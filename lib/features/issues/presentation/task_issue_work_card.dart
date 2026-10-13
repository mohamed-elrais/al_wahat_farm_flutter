import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_photo_service.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_workspace_controller.dart';
import 'package:flutter/material.dart';

class TaskIssueWorkCard extends StatefulWidget {
  const TaskIssueWorkCard({
    required this.taskId,
    this.onPendingChanged,
    this.readOnly = false,
    super.key,
  });
  final String taskId;
  final ValueChanged<bool>? onPendingChanged;
  final bool readOnly;

  @override
  State<TaskIssueWorkCard> createState() => _TaskIssueWorkCardState();
}

class _TaskIssueWorkCardState extends State<TaskIssueWorkCard> {
  List<TaskTreeIssueWork>? _work;
  Object? _error;
  String? _busyIssueId;
  bool _loaded = false;
  bool _loading = false;
  final Map<String, PreparedIssuePhoto> _photos =
      <String, PreparedIssuePhoto>{};
  final IssuePhotoPicker _photoPicker = DeviceIssuePhotoPicker();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded && !_loading) _load();
  }

  Future<void> _load() async {
    final controller = IssueWorkspaceScope.maybeOf(context);
    if (controller == null) {
      _loaded = true;
      return;
    }
    _loading = true;
    try {
      final work = await controller.listTaskWork(widget.taskId);
      if (mounted) {
        setState(() {
          _work = work;
          _loaded = true;
        });
        widget.onPendingChanged?.call(work.any(_needsOutcome));
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _loaded = true;
        });
      }
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final work = _work;
    if (work == null || work.isEmpty) return const SizedBox.shrink();
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WahatCard(
        key: const Key('task-issue-work-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(context.l10n.issueWorkTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(context.l10n.issueWorkIndividualHint),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text('$_error', style: const TextStyle(color: AppColors.issue)),
            ],
            for (final item in work) ...<Widget>[
              const Divider(height: 22),
              Row(
                children: <Widget>[
                  const Icon(Icons.report_problem_outlined,
                      color: AppColors.issue),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item.type.localizedLabel(context.l10n),
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          _treeCodeFor(hierarchy, item.treeId),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(item.severity.localizedLabel(context.l10n)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Chip(
                      label: Text(
                        _stateLabel(context, item.workState),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              if (item.resolutionPhotoRequired) ...<Widget>[
                const SizedBox(height: 6),
                Text(context.l10n.issueWorkPhotoRequired,
                    style: const TextStyle(color: AppColors.orange)),
              ],
              if (widget.readOnly && item.unableReason != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(_reasonLabel(context, item.unableReason!)),
              ],
              if (widget.readOnly &&
                  item.resolutionNotes?.trim().isNotEmpty == true) ...<Widget>[
                const SizedBox(height: 6),
                Text(item.resolutionNotes!),
              ],
              if (!widget.readOnly &&
                  (item.workState == TaskTreeIssueWorkState.pending ||
                      item.workState ==
                          TaskTreeIssueWorkState.returned)) ...<Widget>[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busyIssueId == null
                      ? () => _pickPhoto(item.issueId)
                      : null,
                  icon: Icon(
                    _photos.containsKey(item.issueId)
                        ? Icons.check_circle_outline
                        : Icons.add_a_photo_outlined,
                  ),
                  label: Text(
                    _photos.containsKey(item.issueId)
                        ? context.l10n.issueWorkPhotoReady
                        : context.l10n.issueWorkAddPhoto,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    FilledButton.icon(
                      key: Key('resolve-issue-${item.issueId}'),
                      onPressed: _busyIssueId != null ||
                              (item.resolutionPhotoRequired &&
                                  !_photos.containsKey(item.issueId))
                          ? null
                          : () => _resolve(item),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(context.l10n.issueWorkResolve),
                    ),
                    OutlinedButton.icon(
                      key: Key('unable-issue-${item.issueId}'),
                      onPressed:
                          _busyIssueId == null ? () => _unable(item) : null,
                      icon: const Icon(Icons.build_circle_outlined, size: 18),
                      label: Text(context.l10n.issueWorkUnable),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(TaskTreeIssueWork item) async {
    final operational = OperationalContextScope.maybeOf(context);
    final controller = IssueWorkspaceScope.maybeOf(context)!;
    final notes = await _notesDialog(
      title: context.l10n.issueWorkResolve,
      required: false,
    );
    if (notes == null || !mounted) return;
    await _act(item.issueId, () {
      return controller.resolve(
        taskId: widget.taskId,
        issueId: item.issueId,
        notes: notes,
        preparedPhoto: _photos[item.issueId],
        userId: operational?.profile.id,
        farmId: operational?.selectedMembership.farm.id,
      );
    });
  }

  Future<void> _pickPhoto(String issueId) async {
    final source = await showModalBottomSheet<IssuePhotoSource>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.l10n.commonCamera),
              onTap: () => Navigator.of(context).pop(IssuePhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.commonGallery),
              onTap: () => Navigator.of(context).pop(IssuePhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final photo = await _photoPicker.pick(source);
    if (photo != null && mounted) {
      setState(() => _photos[issueId] = photo);
    }
  }

  Future<void> _unable(TaskTreeIssueWork item) async {
    final l10n = context.l10n;
    final operational = OperationalContextScope.maybeOf(context);
    final controller = IssueWorkspaceScope.maybeOf(context)!;
    final reason = await showModalBottomSheet<TreeIssueUnableReason>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.issueWorkUnableReason,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final reason in TreeIssueUnableReason.values)
              ListTile(
                title: Text(_reasonLabel(context, reason)),
                onTap: () => Navigator.of(context).pop(reason),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    final notes = await _notesDialog(
      title: l10n.issueWorkNotes,
      required: reason == TreeIssueUnableReason.other,
    );
    if (notes == null || !mounted) return;
    await _act(item.issueId, () {
      return controller.unableToFix(
        taskId: widget.taskId,
        issueId: item.issueId,
        reason: reason,
        notes: notes,
        preparedPhoto: _photos[item.issueId],
        userId: operational?.profile.id,
        farmId: operational?.selectedMembership.farm.id,
      );
    });
  }

  Future<String?> _notesDialog({
    required String title,
    required bool required,
  }) async {
    final text = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: text,
          maxLines: 3,
          decoration: InputDecoration(labelText: context.l10n.issueWorkNotes),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              if (required && text.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop(text.text.trim());
            },
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
    text.dispose();
    return result;
  }

  Future<void> _act(String issueId, Future<void> Function() action) async {
    final controller = IssueWorkspaceScope.maybeOf(context);
    setState(() {
      _busyIssueId = issueId;
      _error = null;
    });
    try {
      await action();
      _photos.remove(issueId);
      await _load();
      await controller?.load();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busyIssueId = null);
    }
  }
}

bool _needsOutcome(TaskTreeIssueWork item) =>
    item.workState == TaskTreeIssueWorkState.pending ||
    item.workState == TaskTreeIssueWorkState.returned;

String _treeCodeFor(FarmHierarchy? hierarchy, String treeId) {
  if (hierarchy != null) {
    for (final tree in hierarchy.trees) {
      if (tree.id == treeId) return tree.treeCode;
    }
  }
  return treeId;
}

String _stateLabel(BuildContext context, TaskTreeIssueWorkState state) =>
    switch (state) {
      TaskTreeIssueWorkState.pending => context.l10n.issueWorkPending,
      TaskTreeIssueWorkState.resolutionSubmitted =>
        context.l10n.issueWorkSubmitted,
      TaskTreeIssueWorkState.resolved => context.l10n.issueWorkResolved,
      TaskTreeIssueWorkState.unableToFix => context.l10n.issueWorkUnableState,
      TaskTreeIssueWorkState.returned => context.l10n.issueWorkReturned,
    };

String _reasonLabel(BuildContext context, TreeIssueUnableReason reason) =>
    switch (reason) {
      TreeIssueUnableReason.replacementPartRequired =>
        context.l10n.unableReasonReplacementPart,
      TreeIssueUnableReason.specialistRequired =>
        context.l10n.unableReasonSpecialist,
      TreeIssueUnableReason.additionalWorkerRequired =>
        context.l10n.unableReasonAdditionalWorker,
      TreeIssueUnableReason.equipmentUnavailable =>
        context.l10n.unableReasonEquipment,
      TreeIssueUnableReason.treeInaccessible =>
        context.l10n.unableReasonInaccessible,
      TreeIssueUnableReason.suspectedIncorrectIssue =>
        context.l10n.unableReasonIncorrectIssue,
      TreeIssueUnableReason.other => context.l10n.issueTypeOther,
    };
