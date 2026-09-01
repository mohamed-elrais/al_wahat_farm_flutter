import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/farm_hierarchy_fixture.dart';

void main() {
  test('controller publishes loading then the complete hierarchy', () async {
    final dataSource = CanonicalFarmHierarchyDataSource.load();
    final controller = FarmHierarchyController(
      DefaultFarmHierarchyRepository(
        dataSource,
        MemoryFarmHierarchyCache(),
      ),
    );
    final states = <FarmHierarchyState>[];
    controller.addListener(() => states.add(controller.state));

    await controller.load(CanonicalFarmHierarchyDataSource.farmId);

    expect(states.first, isA<FarmHierarchyLoading>());
    final ready = states.last as FarmHierarchyReady;
    expect(ready.snapshot.hierarchy.sections, hasLength(12));
    expect(ready.snapshot.hierarchy.trees, hasLength(1539));
  });
}
