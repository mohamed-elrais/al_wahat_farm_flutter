import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
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
    expect(painter().selectedValveId, target.valve.assetId);
    expect(painter().highlightZoneUuids, <String>{target.valve.zoneUuid!});

    // Dismiss the sheet; the highlight stays.
    await tester.tapAt(const Offset(215, 60));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('zone-sheet')), findsNothing);
    expect(painter().selectedValveId, target.valve.assetId);

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
    expect(painter().selectedValveId, isNull);
  });

  testWidgets('tapping a mainline isolation valve shows its localized sheet',
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
    await tester.pumpAndSettle();

    final canvasFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is FarmMapPainter,
    );
    final canvasBox = tester.renderObject<RenderBox>(canvasFinder);
    // Pick an isolation valve whose projected point is inside the visible
    // viewer area (some sit under the header chrome after the initial fit).
    final viewerRect =
        tester.getRect(find.byType(InteractiveViewer)).deflate(24);
    // Valve 04 is the user-facing contract: it shuts off submain 04, whose
    // SM04 assets (zones, branches, flush valves) carry 279 trees.
    final isolation = map.valves.firstWhere(
      (projected) => projected.valve.assetId == 'IRR-IV-ML-04',
    );
    expect(
      viewerRect.contains(canvasBox.localToGlobal(isolation.point)),
      isTrue,
      reason: 'valve 04 must be inside the fitted viewer to tap',
    );
    await tester.tapAt(canvasBox.localToGlobal(isolation.point));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('zone-sheet')), findsOneWidget);
    expect(find.text('Mainline Isolation Valve 04'), findsOneWidget);
    expect(find.text('MAINLINE VALVE'), findsOneWidget); // Eyebrow uppercases
    // Valve 04 counts submain 04's trees and highlights its network.
    expect(find.byKey(const Key('valve-sheet-trees')), findsOneWidget);
    expect(
      find.text('279 trees are fed through this valve'),
      findsOneWidget,
    );
    expect(find.text('Feeds submains: 04'), findsOneWidget);
    final painter =
        tester.widget<CustomPaint>(canvasFinder).painter! as FarmMapPainter;
    expect(painter.selectedValveId, 'IRR-IV-ML-04');
    expect(painter.highlightSubmains, <String>{'04'});
    expect(painter.highlightZoneUuids, isNotEmpty);
    // The highlighted pipe is submain 04 itself.
    final submain04 = map.data.valves
        .firstWhere((valve) => valve.assetId == 'IRR-IV-ML-04')
        .downstreamLine!;
    expect(painter.highlightLine, hasLength(submain04.length));
  });

  testWidgets('zone sheet is fully localized in Arabic', (tester) async {
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
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FarmMapScreen(mapFuture: Future<ProjectedFarmMap>.value(map!)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Section chips are localized ("القسم A" instead of raw "Section A").
    expect(find.textContaining('القسم A'), findsOneWidget);
    expect(find.textContaining('Section A'), findsNothing);

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
    // Valve title built from structured fields, not the raw English name.
    expect(find.text(target.valve.name), findsNothing);
    expect(find.textContaining('محبس المنطقة'), findsOneWidget);
    expect(find.text('منطقة الري'), findsOneWidget);
  });
}
