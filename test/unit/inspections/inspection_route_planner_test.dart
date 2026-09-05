import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InspectionRoutePlanner', () {
    const planner = InspectionRoutePlanner();

    test('starts at 001, splits duplicated row blocks, and pairs both sides',
        () {
      final route = planner.plan(
        section: _section,
        trees: <FarmTreeRecord>[
          _tree('a1', 'TREE-A-001', 1, 1, 29, 30),
          _tree('a2', 'TREE-A-002', 1, 2, 29, 30.00001),
          _tree('a3', 'TREE-A-003', 2, 1, 29.00001, 30),
          _tree('a4', 'TREE-A-004', 2, 2, 29.00001, 30.00001),
          // Row numbers restart in a distant physical block.
          _tree('a5', 'TREE-A-005', 1, 1, 29, 30.001),
          _tree('a6', 'TREE-A-006', 1, 2, 29, 30.00101),
          _tree('a7', 'TREE-A-007', 2, 1, 29.00001, 30.001),
          _tree('a8', 'TREE-A-008', 2, 2, 29.00001, 30.00101),
        ],
      );

      expect(route.items.first.treeCode, 'TREE-A-001');
      expect(route.routeVersion, 2);
      expect(route.treeCount, 8);
      expect(route.stationCount, 4);
      expect(route.items.map((item) => item.treeId).toSet(), hasLength(8));
      expect(
        route.station(1).map((item) => item.side).toSet(),
        <InspectionRouteSide>{
          InspectionRouteSide.left,
          InspectionRouteSide.right,
        },
      );
      expect(route.items.map((item) => item.corridorIndex).toSet(), {1, 2});
      expect(route.toRpcRoute().first['sequence_index'], 1);
      expect(
        route.items
            .where((item) => item.corridorIndex == 1)
            .map((item) => item.treeCode),
        <String>['TREE-A-001', 'TREE-A-003', 'TREE-A-004', 'TREE-A-002'],
      );
      expect(
        route.items
            .where((item) => item.corridorIndex == 2)
            .map((item) => item.treeCode),
        <String>['TREE-A-006', 'TREE-A-008', 'TREE-A-005', 'TREE-A-007'],
      );
    });

    test('serializes and restores immutable route snapshot', () {
      final route = planner.plan(
        section: _section,
        trees: <FarmTreeRecord>[
          _tree('a1', 'TREE-A-001', 1, 1, 29, 30),
          _tree('a2', 'TREE-A-002', 1, 2, 29, 30.00001),
          _tree('a3', 'TREE-A-003', 2, 1, 29.00001, 30),
          _tree('a4', 'TREE-A-004', 2, 2, 29.00001, 30.00001),
        ],
      );

      final restored = InspectionRoute.fromJson(route.toJson());

      expect(restored.startingTreeId, 'a1');
      expect(restored.items.map((item) => item.toJson()),
          route.items.map((item) => item.toJson()));
    });

    test('splits repeated row numbers across overlapping physical blocks', () {
      final route = planner.plan(
        section: _section,
        trees: <FarmTreeRecord>[
          _tree('a1', 'TREE-A-001', 1, 1, 29, 30),
          _tree('a2', 'TREE-A-002', 1, 2, 29, 30.00001),
          _tree('a3', 'TREE-A-003', 2, 1, 29.00001, 30),
          _tree('a4', 'TREE-A-004', 2, 2, 29.00001, 30.00001),
          // The same row numbers restart below the first physical block while
          // occupying the same along-row coordinate range.
          _tree('a5', 'TREE-A-005', 1, 1, 28.9999, 30),
          _tree('a6', 'TREE-A-006', 1, 2, 28.9999, 30.00001),
          _tree('a7', 'TREE-A-007', 2, 1, 28.99991, 30),
          _tree('a8', 'TREE-A-008', 2, 2, 28.99991, 30.00001),
        ],
      );

      expect(route.stationCount, 4);
      expect(route.items.map((item) => item.corridorIndex).toSet(), {1, 2});
      expect(
        route.items
            .where((item) => item.corridorIndex == 1)
            .map((item) => item.treeCode)
            .toSet(),
        {'TREE-A-001', 'TREE-A-002', 'TREE-A-003', 'TREE-A-004'},
      );
      expect(
        route.items
            .where((item) => item.corridorIndex == 2)
            .map((item) => item.treeCode)
            .toSet(),
        {'TREE-A-005', 'TREE-A-006', 'TREE-A-007', 'TREE-A-008'},
      );
    });

    test('uses a single side for an unmatched outside row', () {
      final route = planner.plan(
        section: _section,
        trees: <FarmTreeRecord>[
          _tree('a1', 'TREE-A-001', 1, 1, 29, 30),
          _tree('a2', 'TREE-A-002', 1, 2, 29, 30.00001),
          _tree('a3', 'TREE-A-003', 2, 1, 29.00001, 30),
          _tree('a4', 'TREE-A-004', 2, 2, 29.00001, 30.00001),
          _tree('a5', 'TREE-A-005', 3, 1, 29.00002, 30),
          _tree('a6', 'TREE-A-006', 3, 2, 29.00002, 30.00001),
        ],
      );

      expect(
        route.items
            .where((item) => item.corridorIndex == 2)
            .every((item) => item.side == InspectionRouteSide.single),
        isTrue,
      );
    });

    test('starts at the lowest existing number when 001 is not planted', () {
      final route = planner.plan(
        section: _section,
        trees: <FarmTreeRecord>[
          _tree('g37', 'TREE-G-037', 1, 37, 29, 30),
          _tree('g38', 'TREE-G-038', 1, 38, 29, 30.00001),
          _tree('g39', 'TREE-G-039', 2, 39, 29.00001, 30),
          _tree('g40', 'TREE-G-040', 2, 40, 29.00001, 30.00001),
        ],
      );

      expect(route.items.first.treeCode, 'TREE-G-037');
    });

    test('rejects missing coordinates and ambiguous start trees', () {
      expect(
        () => planner.plan(
          section: _section,
          trees: <FarmTreeRecord>[
            _tree('a1', 'TREE-A-001', 1, 1, null, 30),
            _tree('a2', 'TREE-A-002', 1, 2, 29, 30.00001),
          ],
        ),
        throwsA(isA<InspectionRouteException>()),
      );
      expect(
        () => planner.plan(
          section: _section,
          trees: <FarmTreeRecord>[
            _tree('a1', 'TREE-A-001', 1, 1, 29, 30),
            _tree('a2', 'BLOCK-001', 1, 2, 29, 30.00001),
          ],
        ),
        throwsA(isA<InspectionRouteException>()),
      );
    });
  });
}

final FarmSection _section = FarmSection(
  id: 'section-a',
  farmId: 'farm',
  code: 'A',
  name: 'Section A',
  sortOrder: 1,
  isActive: true,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

FarmTreeRecord _tree(
  String id,
  String code,
  int row,
  int number,
  double? latitude,
  double? longitude,
) =>
    FarmTreeRecord(
      id: id,
      farmId: 'farm',
      sectionId: 'section-a',
      treeCode: code,
      rowNumber: row,
      treeNumber: number,
      latitude: latitude,
      longitude: longitude,
      healthStatus: TreeHealthStatus.healthy,
      type: 'Medjool',
      isActive: true,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
