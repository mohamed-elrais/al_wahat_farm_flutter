import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/tree_reconciliation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/farm_hierarchy_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FarmMapData geometry;
  late FarmHierarchy live;

  setUpAll(() async {
    geometry = await const MapAssetRepository().load();
    live = (await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId))
        .hierarchy;
  });

  test('composes the complete live hierarchy over static geometry', () {
    final result = const FarmMapComposer().compose(geometry, live);

    expect(geometry.trees, isEmpty);
    expect(result.data.trees, hasLength(1539));
    expect(result.data.sections, hasLength(12));
    expect(result.data.sections.firstWhere((item) => item.id == 'C').treeCount,
        185);
    expect(result.data.sections.firstWhere((item) => item.id == 'F').treeCount,
        351);
    expect(result.data.sections.firstWhere((item) => item.id == 'G').treeCount,
        72);
    expect(result.resolvedMapZones, 122);
    expect(result.discrepancies, isEmpty);
  });

  test('uses live trees as the complete authority', () {
    final removed = live.trees.first;
    final hierarchy = _copyHierarchy(
      live,
      trees: live.trees.skip(1).toList(growable: false),
    );

    final result = const FarmMapComposer().compose(geometry, hierarchy);

    expect(result.data.trees, hasLength(1538));
    expect(result.data.trees.any((tree) => tree.id == removed.id), isFalse);
  });

  test('binds map features and trees to the current live zone UUID', () {
    final originalZone = live.zones.firstWhere(
      (zone) => geometry.valves.any((valve) => valve.zoneId == zone.code),
    );
    const replacementId = 'replacement-live-zone-uuid';
    final replacementZone = IrrigationZone(
      id: replacementId,
      sectionId: originalZone.sectionId,
      code: originalZone.code,
      name: originalZone.name,
      valveCode: originalZone.valveCode,
      notes: originalZone.notes,
      isActive: originalZone.isActive,
      createdAt: originalZone.createdAt,
      updatedAt: originalZone.updatedAt,
    );
    final trees = <FarmTreeRecord>[
      for (final tree in live.trees)
        tree.irrigationZoneId == originalZone.id
            ? _copyTree(tree, irrigationZoneId: replacementId)
            : tree,
    ];
    final hierarchy = FarmHierarchy(
      farmId: live.farmId,
      sections: live.sections,
      zones: <IrrigationZone>[
        replacementZone,
        ...live.zones.where((zone) => zone.id != originalZone.id),
      ],
      trees: trees,
      plantingPits: live.plantingPits,
    );

    final result = const FarmMapComposer().compose(geometry, hierarchy);
    final valve = result.data.valves.firstWhere(
      (item) => item.zoneId == originalZone.code,
    );

    expect(valve.zoneUuid, replacementId);
    expect(
      result.data.trees.where((tree) => tree.zoneId == replacementId).length,
      trees.where((tree) => tree.irrigationZoneId == replacementId).length,
    );
  });

  test('skips and reports a live tree without coordinates', () {
    final original = live.trees.first;
    final hierarchy = _copyHierarchy(
      live,
      trees: <FarmTreeRecord>[
        _copyTree(original, clearCoordinates: true),
        ...live.trees.skip(1),
      ],
    );

    final result = const FarmMapComposer().compose(geometry, hierarchy);

    expect(result.data.trees, hasLength(1538));
    expect(
      result.discrepancyCounts[MapDataDiscrepancyType.missingTreeCoordinates],
      1,
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
      plantingPits: source.plantingPits,
    );

FarmTreeRecord _copyTree(
  FarmTreeRecord source, {
  String? irrigationZoneId,
  bool clearCoordinates = false,
}) =>
    FarmTreeRecord(
      id: source.id,
      farmId: source.farmId,
      sectionId: source.sectionId,
      irrigationZoneId: irrigationZoneId ?? source.irrigationZoneId,
      treeCode: source.treeCode,
      rowNumber: source.rowNumber,
      treeNumber: source.treeNumber,
      plantedOn: source.plantedOn,
      latitude: clearCoordinates ? null : source.latitude,
      longitude: clearCoordinates ? null : source.longitude,
      healthStatus: source.healthStatus,
      type: source.type,
      notes: source.notes,
      isActive: source.isActive,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
    );
