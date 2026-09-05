import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_painter.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:al_wahat_farm_flutter/features/trees/presentation/tree_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/projected_farm_map_fixture.dart';

Future<ProjectedFarmMap> _loadMap(WidgetTester tester) async =>
    (await tester.runAsync(loadComposedFarmMap))!;

Future<void> _pump(
  WidgetTester tester,
  ProjectedFarmMap map,
  String focus,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: FarmMapScreen(
          mapFuture: Future<ProjectedFarmMap>.value(map),
          focus: focus,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FarmMapPainter _painter(WidgetTester tester) {
  final canvasFinder = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is FarmMapPainter,
  );
  return tester.widget<CustomPaint>(canvasFinder).painter! as FarmMapPainter;
}

void main() {
  testWidgets('zone focus deep link selects the valve and opens its sheet',
      (tester) async {
    final map = await _loadMap(tester);
    final target = map.valves.firstWhere(
      (projected) =>
          projected.valve.isZoneControl && projected.valve.zoneUuid != null,
    );

    await _pump(tester, map, 'zone:${target.valve.zoneUuid}');

    expect(find.byKey(const Key('zone-sheet')), findsOneWidget);
    expect(_painter(tester).selectedValveId, target.valve.assetId);
    expect(
      _painter(tester).highlightZoneUuids,
      contains(target.valve.zoneUuid),
    );
  });

  testWidgets('tree focus deep link opens the tree sheet', (tester) async {
    final map = await _loadMap(tester);
    final tree = map.data.trees.first;

    await _pump(tester, map, 'tree:${tree.id}');

    expect(find.byType(TreeDetailSheet), findsOneWidget);
    expect(_painter(tester).selectedTreeId, tree.id);
    expect(_painter(tester).selectedSection, tree.section);
  });

  testWidgets('section focus deep link applies the section filter',
      (tester) async {
    final map = await _loadMap(tester);
    final section = map.data.sections.first.id;

    await _pump(tester, map, 'section:$section');

    expect(_painter(tester).selectedSection, section);
    expect(find.byKey(const Key('zone-sheet')), findsNothing);
  });

  testWidgets('an unknown focus id is a graceful no-op', (tester) async {
    final map = await _loadMap(tester);

    await _pump(tester, map, 'zone:not-a-real-zone');

    expect(find.byKey(const Key('zone-sheet')), findsNothing);
    expect(_painter(tester).selectedValveId, isNull);
    expect(_painter(tester).selectedSection, isNull);
  });
}
