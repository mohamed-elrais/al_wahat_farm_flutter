import 'dart:convert';
import 'dart:io';

import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';

class CanonicalFarmHierarchyDataSource
    implements FarmHierarchyDataSource, PlantingPitHierarchyDataSource {
  CanonicalFarmHierarchyDataSource._({
    required this.sections,
    required this.zones,
    required this.trees,
    required this.plantingPits,
  });

  static const farmId = 'fixture-farm';
  static const _timestamp = '2026-08-29T00:00:00.000Z';

  final List<Map<String, Object?>> sections;
  final List<Map<String, Object?>> zones;
  final List<Map<String, Object?>> trees;
  final List<Map<String, Object?>> plantingPits;
  bool fail = false;
  List<String>? requestedSectionIds;

  factory CanonicalFarmHierarchyDataSource.load() {
    final decoded = jsonDecode(
      File('test/fixtures/full_farm_hierarchy.json').readAsStringSync(),
    )! as Map<String, Object?>;
    final rawSections = _rows(decoded, 'sections');
    final rawZones = _rows(decoded, 'zones');
    final rawTrees = _rows(decoded, 'trees');
    final rawPits = _rows(decoded, 'plantingPits');

    final sections = <Map<String, Object?>>[
      for (var index = 0; index < rawSections.length; index++)
        <String, Object?>{
          'id': rawSections[index]['code']! as String,
          'farm_id': farmId,
          'code': rawSections[index]['code']! as String,
          'name': rawSections[index]['name']! as String,
          'sort_order': index + 1,
          'area_m2': rawSections[index]['area']! as num,
          'notes': null,
          'is_active': true,
          'created_at': _timestamp,
          'updated_at': _timestamp,
        },
    ];
    final zones = <Map<String, Object?>>[
      for (final zone in rawZones)
        <String, Object?>{
          'id': zone['id']! as String,
          'section_id': zone['section']! as String,
          'code': zone['code']! as String,
          'name': zone['name']! as String,
          'valve_code': zone['code']! as String,
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
          'irrigation_zone_id': tree['zone']! as String,
          'tree_code': tree['code']! as String,
          'row_number': tree['row']! as num,
          'tree_number': tree['number']! as num,
          'planted_on': null,
          'latitude': tree['lat']! as num,
          'longitude': tree['lng']! as num,
          'health_status': 'healthy',
          'type': 'date_palm',
          'notes': null,
          'is_active': true,
          'created_at': _timestamp,
          'updated_at': _timestamp,
        },
    ];
    final plantingPits = <Map<String, Object?>>[
      for (final pit in rawPits)
        <String, Object?>{
          'id': pit['id']! as String,
          'farm_id': farmId,
          'section_id': pit['section']! as String,
          'irrigation_zone_id': pit['zone']! as String,
          'pit_code': pit['code']! as String,
          'row_number': pit['row']! as num,
          'pit_number': pit['number']! as num,
          'latitude': pit['lat']! as num,
          'longitude': pit['lng']! as num,
          'planned_for': null,
          'status': 'planned',
          'marked_at': null,
          'dug_at': null,
          'prepared_at': null,
          'completed_at': null,
          'cancelled_at': null,
          'notes': null,
          'created_by_profile_id': 'fixture-profile',
          'created_at': _timestamp,
          'updated_at': _timestamp,
        },
    ];

    return CanonicalFarmHierarchyDataSource._(
      sections: sections,
      zones: zones,
      trees: trees,
      plantingPits: plantingPits,
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

  @override
  Future<List<Map<String, Object?>>> fetchPlantingPits(String farmId) async {
    _throwIfFailed();
    return plantingPits;
  }

  void _throwIfFailed() {
    if (fail) throw StateError('Fixture network unavailable');
  }
}

List<Map<String, Object?>> _rows(
  Map<String, Object?> decoded,
  String key,
) =>
    (decoded[key]! as List<Object?>)
        .map((row) => Map<String, Object?>.from(row! as Map))
        .toList(growable: false);
