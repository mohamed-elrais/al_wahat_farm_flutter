import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: FarmMapScreen(mapFuture: Future<ProjectedFarmMap>.value(map!)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('section-all')), findsOneWidget);
    final sectionScroll = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    sectionScroll.position.jumpTo(960);
    await tester.pump();
    expect(find.byKey(const Key('section-E')), findsOneWidget);
    await tester.tap(find.byKey(const Key('section-E')));
    await tester.pump();
    expect(find.text('Section E · Unplanted'), findsOneWidget);
  });
}
