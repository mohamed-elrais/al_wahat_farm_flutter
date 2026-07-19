import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_painter.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fidelity certification of the irrigation-network map layers (M2/M3): the
/// full network rendered at the primary phone size, and a zone highlighted by
/// tapping its zone control valve.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf')))
        .load();
    await (FontLoader('LibreBaskerville')
          ..addFont(
            rootBundle.load('assets/fonts/LibreBaskerville-Variable.ttf'),
          ))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  Future<ProjectedFarmMap> pumpMap(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = await tester.runAsync(
      () => const MapAssetRepository().load().then(ProjectedFarmMap.new),
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: FarmMapScreen(mapFuture: Future<ProjectedFarmMap>.value(map!)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return map;
  }

  testWidgets('map with every network layer enabled at 430 by 932',
      (tester) async {
    await pumpMap(tester);
    for (final layer in <String>['Flush valves', 'Water supply']) {
      await tester.tap(find.byTooltip('Map layers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(layer));
      await tester.pumpAndSettle();
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/map_network_430x932.png'),
    );
  });

  testWidgets('map with a highlighted mainline isolation valve at 430 by 932',
      (tester) async {
    final map = await pumpMap(tester);
    final canvasFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is FarmMapPainter,
    );
    final canvasBox = tester.renderObject<RenderBox>(canvasFinder);
    final isolation = map.valves.firstWhere(
      (projected) => projected.valve.assetId == 'IRR-IV-ML-04',
    );
    await tester.tapAt(canvasBox.localToGlobal(isolation.point));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('zone-sheet')), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/map_isolation_highlight_430x932.png'),
    );
  });

  testWidgets('map with a highlighted irrigation zone at 430 by 932',
      (tester) async {
    final map = await pumpMap(tester);
    final canvasFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is FarmMapPainter,
    );
    final canvasBox = tester.renderObject<RenderBox>(canvasFinder);
    final target = map.valves.firstWhere(
      (projected) =>
          projected.valve.isZoneControl && projected.valve.zoneUuid != null,
    );
    await tester.tapAt(canvasBox.localToGlobal(target.point));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('zone-sheet')), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/map_zone_highlight_430x932.png'),
    );
  });
}
