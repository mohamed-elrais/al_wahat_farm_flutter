import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/farm_map_data.dart';

enum TreeDiscrepancyType {
  missingLiveTree,
  unexpectedLiveTree,
  idMismatch,
  codeMismatch,
  sectionMismatch,
  zoneMismatch,
  coordinateMismatch,
}

class TreeDataDiscrepancy {
  const TreeDataDiscrepancy({
    required this.type,
    required this.treeCode,
    this.assetTreeId,
    this.liveTreeId,
  });

  final TreeDiscrepancyType type;
  final String treeCode;
  final String? assetTreeId;
  final String? liveTreeId;

  Map<String, Object?> toLogFields() => <String, Object?>{
        'type': type.name,
        'tree_code': treeCode,
        'asset_tree_id': assetTreeId,
        'live_tree_id': liveTreeId,
      };
}

class TreeReconciliationResult {
  TreeReconciliationResult({
    required List<FarmTree> trees,
    required List<TreeDataDiscrepancy> discrepancies,
    required this.matchedById,
    required this.matchedByCode,
  })  : trees = List<FarmTree>.unmodifiable(trees),
        discrepancies = List<TreeDataDiscrepancy>.unmodifiable(discrepancies);

  final List<FarmTree> trees;
  final List<TreeDataDiscrepancy> discrepancies;
  final int matchedById;
  final int matchedByCode;

  bool get hasDiscrepancies => discrepancies.isNotEmpty;

  Map<TreeDiscrepancyType, int> get discrepancyCounts {
    final counts = <TreeDiscrepancyType, int>{};
    for (final discrepancy in discrepancies) {
      counts.update(discrepancy.type, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map<TreeDiscrepancyType, int>.unmodifiable(counts);
  }
}

class TreeReconciler {
  // The backend stores tree latitude/longitude at 6-decimal precision, so a
  // value can differ from the higher-precision reference asset by up to 5e-7°
  // (~7 cm) purely from rounding. The tolerance sits above that (1e-6° ≈ 11 cm)
  // so rounding is not reported as drift, while a real misplacement — which is
  // at least a tree slot away (metres) — still is.
  const TreeReconciler({this.coordinateTolerance = 0.000001});

  final double coordinateTolerance;

  TreeReconciliationResult reconcile(
    FarmMapData asset,
    FarmHierarchy live,
  ) {
    final liveById = <String, FarmTreeRecord>{
      for (final tree in live.trees) tree.id: tree,
    };
    final liveByCode = <String, FarmTreeRecord>{
      for (final tree in live.trees) tree.treeCode: tree,
    };
    final usedLiveIds = <String>{};
    final reconciled = <FarmTree>[];
    final discrepancies = <TreeDataDiscrepancy>[];
    var matchedById = 0;
    var matchedByCode = 0;

    for (final assetTree in asset.trees) {
      var liveTree = liveById[assetTree.id];
      if (liveTree != null && !usedLiveIds.contains(liveTree.id)) {
        matchedById++;
      } else {
        liveTree = liveByCode[assetTree.code];
        if (liveTree != null && !usedLiveIds.contains(liveTree.id)) {
          matchedByCode++;
          if (liveTree.id != assetTree.id) {
            discrepancies.add(
              TreeDataDiscrepancy(
                type: TreeDiscrepancyType.idMismatch,
                treeCode: assetTree.code,
                assetTreeId: assetTree.id,
                liveTreeId: liveTree.id,
              ),
            );
          }
        }
      }

      if (liveTree == null || usedLiveIds.contains(liveTree.id)) {
        discrepancies.add(
          TreeDataDiscrepancy(
            type: TreeDiscrepancyType.missingLiveTree,
            treeCode: assetTree.code,
            assetTreeId: assetTree.id,
          ),
        );
        reconciled.add(assetTree);
        continue;
      }

      usedLiveIds.add(liveTree.id);
      final sectionCode = live.sectionById(liveTree.sectionId)!.code;
      if (liveTree.treeCode != assetTree.code) {
        discrepancies.add(
          TreeDataDiscrepancy(
            type: TreeDiscrepancyType.codeMismatch,
            treeCode: assetTree.code,
            assetTreeId: assetTree.id,
            liveTreeId: liveTree.id,
          ),
        );
      }
      if (sectionCode != assetTree.section) {
        discrepancies.add(
          TreeDataDiscrepancy(
            type: TreeDiscrepancyType.sectionMismatch,
            treeCode: assetTree.code,
            assetTreeId: assetTree.id,
            liveTreeId: liveTree.id,
          ),
        );
      }
      if (liveTree.irrigationZoneId != null &&
          liveTree.irrigationZoneId != assetTree.zoneId) {
        discrepancies.add(
          TreeDataDiscrepancy(
            type: TreeDiscrepancyType.zoneMismatch,
            treeCode: assetTree.code,
            assetTreeId: assetTree.id,
            liveTreeId: liveTree.id,
          ),
        );
      }
      final latitude = liveTree.latitude ?? assetTree.latitude;
      final longitude = liveTree.longitude ?? assetTree.longitude;
      if ((latitude - assetTree.latitude).abs() > coordinateTolerance ||
          (longitude - assetTree.longitude).abs() > coordinateTolerance) {
        discrepancies.add(
          TreeDataDiscrepancy(
            type: TreeDiscrepancyType.coordinateMismatch,
            treeCode: assetTree.code,
            assetTreeId: assetTree.id,
            liveTreeId: liveTree.id,
          ),
        );
      }

      reconciled.add(
        FarmTree(
          id: liveTree.id,
          code: liveTree.treeCode,
          section: sectionCode,
          zoneId: liveTree.irrigationZoneId ?? assetTree.zoneId,
          row: liveTree.rowNumber ?? assetTree.row,
          number: liveTree.treeNumber ?? assetTree.number,
          latitude: latitude,
          longitude: longitude,
          health: liveTree.healthStatus.wireValue,
          type: liveTree.type,
          color: assetTree.color,
        ),
      );
    }

    for (final liveTree in live.trees) {
      if (usedLiveIds.contains(liveTree.id)) continue;
      discrepancies.add(
        TreeDataDiscrepancy(
          type: TreeDiscrepancyType.unexpectedLiveTree,
          treeCode: liveTree.treeCode,
          liveTreeId: liveTree.id,
        ),
      );
    }

    return TreeReconciliationResult(
      trees: reconciled,
      discrepancies: discrepancies,
      matchedById: matchedById,
      matchedByCode: matchedByCode,
    );
  }
}
