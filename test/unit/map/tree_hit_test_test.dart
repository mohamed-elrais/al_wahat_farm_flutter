import 'dart:ui';

import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/map_projection.dart';
import 'package:flutter_test/flutter_test.dart';

FarmTree tree(String id, String section) => FarmTree(
      id: id,
      code: id,
      section: section,
      zoneId: 'zone',
      row: 1,
      number: 1,
      latitude: 0,
      longitude: 0,
      health: 'healthy',
      type: 'medjool',
      color: const Color(0xFF285C36),
    );

void main() {
  test('nearest eligible tree wins within tolerance', () {
    final index = ProjectedTreeIndex(<ProjectedTree>[
      ProjectedTree(
        tree: tree('TREE-A-001', 'A'),
        point: const Offset(100, 100),
      ),
      ProjectedTree(
        tree: tree('TREE-A-002', 'A'),
        point: const Offset(120, 100),
      ),
    ]);
    expect(
      index.nearest(const Offset(116, 100), tolerance: 44)?.tree.id,
      'TREE-A-002',
    );
    expect(index.nearest(const Offset(200, 200), tolerance: 20), isNull);
  });

  test('section filter excludes closer unrelated points', () {
    final index = ProjectedTreeIndex(<ProjectedTree>[
      ProjectedTree(
        tree: tree('TREE-A-001', 'A'),
        point: const Offset(101, 100),
      ),
      ProjectedTree(
        tree: tree('TREE-B-001', 'B'),
        point: const Offset(100, 100),
      ),
    ]);
    expect(
      index
          .nearest(const Offset(100, 100), tolerance: 44, section: 'A')
          ?.tree
          .id,
      'TREE-A-001',
    );
  });
}
