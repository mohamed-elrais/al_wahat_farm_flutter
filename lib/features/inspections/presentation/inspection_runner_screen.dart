import 'dart:async';

import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_draft_store.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_repository_scope.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/sync_scope.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_evidence_service.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InspectionRunnerScreen extends StatefulWidget {
  const InspectionRunnerScreen({required this.taskId, super.key});
  final String taskId;

  @override
  State<InspectionRunnerScreen> createState() => _InspectionRunnerScreenState();
}

class _InspectionRunnerScreenState extends State<InspectionRunnerScreen> {
  InspectionDetails? _details;
  Object? _error;
  bool _busy = false;
  int? _stationIndex;
  final Map<String, Map<TreeIssueType, IssueSeverity>> _selected =
      <String, Map<TreeIssueType, IssueSeverity>>{};
  final Map<String, Map<TreeIssueType, IssueSeverity>> _original =
      <String, Map<TreeIssueType, IssueSeverity>>{};
  final Map<String, TextEditingController> _notes =
      <String, TextEditingController>{};
  final Map<String, PreparedTaskEvidence> _issuePhotos =
      <String, PreparedTaskEvidence>{};
  final Map<String, String> _savedPhotoPaths = <String, String>{};
  final TaskEvidencePicker _evidencePicker = DeviceTaskEvidencePicker();
  InspectionDraftStore? _draftStore;
  Timer? _draftDebounce;
  bool _draftDirty = false;
  bool _showCompletedStation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppServicesScope.maybeOf(context);
    final profileId = OperationalContextScope.maybeOf(context)?.profile.id;
    if (_draftStore == null && services != null && profileId != null) {
      _draftStore = InspectionDraftStore(
        cache: services.cacheStore,
        pendingPhotos: services.pendingPhotos,
        userId: profileId,
      );
    }
    if (_details == null && !_busy && _error == null) _load();
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    unawaited(_persistDraft());
    for (final controller in _notes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final repository = InspectionRepositoryScope.maybeOf(context);
    if (repository == null) return;
    setState(() => _busy = true);
    try {
      final details = await repository.loadByTask(widget.taskId);
      if (!mounted) return;
      _setDetails(details);
      await _prepareStation();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setDetails(InspectionDetails details) {
    final pending = details.items
        .where((item) => item.status == InspectionItemStatus.pending)
        .toList(growable: false);
    _details = details;
    _stationIndex = pending.isEmpty
        ? details.session.totalStations
        : pending.first.routeItem.stationIndex;
    _showCompletedStation = false;
  }

  void _seedStation() {
    final details = _details;
    final station = _stationIndex;
    if (details == null || station == null) return;
    final summaries = IssueWorkspaceScope.maybeOf(context)?.allIssues ??
        const <TreeIssueSummary>[];
    for (final item in details.station(station)) {
      final existing = <TreeIssueType, IssueSeverity>{
        for (final issue in summaries.where(
          (issue) => issue.treeId == item.routeItem.treeId,
        ))
          issue.type: issue.severity,
      };
      final observations = details.observationsForItem(item.id);
      final selected = item.status == InspectionItemStatus.inspected
          ? <TreeIssueType, IssueSeverity>{
              for (final observation in observations)
                if (observation.outcome !=
                        InspectionStationObservationOutcome.notObserved &&
                    observation.observedSeverity != null)
                  observation.type: observation.observedSeverity!,
            }
          : Map<TreeIssueType, IssueSeverity>.of(existing);
      _selected[item.routeItem.treeId] = selected;
      _original[item.routeItem.treeId] = Map.of(existing);
      final notes = _notes.putIfAbsent(
        item.routeItem.treeId,
        () => TextEditingController(text: item.notes),
      );
      notes.text = item.notes ?? '';
      for (final type in TreeIssueType.values) {
        _savedPhotoPaths.remove(_photoKey(item.routeItem.treeId, type));
      }
      for (final observation in observations) {
        final path = observation.photoStoragePath;
        if (path != null) {
          _savedPhotoPaths[_photoKey(item.routeItem.treeId, observation.type)] =
              path;
        }
      }
    }
  }

  Future<void> _prepareStation() async {
    _seedStation();
    await _restoreSavedPendingPhotos();
    await _restoreDraft();
  }

  Future<void> _restoreSavedPendingPhotos() async {
    final details = _details;
    final station = _stationIndex;
    final store = _draftStore;
    if (details == null || station == null || store == null) return;
    final restored = <String, PreparedTaskEvidence>{};
    for (final item in details.station(station)) {
      for (final observation in details.observationsForItem(item.id)) {
        final blobKey = observation.localPhotoBlobKey;
        if (blobKey == null) continue;
        final photo = await store.loadPreparedPhoto(blobKey);
        if (photo != null) {
          restored[_photoKey(item.routeItem.treeId, observation.type)] = photo;
        }
      }
    }
    if (mounted && restored.isNotEmpty) {
      setState(() => _issuePhotos.addAll(restored));
    }
  }

  Future<void> _restoreDraft() async {
    final details = _details;
    final station = _stationIndex;
    final store = _draftStore;
    if (details == null || station == null || store == null) return;
    final draft = await store.load(details.session.id, station);
    if (draft == null || !mounted) return;
    setState(() {
      for (final result in draft.results) {
        if (!_selected.containsKey(result.treeId)) continue;
        _selected[result.treeId] = <TreeIssueType, IssueSeverity>{
          for (final issue in result.selectedIssues) issue.type: issue.severity,
        };
        _notes[result.treeId]?.text = result.notes ?? '';
      }
      _issuePhotos.addAll(draft.photos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = _details;
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: _busy && details == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null && details == null
                  ? _Failure(
                      error: _error!,
                      taskId: widget.taskId,
                      onRetry: () {
                        setState(() => _error = null);
                        _load();
                      })
                  : details == null
                      ? const SizedBox.shrink()
                      : _body(details),
        ),
      ),
    );
  }

  Widget _body(InspectionDetails details) {
    final session = details.session;
    final operational = OperationalContextScope.maybeOf(context);
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    final section = hierarchy?.sectionById(session.sectionId);
    final sectionLabel = section == null
        ? session.sectionId
        : '${section.name} (${section.code})';
    final pendingChanges = SyncScope.maybeOf(context)?.pendingCount ?? 0;
    final hasPendingSync = widget.taskId.startsWith('local:') ||
        details.session.taskId.startsWith('local:') ||
        pendingChanges > 0;
    final allDone = details.items.every(
      (item) => item.status == InspectionItemStatus.inspected,
    );
    final canTakeOver =
        operational?.selectedMembership.role.canManageTasks == true &&
            operational?.profile.id != session.inspectorProfileId &&
            session.status != InspectionSessionStatus.submitted &&
            session.status != InspectionSessionStatus.cancelled;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Row(
          children: <Widget>[
            WahatBackButton(
              tooltip: context.l10n.commonBack,
              onPressed: () => context.go(widget.taskId.startsWith('local:')
                  ? '/tasks'
                  : '/tasks/${widget.taskId}'),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Eyebrow(context.l10n.inspectionRunnerEyebrow),
                  Text(
                    context.l10n.inspectionRunnerTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasPendingSync) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Chip(
              key: const Key('inspection-pending-sync'),
              avatar: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(pendingChanges > 0
                  ? context.l10n.syncStatusPending(pendingChanges)
                  : context.l10n.syncPendingBadge),
            ),
          ),
        ],
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: session.totalTrees == 0
              ? 0
              : session.inspectedTrees / session.totalTrees,
        ),
        const SizedBox(height: 6),
        Text(context.l10n.inspectionProgress(
          session.inspectedTrees,
          session.totalTrees,
        )),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 10),
          Text('$_error', style: const TextStyle(color: AppColors.issue)),
        ],
        const SizedBox(height: 14),
        if (canTakeOver) ...<Widget>[
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.l10n.inspectionAssignedToAnotherInspector,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(context.l10n.inspectionTakeoverHint),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('inspection-takeover'),
                  onPressed: _busy ? null : _takeOver,
                  icon: const Icon(Icons.person_pin_circle_outlined),
                  label: Text(context.l10n.inspectionTakeover),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!canTakeOver &&
            (session.status == InspectionSessionStatus.notStarted ||
                session.status == InspectionSessionStatus.paused))
          FilledButton.icon(
            onPressed: _busy ? null : _startOrResume,
            icon: const Icon(Icons.play_arrow),
            label: Text(session.status == InspectionSessionStatus.paused
                ? context.l10n.inspectionResume
                : context.l10n.inspectionStart),
          )
        else if (!canTakeOver &&
            allDone &&
            !_showCompletedStation &&
            session.status != InspectionSessionStatus.submitted)
          WahatCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.l10n.inspectionFinalReviewTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(context.l10n.inspectionFinalReviewMessage(
                  session.totalTrees,
                  session.totalStations,
                )),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('inspection-review-previous'),
                  onPressed: _busy ? null : _reviewPreviousStation,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(context.l10n.inspectionPreviousStation),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('inspection-submit'),
                  onPressed: _busy ? null : _submit,
                  icon: const Icon(Icons.done_all),
                  label: Text(context.l10n.inspectionSubmit),
                ),
              ],
            ),
          )
        else if (!canTakeOver &&
            session.status == InspectionSessionStatus.submitted)
          WahatCard(
            child: Text(context.l10n.inspectionSubmitted),
          )
        else if (!canTakeOver &&
            session.status == InspectionSessionStatus.cancelled)
          WahatCard(
            child: Text(context.l10n.taskStatusCancelled),
          )
        else if (!canTakeOver) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.l10n.inspectionStation(
                    _stationIndex!,
                    session.totalStations,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: _busy ? null : _pause,
                icon: const Icon(Icons.pause),
                label: Text(context.l10n.inspectionPause),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in details.station(_stationIndex!)) ...<Widget>[
            _TreeObservationCard(
              item: item,
              sectionLabel: sectionLabel,
              selected: _selected[item.routeItem.treeId]!,
              original: _original[item.routeItem.treeId]!,
              notes: _notes[item.routeItem.treeId]!,
              onToggle: (type, selected) => _toggleIssue(
                item.routeItem.treeId,
                type,
                selected,
              ),
              onSeverity: (type, severity) => setState(() {
                _selected[item.routeItem.treeId]![type] = severity;
                _scheduleDraftSave();
              }),
              requiresPhoto: session.requiresIssuePhoto,
              hasPhoto: (type) =>
                  _issuePhotos.containsKey(
                    _photoKey(item.routeItem.treeId, type),
                  ) ||
                  _savedPhotoPaths.containsKey(
                    _photoKey(item.routeItem.treeId, type),
                  ),
              onPhoto: (type) => _pickIssuePhoto(
                item.routeItem.treeId,
                type,
              ),
              onNotesChanged: (_) => _scheduleDraftSave(),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: <Widget>[
              if (_stationIndex! > 1) ...<Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('inspection-previous'),
                    onPressed: _busy ? null : _goPreviousStation,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(context.l10n.inspectionPreviousStation),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  key: const Key('inspection-save-next'),
                  onPressed: _busy ? null : _saveStation,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: Text(context.l10n.inspectionSaveNext),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _toggleIssue(
    String treeId,
    TreeIssueType type,
    bool selected,
  ) async {
    if (!selected) {
      setState(() => _selected[treeId]!.remove(type));
      _scheduleDraftSave();
      return;
    }
    final severity = await showDialog<IssueSeverity>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.l10n.inspectionSelectSeverity),
        children: IssueSeverity.values
            .map(
              (severity) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(severity),
                child: Text(severity.localizedLabel(context.l10n)),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (severity != null && mounted) {
      setState(() => _selected[treeId]![type] = severity);
      _scheduleDraftSave();
    }
  }

  Future<void> _startOrResume() =>
      _setStatus(InspectionSessionStatus.inProgress);
  Future<void> _pause() => _setStatus(InspectionSessionStatus.paused);

  Future<void> _pickIssuePhoto(String treeId, TreeIssueType type) async {
    final source = await showModalBottomSheet<TaskEvidenceSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.l10n.commonCamera),
              onTap: () => Navigator.of(context).pop(TaskEvidenceSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.commonGallery),
              onTap: () =>
                  Navigator.of(context).pop(TaskEvidenceSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final evidence = await _evidencePicker.pick(source);
      if (evidence != null && mounted) {
        setState(() {
          _issuePhotos[_photoKey(treeId, type)] = evidence;
          _error = null;
        });
        _scheduleDraftSave();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _setStatus(InspectionSessionStatus status) async {
    final repository = InspectionRepositoryScope.maybeOf(context)!;
    setState(() => _busy = true);
    try {
      await repository.setStatus(_details!.session.id, status);
      final refreshed = await repository.loadByTask(widget.taskId);
      if (mounted) {
        setState(() => _setDetails(refreshed));
        await _prepareStation();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveStation() async {
    final details = _details!;
    final stationItems = details.station(_stationIndex!);
    final missingRequiredPhoto = stationItems.any((item) {
      final treeId = item.routeItem.treeId;
      return _selected[treeId]!.keys.any(
            (type) =>
                !_issuePhotos.containsKey(_photoKey(treeId, type)) &&
                !_savedPhotoPaths.containsKey(_photoKey(treeId, type)),
          );
    });
    if (details.session.requiresIssuePhoto && missingRequiredPhoto) {
      setState(() => _error = context.l10n.inspectionPhotoRequiredError);
      return;
    }
    final results = _stationResults(details, _stationIndex!);
    final repository = InspectionRepositoryScope.maybeOf(context)!;
    final operational = OperationalContextScope.maybeOf(context);
    final photos = <String, PreparedTaskEvidence>{
      for (final result in results)
        for (final issue in result.selectedIssues)
          if (_issuePhotos[_photoKey(result.treeId, issue.type)]
              case final photo?)
            _photoKey(result.treeId, issue.type): photo,
    };
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.saveStation(
        details.session.id,
        _stationIndex!,
        results,
        photos: photos,
        userId: operational?.profile.id,
        farmId: details.session.farmId,
        taskId: details.session.taskId,
      );
      _draftDebounce?.cancel();
      await _draftStore?.clear(details.session.id, _stationIndex!);
      _draftDirty = false;
      for (final item in stationItems) {
        for (final type in TreeIssueType.values) {
          _issuePhotos.remove(_photoKey(item.routeItem.treeId, type));
        }
      }
      final refreshed = await repository.loadByTask(widget.taskId);
      if (mounted) {
        setState(() => _setDetails(refreshed));
        await _prepareStation();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _photoKey(String treeId, TreeIssueType type) =>
      '$treeId|${type.wireValue}';

  List<InspectionTreeResult> _stationResults(
    InspectionDetails details,
    int stationIndex,
  ) {
    final now = DateTime.now();
    return details.station(stationIndex).map((item) {
      final treeId = item.routeItem.treeId;
      final selected = _selected[treeId]!;
      final original = _original[treeId]!;
      final notes = _notes[treeId]!.text;
      return InspectionTreeResult(
        treeId: treeId,
        noNewIssueFound: selected.isEmpty,
        notes: notes,
        clientObservedAt: now,
        selectedIssues: selected.entries
            .map(
              (entry) => InspectionSelectedIssue(
                type: entry.key,
                severity: entry.value,
                severityChanged: original.containsKey(entry.key) &&
                    original[entry.key] != entry.value,
                notes: notes,
                photoStoragePath:
                    _savedPhotoPaths[_photoKey(treeId, entry.key)],
              ),
            )
            .toList(growable: false),
      );
    }).toList(growable: false);
  }

  Future<void> _goPreviousStation() async {
    final station = _stationIndex;
    if (_busy || station == null || station <= 1) return;
    setState(() => _busy = true);
    await _persistDraft();
    if (!mounted) return;
    setState(() => _stationIndex = station - 1);
    await _prepareStation();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _reviewPreviousStation() async {
    final details = _details;
    if (_busy || details == null || details.session.totalStations < 1) return;
    setState(() {
      _busy = true;
      _stationIndex = details.session.totalStations;
      _showCompletedStation = true;
    });
    await _prepareStation();
    if (mounted) setState(() => _busy = false);
  }

  void _scheduleDraftSave() {
    _draftDirty = true;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_persistDraft()),
    );
  }

  Future<void> _persistDraft() async {
    final details = _details;
    final station = _stationIndex;
    final store = _draftStore;
    if (!_draftDirty || details == null || station == null || store == null) {
      return;
    }
    final stationTreeIds =
        details.station(station).map((item) => item.routeItem.treeId).toSet();
    final results = _stationResults(details, station);
    final photos = <String, PreparedTaskEvidence>{
      for (final entry in _issuePhotos.entries)
        if (stationTreeIds.any((treeId) => entry.key.startsWith('$treeId|')))
          entry.key: entry.value,
    };
    _draftDirty = false;
    try {
      await store.save(
        sessionId: details.session.id,
        stationIndex: station,
        farmId: details.session.farmId,
        taskId: details.session.taskId,
        results: results,
        photos: photos,
      );
    } catch (_) {
      _draftDirty = true;
    }
  }

  Future<void> _submit() async {
    final repository = InspectionRepositoryScope.maybeOf(context)!;
    final workspace = TaskWorkspaceScope.maybeOf(context);
    setState(() => _busy = true);
    try {
      await repository.submit(_details!.session.id);
      await workspace?.refresh();
      if (mounted) {
        context.go(widget.taskId.startsWith('local:')
            ? '/tasks'
            : '/tasks/${widget.taskId}');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takeOver() async {
    final repository = InspectionRepositoryScope.maybeOf(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.takeOver(_details!.session.id);
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _TreeObservationCard extends StatelessWidget {
  const _TreeObservationCard({
    required this.item,
    required this.sectionLabel,
    required this.selected,
    required this.original,
    required this.notes,
    required this.onToggle,
    required this.onSeverity,
    required this.requiresPhoto,
    required this.hasPhoto,
    required this.onPhoto,
    required this.onNotesChanged,
  });

  final InspectionSessionItem item;
  final String sectionLabel;
  final Map<TreeIssueType, IssueSeverity> selected;
  final Map<TreeIssueType, IssueSeverity> original;
  final TextEditingController notes;
  final void Function(TreeIssueType, bool) onToggle;
  final void Function(TreeIssueType, IssueSeverity) onSeverity;
  final bool requiresPhoto;
  final bool Function(TreeIssueType) hasPhoto;
  final Future<void> Function(TreeIssueType) onPhoto;
  final ValueChanged<String> onNotesChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: context.l10n.inspectionTreeCardSemantics(
          item.routeItem.treeCode,
          _sideLabel(context, item.routeItem.side),
          original.length,
        ),
        child: WahatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(item.routeItem.side == InspectionRouteSide.left
                      ? Icons.keyboard_double_arrow_left
                      : item.routeItem.side == InspectionRouteSide.right
                          ? Icons.keyboard_double_arrow_right
                          : Icons.arrow_upward),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(item.routeItem.treeCode,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Flexible(
                    child: Text(
                      _sideLabel(context, item.routeItem.side),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: <Widget>[
                  Text(
                    sectionLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (item.routeItem.rowNumber != null ||
                      item.routeItem.treeNumber != null)
                    Text(
                      context.l10n.inspectionTreePosition(
                        item.routeItem.rowNumber?.toString() ?? '—',
                        item.routeItem.treeNumber?.toString() ?? '—',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (item.routeItem.latitude != null &&
                      item.routeItem.longitude != null)
                    Text(
                      context.l10n.inspectionCoordinates(
                        item.routeItem.latitude!.toStringAsFixed(6),
                        item.routeItem.longitude!.toStringAsFixed(6),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (original.isNotEmpty)
                    Text(
                      context.l10n.inspectionExistingIssues(original.length),
                      style: const TextStyle(
                        color: AppColors.issue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: TreeIssueType.values
                    .map(
                      (type) => FilterChip(
                        selected: selected.containsKey(type),
                        avatar: original.containsKey(type)
                            ? const Icon(Icons.history, size: 16)
                            : null,
                        label: Text(type.localizedLabel(context.l10n)),
                        onSelected: (value) => onToggle(type, value),
                      ),
                    )
                    .toList(growable: false),
              ),
              for (final entry in selected.entries) ...<Widget>[
                const SizedBox(height: 8),
                DropdownButtonFormField<IssueSeverity>(
                  value: entry.value,
                  decoration: InputDecoration(
                    labelText: entry.key.localizedLabel(context.l10n),
                  ),
                  items: IssueSeverity.values
                      .map(
                        (severity) => DropdownMenuItem<IssueSeverity>(
                          value: severity,
                          child: Text(severity.localizedLabel(context.l10n)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) onSeverity(entry.key, value);
                  },
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  key: Key(
                    'inspection-photo-${item.routeItem.treeId}-${entry.key.wireValue}',
                  ),
                  onPressed: () => onPhoto(entry.key),
                  icon: Icon(
                    hasPhoto(entry.key)
                        ? Icons.check_circle_outline
                        : Icons.add_a_photo_outlined,
                  ),
                  label: Text(
                    hasPhoto(entry.key)
                        ? context.l10n.inspectionIssuePhotoReady
                        : requiresPhoto
                            ? context.l10n.inspectionAddRequiredIssuePhoto
                            : context.l10n.inspectionAddIssuePhoto,
                  ),
                ),
              ],
              if (selected.isEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  context.l10n.inspectionNoNewIssue,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: notes,
                onChanged: onNotesChanged,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.l10n.issueObservationLabel,
                ),
              ),
            ],
          ),
        ),
      );
}

String _sideLabel(BuildContext context, InspectionRouteSide side) =>
    switch (side) {
      InspectionRouteSide.left => context.l10n.inspectionPhysicalLeft,
      InspectionRouteSide.right => context.l10n.inspectionPhysicalRight,
      InspectionRouteSide.single => context.l10n.inspectionSingleSide,
    };

class _Failure extends StatelessWidget {
  const _Failure({
    required this.error,
    required this.taskId,
    required this.onRetry,
  });

  final Object error;
  final String taskId;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isMissing = error is OperationFailure &&
        (error as OperationFailure).kind == OperationFailureKind.notFound;
    return Center(
      child: WahatCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(isMissing
                ? context.l10n.inspectionGuidedSessionMissing
                : context.l10n.inspectionLoadFailed),
            const SizedBox(height: 10),
            if (isMissing)
              FilledButton(
                onPressed: () => context.go('/tasks/$taskId'),
                child: Text(context.l10n.inspectionBackToTask),
              )
            else
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.l10n.commonRetry),
              ),
          ],
        ),
      ),
    );
  }
}
