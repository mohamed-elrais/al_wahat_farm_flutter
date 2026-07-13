import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';

class TreeIdentity {
  const TreeIdentity({
    required this.id,
    required this.code,
    required this.sectionCode,
    required this.healthStatus,
    required this.type,
    this.farmId,
    this.zoneLabel,
    this.rowNumber,
    this.treeNumber,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String? farmId;
  final String code;
  final String sectionCode;
  final String? zoneLabel;
  final int? rowNumber;
  final int? treeNumber;
  final String healthStatus;
  final String type;
  final double? latitude;
  final double? longitude;

  factory TreeIdentity.fromMapTree(
    FarmTree tree, {
    String? farmId,
    String? zoneLabel,
  }) =>
      TreeIdentity(
        id: tree.id,
        farmId: farmId,
        code: tree.code,
        sectionCode: tree.section,
        zoneLabel: zoneLabel ?? tree.zoneId,
        rowNumber: tree.row,
        treeNumber: tree.number,
        healthStatus: tree.health,
        type: tree.type,
        latitude: tree.latitude,
        longitude: tree.longitude,
      );

  static TreeIdentity? fromHierarchy(FarmHierarchy hierarchy, String treeId) {
    FarmTreeRecord? record;
    for (final tree in hierarchy.trees) {
      if (tree.id == treeId) {
        record = tree;
        break;
      }
    }
    if (record == null) return null;

    final section = hierarchy.sectionById(record.sectionId)!;
    String? zoneLabel;
    for (final zone in hierarchy.zones) {
      if (zone.id == record.irrigationZoneId) {
        zoneLabel = zone.code;
        break;
      }
    }
    return TreeIdentity(
      id: record.id,
      farmId: record.farmId,
      code: record.treeCode,
      sectionCode: section.code,
      zoneLabel: zoneLabel ?? record.irrigationZoneId,
      rowNumber: record.rowNumber,
      treeNumber: record.treeNumber,
      healthStatus: record.healthStatus.wireValue,
      type: record.type,
      latitude: record.latitude,
      longitude: record.longitude,
    );
  }
}
