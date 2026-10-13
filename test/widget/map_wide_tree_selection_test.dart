import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:al_wahat_farm_flutter/features/trees/presentation/tree_detail_sheet.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/farm_hierarchy_fixture.dart';
import '../support/projected_farm_map_fixture.dart';

/// The map inside a shell shaped like AppShell: the tab draws under a
/// floating navigation bar (extendBody), on its own navigator.
Widget _app({
  required FarmHierarchy hierarchy,
  required ProjectedFarmMap map,
  required String focus,
}) {
  final operational = OperationalContext(
    profile: const UserProfile(
      id: 'profile',
      fullName: 'Farm member',
      isActive: true,
    ),
    memberships: <FarmMembership>[
      const FarmMembership(
        id: 'membership',
        profileId: 'profile',
        role: FarmRole.owner,
        isActive: true,
        farm: FarmSummary(
          id: CanonicalFarmHierarchyDataSource.farmId,
          name: 'Al Wahat',
          code: 'AL-WAHAT',
          timezone: 'Africa/Cairo',
        ),
      ),
    ],
  );
  final router = GoRouter(
    initialLocation: '/map',
    routes: <RouteBase>[
      ShellRoute(
        builder: (_, __, child) => Scaffold(
          extendBody: true,
          body: child,
          bottomNavigationBar: const SizedBox(
            key: Key('test-navigation-bar'),
            height: 72,
          ),
        ),
        routes: <RouteBase>[
          GoRoute(
            path: '/map',
            builder: (_, __) => FarmMapScreen(
              mapFuture: Future<ProjectedFarmMap>.value(map),
              focus: focus,
            ),
          ),
        ],
      ),
    ],
  );
  return OperationalContextScope(
    contextData: operational,
    child: FarmHierarchyScope(
      snapshot: FarmHierarchySnapshot(
        hierarchy: hierarchy,
        source: FarmHierarchySource.network,
      ),
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  testWidgets(
      'wide map: tree sheet opens above the navigation bar and the side '
      'panel names the zone by code', (tester) async {
    // The desktop window from the user's report (1280 x 566).
    tester.view.physicalSize = const Size(1280, 566);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loaded = (await tester.runAsync(loadCanonicalFarmMapFixture))!;
    final liveTreeIds = loaded.hierarchy.trees.map((tree) => tree.id).toSet();
    final tree = loaded.map.trees.map((projected) => projected.tree).firstWhere(
          (candidate) =>
              liveTreeIds.contains(candidate.id) &&
              loaded.hierarchy.zones.any((zone) => zone.id == candidate.zoneId),
        );
    // The fixture's zone ids equal their codes; give this zone a distinct
    // code, as live zones have (uuid id, IRR-... code).
    const zoneCode = 'IRR-TEST-ZONE-CODE';
    final hierarchy = FarmHierarchy(
      farmId: loaded.hierarchy.farmId,
      sections: loaded.hierarchy.sections,
      zones: <IrrigationZone>[
        for (final zone in loaded.hierarchy.zones)
          zone.id != tree.zoneId
              ? zone
              : IrrigationZone(
                  id: zone.id,
                  sectionId: zone.sectionId,
                  code: zoneCode,
                  name: zone.name,
                  valveCode: zone.valveCode,
                  isActive: zone.isActive,
                  createdAt: zone.createdAt,
                  updatedAt: zone.updatedAt,
                ),
      ],
      trees: loaded.hierarchy.trees,
      plantingPits: loaded.hierarchy.plantingPits,
    );

    await tester.pumpWidget(
      _app(
        hierarchy: hierarchy,
        map: loaded.map,
        focus: 'tree:${tree.id}',
      ),
    );
    await tester.pumpAndSettle();

    final sheet = find.byType(TreeDetailSheet);
    expect(sheet, findsOneWidget);
    // On the root navigator, so the sheet is drawn over the navigation bar
    // instead of under it.
    final rootNavigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    expect(Navigator.of(tester.element(sheet)), same(rootNavigator));

    // Side panel and sheet both show the zone code, never the zone uuid.
    expect(find.text(zoneCode), findsNWidgets(2));
    expect(find.text(tree.zoneId), findsNothing);
  });
}
