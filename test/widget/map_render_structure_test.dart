import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_painter.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('one isolated painter owns all map points and layer toggles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 1366);
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

    final mapPaint = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is FarmMapPainter,
    );
    expect(mapPaint, findsOneWidget);
    expect(
      find.ancestor(of: mapPaint, matching: find.byType(RepaintBoundary)),
      findsWidgets,
    );
    expect(_painter(tester).map.trees, hasLength(1567));
    expect(find.text('Select any tree'), findsOneWidget);
    expect(FarmMapPainter.overviewTreeRadius, 2.7);
    expect(FarmMapPainter.sectionTreeRadius, 4.4);
    expect(FarmMapPainter.selectedTreeRadius, 6.8);

    await tester.tap(find.byTooltip('Map layers'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<String>, 'Trees'),
    );
    await tester.pumpAndSettle();

    expect(_painter(tester).showTrees, isFalse);
    expect(_painter(tester).showIrrigation, isTrue);
    expect(_painter(tester).showUtilities, isTrue);
  });
}

FarmMapPainter _painter(WidgetTester tester) {
  final customPaint = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is FarmMapPainter,
    ),
  );
  return customPaint.painter! as FarmMapPainter;
}
