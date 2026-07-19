import 'dart:convert';
import 'dart:io';

import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonical map data', () {
    late FarmMapData data;

    setUpAll(() {
      final Object? decoded = jsonDecode(
        File('assets/data/al_wahat_map_data.json').readAsStringSync(),
      );
      data = FarmMapData.fromJson(decoded! as Map<String, Object?>);
    });

    test('preserves reference bounds and totals', () {
      expect(data.sections, hasLength(12));
      expect(data.sections.where((section) => section.planted), hasLength(6));
      expect(data.trees, hasLength(1567));
      expect(data.bounds.minLongitude, 28.747598);
      expect(data.bounds.maxLongitude, 28.7546);
      expect(data.bounds.minLatitude, 28.293348);
      expect(data.bounds.maxLatitude, 28.300016);
    });

    test('preserves exact per-section counts', () {
      expect(
        <String, int>{
          for (final section in data.sections) section.id: section.treeCount,
        },
        <String, int>{
          'A': 298,
          'B': 330,
          'C': 168,
          'D': 303,
          'E': 0,
          'F': 360,
          'G': 108,
          'L': 0,
          'M': 0,
          'N': 0,
          'O': 0,
          'Q': 0,
        },
      );
    });

    test('contains every immutable geometry layer', () {
      expect(data.layout, hasLength(7));
      expect(data.utilities, hasLength(12));
      expect(data.waterLines, hasLength(11));
    });

    test('records the asset-only irrigation-zone discrepancy', () {
      expect(data.trees.map((tree) => tree.zoneId).toSet(), hasLength(56));
    });

    test('contains every irrigation-network layer', () {
      expect(data.branchLines, hasLength(121));
      expect(data.valves, hasLength(133));
      expect(
        data.valves.where((valve) => valve.isZoneControl),
        hasLength(122),
      );
      expect(data.flushValves, hasLength(131));
      expect(data.risers, hasLength(66));
      expect(data.waterSupply.points, hasLength(7));
      expect(data.waterSupply.lines, hasLength(12));
    });

    test('zone control valves cover every tree zone by uuid', () {
      final valveZones = data.valves
          .map((valve) => valve.zoneUuid)
          .whereType<String>()
          .toSet();
      final treeZones = data.trees.map((tree) => tree.zoneId).toSet();
      expect(valveZones, hasLength(56));
      expect(treeZones.difference(valveZones), isEmpty);
      // Zone colors on valves match the trees they irrigate.
      final treeColorByZone = <String, Object?>{
        for (final tree in data.trees) tree.zoneId: tree.color,
      };
      for (final valve in data.valves) {
        final zone = valve.zoneUuid;
        if (zone == null) continue;
        expect(valve.color, treeColorByZone[zone],
            reason: 'zone color mismatch for ${valve.assetId}');
      }
    });
  });
}
