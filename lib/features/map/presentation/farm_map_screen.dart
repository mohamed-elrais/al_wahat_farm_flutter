import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/map_projection.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/tree_reconciliation.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_painter.dart';
import 'package:al_wahat_farm_flutter/features/planting_pits/data/planting_pit_repository.dart';
import 'package:al_wahat_farm_flutter/features/planting_pits/domain/planting_pit.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:al_wahat_farm_flutter/features/trees/presentation/tree_detail_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({
    this.mapFuture,
    this.focus,
    this.plantingPitRepository,
    super.key,
  });

  final Future<ProjectedFarmMap>? mapFuture;
  final PlantingPitRepository? plantingPitRepository;

  /// Deep-link focus request: `tree:<id>`, `zone:<uuid>` or
  /// `section:<id|uuid>`. Applied once after the map loads; unknown ids are
  /// a graceful no-op.
  final String? focus;

  @override
  State<FarmMapScreen> createState() => _FarmMapScreenState();
}

class _FarmMapScreenState extends State<FarmMapScreen> {
  late final Future<ProjectedFarmMap> _map;
  final _transformation = TransformationController();
  String? _section;
  FarmTree? _selectedTree;
  PlantingPit? _selectedPlantingPit;
  NetworkValve? _selectedValve;
  bool _trees = true;
  bool _plantingPits = true;
  bool _irrigation = true;
  bool _utilities = true;
  bool _valves = true;
  bool _flushValves = false;
  bool _waterSupply = false;
  ProjectedFarmMap? _lastAssetMap;
  FarmHierarchy? _lastLiveHierarchy;
  ProjectedFarmMap? _lastReconciledMap;
  FarmMapCompositionResult? _composition;
  ProjectedFarmMap? _lastPitMap;
  FarmHierarchy? _lastPitHierarchy;
  List<ProjectedPlantingPit>? _lastProjectedPits;
  String? _pendingFocus;
  bool _needsRefit = false;
  bool _fullScreenOpen = false;
  ValueListenable<bool>? _visibility;

  PlantingPitRepository get _plantingPitRepository =>
      widget.plantingPitRepository ??
      SupabasePlantingPitRepository(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _pendingFocus = widget.focus;
    _map = widget.mapFuture ??
        const MapAssetRepository().load().then(ProjectedFarmMap.new);
  }

  @override
  void didUpdateWidget(FarmMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new deep link while the map tab is alive re-arms the focus.
    if (widget.focus != oldWidget.focus && widget.focus != null) {
      _pendingFocus = widget.focus;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The shell keeps this screen alive in an IndexedStack; TickerMode
    // flips to disabled when the user leaves the tab, which is our signal
    // to drop ephemeral state (selection, highlight, filter, camera).
    final notifier = TickerMode.getNotifier(context);
    if (!identical(notifier, _visibility)) {
      _visibility?.removeListener(_handleVisibilityChanged);
      _visibility = notifier..addListener(_handleVisibilityChanged);
    }
  }

  void _handleVisibilityChanged() {
    if (_visibility?.value != false || !mounted) return;
    // Entering full-screen also disables tickers below the pushed route;
    // that is not "leaving the map".
    if (_fullScreenOpen) return;
    setState(() {
      _selectedTree = null;
      _selectedPlantingPit = null;
      _selectedValve = null;
      _section = null;
      _pendingFocus = null;
      _needsRefit = true; // default camera on the next visit
    });
  }

  @override
  void dispose() {
    _visibility?.removeListener(_handleVisibilityChanged);
    _transformation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PaperBackground(
        child: FutureBuilder<ProjectedFarmMap>(
          future: _map,
          builder:
              (BuildContext context, AsyncSnapshot<ProjectedFarmMap> snapshot) {
            if (snapshot.hasError) return _MapError(error: snapshot.error!);
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final assetMap = snapshot.data!;
            final liveHierarchy =
                FarmHierarchyScope.maybeOf(context)?.hierarchy;
            final map = _effectiveMap(assetMap, liveHierarchy);
            final plantingPits = _projectPlantingPits(map, liveHierarchy);
            final pitCountsBySection = <String, int>{};
            for (final projected in plantingPits) {
              if (projected.pit.status == PlantingPitStatus.cancelled) continue;
              pitCountsBySection.update(
                projected.sectionCode,
                (count) => count + 1,
                ifAbsent: () => 1,
              );
            }
            final manager = OperationalContextScope.maybeOf(context)
                    ?.selectedMembership
                    .role
                    .canManageTasks ??
                false;
            final showDataWarning =
                manager && (_composition?.hasDiscrepancies ?? false);
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final focus = _pendingFocus;
                if (focus != null) {
                  _pendingFocus = null;
                  _needsRefit = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _applyFocus(map, focus, constraints.biggest);
                    // Consume the deep link so the route no longer carries
                    // it: re-opening the map later starts from the default
                    // state, and re-sending the same focus works again.
                    GoRouter.maybeOf(context)?.go('/map');
                  });
                } else if (_needsRefit) {
                  _needsRefit = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _fit(map, null, constraints.biggest);
                  });
                }
                final wide = constraints.maxWidth >= AppBreakpoints.tablet;
                final highlights = _highlights(map);
                final canvas = _MapPanel(
                  map: map,
                  transformation: _transformation,
                  section: _section,
                  selectedTree: _selectedTree,
                  plantingPits: plantingPits,
                  selectedPlantingPit: _selectedPlantingPit,
                  selectedValveId: _selectedValve?.assetId,
                  highlightZones: highlights.zones,
                  highlightSubmains: highlights.submains,
                  highlightLine: highlights.line,
                  showTrees: _trees,
                  showPlantingPits: _plantingPits,
                  showIrrigation: _irrigation,
                  showUtilities: _utilities,
                  showValves: _valves,
                  showFlushValves: _flushValves,
                  showWaterSupply: _waterSupply,
                  onTapTree: (tree) => _selectTree(tree),
                  onTapPlantingPit: (pit) => _selectPlantingPit(pit),
                  onTapValve: (valve) => _selectValve(map, valve),
                  onTapMiss: () {
                    if (_selectedValve != null) {
                      setState(() => _selectedValve = null);
                    }
                  },
                );
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 20 : 10,
                    12,
                    wide ? 20 : 10,
                    90,
                  ),
                  child: Column(
                    children: <Widget>[
                      _MapHeader(
                        map: map,
                        section: _section,
                        plantingPitCount: _section == null
                            ? 0
                            : pitCountsBySection[_section] ?? 0,
                        trees: _trees,
                        plantingPits: _plantingPits,
                        irrigation: _irrigation,
                        utilities: _utilities,
                        valves: _valves,
                        flushValves: _flushValves,
                        waterSupply: _waterSupply,
                        onReset: () => _fit(map, null, constraints.biggest),
                        onFullScreen: () => _openFullScreen(map),
                        onTrees: (value) => setState(() => _trees = value),
                        onPlantingPits: (value) =>
                            setState(() => _plantingPits = value),
                        onIrrigation: (value) =>
                            setState(() => _irrigation = value),
                        onUtilities: (value) =>
                            setState(() => _utilities = value),
                        onValves: (value) => setState(() => _valves = value),
                        onFlushValves: (value) =>
                            setState(() => _flushValves = value),
                        onWaterSupply: (value) =>
                            setState(() => _waterSupply = value),
                      ),
                      const SizedBox(height: 8),
                      _SectionFilter(
                        sections: map.data.sections,
                        plantingPitCounts: pitCountsBySection,
                        selected: _section,
                        onSelected: (section) {
                          setState(() {
                            _section = section;
                            _selectedTree = null;
                            _selectedPlantingPit = null;
                          });
                          _fit(map, section, constraints.biggest);
                        },
                      ),
                      if (manager && _liveSectionFor(_section) != null) ...[
                        const SizedBox(height: 8),
                        _SectionActions(
                          createTaskLabel:
                              context.l10n.mapCreateTaskForSection(_section!),
                          addPitLabel:
                              context.l10n.plantingPitAddForSection(_section!),
                          onCreateTask: () => context.go(
                            '/tasks/create?sectionId='
                            '${_liveSectionFor(_section)!.id}',
                          ),
                          onAddPit: () => _showCreatePlantingPit(
                            _liveSectionFor(_section)!,
                          ),
                        ),
                      ],
                      if (showDataWarning) ...<Widget>[
                        const SizedBox(height: 8),
                        _DiscrepancyBanner(result: _composition!),
                      ],
                      const SizedBox(height: 8),
                      Expanded(
                        child: wide
                            ? Row(
                                children: <Widget>[
                                  Expanded(child: canvas),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 280,
                                    child: _MapSummary(
                                      map: map,
                                      selected: _selectedTree,
                                      selectedPlantingPit: _selectedPlantingPit,
                                    ),
                                  ),
                                ],
                              )
                            : canvas,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );

  List<ProjectedPlantingPit> _projectPlantingPits(
    ProjectedFarmMap map,
    FarmHierarchy? hierarchy,
  ) {
    if (hierarchy == null) return const <ProjectedPlantingPit>[];
    if (identical(map, _lastPitMap) &&
        identical(hierarchy, _lastPitHierarchy) &&
        _lastProjectedPits != null) {
      return _lastProjectedPits!;
    }
    final result = <ProjectedPlantingPit>[];
    for (final pit in hierarchy.plantingPits) {
      final latitude = pit.latitude;
      final longitude = pit.longitude;
      final section = hierarchy.sectionById(pit.sectionId);
      if (latitude == null ||
          longitude == null ||
          section == null ||
          !map.data.sections.any((item) => item.id == section.code)) {
        continue;
      }
      result.add(
        ProjectedPlantingPit(
          pit: pit,
          sectionCode: section.code,
          point: map.projection.project(
            GeoCoordinate(longitude: longitude, latitude: latitude),
          ),
        ),
      );
    }
    final projected = List<ProjectedPlantingPit>.unmodifiable(result);
    _lastPitMap = map;
    _lastPitHierarchy = hierarchy;
    _lastProjectedPits = projected;
    return projected;
  }

  ProjectedFarmMap _effectiveMap(
    ProjectedFarmMap assetMap,
    FarmHierarchy? liveHierarchy,
  ) {
    if (liveHierarchy == null) {
      _composition = null;
      return assetMap;
    }
    if (identical(assetMap, _lastAssetMap) &&
        identical(liveHierarchy, _lastLiveHierarchy) &&
        _lastReconciledMap != null) {
      return _lastReconciledMap!;
    }

    final result = const FarmMapComposer().compose(
      assetMap.data,
      liveHierarchy,
    );
    final reconciledMap = ProjectedFarmMap(result.data);
    _lastAssetMap = assetMap;
    _lastLiveHierarchy = liveHierarchy;
    _lastReconciledMap = reconciledMap;
    _composition = result;
    SafeLog.event(
      'farm_map_composition',
      data: <String, Object?>{
        'trees': result.data.trees.length,
        'resolved_map_zones': result.resolvedMapZones,
        'discrepancies': result.discrepancies.length,
      },
    );
    return reconciledMap;
  }

  void _selectTree(FarmTree tree, {BuildContext? presentationContext}) {
    setState(() {
      _selectedTree = tree;
      _selectedPlantingPit = null;
      _section = tree.section;
    });
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    final operational = OperationalContextScope.maybeOf(context);
    final isLive = hierarchy?.trees.any((item) => item.id == tree.id) ?? false;
    String? zoneLabel;
    if (hierarchy != null) {
      for (final zone in hierarchy.zones) {
        if (zone.id == tree.zoneId) {
          zoneLabel = zone.code;
          break;
        }
      }
    }
    final identity = TreeIdentity.fromMapTree(
      tree,
      farmId: operational?.selectedMembership.farm.id,
      zoneLabel: zoneLabel,
    );
    final canManageTasks =
        operational?.selectedMembership.role.canManageTasks ?? false;
    showModalBottomSheet<void>(
      context: presentationContext ?? context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TreeDetailSheet(
        tree: identity,
        onAttachTask: isLive && canManageTasks
            ? () {
                Navigator.of(sheetContext).pop();
                _leaveFullScreenIfOpen();
                context.go('/tasks/create?treeId=${tree.id}');
              }
            : null,
        onReportIssue: isLive
            ? () {
                Navigator.of(sheetContext).pop();
                _leaveFullScreenIfOpen();
                context.push('/map/tree/${tree.id}/report-issue');
              }
            : null,
      ),
    );
  }

  void _selectPlantingPit(
    ProjectedPlantingPit projected, {
    BuildContext? presentationContext,
  }) {
    setState(() {
      _selectedPlantingPit = projected.pit;
      _selectedTree = null;
      _section = projected.sectionCode;
    });
    final canManage = OperationalContextScope.maybeOf(context)
            ?.selectedMembership
            .role
            .canManageTasks ??
        false;
    final next = projected.pit.status.next;
    showModalBottomSheet<void>(
      context: presentationContext ?? context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlantingPitSheet(
        pit: projected.pit,
        sectionCode: projected.sectionCode,
        onAdvance: canManage && next != null
            ? () => _plantingPitRepository.advanceStatus(
                  projected.pit.id,
                  next,
                )
            : null,
        onCancel: canManage && projected.pit.status.canCancel
            ? () => _plantingPitRepository.cancel(projected.pit.id)
            : null,
        onChanged: _plantingPitChanged,
      ),
    );
  }

  void _plantingPitChanged() {
    if (!mounted) return;
    final scope = FarmHierarchyScope.maybeOf(context);
    final controller = FarmHierarchyScope.maybeControllerOf(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.plantingPitUpdated)),
    );
    if (scope != null) controller?.load(scope.hierarchy.farmId);
  }

  Future<void> _showCreatePlantingPit(FarmSection section) async {
    final scope = FarmHierarchyScope.maybeOf(context);
    final controller = FarmHierarchyScope.maybeControllerOf(context);
    if (scope == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlantingPitCreateSheet(
        repository: _plantingPitRepository,
        farmId: scope.hierarchy.farmId,
        section: section,
        onCreated: () {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.plantingPitCreated)),
          );
          controller?.load(scope.hierarchy.farmId);
        },
      ),
    );
  }

  /// Highlight overlays for the current valve selection, shared by the
  /// embedded panel and the full-screen panel.
  ({Set<String>? zones, Set<String>? submains, List<Offset>? line}) _highlights(
      ProjectedFarmMap map) {
    final selectedValve = _selectedValve;
    final zones = selectedValve == null ? null : _zonesFor(map, selectedValve);
    final isolationSelected =
        selectedValve != null && !selectedValve.isZoneControl;
    final line = !isolationSelected
        ? null
        : map.valves
            .firstWhere(
              (projected) => projected.valve.assetId == selectedValve.assetId,
            )
            .downstreamPoints;
    final submains = selectedValve?.downstreamSubmains;
    return (
      zones: zones,
      submains: isolationSelected && (submains?.isNotEmpty ?? false)
          ? submains!.toSet()
          : null,
      line: line,
    );
  }

  /// The live-zone uuids a valve controls: its own zone for a zone control
  /// valve, every zone on its downstream submains for an isolation valve.
  Set<String>? _zonesFor(ProjectedFarmMap map, NetworkValve valve) {
    if (valve.isZoneControl) {
      final zone = valve.zoneUuid;
      return zone == null ? null : <String>{zone};
    }
    final submains = valve.downstreamSubmains;
    if (submains == null || submains.isEmpty) return null;
    final zones = <String>{
      for (final candidate in map.data.valves)
        if (candidate.isZoneControl &&
            candidate.zoneUuid != null &&
            submains.contains(candidate.submain))
          candidate.zoneUuid!,
    };
    return zones.isEmpty ? null : zones;
  }

  void _selectValve(
    ProjectedFarmMap map,
    NetworkValve valve, {
    BuildContext? presentationContext,
  }) {
    setState(() => _selectedValve = valve);
    final zones = _zonesFor(map, valve) ?? const <String>{};
    final actualTrees =
        map.data.trees.where((tree) => zones.contains(tree.zoneId)).length;
    final canManageTasks = OperationalContextScope.maybeOf(context)
            ?.selectedMembership
            .role
            .canManageTasks ??
        false;
    final zoneUuid = valve.zoneUuid;
    final zoneIsLive = zoneUuid != null &&
        (FarmHierarchyScope.maybeOf(context)
                ?.hierarchy
                .zones
                .any((zone) => zone.id == zoneUuid) ??
            false);
    showModalBottomSheet<void>(
      context: presentationContext ?? context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ZoneSheet(
        valve: valve,
        actualTrees: actualTrees,
        onCreateTask: valve.isZoneControl && zoneIsLive && canManageTasks
            ? () {
                Navigator.of(sheetContext).pop();
                _leaveFullScreenIfOpen();
                context.go('/tasks/create?zoneId=$zoneUuid');
              }
            : null,
      ),
    );
  }

  /// Applies a `kind:id` deep-link focus: selects the entity, fits its
  /// section and opens its sheet. Unknown kinds or ids do nothing.
  void _applyFocus(ProjectedFarmMap map, String focus, Size viewport) {
    final separator = focus.indexOf(':');
    if (separator <= 0 || separator == focus.length - 1) return;
    final kind = focus.substring(0, separator);
    final id = focus.substring(separator + 1);
    switch (kind) {
      case 'tree':
        for (final tree in map.data.trees) {
          if (tree.id == id) {
            _fitSection(map, tree.section, viewport);
            _selectTree(tree);
            return;
          }
        }
      case 'zone':
        for (final valve in map.data.valves) {
          if (valve.isZoneControl && valve.zoneUuid == id) {
            final section = valve.section;
            if (section != null) _fitSection(map, section, viewport);
            _selectValve(map, valve);
            return;
          }
        }
      case 'section':
        final resolved = _mapSectionIdFor(map, id);
        if (resolved != null) {
          setState(() {
            _selectedTree = null;
          });
          _fitSection(map, resolved, viewport);
        }
    }
  }

  /// Resolves a section token that may be a map section id ("A") or a live
  /// hierarchy section uuid.
  String? _mapSectionIdFor(ProjectedFarmMap map, String token) {
    if (map.data.sections.any((section) => section.id == token)) return token;
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    if (hierarchy == null) return null;
    for (final section in hierarchy.sections) {
      if (section.id == token) {
        return map.data.sections.any((item) => item.id == section.code)
            ? section.code
            : null;
      }
    }
    return null;
  }

  void _fitSection(ProjectedFarmMap map, String section, Size viewport) {
    if (!map.data.sections.any((item) => item.id == section)) return;
    setState(() => _section = section);
    _fit(map, section, viewport);
  }

  /// The live hierarchy section matching the map section filter, if any.
  FarmSection? _liveSectionFor(String? mapSectionId) {
    if (mapSectionId == null) return null;
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    if (hierarchy == null) return null;
    for (final section in hierarchy.sections) {
      if (section.code == mapSectionId || section.id == mapSectionId) {
        return section;
      }
    }
    return null;
  }

  /// Navigating to another screen (e.g. create task from a sheet) while
  /// full screen is open must first dismiss the full-screen route, which
  /// sits above the shell on the root navigator.
  void _leaveFullScreenIfOpen() {
    if (!_fullScreenOpen) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Full-screen mode reuses this state's transformation controller and
  /// selection, so camera and highlights survive entering and leaving.
  Future<void> _openFullScreen(ProjectedFarmMap map) async {
    _fullScreenOpen = true;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullScreenMap(host: this, map: map),
      ),
    );
    _fullScreenOpen = false;
    // Reflect any selection made while full screen was open.
    if (mounted) setState(() {});
  }

  void _fit(ProjectedFarmMap map, String? section, Size viewport) {
    final rect = section == null
        ? Offset.zero & MapProjection.canvasSize
        : map.sections.firstWhere((item) => item.section.id == section).bounds;
    final available = Size(viewport.width, viewport.height - 150);
    final scale = (available.width / rect.width).clamp(0.1, 8.0) <
            (available.height / rect.height).clamp(0.1, 8.0)
        ? available.width / rect.width
        : available.height / rect.height;
    _transformation.value = Matrix4.identity()
      ..translate(
        (available.width - rect.width * scale) / 2 - rect.left * scale,
        (available.height - rect.height * scale) / 2 - rect.top * scale,
      )
      ..scale(scale);
  }
}

/// Localized display name for a network valve, built from its structured
/// fields (the raw asset [NetworkValve.name] is English survey data).
String valveDisplayName(AppLocalizations l10n, NetworkValve valve) {
  final number = valve.assetId.split('-').last;
  if (!valve.isZoneControl) return l10n.mapValveNameIsolation(number);
  final section = valve.section;
  final submain = valve.submain;
  if (section != null && submain != null) {
    return l10n.mapValveNameZone(section, submain, number);
  }
  return valve.name;
}

/// Bottom sheet for a tapped valve: a zone control valve shows its zone and
/// tree counts, a mainline isolation valve just identifies itself. Dismissing
/// it keeps the map highlight; tapping empty map space clears it.
class _ZoneSheet extends StatelessWidget {
  const _ZoneSheet({
    required this.valve,
    required this.actualTrees,
    this.onCreateTask,
  });

  final NetworkValve valve;
  final int actualTrees;

  /// Manager-only: creates a task targeting this valve's live zone.
  final VoidCallback? onCreateTask;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final zone = valve.isZoneControl;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: WahatCard(
          key: const Key('zone-sheet'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: valve.color ??
                          (zone
                              ? AppColors.waterMain
                              : const Color(0xFF32424E)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const SizedBox.square(dimension: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Eyebrow(
                          zone
                              ? l10n.mapZoneSheetTitle
                              : l10n.mapIsolationSheetTitle,
                        ),
                        Text(
                          valveDisplayName(l10n, valve),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (zone) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  l10n.mapZoneTreeCount(actualTrees),
                  key: const Key('zone-sheet-trees'),
                ),
                if (valve.zoneTreeCount != null)
                  Text(l10n.mapZoneTreesPlanned(valve.zoneTreeCount!)),
              ] else if (valve.downstreamSubmains?.isNotEmpty ??
                  false) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  l10n.mapValveTreeCount(actualTrees),
                  key: const Key('valve-sheet-trees'),
                ),
                Text(
                  l10n.mapValveDownstream(
                    valve.downstreamSubmains!.join(', '),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                zone ? l10n.mapZoneHighlightHint : l10n.mapValveHighlightHint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
              if (onCreateTask != null) ...<Widget>[
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const Key('zone-sheet-create-task'),
                  onPressed: onCreateTask,
                  icon: const Icon(Icons.assignment_add),
                  label: Text(l10n.attachTask),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscrepancyBanner extends StatelessWidget {
  const _DiscrepancyBanner({required this.result});

  final FarmMapCompositionResult result;

  @override
  Widget build(BuildContext context) {
    final summary = result.discrepancyCounts.entries
        .map((entry) => '${entry.key.name}: ${entry.value}')
        .join(' · ');
    return Semantics(
      label: context.l10n.mapDiscrepancySemantics,
      child: DecoratedBox(
        key: const Key('map-data-warning'),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEFE5),
          border: Border.all(color: AppColors.orange.withOpacity(0.55)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.mapDiscrepancy(
                    result.discrepancies.length,
                    summary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPanel extends StatefulWidget {
  const _MapPanel({
    required this.map,
    required this.transformation,
    required this.section,
    required this.selectedTree,
    required this.plantingPits,
    required this.selectedPlantingPit,
    required this.selectedValveId,
    required this.highlightZones,
    required this.highlightSubmains,
    required this.highlightLine,
    required this.showTrees,
    required this.showPlantingPits,
    required this.showIrrigation,
    required this.showUtilities,
    required this.showValves,
    required this.showFlushValves,
    required this.showWaterSupply,
    required this.onTapTree,
    required this.onTapPlantingPit,
    required this.onTapValve,
    required this.onTapMiss,
    this.autoFit = true,
  });
  final ProjectedFarmMap map;
  final TransformationController transformation;

  /// The full-screen panel shares the embedded panel's transformation
  /// controller and must not clobber its camera with an initial fit.
  final bool autoFit;
  final String? section;
  final FarmTree? selectedTree;
  final List<ProjectedPlantingPit> plantingPits;
  final PlantingPit? selectedPlantingPit;
  final String? selectedValveId;
  final Set<String>? highlightZones;
  final Set<String>? highlightSubmains;
  final List<Offset>? highlightLine;
  final bool showTrees;
  final bool showPlantingPits;
  final bool showIrrigation;
  final bool showUtilities;
  final bool showValves;
  final bool showFlushValves;
  final bool showWaterSupply;
  final ValueChanged<FarmTree> onTapTree;
  final ValueChanged<ProjectedPlantingPit> onTapPlantingPit;
  final ValueChanged<NetworkValve> onTapValve;
  final VoidCallback onTapMiss;

  @override
  State<_MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<_MapPanel> {
  static const _minScale = 0.1;
  static const _maxScale = 8.0;
  static const _zoomStep = 1.4;

  bool _fitted = false;

  void _zoom(double factor, Size viewportSize) {
    final current = widget.transformation.value;
    final currentScale = current.getMaxScaleOnAxis();
    final targetScale =
        (currentScale * factor).clamp(_minScale, _maxScale).toDouble();
    if ((targetScale - currentScale).abs() < 0.0001) return;

    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final sceneCenter = widget.transformation.toScene(viewportCenter);
    final relativeScale = targetScale / currentScale;
    widget.transformation.value = current.clone()
      ..translate(sceneCenter.dx, sceneCenter.dy)
      ..scale(relativeScale)
      ..translate(-sceneCenter.dx, -sceneCenter.dy);
  }

  /// The closest tappable valve (zone control or mainline isolation) within
  /// [tolerance] canvas units.
  NetworkValve? _nearestValve(Offset point, double tolerance) {
    NetworkValve? best;
    var bestDistance = tolerance;
    for (final projected in widget.map.valves) {
      final distance = (projected.point - point).distance;
      if (distance <= bestDistance) {
        bestDistance = distance;
        best = projected.valve;
      }
    }
    return best;
  }

  ProjectedPlantingPit? _nearestPlantingPit(
    Offset point,
    double tolerance,
  ) {
    ProjectedPlantingPit? best;
    var bestDistance = tolerance;
    for (final projected in widget.plantingPits) {
      if (widget.section != null && projected.sectionCode != widget.section) {
        continue;
      }
      final distance = (projected.point - point).distance;
      if (distance <= bestDistance) {
        bestDistance = distance;
        best = projected;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (widget.autoFit && !_fitted) {
            _fitted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final scale = (constraints.maxWidth /
                          MapProjection.canvasSize.width) <
                      (constraints.maxHeight / MapProjection.canvasSize.height)
                  ? constraints.maxWidth / MapProjection.canvasSize.width
                  : constraints.maxHeight / MapProjection.canvasSize.height;
              widget.transformation.value = Matrix4.identity()
                ..translate(
                  (constraints.maxWidth -
                          MapProjection.canvasSize.width * scale) /
                      2,
                  (constraints.maxHeight -
                          MapProjection.canvasSize.height * scale) /
                      2,
                )
                ..scale(scale);
            });
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: AppColors.sand,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final inverse = Matrix4.inverted(
                          widget.transformation.value,
                        );
                        final point = MatrixUtils.transformPoint(
                          inverse,
                          details.localPosition,
                        );
                        final scale =
                            widget.transformation.value.getMaxScaleOnAxis();
                        // Valves sit above trees, so they win the tap.
                        if (widget.showValves) {
                          final valve = _nearestValve(point, 30 / scale);
                          if (valve != null) {
                            widget.onTapValve(valve);
                            return;
                          }
                        }
                        if (widget.showPlantingPits) {
                          final pit = _nearestPlantingPit(point, 40 / scale);
                          if (pit != null) {
                            widget.onTapPlantingPit(pit);
                            return;
                          }
                        }
                        if (widget.showTrees) {
                          final nearest = widget.map.treeIndex.nearest(
                            point,
                            tolerance: 44 / scale,
                            section: widget.section,
                          );
                          if (nearest != null) {
                            widget.onTapTree(nearest.tree);
                            return;
                          }
                        }
                        widget.onTapMiss();
                      },
                      // North-up geographic canvas uses absolute projected
                      // pixel coordinates, so it must never be mirrored in
                      // RTL locales. Only this map subtree is locked to LTR;
                      // the surrounding chrome keeps the ambient direction.
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: InteractiveViewer(
                          constrained: false,
                          minScale: _minScale,
                          maxScale: _maxScale,
                          transformationController: widget.transformation,
                          boundaryMargin: const EdgeInsets.all(220),
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: MapProjection.canvasSize,
                              painter: FarmMapPainter(
                                map: widget.map,
                                selectedSection: widget.section,
                                selectedTreeId: widget.selectedTree?.id,
                                plantingPits: widget.plantingPits,
                                selectedPlantingPitId:
                                    widget.selectedPlantingPit?.id,
                                showTrees: widget.showTrees,
                                showPlantingPits: widget.showPlantingPits,
                                showIrrigation: widget.showIrrigation,
                                showUtilities: widget.showUtilities,
                                showValves: widget.showValves,
                                showFlushValves: widget.showFlushValves,
                                showWaterSupply: widget.showWaterSupply,
                                selectedValveId: widget.selectedValveId,
                                highlightZoneUuids: widget.highlightZones,
                                highlightSubmains: widget.highlightSubmains,
                                highlightLine: widget.highlightLine,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 12,
                    bottom: 12,
                    child: _MapZoomControls(
                      onZoomIn: () => _zoom(_zoomStep, constraints.biggest),
                      onZoomOut: () =>
                          _zoom(1 / _zoomStep, constraints.biggest),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.card.withOpacity(0.94),
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              key: const Key('map-zoom-in'),
              tooltip: context.l10n.mapZoomIn,
              onPressed: onZoomIn,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(
              width: 32,
              child: Divider(height: 1),
            ),
            IconButton(
              key: const Key('map-zoom-out'),
              tooltip: context.l10n.mapZoomOut,
              onPressed: onZoomOut,
              icon: const Icon(Icons.remove),
            ),
          ],
        ),
      );
}

/// Root-navigator full-screen map. It renders through the HOST screen's
/// state (same transformation controller, same selection fields), so the
/// camera and highlights carry over in both directions; taps route through
/// the host's handlers and its sheets open above this route.
class _FullScreenMap extends StatefulWidget {
  const _FullScreenMap({required this.host, required this.map});

  final _FarmMapScreenState host;
  final ProjectedFarmMap map;

  @override
  State<_FullScreenMap> createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<_FullScreenMap> {
  @override
  Widget build(BuildContext context) {
    final host = widget.host;
    final highlights = host._highlights(widget.map);
    // The root full-screen navigator may sit above FarmHierarchyScope in the
    // production shell. Reuse the host screen's verified hierarchy instead
    // of relying on inherited data from this route.
    final hierarchy = FarmHierarchyScope.maybeOf(host.context)?.hierarchy;
    final plantingPits = host._projectPlantingPits(widget.map, hierarchy);
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: _MapPanel(
                map: widget.map,
                transformation: host._transformation,
                section: host._section,
                selectedTree: host._selectedTree,
                plantingPits: plantingPits,
                selectedPlantingPit: host._selectedPlantingPit,
                selectedValveId: host._selectedValve?.assetId,
                highlightZones: highlights.zones,
                highlightSubmains: highlights.submains,
                highlightLine: highlights.line,
                showTrees: host._trees,
                showPlantingPits: host._plantingPits,
                showIrrigation: host._irrigation,
                showUtilities: host._utilities,
                showValves: host._valves,
                showFlushValves: host._flushValves,
                showWaterSupply: host._waterSupply,
                autoFit: false,
                onTapTree: (tree) {
                  host._selectTree(tree, presentationContext: context);
                  setState(() {});
                },
                onTapPlantingPit: (pit) {
                  host._selectPlantingPit(
                    pit,
                    presentationContext: context,
                  );
                  setState(() {});
                },
                onTapValve: (valve) {
                  host._selectValve(
                    widget.map,
                    valve,
                    presentationContext: context,
                  );
                  setState(() {});
                },
                onTapMiss: () {
                  if (host._selectedValve != null) {
                    // The host rebuilds itself; this route re-reads its
                    // fields on the local setState below.
                    // ignore: invalid_use_of_protected_member
                    host.setState(() => host._selectedValve = null);
                    setState(() {});
                  }
                },
              ),
            ),
            PositionedDirectional(
              top: 10,
              end: 10,
              child: Material(
                color: AppColors.card.withOpacity(0.92),
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  key: const Key('map-exit-full-screen'),
                  tooltip: context.l10n.mapExitFullScreen,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.fullscreen_exit),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.map,
    required this.section,
    required this.plantingPitCount,
    required this.trees,
    required this.plantingPits,
    required this.irrigation,
    required this.utilities,
    required this.valves,
    required this.flushValves,
    required this.waterSupply,
    required this.onReset,
    required this.onFullScreen,
    required this.onTrees,
    required this.onPlantingPits,
    required this.onIrrigation,
    required this.onUtilities,
    required this.onValves,
    required this.onFlushValves,
    required this.onWaterSupply,
  });
  final ProjectedFarmMap map;
  final String? section;
  final int plantingPitCount;
  final bool trees;
  final bool plantingPits;
  final bool irrigation;
  final bool utilities;
  final bool valves;
  final bool flushValves;
  final bool waterSupply;
  final VoidCallback onReset;
  final VoidCallback onFullScreen;
  final ValueChanged<bool> onTrees;
  final ValueChanged<bool> onPlantingPits;
  final ValueChanged<bool> onIrrigation;
  final ValueChanged<bool> onUtilities;
  final ValueChanged<bool> onValves;
  final ValueChanged<bool> onFlushValves;
  final ValueChanged<bool> onWaterSupply;

  @override
  Widget build(BuildContext context) {
    final selected = section == null
        ? null
        : map.data.sections.firstWhere((item) => item.id == section);
    final title = selected == null
        ? context.l10n.homeFarmOverview
        : <String>[
            context.l10n.mapSectionName(selected.id),
            selected.treeCount == 0
                ? context.l10n.mapSectionUnplanted
                : selected.treeCount.toString(),
            if (plantingPitCount > 0)
              context.l10n.mapSectionPitCount(plantingPitCount),
          ].join(' · ');
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Eyebrow(context.l10n.mapEyebrow),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
    final controls = _controls(context);
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 380
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 4),
                ...controls,
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: titleBlock),
                ...controls,
              ],
            ),
    );
  }

  List<Widget> _controls(BuildContext context) => <Widget>[
        _Control(
          icon: Icons.fullscreen,
          tooltip: context.l10n.mapFullScreen,
          onTap: onFullScreen,
        ),
        _Control(
          icon: Icons.center_focus_strong,
          tooltip: context.l10n.mapReset,
          onTap: onReset,
        ),
        PopupMenuButton<String>(
          tooltip: context.l10n.mapLayers,
          icon: const Icon(Icons.layers_outlined),
          itemBuilder: (_) => <PopupMenuEntry<String>>[
            CheckedPopupMenuItem(
              value: 'trees',
              checked: trees,
              child: Text(context.l10n.mapLayerTrees),
            ),
            CheckedPopupMenuItem(
              key: const Key('map-layer-planting-pits'),
              value: 'plantingPits',
              checked: plantingPits,
              child: Text(context.l10n.mapLayerPlantingPits),
            ),
            CheckedPopupMenuItem(
              value: 'irrigation',
              checked: irrigation,
              child: Text(context.l10n.mapLayerIrrigation),
            ),
            CheckedPopupMenuItem(
              value: 'utilities',
              checked: utilities,
              child: Text(context.l10n.mapLayerUtilities),
            ),
            CheckedPopupMenuItem(
              value: 'valves',
              checked: valves,
              child: Text(context.l10n.mapLayerValves),
            ),
            CheckedPopupMenuItem(
              value: 'flushValves',
              checked: flushValves,
              child: Text(context.l10n.mapLayerFlushValves),
            ),
            CheckedPopupMenuItem(
              value: 'waterSupply',
              checked: waterSupply,
              child: Text(context.l10n.mapLayerWaterSupply),
            ),
          ],
          onSelected: (value) {
            if (value == 'trees') onTrees(!trees);
            if (value == 'plantingPits') onPlantingPits(!plantingPits);
            if (value == 'irrigation') onIrrigation(!irrigation);
            if (value == 'utilities') onUtilities(!utilities);
            if (value == 'valves') onValves(!valves);
            if (value == 'flushValves') onFlushValves(!flushValves);
            if (value == 'waterSupply') onWaterSupply(!waterSupply);
          },
        ),
      ];
}

class _Control extends StatelessWidget {
  const _Control({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon),
      );
}

class _SectionActions extends StatelessWidget {
  const _SectionActions({
    required this.createTaskLabel,
    required this.addPitLabel,
    required this.onCreateTask,
    required this.onAddPit,
  });

  final String createTaskLabel;
  final String addPitLabel;
  final VoidCallback onCreateTask;
  final VoidCallback onAddPit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Row(
              children: <Widget>[
                Expanded(
                  child: Tooltip(
                    message: createTaskLabel,
                    child: OutlinedButton(
                      key: const Key('map-section-create-task'),
                      onPressed: onCreateTask,
                      child: _CompactActionLabel(
                        icon: Icons.assignment_add,
                        label: createTaskLabel,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Tooltip(
                    message: addPitLabel,
                    child: FilledButton(
                      key: const Key('map-section-add-pit'),
                      onPressed: onAddPit,
                      child: _CompactActionLabel(
                        icon: Icons.add_location_alt,
                        label: addPitLabel,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  key: const Key('map-section-create-task'),
                  onPressed: onCreateTask,
                  icon: const Icon(Icons.assignment_add, size: 18),
                  label: Text(createTaskLabel),
                ),
                FilledButton.icon(
                  key: const Key('map-section-add-pit'),
                  onPressed: onAddPit,
                  icon: const Icon(Icons.add_location_alt),
                  label: Text(addPitLabel),
                ),
              ],
            ),
          );
        },
      );
}

class _CompactActionLabel extends StatelessWidget {
  const _CompactActionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}

class _SectionFilter extends StatelessWidget {
  const _SectionFilter({
    required this.sections,
    required this.plantingPitCounts,
    required this.selected,
    required this.onSelected,
  });
  final List<FarmSectionGeometry> sections;
  final Map<String, int> plantingPitCounts;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          key: const Key('map-section-filter'),
          scrollDirection: Axis.horizontal,
          itemCount: sections.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, index) {
            final section = index == 0 ? null : sections[index - 1];
            final active = selected == section?.id;
            final pitCount =
                section == null ? 0 : plantingPitCounts[section.id] ?? 0;
            return ChoiceChip(
              key: Key('section-${section?.id ?? 'all'}'),
              selected: active,
              onSelected: (_) => onSelected(section?.id),
              label: section == null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.grid_view_outlined, size: 16),
                        const SizedBox(width: 5),
                        Text(context.l10n.mapAllSections),
                      ],
                    )
                  : _SectionChipLabel(
                      sectionName: context.l10n.mapSectionName(section.id),
                      treeCount: section.treeCount,
                      pitCount: pitCount,
                    ),
            );
          },
        ),
      );
}

class _SectionChipLabel extends StatelessWidget {
  const _SectionChipLabel({
    required this.sectionName,
    required this.treeCount,
    required this.pitCount,
  });

  final String sectionName;
  final int treeCount;
  final int pitCount;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.grid_view_outlined, size: 16),
          const SizedBox(width: 4),
          Text(sectionName),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 7),
            child: Text('/'),
          ),
          const Icon(Icons.park_outlined, size: 16),
          const SizedBox(width: 4),
          Text(treeCount.toString()),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 7),
            child: Text('/'),
          ),
          const Icon(Icons.location_on_outlined, size: 16),
          const SizedBox(width: 4),
          Text(pitCount.toString()),
        ],
      );
}

class _MapSummary extends StatelessWidget {
  const _MapSummary({
    required this.map,
    required this.selected,
    required this.selectedPlantingPit,
  });
  final ProjectedFarmMap map;
  final FarmTree? selected;
  final PlantingPit? selectedPlantingPit;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: selectedPlantingPit != null
            ? _PlantingPitContent(pit: selectedPlantingPit!)
            : selected == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.touch_app_outlined,
                        size: 40,
                        color: AppColors.green,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.mapSelectAnyTree,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n
                            .mapTreePointsAvailable(map.data.trees.length),
                      ),
                    ],
                  )
                : TreeDetailContent(
                    tree: TreeIdentity.fromMapTree(selected!),
                  ),
      );
}

class _PlantingPitCreateSheet extends StatefulWidget {
  const _PlantingPitCreateSheet({
    required this.repository,
    required this.farmId,
    required this.section,
    required this.onCreated,
  });

  final PlantingPitRepository repository;
  final String farmId;
  final FarmSection section;
  final VoidCallback onCreated;

  @override
  State<_PlantingPitCreateSheet> createState() =>
      _PlantingPitCreateSheetState();
}

class _PlantingPitCreateSheetState extends State<_PlantingPitCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _row = TextEditingController();
  final _number = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _plannedFor;
  String? _formError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _code.text = 'PIT-${widget.section.code}-';
  }

  @override
  void dispose() {
    _code.dispose();
    _row.dispose();
    _number.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _plannedFor ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null && mounted) {
      setState(() => _plannedFor = selected);
    }
  }

  String? _positiveInteger(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    return parsed == null || parsed <= 0
        ? context.l10n.inventoryInvalidNumber
        : null;
  }

  String? _coordinate(String? value, double min, double max) {
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < min || parsed > max
        ? context.l10n.plantingPitInvalidCoordinate
        : null;
  }

  Future<void> _save() async {
    setState(() => _formError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rowText = _row.text.trim();
    final numberText = _number.text.trim();
    if (rowText.isEmpty != numberText.isEmpty) {
      setState(() => _formError = context.l10n.plantingPitGridPairRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.create(
        PlantingPitDraft(
          farmId: widget.farmId,
          sectionId: widget.section.id,
          pitCode: _code.text,
          rowNumber: rowText.isEmpty ? null : int.parse(rowText),
          pitNumber: numberText.isEmpty ? null : int.parse(numberText),
          latitude: double.parse(_latitude.text.trim()),
          longitude: double.parse(_longitude.text.trim()),
          plannedFor: _plannedFor,
          notes: _notes.text,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreated();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = context.l10n.plantingPitCreateFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            0,
            14,
            14 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: WahatCard(
            key: const Key('planting-pit-create-sheet'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 650),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fieldWidth = constraints.maxWidth >= 600
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Eyebrow(context.l10n.plantingPitEyebrow),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.plantingPitCreateTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n
                                .plantingPitSection(widget.section.code),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const Key('planting-pit-code-field'),
                            controller: _code,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: context.l10n.plantingPitCodeField,
                            ),
                            validator: (value) => value?.trim().isEmpty ?? true
                                ? context.l10n.plantingPitRequiredField
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              SizedBox(
                                width: fieldWidth,
                                child: TextFormField(
                                  key: const Key('planting-pit-row-field'),
                                  controller: _row,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: context.l10n.plantingPitRowField,
                                  ),
                                  validator: _positiveInteger,
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: TextFormField(
                                  key: const Key('planting-pit-number-field'),
                                  controller: _number,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText:
                                        context.l10n.plantingPitNumberField,
                                  ),
                                  validator: _positiveInteger,
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: TextFormField(
                                  key: const Key('planting-pit-latitude-field'),
                                  controller: _latitude,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                                  decoration: InputDecoration(
                                    labelText:
                                        context.l10n.plantingPitLatitudeField,
                                  ),
                                  validator: (value) =>
                                      _coordinate(value, -90, 90),
                                ),
                              ),
                              SizedBox(
                                width: fieldWidth,
                                child: TextFormField(
                                  key:
                                      const Key('planting-pit-longitude-field'),
                                  controller: _longitude,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                                  decoration: InputDecoration(
                                    labelText:
                                        context.l10n.plantingPitLongitudeField,
                                  ),
                                  validator: (value) =>
                                      _coordinate(value, -180, 180),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key('planting-pit-date-field'),
                            onPressed: _saving ? null : _pickDate,
                            icon: const Icon(Icons.event_outlined),
                            label: Text(
                              _plannedFor == null
                                  ? context.l10n.plantingPitPlannedDateField
                                  : MaterialLocalizations.of(context)
                                      .formatMediumDate(_plannedFor!),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notes,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: context.l10n.plantingPitNotesField,
                            ),
                          ),
                          if (_formError != null) ...<Widget>[
                            const SizedBox(height: 10),
                            Text(
                              _formError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            key: const Key('planting-pit-save'),
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_location_alt),
                            label: Text(
                              _saving
                                  ? context.l10n.plantingPitSaving
                                  : context.l10n.plantingPitSave,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _PlantingPitSheet extends StatefulWidget {
  const _PlantingPitSheet({
    required this.pit,
    required this.sectionCode,
    required this.onChanged,
    this.onAdvance,
    this.onCancel,
  });

  final PlantingPit pit;
  final String sectionCode;
  final Future<void> Function()? onAdvance;
  final Future<void> Function()? onCancel;
  final VoidCallback onChanged;

  @override
  State<_PlantingPitSheet> createState() => _PlantingPitSheetState();
}

class _PlantingPitSheetState extends State<_PlantingPitSheet> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onChanged();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.plantingPitUpdateFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: WahatCard(
            key: const Key('planting-pit-sheet'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _PlantingPitContent(
                  pit: widget.pit,
                  sectionCode: widget.sectionCode,
                ),
                if (widget.onAdvance != null || widget.onCancel != null) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      if (widget.onAdvance != null)
                        FilledButton.icon(
                          key: const Key('planting-pit-advance'),
                          onPressed:
                              _busy ? null : () => _run(widget.onAdvance!),
                          icon: _busy
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward),
                          label: Text(
                            _busy
                                ? context.l10n.plantingPitUpdating
                                : context.l10n.plantingPitAdvanceTo(
                                    _plantingPitStatusLabel(
                                      context,
                                      widget.pit.status.next!,
                                    ),
                                  ),
                          ),
                        ),
                      if (widget.onCancel != null)
                        OutlinedButton.icon(
                          key: const Key('planting-pit-cancel'),
                          onPressed:
                              _busy ? null : () => _run(widget.onCancel!),
                          icon: const Icon(Icons.block_outlined),
                          label: Text(context.l10n.plantingPitCancel),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}

class _PlantingPitContent extends StatelessWidget {
  const _PlantingPitContent({required this.pit, this.sectionCode});

  final PlantingPit pit;
  final String? sectionCode;

  @override
  Widget build(BuildContext context) {
    final plannedFor = pit.plannedFor;
    final latitude = pit.latitude;
    final longitude = pit.longitude;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Eyebrow(context.l10n.plantingPitEyebrow),
        const SizedBox(height: 4),
        Text(
          pit.pitCode,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            Chip(label: Text(_plantingPitStatusLabel(context, pit.status))),
            if (sectionCode != null)
              Chip(
                label: Text(context.l10n.plantingPitSection(sectionCode!)),
              ),
          ],
        ),
        if (pit.rowNumber != null || pit.pitNumber != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            context.l10n.plantingPitPosition(
              pit.rowNumber?.toString() ?? '—',
              pit.pitNumber?.toString() ?? '—',
            ),
          ),
        ],
        if (latitude != null && longitude != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            context.l10n.plantingPitCoordinates(
              latitude.toStringAsFixed(6),
              longitude.toStringAsFixed(6),
            ),
            textDirection: TextDirection.ltr,
          ),
        ],
        if (plannedFor != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            context.l10n.plantingPitPlannedFor(
              MaterialLocalizations.of(context).formatMediumDate(plannedFor),
            ),
          ),
        ],
        if (pit.notes?.isNotEmpty ?? false) ...<Widget>[
          const SizedBox(height: 10),
          Text(pit.notes!),
        ],
      ],
    );
  }
}

String _plantingPitStatusLabel(
  BuildContext context,
  PlantingPitStatus status,
) =>
    switch (status) {
      PlantingPitStatus.planned => context.l10n.plantingPitStatusPlanned,
      PlantingPitStatus.marked => context.l10n.plantingPitStatusMarked,
      PlantingPitStatus.dug => context.l10n.plantingPitStatusDug,
      PlantingPitStatus.prepared => context.l10n.plantingPitStatusPrepared,
      PlantingPitStatus.completed => context.l10n.plantingPitStatusCompleted,
      PlantingPitStatus.cancelled => context.l10n.plantingPitStatusCancelled,
    };

class _MapError extends StatelessWidget {
  const _MapError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.mapGeometryFailed(error.toString()),
            textAlign: TextAlign.center,
          ),
        ),
      );
}
