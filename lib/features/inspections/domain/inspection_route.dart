import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';

enum InspectionRouteSide {
  left,
  right,
  single;

  String get wireValue => name;

  factory InspectionRouteSide.fromJson(String value) => switch (value) {
        'left' => left,
        'right' => right,
        'single' => single,
        _ => throw FormatException('Unknown inspection route side: $value'),
      };
}

class InspectionRouteItem {
  const InspectionRouteItem({
    required this.treeId,
    required this.treeCode,
    required this.sequenceIndex,
    required this.corridorIndex,
    required this.stationIndex,
    required this.side,
    this.rowNumber,
    this.treeNumber,
    this.latitude,
    this.longitude,
  });

  final String treeId;
  final String treeCode;
  final int sequenceIndex;
  final int corridorIndex;
  final int stationIndex;
  final InspectionRouteSide side;
  final int? rowNumber;
  final int? treeNumber;
  final double? latitude;
  final double? longitude;

  Map<String, Object?> toRpcJson() => <String, Object?>{
        'tree_id': treeId,
        'sequence_index': sequenceIndex,
        'corridor_index': corridorIndex,
        'station_index': stationIndex,
        'side': side.wireValue,
      };

  Map<String, Object?> toJson() => <String, Object?>{
        ...toRpcJson(),
        'tree_code': treeCode,
        'row_number': rowNumber,
        'tree_number': treeNumber,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory InspectionRouteItem.fromJson(Map<String, Object?> json) =>
      InspectionRouteItem(
        treeId: json['tree_id']! as String,
        treeCode: json['tree_code']! as String,
        sequenceIndex: (json['sequence_index']! as num).toInt(),
        corridorIndex: (json['corridor_index']! as num).toInt(),
        stationIndex: (json['station_index']! as num).toInt(),
        side: InspectionRouteSide.fromJson(json['side']! as String),
        rowNumber: (json['row_number'] as num?)?.toInt(),
        treeNumber: (json['tree_number'] as num?)?.toInt(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

class InspectionRoute {
  InspectionRoute({
    required this.sectionId,
    required this.startingTreeId,
    required this.routeVersion,
    required List<InspectionRouteItem> items,
  }) : items = List<InspectionRouteItem>.unmodifiable(items) {
    if (items.isEmpty) {
      throw const FormatException('Inspection route cannot be empty');
    }
    if (items.first.treeId != startingTreeId ||
        items.first.sequenceIndex != 1) {
      throw const FormatException(
        'Inspection route must begin with its starting tree',
      );
    }
    final treeIds = items.map((item) => item.treeId).toSet();
    final sequences = items.map((item) => item.sequenceIndex).toSet();
    if (treeIds.length != items.length || sequences.length != items.length) {
      throw const FormatException(
        'Inspection route trees and sequence values must be unique',
      );
    }
  }

  final String sectionId;
  final String startingTreeId;
  final int routeVersion;
  final List<InspectionRouteItem> items;

  int get treeCount => items.length;

  int get stationCount => items.map((item) => item.stationIndex).toSet().length;

  List<InspectionRouteItem> station(int stationIndex) => items
      .where((item) => item.stationIndex == stationIndex)
      .toList(growable: false);

  List<Map<String, Object?>> toRpcRoute() =>
      items.map((item) => item.toRpcJson()).toList(growable: false);

  Map<String, Object?> toJson() => <String, Object?>{
        'section_id': sectionId,
        'starting_tree_id': startingTreeId,
        'route_version': routeVersion,
        'items': items.map((item) => item.toJson()).toList(growable: false),
      };

  factory InspectionRoute.fromJson(Map<String, Object?> json) =>
      InspectionRoute(
        sectionId: json['section_id']! as String,
        startingTreeId: json['starting_tree_id']! as String,
        routeVersion: (json['route_version']! as num).toInt(),
        items: (json['items']! as List<Object?>)
            .map((item) => InspectionRouteItem.fromJson(
                  Map<String, Object?>.from(item! as Map),
                ))
            .toList(growable: false),
      );
}

class InspectionRouteException implements Exception {
  const InspectionRouteException(this.message);

  final String message;

  @override
  String toString() => 'InspectionRouteException: $message';
}

extension InspectionRouteTreeSnapshot on FarmTreeRecord {
  InspectionRouteItem toInspectionRouteItem({
    required int sequenceIndex,
    required int corridorIndex,
    required int stationIndex,
    required InspectionRouteSide side,
  }) =>
      InspectionRouteItem(
        treeId: id,
        treeCode: treeCode,
        sequenceIndex: sequenceIndex,
        corridorIndex: corridorIndex,
        stationIndex: stationIndex,
        side: side,
        rowNumber: rowNumber,
        treeNumber: treeNumber,
        latitude: latitude,
        longitude: longitude,
      );
}
