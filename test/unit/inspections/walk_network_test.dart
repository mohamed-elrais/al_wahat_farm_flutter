import 'dart:convert';
import 'dart:io';

import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route_planner.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_walk.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/walk_network.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/farm_hierarchy_fixture.dart';

void main() {
  late FarmMapData map;
  late InspectionWalk walkA;

  setUpAll(() async {
    map = FarmMapData.fromJson(
      jsonDecode(File('assets/data/al_wahat_map_data.json').readAsStringSync())
          as Map<String, Object?>,
    );
    final snapshot = await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId);
    walkA = InspectionWalk(const InspectionRoutePlanner()
        .plan(
          section: snapshot.hierarchy.sectionByCode('A')!,
          trees: snapshot.hierarchy.trees,
        )
        .items);
  });

  test('section A gets its own branch lines, valves and flush valves', () {
    final network = WalkNetwork.forWalk(map, walkA)!;

    expect(network.branches, hasLength(12));
    expect(network.zoneValves, hasLength(12));
    expect(network.flushValves, hasLength(14));
    expect(network.mains, hasLength(1));
    expect(network.submains, hasLength(10));
    expect(network.isEmpty, isFalse);
    // Every mainline isolation valve kept is next to section A's trees.
    for (final valve in network.isolationValves) {
      final located = walkA.locate(
        valve.latitude,
        valve.longitude,
        current: 1,
      )!;
      expect(
          located.metersOutside, lessThanOrEqualTo(WalkNetwork.nearbyMeters));
    }
  });

  test('a walk outside every section has no network', () {
    final far = InspectionWalk(walkA.items.map(
      (item) => InspectionRouteItem(
        treeId: item.treeId,
        treeCode: item.treeCode,
        sequenceIndex: item.sequenceIndex,
        corridorIndex: item.corridorIndex,
        stationIndex: item.stationIndex,
        side: item.side,
        latitude: item.latitude! + 1,
        longitude: item.longitude,
      ),
    ));
    expect(WalkNetwork.forWalk(map, far), isNull);
  });
}
