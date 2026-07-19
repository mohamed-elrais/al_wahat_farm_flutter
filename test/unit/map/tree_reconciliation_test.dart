import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/tree_reconciliation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/farm_hierarchy_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FarmMapData asset;
  late FarmHierarchy live;

  setUpAll(() async {
    asset = await const MapAssetRepository().load();
    final source = CanonicalFarmHierarchyDataSource.load();
    live = (await DefaultFarmHierarchyRepository(
      source,
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId))
        .hierarchy;
  });

  test('matches the complete canonical fixture by UUID', () {
    final result = const TreeReconciler().reconcile(asset, live);

    expect(result.trees, hasLength(1567));
    expect(result.matchedById, 1567);
    expect(result.matchedByCode, 0);
    expect(result.discrepancies, isEmpty);
  });

  test('falls back to tree code and reports an ID mismatch', () {
    final original = live.trees.first;
    final changed = _copyTree(original, id: 'live-tree-id');
    final hierarchy = _copyHierarchy(
      live,
      trees: <FarmTreeRecord>[changed, ...live.trees.skip(1)],
    );

    final result = const TreeReconciler().reconcile(asset, hierarchy);

    expect(result.matchedById, 1566);
    expect(result.matchedByCode, 1);
    expect(result.trees.first.id, 'live-tree-id');
    expect(
      result.discrepancyCounts[TreeDiscrepancyType.idMismatch],
      1,
    );
  });

  test('keeps missing asset geometry and never fabricates unexpected rows', () {
    final original = live.trees.first;
    final unexpected = _copyTree(
      original,
      id: 'unexpected-id',
      treeCode: 'TREE-X-999',
    );
    final hierarchy = _copyHierarchy(
      live,
      trees: <FarmTreeRecord>[...live.trees.skip(1), unexpected],
    );

    final result = const TreeReconciler().reconcile(asset, hierarchy);

    expect(result.trees, hasLength(1567));
    expect(result.trees.first.id, asset.trees.first.id);
    expect(result.trees.where((tree) => tree.id == 'unexpected-id'), isEmpty);
    expect(
      result.discrepancyCounts[TreeDiscrepancyType.missingLiveTree],
      1,
    );
    expect(
      result.discrepancyCounts[TreeDiscrepancyType.unexpectedLiveTree],
      1,
    );
  });

  test('enriches display state and reports coordinate drift', () {
    final original = live.trees.first;
    final changed = _copyTree(
      original,
      latitude: original.latitude! + 0.00001,
      healthStatus: TreeHealthStatus.needsEngineerReview,
      type: 'olive',
    );
    final hierarchy = _copyHierarchy(
      live,
      trees: <FarmTreeRecord>[changed, ...live.trees.skip(1)],
    );

    final result = const TreeReconciler().reconcile(asset, hierarchy);

    expect(result.trees.first.health, 'needs_engineer_review');
    expect(result.trees.first.type, 'olive');
    expect(result.trees.first.latitude, changed.latitude);
    expect(
      result.discrepancyCounts[TreeDiscrepancyType.coordinateMismatch],
      1,
    );
  });

  test('6-decimal backend rounding is within tolerance (no false drift)', () {
    final original = live.trees.first;
    // Rounding an 8-decimal asset value to the backend's 6 decimals shifts it by
    // up to 5e-7 (~7 cm) — this must NOT be reported as coordinate drift.
    final rounded = _copyTree(
      original,
      latitude: original.latitude! + 0.0000005,
      longitude: original.longitude! - 0.0000005,
    );
    final hierarchy = _copyHierarchy(
      live,
      trees: <FarmTreeRecord>[rounded, ...live.trees.skip(1)],
    );

    final result = const TreeReconciler().reconcile(asset, hierarchy);

    expect(
      result.discrepancyCounts[TreeDiscrepancyType.coordinateMismatch],
      isNull,
    );
  });
}

FarmHierarchy _copyHierarchy(
  FarmHierarchy source, {
  required List<FarmTreeRecord> trees,
}) =>
    FarmHierarchy(
      farmId: source.farmId,
      sections: source.sections,
      zones: source.zones,
      trees: trees,
    );

FarmTreeRecord _copyTree(
  FarmTreeRecord source, {
  String? id,
  String? treeCode,
  double? latitude,
  double? longitude,
  TreeHealthStatus? healthStatus,
  String? type,
}) =>
    FarmTreeRecord(
      id: id ?? source.id,
      farmId: source.farmId,
      sectionId: source.sectionId,
      irrigationZoneId: source.irrigationZoneId,
      treeCode: treeCode ?? source.treeCode,
      rowNumber: source.rowNumber,
      treeNumber: source.treeNumber,
      plantedOn: source.plantedOn,
      latitude: latitude ?? source.latitude,
      longitude: longitude ?? source.longitude,
      healthStatus: healthStatus ?? source.healthStatus,
      type: type ?? source.type,
      notes: source.notes,
      isActive: source.isActive,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    );
