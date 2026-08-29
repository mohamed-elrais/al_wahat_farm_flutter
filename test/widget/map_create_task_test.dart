import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_painter.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:al_wahat_farm_flutter/features/planting_pits/data/planting_pit_repository.dart';
import 'package:al_wahat_farm_flutter/features/planting_pits/domain/planting_pit.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/farm_hierarchy_fixture.dart';

Future<
    ({
      ProjectedFarmMap map,
      FarmHierarchy hierarchy,
    })> _load(WidgetTester tester) async {
  final map = await tester.runAsync(
    () => const MapAssetRepository().load().then(ProjectedFarmMap.new),
  );
  final hierarchy = (await DefaultFarmHierarchyRepository(
    CanonicalFarmHierarchyDataSource.load(),
    MemoryFarmHierarchyCache(),
  ).load(CanonicalFarmHierarchyDataSource.farmId))
      .hierarchy;
  return (map: map!, hierarchy: hierarchy);
}

Widget _app({
  required FarmRole role,
  required FarmHierarchy hierarchy,
  required ProjectedFarmMap map,
  String? focus,
  PlantingPitRepository? plantingPitRepository,
}) {
  final operational = OperationalContext(
    profile: const UserProfile(
      id: 'profile',
      fullName: 'Farm member',
      isActive: true,
    ),
    memberships: <FarmMembership>[
      FarmMembership(
        id: 'membership',
        profileId: 'profile',
        role: role,
        isActive: true,
        farm: const FarmSummary(
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
      GoRoute(
        path: '/map',
        builder: (_, __) => Scaffold(
          body: FarmMapScreen(
            mapFuture: Future<ProjectedFarmMap>.value(map),
            focus: focus,
            plantingPitRepository: plantingPitRepository,
          ),
        ),
      ),
      GoRoute(
        path: '/tasks/create',
        builder: (_, GoRouterState state) => Scaffold(
          body: Text(
            'create-stub:'
            'zone=${state.uri.queryParameters['zoneId']} '
            'section=${state.uri.queryParameters['sectionId']}',
          ),
        ),
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
  testWidgets('manager creates a zone task from the focused zone sheet',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loaded = await _load(tester);
    final liveZoneIds = loaded.hierarchy.zones.map((zone) => zone.id).toSet();
    final valve = loaded.map.data.valves.firstWhere(
      (candidate) =>
          candidate.isZoneControl && liveZoneIds.contains(candidate.zoneUuid),
    );

    await tester.pumpWidget(
      _app(
        role: FarmRole.owner,
        hierarchy: loaded.hierarchy,
        map: loaded.map,
        focus: 'zone:${valve.zoneUuid}',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('zone-sheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('zone-sheet-create-task')));
    await tester.pumpAndSettle();

    expect(
      find.text('create-stub:zone=${valve.zoneUuid} section=null'),
      findsOneWidget,
    );
  });

  testWidgets('worker zone sheet has no create-task button', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loaded = await _load(tester);
    final liveZoneIds = loaded.hierarchy.zones.map((zone) => zone.id).toSet();
    final valve = loaded.map.data.valves.firstWhere(
      (candidate) =>
          candidate.isZoneControl && liveZoneIds.contains(candidate.zoneUuid),
    );

    await tester.pumpWidget(
      _app(
        role: FarmRole.worker,
        hierarchy: loaded.hierarchy,
        map: loaded.map,
        focus: 'zone:${valve.zoneUuid}',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('zone-sheet')), findsOneWidget);
    expect(find.byKey(const Key('zone-sheet-create-task')), findsNothing);
  });

  testWidgets('manager creates a section task from the section affordance',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loaded = await _load(tester);
    // A live section whose code exists as a map section.
    final mapSectionIds =
        loaded.map.data.sections.map((section) => section.id).toSet();
    final liveSection = loaded.hierarchy.sections
        .firstWhere((section) => mapSectionIds.contains(section.code));

    await tester.pumpWidget(
      _app(
        role: FarmRole.owner,
        hierarchy: loaded.hierarchy,
        map: loaded.map,
        focus: 'section:${liveSection.id}',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('map-section-create-task')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('map-section-create-task')));
    await tester.pumpAndSettle();

    expect(
      find.text('create-stub:zone=null section=${liveSection.id}'),
      findsOneWidget,
    );
  });

  testWidgets('manager creates an independent planting pit for a section',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loaded = await _load(tester);
    final mapSectionIds =
        loaded.map.data.sections.map((section) => section.id).toSet();
    final liveSection = loaded.hierarchy.sections
        .firstWhere((section) => mapSectionIds.contains(section.code));
    final repository = _RecordingPlantingPitRepository();

    await tester.pumpWidget(
      _app(
        role: FarmRole.agriculturalEngineer,
        hierarchy: loaded.hierarchy,
        map: loaded.map,
        focus: 'section:${liveSection.id}',
        plantingPitRepository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('map-section-add-pit')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('planting-pit-create-sheet')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('planting-pit-code-field')),
      'PIT-${liveSection.code}-R01-001',
    );
    await tester.enterText(
      find.byKey(const Key('planting-pit-row-field')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('planting-pit-number-field')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('planting-pit-latitude-field')),
      '28.2951',
    );
    await tester.enterText(
      find.byKey(const Key('planting-pit-longitude-field')),
      '28.75018',
    );
    await tester.ensureVisible(find.byKey(const Key('planting-pit-save')));
    await tester.tap(find.byKey(const Key('planting-pit-save')));
    await tester.pumpAndSettle();

    expect(repository.created, hasLength(1));
    final draft = repository.created.single;
    expect(draft.farmId, CanonicalFarmHierarchyDataSource.farmId);
    expect(draft.sectionId, liveSection.id);
    expect(draft.pitCode, 'PIT-${liveSection.code}-R01-001');
    expect(draft.toInsertJson().containsKey('tree_id'), isFalse);
  });

  testWidgets('worker cannot add a planting pit from the map', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loaded = await _load(tester);
    final mapSectionIds =
        loaded.map.data.sections.map((section) => section.id).toSet();
    final liveSection = loaded.hierarchy.sections
        .firstWhere((section) => mapSectionIds.contains(section.code));

    await tester.pumpWidget(
      _app(
        role: FarmRole.worker,
        hierarchy: loaded.hierarchy,
        map: loaded.map,
        focus: 'section:${liveSection.id}',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('map-section-add-pit')), findsNothing);
  });

  testWidgets('worker can inspect a pit marker without lifecycle controls',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loaded = await _load(tester);
    final pit = loaded.hierarchy.plantingPits.single;

    await tester.pumpWidget(
      _app(
        role: FarmRole.worker,
        hierarchy: loaded.hierarchy,
        map: loaded.map,
        focus: 'section:${pit.sectionId}',
      ),
    );
    await tester.pumpAndSettle();

    // Pit hit-testing comes after valve hit-testing by design. Hide valves so
    // this test targets only the pit marker contract.
    await tester.tap(find.byTooltip('Map layers'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zone valves'));
    await tester.pumpAndSettle();

    final canvasFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is FarmMapPainter,
    );
    final painter =
        tester.widget<CustomPaint>(canvasFinder).painter! as FarmMapPainter;
    final projected = painter.plantingPits.single;
    final canvasBox = tester.renderObject<RenderBox>(canvasFinder);
    await tester.tapAt(canvasBox.localToGlobal(projected.point));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('planting-pit-sheet')), findsOneWidget);
    expect(find.text(pit.pitCode), findsOneWidget);
    expect(find.byKey(const Key('planting-pit-advance')), findsNothing);
    expect(find.byKey(const Key('planting-pit-cancel')), findsNothing);
  });
}

class _RecordingPlantingPitRepository implements PlantingPitRepository {
  final List<PlantingPitDraft> created = <PlantingPitDraft>[];

  @override
  Future<String> create(PlantingPitDraft draft) async {
    created.add(draft);
    return 'created-pit';
  }

  @override
  Future<void> advanceStatus(String pitId, PlantingPitStatus status) async {}

  @override
  Future<void> cancel(String pitId) async {}
}
