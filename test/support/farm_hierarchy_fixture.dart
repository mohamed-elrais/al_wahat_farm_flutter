import 'dart:convert';
import 'dart:io';

import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';

class CanonicalFarmHierarchyDataSource implements FarmHierarchyDataSource {
  CanonicalFarmHierarchyDataSource._({
    required this.sections,
    required this.zones,
    required this.trees,
  });

  static const farmId = 'fixture-farm';
  static const _timestamp = '2026-01-01T00:00:00.000Z';

  final List<Map<String, Object?>> sections;
  final List<Map<String, Object?>> zones;
  final List<Map<String, Object?>> trees;
  bool fail = false;
  List<String>? requestedSectionIds;

  factory CanonicalFarmHierarchyDataSource.load() {
    final decoded = jsonDecode(
      File('assets/data/al_wahat_map_data.json').readAsStringSync(),
    )! as Map<String, Object?>;
    final rawSections =
        (decoded['sections']! as List<Object?>).cast<Map<String, Object?>>();
    final rawTrees =
        (decoded['trees']! as List<Object?>).cast<Map<String, Object?>>();

    final sections = <Map<String, Object?>>[
      for (var index = 0; index < rawSections.length; index++)
        <String, Object?>{
          'id': rawSections[index]['id']! as String,
          'farm_id': farmId,
          'code': rawSections[index]['id']! as String,
          'name': rawSections[index]['name']! as String,
          'sort_order': index + 1,
          'area_m2': rawSections[index]['area']! as num,
          'notes': null,
          'is_active': true,
          'created_at': _timestamp,
          'updated_at': _timestamp,
        },
    ];

    final zoneSections = <String, String>{};
    for (final tree in rawTrees) {
      zoneSections.putIfAbsent(
        tree['zoneId']! as String,
        () => tree['section']! as String,
      );
    }
    final zones = <Map<String, Object?>>[
      for (final entry in zoneSections.entries)
        <String, Object?>{
          'id': entry.key,
          'section_id': entry.value,
          'code': 'FIXTURE-${entry.key.substring(0, 8)}',
          'name': 'Asset irrigation zone',
          'valve_code': null,
          'notes': null,
          'is_active': true,
          'created_at': _timestamp,
          'updated_at': _timestamp,
        },
    ];

    final trees = <Map<String, Object?>>[
      for (final tree in rawTrees)
        <String, Object?>{
          'id': tree['id']! as String,
          'farm_id': farmId,
          'section_id': tree['section']! as String,
          'irrigation_zone_id': tree['zoneId']! as String,
          'tree_code': tree['code']! as String,
          'row_number': tree['row']! as num,
          'tree_number': tree['number']! as num,
          'planted_on': null,
          'latitude': tree['lat']! as num,
          'longitude': tree['lng']! as num,
          'health_status': tree['health']! as String,
          'type': tree['type']! as String,
          'notes': null,
          'is_active': true,
          'created_at': _timestamp,
          'updated_at': _timestamp,
        },
    ];

    return CanonicalFarmHierarchyDataSource._(
      sections: sections,
      zones: zones,
      trees: trees,
    );
  }

  @override
  Future<List<Map<String, Object?>>> fetchSections(String farmId) async {
    _throwIfFailed();
    return sections;
  }

  @override
  Future<List<Map<String, Object?>>> fetchZones(
    List<String> sectionIds,
  ) async {
    _throwIfFailed();
    requestedSectionIds = List<String>.of(sectionIds);
    return zones;
  }

  @override
  Future<List<Map<String, Object?>>> fetchTrees(String farmId) async {
    _throwIfFailed();
    return trees;
  }

  void _throwIfFailed() {
    if (fail) throw StateError('Fixture network unavailable');
  }
}
