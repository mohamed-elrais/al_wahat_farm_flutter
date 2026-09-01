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

    test('preserves reference bounds and static geometry contract', () {
      expect(data.sections, hasLength(12));
      expect(data.sections.where((section) => section.planted), isEmpty);
      expect(data.trees, isEmpty);
      expect(data.bounds.minLongitude, 28.747598);
      expect(data.bounds.maxLongitude, 28.7546);
      expect(data.bounds.minLatitude, 28.293348);
      expect(data.bounds.maxLatitude, 28.300016);
    });

    test('leaves mutable per-section tree counts for runtime composition', () {
      expect(
        <String, int>{
          for (final section in data.sections) section.id: section.treeCount,
        },
        <String, int>{
          'A': 0,
          'B': 0,
          'C': 0,
          'D': 0,
          'E': 0,
          'F': 0,
          'G': 0,
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
      // 12 surveyed utilities incl. the two gates, plus tanks 03/04 folded in
      // from the water-supply folder.
      expect(data.utilities, hasLength(14));
      expect(data.waterLines, hasLength(11));
    });

    test('utilities carry surveyed types and style colors', () {
      final byName = {for (final shape in data.utilities) shape.name: shape};
      expect(byName['Water Tank 01']!.type, 'water_tank');
      expect(byName['Water Tank 04']!.type, 'water_tank');
      expect(byName['Water Tank 01']!.fillColor, isNotNull);
      expect(byName['Mosque']!.type, 'building');
      expect(byName['Main Gate']!.type, 'gate');
      expect(byName['House Solar Array']!.type, 'solar_array');
    });

    test('does not bundle mutable Supabase UUIDs', () {
      expect(data.branchLines.map((line) => line.zoneUuid).whereType<String>(),
          isEmpty);
      expect(data.valves.map((valve) => valve.zoneUuid).whereType<String>(),
          isEmpty);
    });

    test('contains every irrigation-network layer', () {
      expect(data.branchLines, hasLength(120));
      expect(data.valves, hasLength(133));
      expect(
        data.valves.where((valve) => valve.isZoneControl),
        hasLength(122),
      );
      expect(data.flushValves, hasLength(131));
      expect(data.risers, hasLength(64));
      expect(data.waterSupply.points, hasLength(7));
      expect(data.waterSupply.lines, hasLength(12));
    });

    test('mainline isolation valve NN is the shutoff for submain NN', () {
      final isolation = data.valves
          .where((valve) => valve.assetId.contains('-IV-ML-'))
          .toList(growable: false);
      expect(isolation, hasLength(10));
      for (final valve in isolation) {
        final number = valve.assetId.split('-').last;
        expect(valve.downstreamSubmains, <String>[number],
            reason: '${valve.assetId} must feed submain $number');
        expect(valve.downstreamLine, isNotNull,
            reason: '${valve.assetId} lacks its submain geometry');
        expect(valve.downstreamLine!.length, greaterThanOrEqualTo(2));
      }
      // Spot-check the topology: valve 04 controls the SM04 geometry.
      expect(
        data.branchLines.where((line) => line.submain == '04'),
        isNotEmpty,
      );
      expect(
        data.flushValves.where((valve) => valve.submain == '04'),
        isNotEmpty,
      );
    });

    test('zone control valves carry stable codes for runtime UUID binding', () {
      final valveZones = data.valves
          .where((valve) => valve.isZoneControl)
          .map((valve) => valve.zoneId)
          .whereType<String>()
          .toSet();
      final branchZones = data.branchLines
          .map((line) => line.zoneId)
          .whereType<String>()
          .toSet();
      expect(valveZones, hasLength(122));
      expect(branchZones, hasLength(120));
      expect(branchZones.difference(valveZones), isEmpty);
      expect(
        data.valves
            .where((valve) => valve.isZoneControl)
            .where((valve) => valve.color != null),
        hasLength(120),
      );
    });
  });
}
