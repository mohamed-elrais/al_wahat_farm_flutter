import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_painter.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping a zone valve highlights its zone; a miss clears it',
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
    await tester.pumpAndSettle(); // initial fit transform applied post-frame

    final canvasFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is FarmMapPainter,
    );
    FarmMapPainter painter() =>
        (tester.widget<CustomPaint>(canvasFinder).painter as FarmMapPainter?)!;
    final canvasBox = tester.renderObject<RenderBox>(canvasFinder);

    // A zone control valve that irrigates trees.
    final target = map.valves.firstWhere(
      (projected) =>
          projected.valve.isZoneControl && projected.valve.zoneUuid != null,
    );
    await tester.tapAt(canvasBox.localToGlobal(target.point));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('zone-sheet')), findsOneWidget);
    expect(find.text(target.valve.name), findsOneWidget);
    expect(painter().selectedZoneValveId, target.valve.assetId);
    expect(painter().selectedZoneUuid, target.valve.zoneUuid);

    // Dismiss the sheet; the highlight stays.
    await tester.tapAt(const Offset(215, 60));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('zone-sheet')), findsNothing);
    expect(painter().selectedZoneValveId, target.valve.assetId);

    // A tap on empty map space (far from every valve and tree) clears it.
    final scale = 430 / canvasBox.size.width;
    final valveTolerance = 30 / scale;
    final treeTolerance = 44 / scale;
    Offset? empty;
    for (double x = 4; x < canvasBox.size.width && empty == null; x += 20) {
      for (double y = 4; y < canvasBox.size.height && empty == null; y += 20) {
        final candidate = Offset(x, y);
        final valveClear = map.valves.every(
          (projected) =>
              (projected.point - candidate).distance > valveTolerance + 4,
        );
        final treeClear = map.trees.every(
          (projected) =>
              (projected.point - candidate).distance > treeTolerance + 4,
        );
        if (valveClear && treeClear) empty = candidate;
      }
    }
    expect(empty, isNotNull, reason: 'no empty canvas spot found');
    final globalEmpty = canvasBox.localToGlobal(empty!);
    await tester.tapAt(globalEmpty);
    await tester.pumpAndSettle();
    expect(painter().selectedZoneValveId, isNull);
  });
}
