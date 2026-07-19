import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_controller.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_controller.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/inventory_fakes.dart';
import '../support/schedule_fakes.dart';
import '../support/task_fakes.dart';

/// M8 certification goldens for the inventory / schedules / multi-target
/// surfaces added by the inventory-and-scheduling plan.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader('Inter')
          ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf')))
        .load();
    await (FontLoader('LibreBaskerville')
          ..addFont(
            rootBundle.load('assets/fonts/LibreBaskerville-Variable.ttf'),
          ))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  testWidgets('inventory list at 390 by 844', (tester) async {
    _setSize(tester, const Size(390, 844));
    final repo = FakeInventoryRepository();
    final fertilizer = repo.seedCategory('fertilizer');
    final pesticide = repo.seedCategory('pesticide');
    repo.seedItem('Calcium nitrate',
        categoryId: fertilizer, quantity: 5, minimumStock: 10);
    repo.seedItem('Urea 46%', categoryId: fertilizer, quantity: 120);
    repo.seedItem('Neem oil', categoryId: pesticide, quantity: 18);
    final controller = InventoryController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: InventoryScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/inventory_list_390x844.png'),
    );
  });

  testWidgets('schedules list at 390 by 844', (tester) async {
    _setSize(tester, const Size(390, 844));
    final repo = FakeScheduleRepository();
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.fertilization,
      title: 'Friday calcium feed',
      scheduleType: PlanScheduleType.weekly,
      startsOn: DateTime(2026, 8, 1),
      daysOfWeek: const <int>[5],
      scheduledStartTime: '08:00:00',
      status: OperationPlanStatus.active,
    ));
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.irrigation,
      title: 'Daily watering',
      scheduleType: PlanScheduleType.daily,
      startsOn: DateTime(2026, 8, 1),
      status: OperationPlanStatus.paused,
    ));
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    await controller.load();

    await tester.pumpWidget(
      _managerScope(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: SchedulesScreen(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SchedulesScreen),
      matchesGoldenFile('../goldens/schedules_list_390x844.png'),
    );
  });

  testWidgets('multi-target task detail at 390 by 844', (tester) async {
    _setSize(tester, const Size(390, 844));
    final store = InMemoryTaskStore();
    final manager = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final taskId = await manager.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.fertilization,
        title: 'Feed zones one and two',
        scheduledFor: DateTime(2026, 7, 24),
        targets: const <TaskTarget>[
          TaskTarget(irrigationZoneId: 'zone-1'),
          TaskTarget(irrigationZoneId: 'zone-2'),
        ],
        assigneeProfileIds: const <String>['worker-id'],
      ),
    );
    final controller = TaskDetailController(
      repository: manager,
      evidencePicker: FakeTaskEvidencePicker(),
      evidenceStorage: FakeTaskEvidenceStorage(),
      taskId: taskId,
      farmId: 'farm-id',
      userId: 'manager-id',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: TaskDetailScreen(
          taskId: taskId,
          controller: controller,
          hierarchy: _hierarchy,
          role: FarmRole.owner,
          userId: 'manager-id',
          farmId: 'farm-id',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/task_detail_targets_390x844.png'),
    );
  });
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _managerScope(Widget child) => OperationalContextScope(
      contextData: OperationalContext(
        profile: const UserProfile(
          id: 'manager-id',
          fullName: 'Farm Manager',
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
      ),
      child: child,
    );

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
  trees: const <FarmTreeRecord>[],
);
