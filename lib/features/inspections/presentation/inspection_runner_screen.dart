import 'dart:async';

import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/location/location_service.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_draft_store.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_walk.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_repository_scope.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_walk_map.dart';
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
  const InspectionRunnerScreen({
    required this.taskId,
    this.location = const DeviceLocationService(),
    super.key,
  });

  final String taskId;
  final LocationService location;

  @override
  State<InspectionRunnerScreen> createState() => _InspectionRunnerScreenState();
}

enum _Mode { takeOver, start, review, submitted, cancelled, station }

class _InspectionRunnerScreenState extends State<InspectionRunnerScreen> {
  InspectionDetails? _details;
  InspectionWalk? _walk;
  Map<String, InspectionTreeMark> _marks = const {};
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

  late final LocationWatcher _location = LocationWatcher(widget.location)
    ..addListener(_onLocationChanged);
  bool _locationPreferenceLoaded = false;

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
    if (!_locationPreferenceLoaded && services != null) {
      _locationPreferenceLoaded = true;
      unawaited(_location.restore(services.cacheStore));
    }
    if (_details == null && !_busy && _error == null) _load();
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    unawaited(_persistDraft());
    _location.dispose();
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
    _details = details;
    _stationIndex = _firstPendingStation(details);
    _showCompletedStation = false;
    _walk = details.items.isEmpty
        ? null
        : InspectionWalk(details.items.map((item) => item.routeItem));
    _marks = <String, InspectionTreeMark>{
      for (final item in details.items)
        if (item.status == InspectionItemStatus.inspected)
          item.routeItem.treeId: item.noNewIssueFound
              ? InspectionTreeMark.done
              : InspectionTreeMark.flagged,
    };
  }

  /// The lowest unsaved station, where the walk continues; the last station
  /// when all are saved. Independent of the order the items arrive in.
  static int _firstPendingStation(InspectionDetails details) {
    int? first;
    for (final item in details.items) {
      if (item.status != InspectionItemStatus.pending) continue;
      final station = item.routeItem.stationIndex;
      if (first == null || station < first) first = station;
    }
    return first ?? details.session.totalStations;
  }

  static bool _stationSaved(InspectionDetails details, int station) {
    final items = details.station(station);
    return items.isNotEmpty &&
        items.every((item) => item.status == InspectionItemStatus.inspected);
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

  void _onLocationChanged() {
    if (mounted) setState(() {});
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

  _Mode _mode(InspectionDetails details, {required bool canTakeOver}) {
    final status = details.session.status;
    final allDone = details.items.every(
      (item) => item.status == InspectionItemStatus.inspected,
    );
    if (canTakeOver) return _Mode.takeOver;
    if (status == InspectionSessionStatus.notStarted ||
        status == InspectionSessionStatus.paused) {
      return _Mode.start;
    }
    if (allDone &&
        !_showCompletedStation &&
        status != InspectionSessionStatus.submitted) {
      return _Mode.review;
    }
    if (status == InspectionSessionStatus.submitted) return _Mode.submitted;
    if (status == InspectionSessionStatus.cancelled) return _Mode.cancelled;
    return _Mode.station;
  }

  Widget _body(InspectionDetails details) {
    final l10n = context.l10n;
    final session = details.session;
    final operational = OperationalContextScope.maybeOf(context);
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    final section = hierarchy?.sectionById(session.sectionId);
    final pendingChanges = SyncScope.maybeOf(context)?.pendingCount ?? 0;
    final hasPendingSync = widget.taskId.startsWith('local:') ||
        details.session.taskId.startsWith('local:') ||
        pendingChanges > 0;
    final canTakeOver =
        operational?.selectedMembership.role.canManageTasks == true &&
            operational?.profile.id != session.inspectorProfileId &&
            session.status != InspectionSessionStatus.submitted &&
            session.status != InspectionSessionStatus.cancelled;
    final mode = _mode(details, canTakeOver: canTakeOver);
    final walk = _walk;
    final station = _stationIndex;
    final showWalk = walk != null &&
        station != null &&
        walk.stations.contains(station) &&
        (mode == _Mode.start ||
            mode == _Mode.station ||
            mode == _Mode.takeOver);

    final list = ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            WahatBackButton(
              tooltip: l10n.commonBack,
              onPressed: () => context.go(widget.taskId.startsWith('local:')
                  ? '/tasks'
                  : '/tasks/${widget.taskId}'),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Eyebrow(l10n.inspectionRunnerEyebrow),
                  Text(
                    l10n.inspectionRunnerTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (section != null)
                    Text(
                      section.name,
                      style: Theme.of(context).textTheme.bodySmall,
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
                  ? l10n.syncStatusPending(pendingChanges)
                  : l10n.syncPendingBadge),
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
        Text(l10n.inspectionProgress(
          session.inspectedTrees,
          session.totalTrees,
        )),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 10),
          Text('$_error', style: const TextStyle(color: AppColors.issue)),
        ],
        const SizedBox(height: 14),
        ...switch (mode) {
          // A manager sees where the assigned inspector has got to.
          _Mode.takeOver => <Widget>[
              _takeOverCard(),
              if (showWalk) ...<Widget>[
                const SizedBox(height: 12),
                _walkCard(walk, station, canJump: false),
              ],
            ],
          _Mode.start => <Widget>[
              FilledButton.icon(
                onPressed: _busy ? null : _startOrResume,
                icon: const Icon(Icons.play_arrow),
                label: Text(session.status == InspectionSessionStatus.paused
                    ? l10n.inspectionResume
                    : l10n.inspectionStart),
              ),
              if (showWalk) ...<Widget>[
                const SizedBox(height: 12),
                _walkCard(walk, station, canJump: false),
              ],
            ],
          _Mode.review => <Widget>[_reviewCard(session)],
          _Mode.submitted => <Widget>[
              WahatCard(child: Text(l10n.inspectionSubmitted)),
            ],
          _Mode.cancelled => <Widget>[
              WahatCard(child: Text(l10n.taskStatusCancelled)),
            ],
          _Mode.station => <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.inspectionStation(station!, session.totalStations),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _pause,
                    icon: const Icon(Icons.pause),
                    label: Text(l10n.inspectionPause),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (showWalk) ...<Widget>[
                _walkCard(walk, station, canJump: true),
                const SizedBox(height: 10),
              ],
              ..._stationTrees(details, session),
              if (showWalk && walk.step(station).next.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  l10n.inspectionNextTrees(
                    walk
                        .step(station)
                        .next
                        .map((item) => item.treeCode)
                        .join(' · '),
                  ),
                  key: const Key('inspection-next-trees'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
              ],
            ],
        },
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Column(
          children: <Widget>[
            Expanded(child: list),
            if (mode == _Mode.station) _actionBar(details),
          ],
        ),
      ),
    );
  }

  Widget _takeOverCard() => WahatCard(
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
      );

  Widget _reviewCard(InspectionSession session) => WahatCard(
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
      );

  /// The section map with the walk, the station's place in its aisle, GPS
  /// guidance and turn instructions.
  Widget _walkCard(
    InspectionWalk walk,
    int station, {
    required bool canJump,
  }) {
    final l10n = context.l10n;
    final step = walk.step(station);
    final rows = step.rows;
    final turns = <String>[
      if (step.startsAisle && step.aisle > 1)
        if (rows.length >= 2)
          l10n.inspectionAisleStart(rows[0], rows[1])
        else if (rows.length == 1)
          l10n.inspectionAisleStartSingle(rows.single),
      if (step.nextAisle case final nextAisle?)
        l10n.inspectionAisleEnd(nextAisle),
    ];
    return WahatCard(
      key: const Key('inspection-walk-card'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (walk.hasCoordinates) ...<Widget>[
            LayoutBuilder(
              builder: (context, constraints) => SizedBox(
                height: constraints.maxWidth >= 600 ? 260 : 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openMap(canJump: canJump),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: ValueListenableBuilder<LocationFix?>(
                            valueListenable: _location.fix,
                            builder: (context, fix, _) => InspectionWalkMap(
                              key: const Key('inspection-walk-map'),
                              walk: walk,
                              marks: _marks,
                              currentStation: station,
                              fix: fix,
                              semanticsLabel: l10n.inspectionMapSemantics(
                                station,
                                walk.stations.length,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      children: <Widget>[
                        IconButton.outlined(
                          key: const Key('inspection-location-toggle'),
                          tooltip: _location.isOn
                              ? l10n.locationHide
                              : l10n.locationShow,
                          isSelected: _location.isOn,
                          onPressed: () => _location.toggle(
                            AppServicesScope.maybeOf(context)?.cacheStore,
                          ),
                          icon: const Icon(Icons.location_searching),
                          selectedIcon: const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 4),
                        IconButton.outlined(
                          key: const Key('inspection-open-map'),
                          tooltip: l10n.inspectionOpenMap,
                          onPressed: () => _openMap(canJump: canJump),
                          icon: const Icon(Icons.open_in_full),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            l10n.inspectionAislePosition(
              step.aisle,
              step.aisleCount,
              step.stationInAisle,
              step.stationsInAisle,
            ),
            key: const Key('inspection-aisle-position'),
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (_location.isOn)
            ValueListenableBuilder<LocationFix?>(
              valueListenable: _location.fix,
              builder: (context, fix, _) => _locationLine(walk, station, fix),
            ),
          if (turns.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              key: const Key('inspection-turn'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.u_turn_left, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      turns.join('\n'),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationLine(InspectionWalk walk, int station, LocationFix? fix) {
    final l10n = context.l10n;
    final error = _location.error;
    final String text;
    if (error != null) {
      text = switch (error) {
        LocationUnavailableReason.denied => l10n.locationDenied,
        LocationUnavailableReason.serviceOff => l10n.locationServiceOff,
        LocationUnavailableReason.failed => l10n.locationFailed,
      };
    } else if (fix == null) {
      text = l10n.locationFinding;
    } else {
      text = inspectionLocationText(l10n, walk, station, fix);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            error == null ? Icons.my_location : Icons.location_disabled,
            size: 18,
            color: error == null ? AppColors.waterMain : AppColors.muted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, key: const Key('inspection-location-text')),
          ),
        ],
      ),
    );
  }

  List<Widget> _stationTrees(
    InspectionDetails details,
    InspectionSession session,
  ) {
    final items = List<InspectionSessionItem>.of(
        details.station(_stationIndex!))
      ..sort(
          (a, b) => a.routeItem.side.index.compareTo(b.routeItem.side.index));
    final ambient = Directionality.of(context);
    final tiles = <Widget>[
      for (final item in items)
        Expanded(
          child: Directionality(
            textDirection: ambient,
            child: _TreeTile(
              item: item.routeItem,
              selectedCount: _selected[item.routeItem.treeId]!.length,
              originalCount: _original[item.routeItem.treeId]!.length,
              hasReport: _selected[item.routeItem.treeId]!.isNotEmpty ||
                  _notes[item.routeItem.treeId]!.text.isNotEmpty,
              onReport: () => _openIssueSheet(item.routeItem, session),
            ),
          ),
        ),
    ];
    return <Widget>[
      // Physical left stays on the left in Arabic, like the map.
      Directionality(
        textDirection: TextDirection.ltr,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (var index = 0; index < tiles.length; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: 10),
                tiles[index],
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
    ];
  }

  /// The issue editor for one tree, in a sheet above the navigation bar. It
  /// edits the runner's own state, so closing it keeps every choice.
  Future<void> _openIssueSheet(
    InspectionRouteItem item,
    InspectionSession session,
  ) async {
    final treeId = item.treeId;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          Future<void> refresh(Future<void> action) async {
            await action;
            if (sheetContext.mounted) setSheet(() {});
          }

          final media = MediaQuery.of(sheetContext);
          return Padding(
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _IssueEditor(
                          item: item,
                          selected: _selected[treeId]!,
                          original: _original[treeId]!,
                          notes: _notes[treeId]!,
                          onToggle: (type, selected) =>
                              refresh(_toggleIssue(treeId, type, selected)),
                          onChangeSeverity: (type) =>
                              refresh(_changeSeverity(treeId, type)),
                          requiresPhoto: session.requiresIssuePhoto,
                          hasPhoto: (type) =>
                              _issuePhotos
                                  .containsKey(_photoKey(treeId, type)) ||
                              _savedPhotoPaths
                                  .containsKey(_photoKey(treeId, type)),
                          onPhoto: (type) =>
                              refresh(_pickIssuePhoto(treeId, type)),
                          onNotesChanged: (_) => _scheduleDraftSave(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: FilledButton(
                        key: const Key('inspection-issue-done'),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(sheetContext.l10n.inspectionIssuesDone),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _actionBar(InspectionDetails details) {
    final l10n = context.l10n;
    final allHealthy = details
        .station(_stationIndex!)
        .every((item) => _selected[item.routeItem.treeId]?.isEmpty ?? true);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: <Widget>[
            if (_stationIndex! > 1) ...<Widget>[
              OutlinedButton.icon(
                key: const Key('inspection-previous'),
                onPressed: _busy ? null : _goPreviousStation,
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.commonBack),
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
                    : Icon(allHealthy ? Icons.done_all : Icons.arrow_forward),
                label: Text(
                  allHealthy
                      ? l10n.inspectionAllHealthyNext
                      : l10n.inspectionSaveNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<IssueSeverity?> _askSeverity() => showDialog<IssueSeverity>(
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
    final severity = await _askSeverity();
    if (severity != null && mounted) {
      setState(() => _selected[treeId]![type] = severity);
      _scheduleDraftSave();
    }
  }

  Future<void> _changeSeverity(String treeId, TreeIssueType type) async {
    final severity = await _askSeverity();
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
      useRootNavigator: true,
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
    await _jumpTo(station - 1);
  }

  /// Opens a saved station, or the first unsaved one. Unsaved stations past
  /// it stay closed so the walk keeps its order.
  Future<void> _jumpTo(int station) async {
    final details = _details;
    if (_busy || details == null || station == _stationIndex) return;
    setState(() => _busy = true);
    await _persistDraft();
    if (!mounted) return;
    setState(() {
      _stationIndex = station;
      if (details.items.every(
        (item) => item.status == InspectionItemStatus.inspected,
      )) {
        _showCompletedStation = true;
      }
    });
    await _prepareStation();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openMap({required bool canJump}) async {
    final walk = _walk;
    final station = _stationIndex;
    final details = _details;
    if (walk == null || station == null || details == null) return;
    final firstPending = _firstPendingStation(details);
    final picked = await Navigator.of(context, rootNavigator: true).push<int>(
      MaterialPageRoute<int>(
        fullscreenDialog: true,
        builder: (_) => InspectionWalkMapPage(
          walk: walk,
          marks: _marks,
          currentStation: station,
          fix: _location.fix,
          canOpenStation: canJump
              ? (candidate) =>
                  candidate <= firstPending || _stationSaved(details, candidate)
              : null,
          blockedMessage: context.l10n.inspectionJumpBlocked(firstPending),
        ),
      ),
    );
    if (picked != null && mounted) await _jumpTo(picked);
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

/// Plain-language GPS guidance for [station]. GPS is good to a few metres
/// and trees are about 8 m apart, so this guides; it never moves the walk.
String inspectionLocationText(
  AppLocalizations l10n,
  InspectionWalk walk,
  int station,
  LocationFix fix,
) {
  final accuracy = fix.accuracyMeters.round();
  if (fix.accuracyMeters > 25) return l10n.locationWeak(accuracy);
  final located = walk.locate(fix.latitude, fix.longitude, current: station);
  if (located == null) return l10n.locationFailed;
  if (located.metersOutside > 40) {
    return l10n.inspectionLocationOutside(located.metersOutside.round());
  }
  final meters = located.metersToStation.round();
  final here = located.metersToStation <= 6;
  // Below ~10 m the fix may sit between rows; only point elsewhere beyond it.
  final clearlyElsewhere = located.metersToStation > 10;
  final lines = <String>[
    if (here)
      l10n.inspectionLocationHere(accuracy)
    else
      l10n.inspectionLocationAway(meters, accuracy),
  ];
  final aisle = walk.aisleOf(station);
  if (clearlyElsewhere && located.nearestAisle != aisle) {
    lines.add(l10n.inspectionLocationOtherAisle(located.nearestAisle, aisle));
  } else if (clearlyElsewhere && located.nearestStation != station) {
    final offset = walk.stations.indexOf(located.nearestStation) -
        walk.stations.indexOf(station);
    lines.add(offset > 0
        ? l10n.inspectionLocationAhead(offset)
        : l10n.inspectionLocationBehind(-offset));
  }
  return lines.join(' ');
}

/// One tree of the station: which side, its label, and whether anything is
/// reported. Healthy is the default, so the common case needs no input.
class _TreeTile extends StatelessWidget {
  const _TreeTile({
    required this.item,
    required this.selectedCount,
    required this.originalCount,
    required this.hasReport,
    required this.onReport,
  });

  final InspectionRouteItem item;
  final int selectedCount;
  final int originalCount;

  /// Whether this tree already has issues or a note, so the button edits.
  final bool hasReport;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final side = _sideLabel(context, item.side);
    return Semantics(
      container: true,
      label: l10n.inspectionTreeCardSemantics(
        item.treeCode,
        side,
        originalCount,
      ),
      child: WahatCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  switch (item.side) {
                    InspectionRouteSide.left => Icons.west,
                    InspectionRouteSide.right => Icons.east,
                    InspectionRouteSide.single => Icons.north,
                  },
                  size: 18,
                  color: AppColors.green,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(side, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(item.treeCode, style: theme.textTheme.titleLarge),
            ),
            if (item.rowNumber != null || item.treeNumber != null)
              Text(
                l10n.inspectionRowTree(
                  item.rowNumber?.toString() ?? '—',
                  item.treeNumber?.toString() ?? '—',
                ),
                style: theme.textTheme.bodySmall,
              ),
            if (originalCount > 0)
              Text(
                l10n.inspectionExistingIssues(originalCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.issue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(
                  selectedCount == 0
                      ? Icons.check_circle
                      : Icons.report_problem_outlined,
                  size: 20,
                  color: selectedCount == 0 ? AppColors.green : AppColors.issue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    selectedCount == 0
                        ? l10n.inspectionHealthy
                        : l10n.inspectionIssueCount(selectedCount),
                    style: TextStyle(
                      color: selectedCount == 0
                          ? AppColors.green
                          : AppColors.issue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              key: Key('inspection-report-${item.treeId}'),
              onPressed: onReport,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: Icon(hasReport ? Icons.edit_outlined : Icons.add, size: 18),
              label: Text(
                hasReport
                    ? l10n.inspectionEditIssues
                    : l10n.inspectionReportIssue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueEditor extends StatelessWidget {
  const _IssueEditor({
    required this.item,
    required this.selected,
    required this.original,
    required this.notes,
    required this.onToggle,
    required this.onChangeSeverity,
    required this.requiresPhoto,
    required this.hasPhoto,
    required this.onPhoto,
    required this.onNotesChanged,
  });

  final InspectionRouteItem item;
  final Map<TreeIssueType, IssueSeverity> selected;
  final Map<TreeIssueType, IssueSeverity> original;
  final TextEditingController notes;
  final void Function(TreeIssueType, bool) onToggle;
  final void Function(TreeIssueType) onChangeSeverity;
  final bool requiresPhoto;
  final bool Function(TreeIssueType) hasPhoto;
  final Future<void> Function(TreeIssueType) onPhoto;
  final ValueChanged<String> onNotesChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeyedSubtree(
      key: Key('inspection-editor-${item.treeId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '${item.treeCode} · ${_sideLabel(context, item.side)}',
            style: Theme.of(context).textTheme.titleMedium,
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
                        ? Icon(
                            Icons.history,
                            size: 16,
                            color: selected.containsKey(type)
                                ? Colors.white
                                : AppColors.ink,
                          )
                        : null,
                    // The theme fills selected chips dark green.
                    labelStyle: TextStyle(
                      color: selected.containsKey(type)
                          ? Colors.white
                          : AppColors.ink,
                    ),
                    label: Text(type.localizedLabel(l10n)),
                    onSelected: (value) => onToggle(type, value),
                  ),
                )
                .toList(growable: false),
          ),
          for (final entry in selected.entries) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    entry.key.localizedLabel(l10n),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: Key(
                    'inspection-severity-${item.treeId}-${entry.key.wireValue}',
                  ),
                  onPressed: () => onChangeSeverity(entry.key),
                  icon: const Icon(Icons.arrow_drop_down),
                  label: Text(entry.value.localizedLabel(l10n)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              key: Key(
                'inspection-photo-${item.treeId}-${entry.key.wireValue}',
              ),
              onPressed: () => onPhoto(entry.key),
              icon: Icon(
                hasPhoto(entry.key)
                    ? Icons.check_circle_outline
                    : Icons.add_a_photo_outlined,
              ),
              label: Text(
                hasPhoto(entry.key)
                    ? l10n.inspectionIssuePhotoReady
                    : requiresPhoto
                        ? l10n.inspectionAddRequiredIssuePhoto
                        : l10n.inspectionAddIssuePhoto,
              ),
            ),
          ],
          if (original.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              l10n.inspectionExistingIssueHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: notes,
            onChanged: onNotesChanged,
            maxLines: 2,
            decoration: InputDecoration(labelText: l10n.issueObservationLabel),
          ),
        ],
      ),
    );
  }
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
