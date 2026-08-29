import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/farm_hierarchy_fixture.dart';

void main() {
  testWidgets('section filter switches map heading to unplanted section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final map = await tester.runAsync(
      () => const MapAssetRepository().load().then(ProjectedFarmMap.new),
    );
    final hierarchy = (await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId))
        .hierarchy;

    await tester.pumpWidget(
      FarmHierarchyScope(
        snapshot: FarmHierarchySnapshot(
          hierarchy: hierarchy,
          source: FarmHierarchySource.network,
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body:
                FarmMapScreen(mapFuture: Future<ProjectedFarmMap>.value(map!)),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('section-all')), findsOneWidget);
    final sectionScroll = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    sectionScroll.position.jumpTo(1000);
    await tester.pump();
    expect(find.byKey(const Key('section-E')), findsOneWidget);
    await tester.tap(find.byKey(const Key('section-E')));
    await tester.pump();
    expect(find.text('Section E · Unplanted · 1 pit'), findsOneWidget);
  });
}
