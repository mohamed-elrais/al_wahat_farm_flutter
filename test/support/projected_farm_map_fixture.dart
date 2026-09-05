import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/tree_reconciliation.dart';

import 'farm_hierarchy_fixture.dart';

Future<FarmHierarchy> loadCanonicalFarmHierarchy() async =>
    (await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId))
        .hierarchy;

Future<
    ({
      ProjectedFarmMap map,
      FarmHierarchy hierarchy,
    })> loadCanonicalFarmMapFixture() async {
  final geometry = await const MapAssetRepository().load();
  final hierarchy = await loadCanonicalFarmHierarchy();
  final composition = const FarmMapComposer().compose(geometry, hierarchy);
  return (
    map: ProjectedFarmMap(composition.data),
    hierarchy: hierarchy,
  );
}

Future<ProjectedFarmMap> loadComposedFarmMap() async =>
    (await loadCanonicalFarmMapFixture()).map;
