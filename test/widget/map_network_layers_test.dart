import 'dart:ui' as ui;

import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/map_projection.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_painter.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('layers menu exposes the irrigation-network toggles',
      (tester) async {
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

    await tester.tap(find.byTooltip('Map layers'));
    await tester.pumpAndSettle();

    expect(find.text('Planting pits'), findsOneWidget);
    expect(find.text('Zone valves'), findsOneWidget);
    expect(find.text('Flush valves'), findsOneWidget);
    expect(find.text('Water supply'), findsOneWidget);

    // Enabling a default-off layer must not throw while painting.
    await tester.tap(find.text('Flush valves'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'map header survives a narrow display-zoomed canvas without overflow',
      (tester) async {
    // Realme C75 geometry: density override 540 -> a 320dp-wide canvas.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.375;
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

    // The controls are present in the stacked narrow layout, and the
    // full-width title lays out without overflow errors.
    expect(find.byTooltip('Map layers'), findsOneWidget);
    expect(find.byTooltip('Full screen'), findsOneWidget);
    expect(find.text('Al Wahat farm overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('painter renders every network layer without errors', () async {
    final map = ProjectedFarmMap(await const MapAssetRepository().load());
    expect(map.branchLines, hasLength(121));
    expect(map.valves, hasLength(133));
    expect(map.flushValves, hasLength(131));
    expect(map.risers, hasLength(66));
    expect(map.supplyPoints, hasLength(7));
    expect(map.supplyLines, hasLength(12));

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    FarmMapPainter(
      map: map,
      selectedSection: null,
      selectedTreeId: null,
      plantingPits: const <ProjectedPlantingPit>[],
      selectedPlantingPitId: null,
      showTrees: true,
      showPlantingPits: true,
      showIrrigation: true,
      showUtilities: true,
      showValves: true,
      showFlushValves: true,
      showWaterSupply: true,
    ).paint(canvas, MapProjection.canvasSize);
    final picture = recorder.endRecording();
    expect(picture, isNotNull);
  });
}
