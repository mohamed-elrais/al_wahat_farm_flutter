import 'dart:ui';

import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';

enum MapDataDiscrepancyType {
  unknownSection,
  unknownZone,
  missingTreeCoordinates,
  missingTreeGridPosition,
  missingZoneStyle,
  unresolvedMapZone,
}

class MapDataDiscrepancy {
  const MapDataDiscrepancy({
    required this.type,
    required this.entityCode,
  });

  final MapDataDiscrepancyType type;
  final String entityCode;

  Map<String, Object?> toLogFields() => <String, Object?>{
        'type': type.name,
        'entity_code': entityCode,
      };
}

class FarmMapCompositionResult {
  FarmMapCompositionResult({
    required this.data,
    required List<MapDataDiscrepancy> discrepancies,
    required this.resolvedMapZones,
  }) : discrepancies = List<MapDataDiscrepancy>.unmodifiable(discrepancies);

  final FarmMapData data;
  final List<MapDataDiscrepancy> discrepancies;
  final int resolvedMapZones;

  bool get hasDiscrepancies => discrepancies.isNotEmpty;

  Map<MapDataDiscrepancyType, int> get discrepancyCounts {
    final counts = <MapDataDiscrepancyType, int>{};
    for (final discrepancy in discrepancies) {
      counts.update(discrepancy.type, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map<MapDataDiscrepancyType, int>.unmodifiable(counts);
  }
}

/// Combines immutable KMZ geometry with mutable Supabase/cache hierarchy data.
///
/// Stable irrigation-zone codes join both sources. Supabase UUIDs never need
/// to be embedded in the generated asset, and live trees are never discarded
/// merely because an older static snapshot did not contain them.
class FarmMapComposer {
  const FarmMapComposer({
    this.fallbackTreeColor = const Color(0xFF2E7D32),
  });

  final Color fallbackTreeColor;

  FarmMapCompositionResult compose(
    FarmMapData geometry,
    FarmHierarchy hierarchy,
  ) {
    final discrepancies = <MapDataDiscrepancy>[];
    final geometrySections = <String, FarmSectionGeometry>{
      for (final section in geometry.sections) section.id: section,
    };
    final liveSectionsById = <String, FarmSection>{
      for (final section in hierarchy.sections) section.id: section,
    };
    final liveSectionsByCode = <String, FarmSection>{
      for (final section in hierarchy.sections) section.code: section,
    };
    final zonesById = <String, IrrigationZone>{
      for (final zone in hierarchy.zones) zone.id: zone,
    };
    final zonesByCode = <String, IrrigationZone>{
      for (final zone in hierarchy.zones) zone.code: zone,
    };
    final colorsByZoneCode = _zoneColors(geometry);

    final trees = <FarmTree>[];
    final treeCounts = <String, int>{};
    for (final record in hierarchy.trees) {
      final section = liveSectionsById[record.sectionId];
      if (section == null || !geometrySections.containsKey(section.code)) {
        discrepancies.add(
          MapDataDiscrepancy(
            type: MapDataDiscrepancyType.unknownSection,
            entityCode: record.treeCode,
          ),
        );
        continue;
      }
      final zoneId = record.irrigationZoneId;
      final zone = zoneId == null ? null : zonesById[zoneId];
      if (zone == null) {
        discrepancies.add(
          MapDataDiscrepancy(
            type: MapDataDiscrepancyType.unknownZone,
            entityCode: record.treeCode,
          ),
        );
        continue;
      }
      final latitude = record.latitude;
      final longitude = record.longitude;
      if (latitude == null || longitude == null) {
        discrepancies.add(
          MapDataDiscrepancy(
            type: MapDataDiscrepancyType.missingTreeCoordinates,
            entityCode: record.treeCode,
          ),
        );
        continue;
      }
      final row = record.rowNumber;
      final number = record.treeNumber;
      if (row == null || number == null) {
        discrepancies.add(
          MapDataDiscrepancy(
            type: MapDataDiscrepancyType.missingTreeGridPosition,
            entityCode: record.treeCode,
          ),
        );
        continue;
      }
      final color = colorsByZoneCode[zone.code];
      if (color == null) {
        discrepancies.add(
          MapDataDiscrepancy(
            type: MapDataDiscrepancyType.missingZoneStyle,
            entityCode: record.treeCode,
          ),
        );
      }
      trees.add(
        FarmTree(
          id: record.id,
          code: record.treeCode,
          section: section.code,
          zoneId: zone.id,
          row: row,
          number: number,
          latitude: latitude,
          longitude: longitude,
          health: record.healthStatus.wireValue,
          type: record.type,
          color: color ?? fallbackTreeColor,
        ),
      );
      treeCounts.update(section.code, (count) => count + 1, ifAbsent: () => 1);
    }
    trees.sort((left, right) => left.code.compareTo(right.code));

    final sections = <FarmSectionGeometry>[
      for (final section in geometry.sections)
        FarmSectionGeometry(
          id: section.id,
          name: liveSectionsByCode[section.id]?.name ?? section.name,
          area: liveSectionsByCode[section.id]?.areaM2 ?? section.area,
          planted: (treeCounts[section.id] ?? 0) > 0,
          treeCount: treeCounts[section.id] ?? 0,
          polygon: section.polygon,
        ),
    ];

    final resolvedMapZoneCodes = <String>{};
    final branchLines = <BranchLine>[
      for (final line in geometry.branchLines)
        _bindBranchLine(
          line,
          zonesByCode,
          discrepancies,
          onResolved: resolvedMapZoneCodes.add,
        ),
    ];
    final valves = <NetworkValve>[
      for (final valve in geometry.valves)
        _bindValve(
          valve,
          zonesByCode,
          discrepancies,
          onResolved: resolvedMapZoneCodes.add,
        ),
    ];

    return FarmMapCompositionResult(
      data: FarmMapData(
        generatedFrom: geometry.generatedFrom,
        bounds: geometry.bounds,
        sections: sections,
        trees: trees,
        layout: geometry.layout,
        utilities: geometry.utilities,
        waterLines: geometry.waterLines,
        branchLines: branchLines,
        valves: valves,
        flushValves: geometry.flushValves,
        risers: geometry.risers,
        waterSupply: geometry.waterSupply,
      ),
      discrepancies: discrepancies,
      resolvedMapZones: resolvedMapZoneCodes.length,
    );
  }

  Map<String, Color> _zoneColors(FarmMapData geometry) {
    final colors = <String, Color>{};
    for (final line in geometry.branchLines) {
      final zoneCode = line.zoneId;
      final color = line.color;
      if (zoneCode != null && color != null) colors[zoneCode] = color;
    }
    for (final valve in geometry.valves) {
      final zoneCode = valve.zoneId;
      final color = valve.color;
      if (zoneCode != null && color != null) colors[zoneCode] = color;
    }
    return colors;
  }

  BranchLine _bindBranchLine(
    BranchLine line,
    Map<String, IrrigationZone> zonesByCode,
    List<MapDataDiscrepancy> discrepancies, {
    required void Function(String) onResolved,
  }) {
    final zoneCode = line.zoneId;
    final zone = zoneCode == null ? null : zonesByCode[zoneCode];
    if (zoneCode != null && zone == null) {
      discrepancies.add(
        MapDataDiscrepancy(
          type: MapDataDiscrepancyType.unresolvedMapZone,
          entityCode: line.assetId,
        ),
      );
    } else if (zone != null) {
      onResolved(zone.code);
    }
    return BranchLine(
      assetId: line.assetId,
      name: line.name,
      section: line.section,
      submain: line.submain,
      coordinates: line.coordinates,
      zoneId: line.zoneId,
      zoneUuid: zone?.id,
      color: line.color,
      status: line.status,
    );
  }

  NetworkValve _bindValve(
    NetworkValve valve,
    Map<String, IrrigationZone> zonesByCode,
    List<MapDataDiscrepancy> discrepancies, {
    required void Function(String) onResolved,
  }) {
    final zoneCode = valve.zoneId;
    final zone = zoneCode == null ? null : zonesByCode[zoneCode];
    if (valve.isZoneControl && zone == null) {
      discrepancies.add(
        MapDataDiscrepancy(
          type: MapDataDiscrepancyType.unresolvedMapZone,
          entityCode: valve.assetId,
        ),
      );
    } else if (zone != null) {
      onResolved(zone.code);
    }
    return NetworkValve(
      assetId: valve.assetId,
      name: valve.name,
      type: valve.type,
      latitude: valve.latitude,
      longitude: valve.longitude,
      section: valve.section,
      submain: valve.submain,
      zoneId: valve.zoneId,
      zoneUuid: zone?.id,
      color: valve.color,
      zoneTreeCount: valve.zoneTreeCount,
      status: valve.status,
      downstreamSubmains: valve.downstreamSubmains,
      downstreamLine: valve.downstreamLine,
    );
  }
}
