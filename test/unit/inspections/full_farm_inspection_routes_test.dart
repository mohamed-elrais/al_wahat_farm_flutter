import 'dart:math' as math;

import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route_planner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/farm_hierarchy_fixture.dart';

void main() {
  test('canonical planted sections produce complete walking routes', () async {
    final snapshot = await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId);
    final hierarchy = snapshot.hierarchy;
    const planner = InspectionRoutePlanner();
    final summaries = <String, String>{};

    for (final code in const <String>['A', 'B', 'C', 'D', 'F', 'G']) {
      final section = hierarchy.sectionByCode(code)!;
      final sectionTrees = hierarchy.trees
          .where((tree) => tree.sectionId == section.id && tree.isActive)
          .toList(growable: false);
      final route = planner.plan(section: section, trees: hierarchy.trees);

      expect(
        route.items.first.treeCode,
        code == 'G' ? 'TREE-G-037' : endsWith('-001'),
        reason: code,
      );
      expect(route.treeCount, sectionTrees.length, reason: code);
      expect(route.items.map((item) => item.treeId).toSet(),
          hasLength(sectionTrees.length),
          reason: code);
      expect(
        route.items.map((item) => item.sequenceIndex),
        orderedEquals(
            List<int>.generate(route.treeCount, (index) => index + 1)),
        reason: code,
      );
      for (var station = 1; station <= route.stationCount; station++) {
        final items = route.station(station);
        expect(items, isNotEmpty, reason: '$code station $station');
        expect(items.length, lessThanOrEqualTo(2),
            reason: '$code station $station');
        if (items.length == 2) {
          expect(
            items.map((item) => item.side).toSet(),
            <InspectionRouteSide>{
              InspectionRouteSide.left,
              InspectionRouteSide.right,
            },
            reason: '$code station $station',
          );
        }
      }
      summaries[code] =
          '${route.treeCount}/${route.stationCount}/${route.items.last.treeCode}';
    }

    expect(summaries, <String, String>{
      'A': '298/153/TREE-A-294',
      'B': '330/176/TREE-B-309',
      'C': '185/107/TREE-C-299',
      'D': '303/161/TREE-D-299',
      'F': '351/192/TREE-F-337',
      'G': '72/36/TREE-G-097',
    });
  });

  test('canonical empty section E cannot create a tree inspection', () async {
    final snapshot = await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId);
    final hierarchy = snapshot.hierarchy;
    final section = hierarchy.sectionByCode('E')!;

    expect(
      () => const InspectionRoutePlanner().plan(
        section: section,
        trees: hierarchy.trees,
      ),
      throwsA(
        isA<InspectionRouteException>().having(
          (error) => error.message,
          'message',
          'The section has no active trees to inspect.',
        ),
      ),
    );
  });

  test('section A corridor paths do not jump between repeated row blocks',
      () async {
    final snapshot = await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId);
    final hierarchy = snapshot.hierarchy;
    final section = hierarchy.sectionByCode('A')!;
    final route = const InspectionRoutePlanner().plan(
      section: section,
      trees: hierarchy.trees,
    );
    final corridors =
        route.items.map((item) => item.corridorIndex).toSet().toList()..sort();

    expect(
        corridors, orderedEquals(List<int>.generate(8, (index) => index + 1)));

    for (final corridor in corridors) {
      final stationIndexes = route.items
          .where((item) => item.corridorIndex == corridor)
          .map((item) => item.stationIndex)
          .toSet()
          .toList()
        ..sort();
      final centers = stationIndexes
          .map((station) => _stationCenter(route.station(station)))
          .toList(growable: false);
      expect(centers.length, greaterThanOrEqualTo(3));
      var walked = 0.0;
      for (var index = 1; index < centers.length; index++) {
        walked += _distance(centers[index - 1], centers[index]);
      }
      final direct = _distance(centers.first, centers.last);

      expect(
        walked / direct,
        lessThan(1.5),
        reason: 'Section A corridor $corridor must be one straight walk',
      );
    }
  });
}

({double latitude, double longitude}) _stationCenter(
  List<InspectionRouteItem> items,
) =>
    (
      latitude: items.map((item) => item.latitude!).reduce((a, b) => a + b) /
          items.length,
      longitude: items.map((item) => item.longitude!).reduce((a, b) => a + b) /
          items.length,
    );

double _distance(
  ({double latitude, double longitude}) first,
  ({double latitude, double longitude}) second,
) =>
    math.sqrt(
      math.pow(first.latitude - second.latitude, 2) +
          math.pow(first.longitude - second.longitude, 2),
    );
