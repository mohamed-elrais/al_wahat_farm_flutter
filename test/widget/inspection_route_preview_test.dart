import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_route_preview.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('route preview adapts and exposes one useful semantic image',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InspectionRoutePreviewMap(
            route: _route,
            semanticsLabel: 'Route starts at TREE-A-001, 4 trees, 2 stations',
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('inspection-route-preview-painter')),
        findsOneWidget);
    expect(
      find.bySemanticsLabel('Route starts at TREE-A-001, 4 trees, 2 stations'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Arabic does not mirror physical route geometry', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InspectionRoutePreviewMap(
            route: _route,
            semanticsLabel: 'مسار المشي',
          ),
        ),
      ),
    );

    final paint = tester.getSize(
      find.byKey(const Key('inspection-route-preview-painter')),
    );
    expect(paint.height, 360);
    expect(tester.takeException(), isNull);
  });
}

final _route = InspectionRoute(
  sectionId: 'section-a',
  startingTreeId: 'tree-1',
  routeVersion: 1,
  items: const <InspectionRouteItem>[
    InspectionRouteItem(
      treeId: 'tree-1',
      treeCode: 'TREE-A-001',
      sequenceIndex: 1,
      corridorIndex: 1,
      stationIndex: 1,
      side: InspectionRouteSide.left,
      latitude: 25,
      longitude: 30,
    ),
    InspectionRouteItem(
      treeId: 'tree-2',
      treeCode: 'TREE-A-002',
      sequenceIndex: 2,
      corridorIndex: 1,
      stationIndex: 1,
      side: InspectionRouteSide.right,
      latitude: 25.0001,
      longitude: 30,
    ),
    InspectionRouteItem(
      treeId: 'tree-3',
      treeCode: 'TREE-A-003',
      sequenceIndex: 3,
      corridorIndex: 1,
      stationIndex: 2,
      side: InspectionRouteSide.left,
      latitude: 25,
      longitude: 30.0001,
    ),
    InspectionRouteItem(
      treeId: 'tree-4',
      treeCode: 'TREE-A-004',
      sequenceIndex: 4,
      corridorIndex: 1,
      stationIndex: 2,
      side: InspectionRouteSide.right,
      latitude: 25.0001,
      longitude: 30.0001,
    ),
  ],
);
