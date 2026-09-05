import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/farm_hierarchy_fixture.dart';

void main() {
  testWidgets('live data discrepancies are visible to managers only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = await tester.runAsync(
      () => const MapAssetRepository().load().then(ProjectedFarmMap.new),
    );
    final fixture = CanonicalFarmHierarchyDataSource.load();
    final complete = (await DefaultFarmHierarchyRepository(
      fixture,
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId))
        .hierarchy;
    final invalidTree = complete.trees.first;
    final incomplete = FarmHierarchy(
      farmId: complete.farmId,
      sections: complete.sections,
      zones: complete.zones,
      trees: <FarmTreeRecord>[
        FarmTreeRecord(
          id: invalidTree.id,
          farmId: invalidTree.farmId,
          sectionId: invalidTree.sectionId,
          irrigationZoneId: invalidTree.irrigationZoneId,
          treeCode: invalidTree.treeCode,
          rowNumber: invalidTree.rowNumber,
          treeNumber: invalidTree.treeNumber,
          plantedOn: invalidTree.plantedOn,
          healthStatus: invalidTree.healthStatus,
          type: invalidTree.type,
          notes: invalidTree.notes,
          isActive: invalidTree.isActive,
          createdAt: invalidTree.createdAt,
          updatedAt: invalidTree.updatedAt,
        ),
        ...complete.trees.skip(1),
      ],
      plantingPits: complete.plantingPits,
    );

    await tester.pumpWidget(
      _app(
        role: FarmRole.owner,
        hierarchy: incomplete,
        map: map!,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('map-data-warning')), findsOneWidget);

    await tester.pumpWidget(
      _app(
        role: FarmRole.worker,
        hierarchy: incomplete,
        map: map,
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('map-data-warning')), findsNothing);
  });
}

Widget _app({
  required FarmRole role,
  required FarmHierarchy hierarchy,
  required ProjectedFarmMap map,
}) {
  final operational = OperationalContext(
    profile: const UserProfile(
      id: 'profile',
      fullName: 'Farm member',
      isActive: true,
    ),
    memberships: <FarmMembership>[
      FarmMembership(
        id: 'membership',
        profileId: 'profile',
        role: role,
        isActive: true,
        farm: const FarmSummary(
          id: CanonicalFarmHierarchyDataSource.farmId,
          name: 'Al Wahat',
          code: 'AL-WAHAT',
          timezone: 'Africa/Cairo',
        ),
      ),
    ],
  );
  return MaterialApp(
    theme: AppTheme.light,
    home: OperationalContextScope(
      contextData: operational,
      child: FarmHierarchyScope(
        snapshot: FarmHierarchySnapshot(
          hierarchy: hierarchy,
          source: FarmHierarchySource.network,
        ),
        child: Scaffold(
          body: FarmMapScreen(
            mapFuture: Future<ProjectedFarmMap>.value(map),
          ),
        ),
      ),
    ),
  );
}
