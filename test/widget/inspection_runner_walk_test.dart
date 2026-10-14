import 'dart:async';
import 'dart:math' as math;

import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/l10n/locale_controller.dart';
import 'package:al_wahat_farm_flutter/core/location/location_service.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route_planner.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_walk.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_repository_scope.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_runner_screen.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/farm_hierarchy_fixture.dart';

class _Repository implements InspectionRepository {
  _Repository(this.details);

  final InspectionDetails details;
  final saved = <int, List<InspectionTreeResult>>{};

  @override
  Future<InspectionDetails> loadByTask(String taskId) async => details;

  @override
  Future<void> saveStation(
    String sessionId,
    int stationIndex,
    List<InspectionTreeResult> results, {
    String? opId,
    Map<String, PreparedTaskEvidence> photos = const {},
    String? userId,
    String? farmId,
    String? taskId,
  }) async {
    saved[stationIndex] = results;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Location implements LocationService {
  _Location(this.stream);

  final Stream<LocationFix> stream;

  @override
  Stream<LocationFix> watch() => stream;
}

late InspectionRoute _route;

InspectionDetails _detailsAt(int current) {
  final now = DateTime.utc(2026, 10, 14, 8);
  final items = _route.items
      .map(
        (item) => InspectionSessionItem(
          id: 'item-${item.sequenceIndex}',
          sessionId: 'session',
          routeItem: item,
          status: item.stationIndex < current
              ? InspectionItemStatus.inspected
              : InspectionItemStatus.pending,
          noNewIssueFound: item.stationIndex < current,
        ),
      )
      .toList(growable: false);
  return InspectionDetails(
    session: InspectionSession(
      id: 'session',
      farmId: 'farm',
      sectionId: _route.sectionId,
      taskId: 'task-id',
      inspectorProfileId: 'worker',
      createdByProfileId: 'manager',
      startingTreeId: _route.startingTreeId,
      status: InspectionSessionStatus.inProgress,
      routeVersion: 2,
      totalStations: _route.stationCount,
      totalTrees: _route.treeCount,
      inspectedTrees: items
          .where((item) => item.status == InspectionItemStatus.inspected)
          .length,
      requiresIssuePhoto: false,
      revision: 1,
      createdAt: now,
      updatedAt: now,
    ),
    items: items,
  );
}

Widget _app(
  _Repository repository, {
  LocationService location = const DeviceLocationService(),
  LocalCacheStore? store,
  Widget Function(Widget runner)? wrap,
}) {
  final cache = store ?? InMemoryCacheStore();
  return AppServicesScope(
    services: AppServices(
      cacheStore: cache,
      outbox: InMemoryOutboxStore(),
      pendingPhotos: InMemoryPendingPhotoStore(),
      connectivity: ConnectivityController(PlatformConnectivityService()),
      locale: LocaleController(cache),
      persistentStorageAvailable: true,
    ),
    child: InspectionRepositoryScope(
      repository: repository,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: (wrap ?? (runner) => runner)(
          InspectionRunnerScreen(taskId: 'task-id', location: location),
        ),
      ),
    ),
  );
}

void main() {
  late InspectionWalk walk;
  late int aisleThree;

  setUpAll(() async {
    final snapshot = await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId);
    _route = const InspectionRoutePlanner().plan(
      section: snapshot.hierarchy.sectionByCode('A')!,
      trees: snapshot.hierarchy.trees,
    );
    walk = InspectionWalk(_route.items);
    aisleThree = walk.stations.firstWhere((s) => walk.aisleOf(s) == 3);
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows where the station is and saves a healthy pair in one tap',
      (tester) async {
    phone(tester);
    final repository = _Repository(_detailsAt(aisleThree));
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    final step = walk.step(aisleThree);
    expect(find.byKey(const Key('inspection-walk-map')), findsOneWidget);
    expect(
      find.text('Aisle 3 of 8 · station 1 of ${step.stationsInAisle} '
          'in this aisle'),
      findsOneWidget,
    );
    expect(
      find.text('New aisle: turn around and walk the other way, between rows '
          '${step.rows[0]} and ${step.rows[1]}.'),
      findsOneWidget,
    );
    expect(
      find.text('Next: ${step.next.map((item) => item.treeCode).join(' · ')}'),
      findsOneWidget,
    );
    expect(find.text('Healthy'), findsNWidgets(2));
    // Raw coordinates are no longer shown to the inspector.
    expect(find.textContaining('28.29'), findsNothing);

    await tester.tap(find.text('All healthy · next'));
    await tester.pumpAndSettle();

    final saved = repository.saved[aisleThree]!;
    expect(saved, hasLength(2));
    expect(saved.every((result) => result.noNewIssueFound), isTrue);
  });

  testWidgets('physical left stays on the left in Arabic', (tester) async {
    phone(tester);
    final repository = _Repository(_detailsAt(aisleThree + 4));
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    final step = walk.step(aisleThree + 4);
    final left = step.items.first.treeCode;
    final right = step.items.last.treeCode;

    double x(String text) => tester.getCenter(find.text(text)).dx;
    expect(x(left), lessThan(x(right)));

    final arabic = _Repository(_detailsAt(aisleThree + 4));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InspectionRepositoryScope(
          repository: arabic,
          child: const InspectionRunnerScreen(taskId: 'task-id'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(x(left), lessThan(x(right)));
  });

  testWidgets('reporting an issue opens the editor and changes the save label',
      (tester) async {
    phone(tester);
    final station = aisleThree + 2;
    final repository = _Repository(_detailsAt(station));
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    final left = walk.step(station).items.first;

    await tester.tap(find.byKey(Key('inspection-report-${left.treeId}')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('inspection-editor-${left.treeId}')), findsOneWidget);

    final chip = find.widgetWithText(FilterChip, 'Tree damage');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await tester.tap(find.text('High'));
    await tester.pumpAndSettle();

    expect(find.text('1 issue'), findsOneWidget);
    expect(find.text('All healthy · next'), findsNothing);
    final severity = find.byKey(
      Key('inspection-severity-${left.treeId}-tree_damage'),
    );
    expect(
      find.descendant(of: severity, matching: find.text('High')),
      findsOneWidget,
    );

    // Change the severity in place.
    await tester.ensureVisible(severity);
    await tester.tap(severity);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Low').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save station and continue'));
    await tester.pumpAndSettle();
    final result = repository.saved[station]!
        .firstWhere((result) => result.treeId == left.treeId);
    expect(result.noNewIssueFound, isFalse);
    expect(result.selectedIssues.single.type, TreeIssueType.treeDamage);
    expect(result.selectedIssues.single.severity, IssueSeverity.low);
  });

  testWidgets('location guidance turns on, is remembered, and explains denial',
      (tester) async {
    phone(tester);
    final station = aisleThree + 6;
    final center = walk.centerOf(station)!;
    final store = InMemoryCacheStore();
    final fixes = StreamController<LocationFix>.broadcast();
    addTearDown(fixes.close);
    final repository = _Repository(_detailsAt(station));
    await tester.pumpWidget(
      _app(repository, location: _Location(fixes.stream), store: store),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inspection-location-text')), findsNothing);

    await tester.tap(find.byKey(const Key('inspection-location-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Finding your location…'), findsOneWidget);
    expect(
        await tester.runAsync(
          () => store.read(LocationPreference.storageKey),
        ),
        'true');

    fixes.add(LocationFix(
      latitude: center.latitude,
      longitude: center.longitude,
      accuracyMeters: 4,
    ));
    await tester.pumpAndSettle();
    expect(find.text('You are at this station (GPS ±4 m).'), findsOneWidget);

    fixes.addError(const LocationUnavailable(LocationUnavailableReason.denied));
    await tester.pumpAndSettle();
    expect(
      find.text('Location is blocked. Allow it for this app in the phone '
          'settings.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('inspection-location-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inspection-location-text')), findsNothing);
    expect(
        await tester.runAsync(
          () => store.read(LocationPreference.storageKey),
        ),
        isNull);
  });

  testWidgets('the full map opens a saved station and blocks skipping ahead',
      (tester) async {
    phone(tester);
    final station = aisleThree + 1;
    final repository = _Repository(_detailsAt(station));
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('inspection-open-map')));
    await tester.pumpAndSettle();
    expect(find.text('Inspection map'), findsOneWidget);
    expect(find.text('Current station'), findsOneWidget);

    final map = find.byKey(const Key('inspection-walk-map-full'));
    final box = tester.getRect(map);

    final located = _route.items;
    final latitudes = located.map((item) => item.latitude!).toList();
    final longitudes = located.map((item) => item.longitude!).toList();
    // The page projects with one uniform scale; mirror it to find trees.
    Offset project(InspectionRouteItem item) {
      double mean(List<double> values) =>
          values.reduce((a, b) => a + b) / values.length;
      final lat0 = mean(latitudes);
      final lng0 = mean(longitudes);
      final cosine = math.cos(lat0 * math.pi / 180);
      final xs =
          located.map((i) => (i.longitude! - lng0) * cosine * 111320).toList();
      final ys = located.map((i) => (i.latitude! - lat0) * 111320).toList();
      final minX = xs.reduce((a, b) => a < b ? a : b);
      final maxX = xs.reduce((a, b) => a > b ? a : b);
      final minY = ys.reduce((a, b) => a < b ? a : b);
      final maxY = ys.reduce((a, b) => a > b ? a : b);
      final width = maxX - minX;
      final height = maxY - minY;
      final scale = math.min(
        (box.width - 32) / width,
        (box.height - 32) / height,
      );
      final ox = (box.width - width * scale) / 2 - minX * scale;
      final oy = (box.height + height * scale) / 2 + minY * scale;
      final x = (item.longitude! - lng0) * cosine * 111320;
      final y = (item.latitude! - lat0) * 111320;
      return box.topLeft + Offset(ox + x * scale, oy - y * scale);
    }

    final earlier = project(walk.station(station - 3).first);
    final later = project(walk.station(station + 20).first);

    await tester.tapAt(later);
    await tester.pump();
    expect(
      find.text('Finish station $station first. Stations are saved in '
          'walking order.'),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tapAt(earlier);
    await tester.pumpAndSettle();
    expect(find.text('Inspection map'), findsNothing);
    expect(find.text('Station ${station - 3} of 153'), findsOneWidget);
  });

  testWidgets('the action bar stays above the floating navigation bar',
      (tester) async {
    phone(tester);
    final repository = _Repository(_detailsAt(aisleThree));
    await tester.pumpWidget(_app(
      repository,
      // Mirrors AppShell: tabs draw under a floating bar (extendBody).
      wrap: (runner) => Scaffold(
        extendBody: true,
        body: runner,
        bottomNavigationBar: const SizedBox(height: 96),
      ),
    ));
    await tester.pumpAndSettle();

    final save = tester.getRect(find.byKey(const Key('inspection-save-next')));
    expect(save.bottom, lessThanOrEqualTo(932 - 96));
  });

  testWidgets('a manager watching another inspector sees the walk map',
      (tester) async {
    phone(tester);
    final repository = _Repository(_detailsAt(aisleThree + 3));
    final operational = OperationalContext(
      profile:
          const UserProfile(id: 'manager', fullName: 'Manager', isActive: true),
      memberships: const <FarmMembership>[
        FarmMembership(
          id: 'membership',
          profileId: 'manager',
          role: FarmRole.owner,
          isActive: true,
          farm: FarmSummary(
            id: 'farm',
            name: 'Al Wahat',
            code: 'AL-WAHAT',
            timezone: 'Africa/Cairo',
          ),
        ),
      ],
    );
    await tester.pumpWidget(OperationalContextScope(
      contextData: operational,
      child: _app(repository),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inspection-takeover')), findsOneWidget);
    expect(find.byKey(const Key('inspection-walk-map')), findsOneWidget);
    expect(find.byKey(const Key('inspection-save-next')), findsNothing);
  });
}
