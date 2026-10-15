import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_controller.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/plan_run.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedule_detail_screen.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedule_form_screen.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
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
  zones: const <IrrigationZone>[],
  trees: const <FarmTreeRecord>[],
);

/// A weekly schedule that started before today (it is already running).
OperationPlan _plan({String? itemId}) {
  final today = DateUtils.dateOnly(DateTime.now());
  return OperationPlan(
    id: 'plan-1',
    farmId: 'farm-id',
    type: itemId == null
        ? OperationPlanType.irrigation
        : OperationPlanType.fertilization,
    title: 'Wednesday feed',
    status: OperationPlanStatus.active,
    scheduleType: PlanScheduleType.weekly,
    startsOn: today.subtract(const Duration(days: 20)),
    endsOn: today.add(const Duration(days: 60)),
    daysOfWeek: const <int>[3],
    repeatEvery: 2,
    plannedDurationMinutes: 30,
    targets: const <PlanTarget>[PlanTarget(sectionId: 'section-1')],
    defaultAssigneeProfileIds: const <String>[],
    inventoryItemId: itemId,
    applicationRate: itemId == null ? null : 100,
    rateBasis: itemId == null ? null : RateBasis.perFeddan,
    rateUnit: itemId == null ? null : InventoryUnit.gram,
  );
}

Widget _app(
  SchedulesController controller,
  InventoryController inventory, {
  String initial = '/more/schedules/plan-1',
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
          initialLocation: initial,
          routes: <RouteBase>[
            GoRoute(
              path: '/more/schedules',
              builder: (_, __) => const Scaffold(body: Text('list-stub')),
              routes: <RouteBase>[
                GoRoute(
                  path: ':planId',
                  builder: (_, state) => Scaffold(
                    body: ScheduleDetailScreen(
                      planId: state.pathParameters['planId']!,
                      controller: controller,
                      inventoryController: inventory,
                    ),
                  ),
                  routes: <RouteBase>[
                    GoRoute(
                      path: 'edit',
                      builder: (_, state) => Scaffold(
                        body: ScheduleFormScreen(
                          planId: state.pathParameters['planId'],
                          controller: controller,
                          inventoryController: inventory,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/tasks/:taskId',
              builder: (_, state) => Scaffold(
                body: Text('task-stub:${state.pathParameters['taskId']}'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('shows the pattern, workers, dose and what each run did',
      (tester) async {
    _tall(tester);
    final inventoryRepo = FakeInventoryRepository();
    final category =
        inventoryRepo.seedCategory('fertilizer', appliesTo: 'fertilization');
    final itemId = inventoryRepo.seedItem('Calcium nitrate',
        categoryId: category, quantity: 500);
    final repo = FakeScheduleRepository()..plans.add(_plan(itemId: itemId));
    repo.runs['plan-1'] = <PlanRunDay>[
      PlanRunDay(
        date: DateTime(2026, 10, 21),
        tasks: const <PlanRunTask>[
          PlanRunTask(taskId: 'task-1', status: TaskStatus.completed),
        ],
        blockedForStock: false,
      ),
      PlanRunDay(
        date: DateTime(2026, 10, 7),
        tasks: const <PlanRunTask>[],
        blockedForStock: true,
      ),
    ];
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    final inventory =
        InventoryController(repository: inventoryRepo, farmId: 'farm-id');
    addTearDown(inventory.dispose);

    await tester.pumpWidget(_app(controller, inventory));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Text>(find.byKey(const Key('schedule-detail-summary')))
          .data,
      startsWith('Every 2 weeks · '),
    );
    expect(find.text('30 minutes'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('schedule-detail-workers')))
          .data,
      'All workers',
    );
    expect(find.text('Calcium nitrate'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('schedule-detail-dose'))).data,
      '100 Grams · Per feddan',
    );
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Skipped: not enough stock'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('task-stub:task-1'), findsOneWidget);
  });

  testWidgets('archiving asks first', (tester) async {
    _tall(tester);
    final repo = FakeScheduleRepository()..plans.add(_plan());
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    final inventory = InventoryController(
      repository: FakeInventoryRepository(),
      farmId: 'farm-id',
    );
    addTearDown(inventory.dispose);

    await tester.pumpWidget(_app(controller, inventory));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('schedule-archive')));
    await tester.pumpAndSettle();
    expect(find.text('Archive this schedule?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.plans.single.status, OperationPlanStatus.active);

    await tester.tap(find.byKey(const Key('schedule-archive')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-archive-confirm')));
    await tester.pumpAndSettle();
    expect(repo.plans.single.status, OperationPlanStatus.archived);
    expect(find.text('list-stub'), findsOneWidget);
  });

  testWidgets('editing a running schedule keeps its start date and targets',
      (tester) async {
    _tall(tester);
    final repo = FakeScheduleRepository()..plans.add(_plan());
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    final inventory = InventoryController(
      repository: FakeInventoryRepository(),
      farmId: 'farm-id',
    );
    addTearDown(inventory.dispose);

    await tester.pumpWidget(_app(controller, inventory));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('schedule-edit')));
    await tester.pumpAndSettle();

    expect(find.text('Edit schedule'), findsOneWidget);
    expect(find.text('Wednesday feed'), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('schedule-title-field')),
      'Wednesday water',
    );
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.byKey(const Key('schedule-create-button')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Save changes'), findsOneWidget);
    tester
        .widget<FilledButton>(find.byKey(const Key('schedule-create-button')))
        .onPressed!();
    await tester.pumpAndSettle();

    final call = repo.editCalls.single;
    expect(call['p_title'], 'Wednesday water');
    // Unchanged: no start date (it is in the past) and no target rewrite.
    expect(call['p_starts_on'], isNull);
    expect(call['p_replace_targets'], isFalse);
    expect(call['p_repeat_every'], 2);
    expect(repo.plans.single.title, 'Wednesday water');
  });
}
