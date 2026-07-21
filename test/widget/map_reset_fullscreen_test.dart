import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_painter.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProjectedFarmMap> _loadMap(WidgetTester tester) async =>
    (await tester.runAsync(
      () => const MapAssetRepository().load().then(ProjectedFarmMap.new),
    ))!;

Widget _app(ProjectedFarmMap map, {String? focus, bool visible = true}) =>
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        // Mirrors the shell's IndexedStack: hidden branches keep their
        // state but have tickers disabled.
        body: TickerMode(
          enabled: visible,
          child: FarmMapScreen(
            mapFuture: Future<ProjectedFarmMap>.value(map),
            focus: focus,
          ),
        ),
      ),
    );

FarmMapPainter _painter(WidgetTester tester) {
  final canvasFinder = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is FarmMapPainter,
  );
  return tester.widget<CustomPaint>(canvasFinder.last).painter!
      as FarmMapPainter;
}

void main() {
  testWidgets('leaving the map clears selection, highlight and filter',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = await _loadMap(tester);
    final target = map.valves.firstWhere(
      (projected) =>
          projected.valve.isZoneControl && projected.valve.zoneUuid != null,
    );

    await tester.pumpWidget(_app(map, focus: 'zone:${target.valve.zoneUuid}'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('zone-sheet')), findsOneWidget);
    expect(_painter(tester).selectedValveId, target.valve.assetId);

    // Dismiss the sheet, then leave the tab (tickers off) and come back.
    await tester.tapAt(const Offset(215, 60));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(map, visible: false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(map));
    await tester.pumpAndSettle();

    expect(_painter(tester).selectedValveId, isNull);
    expect(_painter(tester).selectedSection, isNull);
    expect(_painter(tester).selectedTreeId, isNull);
    expect(find.byKey(const Key('zone-sheet')), findsNothing);
  });

  testWidgets(
      'full screen keeps camera and selection and exits with the button',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = await _loadMap(tester);
    final target = map.valves.firstWhere(
      (projected) =>
          projected.valve.isZoneControl && projected.valve.zoneUuid != null,
    );

    await tester.pumpWidget(_app(map, focus: 'zone:${target.valve.zoneUuid}'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(215, 60)); // dismiss the sheet
    await tester.pumpAndSettle();

    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    final cameraBefore = controller.value.clone();

    // The zoom buttons are gone; full screen replaces them.
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.remove), findsNothing);
    await tester.tap(find.byIcon(Icons.fullscreen));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map-exit-full-screen')), findsOneWidget);
    // Same controller, same camera, selection still highlighted.
    final fullScreenViewer = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer).last)
        .transformationController;
    expect(identical(fullScreenViewer, controller), isTrue);
    expect(controller.value, cameraBefore);
    expect(_painter(tester).selectedValveId, target.valve.assetId);

    await tester.tap(find.byKey(const Key('map-exit-full-screen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-exit-full-screen')), findsNothing);
    expect(_painter(tester).selectedValveId, target.valve.assetId);
    expect(controller.value, cameraBefore);
  });
}
