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
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:al_wahat_farm_flutter/features/trees/presentation/tree_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FarmMapScreen extends StatefulWidget {
  const FarmMapScreen({this.mapFuture, this.focus, super.key});

  final Future<ProjectedFarmMap>? mapFuture;

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
  NetworkValve? _selectedValve;
  bool _trees = true;
  bool _irrigation = true;
  bool _utilities = true;
  bool _valves = true;
  bool _flushValves = false;
  bool _waterSupply = false;
  ProjectedFarmMap? _lastAssetMap;
  FarmHierarchy? _lastLiveHierarchy;
  ProjectedFarmMap? _lastReconciledMap;
  TreeReconciliationResult? _reconciliation;
  String? _pendingFocus;

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
  void dispose() {
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
            final manager = OperationalContextScope.maybeOf(context)
                    ?.selectedMembership
                    .role
                    .canManageTasks ??
                false;
            final showDataWarning =
                manager && (_reconciliation?.hasDiscrepancies ?? false);
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final focus = _pendingFocus;
                if (focus != null) {
                  _pendingFocus = null;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _applyFocus(map, focus, constraints.biggest);
                  });
                }
                final wide = constraints.maxWidth >= AppBreakpoints.tablet;
                final selectedValve = _selectedValve;
                final highlightZones = selectedValve == null
                    ? null
                    : _zonesFor(map, selectedValve);
                final isolationSelected =
                    selectedValve != null && !selectedValve.isZoneControl;
                final highlightLine = !isolationSelected
                    ? null
                    : map.valves
                        .firstWhere(
                          (projected) =>
                              projected.valve.assetId == selectedValve.assetId,
                        )
                        .downstreamPoints;
                final submains = selectedValve?.downstreamSubmains;
                final highlightSubmains =
                    isolationSelected && (submains?.isNotEmpty ?? false)
                        ? submains!.toSet()
                        : null;
                final canvas = _MapPanel(
                  map: map,
                  transformation: _transformation,
                  section: _section,
                  selectedTree: _selectedTree,
                  selectedValveId: selectedValve?.assetId,
                  highlightZones: highlightZones,
                  highlightSubmains: highlightSubmains,
                  highlightLine: highlightLine,
                  showTrees: _trees,
                  showIrrigation: _irrigation,
                  showUtilities: _utilities,
                  showValves: _valves,
                  showFlushValves: _flushValves,
                  showWaterSupply: _waterSupply,
                  onTapTree: (tree) => _selectTree(tree),
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
                        trees: _trees,
                        irrigation: _irrigation,
                        utilities: _utilities,
                        valves: _valves,
                        flushValves: _flushValves,
                        waterSupply: _waterSupply,
                        onReset: () => _fit(map, null, constraints.biggest),
                        onZoom: _zoom,
                        onTrees: (value) => setState(() => _trees = value),
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
                        selected: _section,
                        onSelected: (section) {
                          setState(() {
                            _section = section;
                            _selectedTree = null;
                          });
                          _fit(map, section, constraints.biggest);
                        },
                      ),
                      if (manager && _liveSectionFor(_section) != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: OutlinedButton.icon(
                            key: const Key('map-section-create-task'),
                            onPressed: () => context.go(
                              '/tasks/create?sectionId='
                              '${_liveSectionFor(_section)!.id}',
                            ),
                            icon: const Icon(Icons.assignment_add, size: 18),
                            label: Text(
                              context.l10n.mapCreateTaskForSection(_section!),
                            ),
                          ),
                        ),
                      ],
                      if (showDataWarning) ...<Widget>[
                        const SizedBox(height: 8),
                        _DiscrepancyBanner(result: _reconciliation!),
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

  ProjectedFarmMap _effectiveMap(
    ProjectedFarmMap assetMap,
    FarmHierarchy? liveHierarchy,
  ) {
    if (liveHierarchy == null) {
      _reconciliation = null;
      return assetMap;
    }
    if (identical(assetMap, _lastAssetMap) &&
        identical(liveHierarchy, _lastLiveHierarchy) &&
        _lastReconciledMap != null) {
      return _lastReconciledMap!;
    }

    final result = const TreeReconciler().reconcile(
      assetMap.data,
      liveHierarchy,
    );
    final reconciledData = FarmMapData(
      generatedFrom: assetMap.data.generatedFrom,
      bounds: assetMap.data.bounds,
      sections: assetMap.data.sections,
      trees: result.trees,
      layout: assetMap.data.layout,
      utilities: assetMap.data.utilities,
      waterLines: assetMap.data.waterLines,
      branchLines: assetMap.data.branchLines,
      valves: assetMap.data.valves,
      flushValves: assetMap.data.flushValves,
      risers: assetMap.data.risers,
      waterSupply: assetMap.data.waterSupply,
    );
    final reconciledMap = ProjectedFarmMap(reconciledData);
    _lastAssetMap = assetMap;
    _lastLiveHierarchy = liveHierarchy;
    _lastReconciledMap = reconciledMap;
    _reconciliation = result;
    SafeLog.event(
      'farm_tree_reconciliation',
      data: <String, Object?>{
        'matched_by_id': result.matchedById,
        'matched_by_code': result.matchedByCode,
        'discrepancies': result.discrepancies.length,
      },
    );
    return reconciledMap;
  }

  void _selectTree(FarmTree tree) {
    setState(() {
      _selectedTree = tree;
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
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TreeDetailSheet(
        tree: identity,
        onAttachTask: isLive && canManageTasks
            ? () {
                Navigator.of(sheetContext).pop();
                context.go('/tasks/create?treeId=${tree.id}');
              }
            : null,
        onReportIssue: isLive
            ? () {
                Navigator.of(sheetContext).pop();
                context.push('/map/tree/${tree.id}/report-issue');
              }
            : null,
      ),
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

  void _selectValve(ProjectedFarmMap map, NetworkValve valve) {
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
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ZoneSheet(
        valve: valve,
        actualTrees: actualTrees,
        onCreateTask: valve.isZoneControl && zoneIsLive && canManageTasks
            ? () {
                Navigator.of(sheetContext).pop();
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

  void _zoom(double factor) {
    final matrix = _transformation.value.clone();
    final scale = matrix.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(0.3, 8.0) / scale;
    _transformation.value = matrix..scale(next);
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

  final TreeReconciliationResult result;

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
    required this.selectedValveId,
    required this.highlightZones,
    required this.highlightSubmains,
    required this.highlightLine,
    required this.showTrees,
    required this.showIrrigation,
    required this.showUtilities,
    required this.showValves,
    required this.showFlushValves,
    required this.showWaterSupply,
    required this.onTapTree,
    required this.onTapValve,
    required this.onTapMiss,
  });
  final ProjectedFarmMap map;
  final TransformationController transformation;
  final String? section;
  final FarmTree? selectedTree;
  final String? selectedValveId;
  final Set<String>? highlightZones;
  final Set<String>? highlightSubmains;
  final List<Offset>? highlightLine;
  final bool showTrees;
  final bool showIrrigation;
  final bool showUtilities;
  final bool showValves;
  final bool showFlushValves;
  final bool showWaterSupply;
  final ValueChanged<FarmTree> onTapTree;
  final ValueChanged<NetworkValve> onTapValve;
  final VoidCallback onTapMiss;

  @override
  State<_MapPanel> createState() => _MapPanelState();
}

class _MapPanelState extends State<_MapPanel> {
  bool _fitted = false;

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

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (!_fitted) {
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
                  final scale = widget.transformation.value.getMaxScaleOnAxis();
                  // Valves sit above trees, so they win the tap.
                  if (widget.showValves) {
                    final valve = _nearestValve(point, 30 / scale);
                    if (valve != null) {
                      widget.onTapValve(valve);
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
                // North-up geographic canvas uses absolute projected pixel
                // coordinates, so it must never be mirrored in RTL locales.
                // Only this map subtree is locked to LTR; the surrounding
                // chrome keeps the ambient (RTL in Arabic) direction.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: InteractiveViewer(
                    constrained: false,
                    minScale: 0.1,
                    maxScale: 8,
                    transformationController: widget.transformation,
                    boundaryMargin: const EdgeInsets.all(220),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: MapProjection.canvasSize,
                        painter: FarmMapPainter(
                          map: widget.map,
                          selectedSection: widget.section,
                          selectedTreeId: widget.selectedTree?.id,
                          showTrees: widget.showTrees,
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
          );
        },
      );
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.map,
    required this.section,
    required this.trees,
    required this.irrigation,
    required this.utilities,
    required this.valves,
    required this.flushValves,
    required this.waterSupply,
    required this.onReset,
    required this.onZoom,
    required this.onTrees,
    required this.onIrrigation,
    required this.onUtilities,
    required this.onValves,
    required this.onFlushValves,
    required this.onWaterSupply,
  });
  final ProjectedFarmMap map;
  final String? section;
  final bool trees;
  final bool irrigation;
  final bool utilities;
  final bool valves;
  final bool flushValves;
  final bool waterSupply;
  final VoidCallback onReset;
  final ValueChanged<double> onZoom;
  final ValueChanged<bool> onTrees;
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
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Eyebrow(context.l10n.mapEyebrow),
        Text(
          selected == null
              ? context.l10n.homeFarmOverview
              : '${context.l10n.mapSectionName(selected.id)} · ${selected.treeCount == 0 ? context.l10n.mapSectionUnplanted : selected.treeCount}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
    final controls = _controls(context);
    // Four 44dp controls leave too little of a narrow (display-zoomed)
    // canvas for the title, wrapping it line-per-word. Below 380dp the title
    // gets the full width and the controls move to their own row.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 380
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                titleBlock,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: controls,
                ),
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
          icon: Icons.add,
          tooltip: context.l10n.mapZoomIn,
          onTap: () => onZoom(1.25),
        ),
        _Control(
          icon: Icons.remove,
          tooltip: context.l10n.mapZoomOut,
          onTap: () => onZoom(0.8),
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

class _SectionFilter extends StatelessWidget {
  const _SectionFilter({
    required this.sections,
    required this.selected,
    required this.onSelected,
  });
  final List<FarmSectionGeometry> sections;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: sections.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, index) {
            final section = index == 0 ? null : sections[index - 1];
            final active = selected == section?.id;
            return ChoiceChip(
              key: Key('section-${section?.id ?? 'all'}'),
              selected: active,
              onSelected: (_) => onSelected(section?.id),
              label: Text(
                section == null
                    ? context.l10n.mapAllSections
                    : '${context.l10n.mapSectionName(section.id)}  ${section.treeCount == 0 ? context.l10n.mapSectionEmpty : section.treeCount}',
              ),
            );
          },
        ),
      );
}

class _MapSummary extends StatelessWidget {
  const _MapSummary({required this.map, required this.selected});
  final ProjectedFarmMap map;
  final FarmTree? selected;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: selected == null
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
                    context.l10n.mapTreePointsAvailable(map.data.trees.length),
                  ),
                ],
              )
            : TreeDetailContent(
                tree: TreeIdentity.fromMapTree(selected!),
              ),
      );
}

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
