import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_controller.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedule_form_screen.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_controller.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/inventory_fakes.dart';
import '../support/schedule_fakes.dart';

final _epoch = DateTime(2026);

final _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: <FarmSection>[
    FarmSection(
      id: 'section-1',
      farmId: 'farm-id',
      code: 'S1',
      name: 'Section One',
      sortOrder: 1,
      isActive: true,
      createdAt: _epoch,
      updatedAt: _epoch,
    ),
  ],
  zones: <IrrigationZone>[
    IrrigationZone(
      id: 'zone-1',
      sectionId: 'section-1',
      code: 'Z1',
      name: 'Zone One',
      isActive: true,
      createdAt: _epoch,
      updatedAt: _epoch,
    ),
    IrrigationZone(
      id: 'zone-2',
      sectionId: 'section-1',
      code: 'Z2',
      name: 'Zone Two',
      isActive: true,
      createdAt: _epoch,
      updatedAt: _epoch,
    ),
  ],
  trees: <FarmTreeRecord>[
    // 60 trees in zone-1 (one feddan) and 30 in zone-2 (half a feddan).
    for (var i = 0; i < 60; i++)
      FarmTreeRecord(
        id: 'tree-a-$i',
        farmId: 'farm-id',
        sectionId: 'section-1',
        irrigationZoneId: 'zone-1',
        treeCode: 'TREE-A-$i',
        healthStatus: TreeHealthStatus.healthy,
        type: 'date_palm',
        isActive: true,
        createdAt: _epoch,
        updatedAt: _epoch,
      ),
    for (var i = 0; i < 30; i++)
      FarmTreeRecord(
        id: 'tree-b-$i',
        farmId: 'farm-id',
        sectionId: 'section-1',
        irrigationZoneId: 'zone-2',
        treeCode: 'TREE-B-$i',
        healthStatus: TreeHealthStatus.healthy,
        type: 'date_palm',
        isActive: true,
        createdAt: _epoch,
        updatedAt: _epoch,
      ),
  ],
);

Widget _app({
  required SchedulesController controller,
  required InventoryController inventory,
}) {
  final operational = OperationalContext(
    profile: const UserProfile(
      id: 'manager-id',
      fullName: 'Manager',
      isActive: true,
    ),
    memberships: <FarmMembership>[
      const FarmMembership(
        id: 'membership',
        profileId: 'manager-id',
        role: FarmRole.owner,
        isActive: true,
        farm: FarmSummary(
          id: 'farm-id',
          name: 'Al Wahat',
          code: 'AL-WAHAT',
          timezone: 'Africa/Cairo',
        ),
      ),
    ],
  );
  return OperationalContextScope(
    contextData: operational,
    child: FarmHierarchyScope(
      snapshot: FarmHierarchySnapshot(
        hierarchy: _hierarchy,
        source: FarmHierarchySource.network,
      ),
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          initialLocation: '/form',
          routes: <RouteBase>[
            GoRoute(
              path: '/form',
              builder: (_, __) => Scaffold(
                body: ScheduleFormScreen(
                  controller: controller,
                  inventoryController: inventory,
                ),
              ),
            ),
            GoRoute(
              path: '/more/schedules/:planId',
              builder: (_, GoRouterState state) => Scaffold(
                body: Text('detail-stub:${state.pathParameters['planId']}'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('form previews repetitions, totals, grouping and the live review',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scheduleRepo = FakeScheduleRepository();
    final controller =
        SchedulesController(repository: scheduleRepo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    final inventoryRepo = FakeInventoryRepository();
    final fertilizer =
        inventoryRepo.seedCategory('fertilizer', appliesTo: 'fertilization');
    inventoryRepo.seedItem('Calcium', categoryId: fertilizer, quantity: 35);
    final inventory =
        InventoryController(repository: inventoryRepo, farmId: 'farm-id');
    addTearDown(inventory.dispose);

    await tester.pumpWidget(
      _app(controller: controller, inventory: inventory),
    );
    await tester.pumpAndSettle();

    // `once` recurrence: exactly one run, no end date needed up front.
    await tester.tap(find.byKey(const Key('schedule-recurrence-once')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('schedule-repetitions')), findsOneWidget);
    expect(find.text('Runs once'), findsWidgets);

    // Fertilization + both zones (90 trees = 1.5 feddan).
    await tester.tap(find.byKey(const Key('schedule-type-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fertilization').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('schedule-title-field')),
      'Feed both zones',
    );
    tester.testTextInput.hide();
    await tester.tap(find.byKey(const Key('schedule-target-zones')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-zone-Z1')));
    await tester.pumpAndSettle();
    // One target: no grouping choice yet.
    expect(
      find.byKey(const Key('schedule-grouping-combined')),
      findsNothing,
    );
    await tester.tap(find.byKey(const Key('schedule-zone-Z2')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('schedule-grouping-combined')),
      findsOneWidget,
    );

    // Product: 10 kg... (10 units) per feddan -> 15 per run, 35 in stock.
    await tester.scrollUntilVisible(
      find.byKey(const Key('schedule-product-field')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('schedule-product-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Calcium').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('schedule-rate-field')),
      '10',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();

    // Whole-schedule projection: 15 x 1 run, 35 available -> 20 left.
    await tester.scrollUntilVisible(
      find.byKey(const Key('schedule-total-required')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('schedule-total-required')), findsOneWidget);
    expect(find.byKey(const Key('schedule-remaining')), findsOneWidget);
    expect(find.byKey(const Key('schedule-shortage')), findsNothing);

    // Combined grouping halves nothing but the task count.
    await tester.scrollUntilVisible(
      find.byKey(const Key('schedule-grouping-combined')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('schedule-grouping-combined')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('schedule-review')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('1 task will be created in total'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('schedule-review-grouping')), findsOneWidget);

    // Submit stores the combined grouping on the plan.
    await tester.scrollUntilVisible(
      find.byKey(const Key('schedule-create-button')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    tester
        .widget<FilledButton>(find.byKey(const Key('schedule-create-button')))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(scheduleRepo.plans, hasLength(1));
    expect(scheduleRepo.plans.single.taskGrouping, TaskGrouping.combined);
    expect(scheduleRepo.plans.single.endsOn, isNotNull);
  });

  testWidgets('daily schedules cannot be created without an end date',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scheduleRepo = FakeScheduleRepository();
    final controller =
        SchedulesController(repository: scheduleRepo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    final inventory = InventoryController(
      repository: FakeInventoryRepository(),
      farmId: 'farm-id',
    );
    addTearDown(inventory.dispose);

    await tester.pumpWidget(
      _app(controller: controller, inventory: inventory),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('schedule-title-field')),
      'Daily watering',
    );
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.byKey(const Key('schedule-create-button')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    tester
        .widget<FilledButton>(find.byKey(const Key('schedule-create-button')))
        .onPressed!();
    await tester.pumpAndSettle();

    expect(
      find.text('Choose an end date — schedules need one'),
      findsOneWidget,
    );
    expect(scheduleRepo.plans, isEmpty);
  });

  testWidgets('weekly every 2 weeks: readable days, pattern and all workers',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = SchedulesController(
      repository: FakeScheduleRepository(),
      farmId: 'farm-id',
    );
    addTearDown(controller.dispose);
    final inventory = InventoryController(
      repository: FakeInventoryRepository(),
      farmId: 'farm-id',
    );
    addTearDown(inventory.dispose);

    await tester.pumpWidget(
      _app(controller: controller, inventory: inventory),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('schedule-recurrence-weekly')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-weekday-3')));
    await tester.pumpAndSettle();

    // A selected day is filled dark green, so its word must be white.
    final dayText = tester.widget<RichText>(find.descendant(
      of: find.byKey(const Key('schedule-weekday-3')),
      matching: find.byType(RichText),
    ));
    expect(dayText.text.style?.color, Colors.white);

    await tester.tap(find.byKey(const Key('schedule-repeat-every')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Every 2 weeks').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('schedule-review')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    final repeat = tester.widget<Text>(
      find.byKey(const Key('schedule-review-repeat')),
    );
    expect(repeat.data, startsWith('Every 2 weeks · '));
    expect(
      tester
          .widget<Text>(find.byKey(const Key('schedule-review-workers')))
          .data,
      'All workers',
    );
    expect(find.byKey(const Key('schedule-all-workers-hint')), findsOneWidget);
  });

  testWidgets('zones are grouped by section with "all zones"', (tester) async {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = SchedulesController(
      repository: FakeScheduleRepository(),
      farmId: 'farm-id',
    );
    addTearDown(controller.dispose);
    final inventory = InventoryController(
      repository: FakeInventoryRepository(),
      farmId: 'farm-id',
    );
    addTearDown(inventory.dispose);

    await tester.pumpWidget(
      _app(controller: controller, inventory: inventory),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('schedule-target-zones')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('schedule-target-zones')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('schedule-zone-section-S1')));
    await tester.pumpAndSettle();
    for (final code in <String>['Z1', 'Z2']) {
      expect(
        tester
            .widget<FilterChip>(find.byKey(Key('schedule-zone-$code')))
            .selected,
        isTrue,
      );
    }
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.byKey(const Key('schedule-zone-section-S1')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilterChip>(find.byKey(const Key('schedule-zone-Z1')))
          .selected,
      isFalse,
    );
  });
}
