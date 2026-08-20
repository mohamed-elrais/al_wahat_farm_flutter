import 'dart:io';
import 'dart:ui' as ui;

import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/widgets/app_shell.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_controller.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:al_wahat_farm_flutter/features/map/data/map_asset_repository.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_controller.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/tasks_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/inventory_fakes.dart';
import '../support/schedule_fakes.dart';
import '../support/task_fakes.dart';

/// App Store screenshot generator. A no-op in normal test runs; produces
/// PNGs at Apple's exact required sizes when enabled:
///
///   flutter test --dart-define=STORE_SHOTS=true \
///     test/tools/store_screenshots_test.dart
///
/// Output: store_screenshots/iphone_65/*.png (1284x2778) and
/// store_screenshots/ipad_13/*.png (2048x2732).
const bool _enabled = bool.fromEnvironment('STORE_SHOTS');

const _rootKey = Key('store-shot-root');

void main() {
  setUpAll(() async {
    if (!_enabled) return;
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

  testWidgets('generate store screenshots', (tester) async {
    if (!_enabled) return;

    final devices = <({String dir, Size logical, double dpr})>[
      (dir: 'iphone_65', logical: const Size(428, 926), dpr: 3),
      (dir: 'ipad_13', logical: const Size(1024, 1366), dpr: 2),
    ];

    final map = await tester.runAsync(
      () => const MapAssetRepository().load().then(ProjectedFarmMap.new),
    );

    for (final device in devices) {
      tester.view.physicalSize = device.logical * device.dpr;
      tester.view.devicePixelRatio = device.dpr;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _shoot(
        tester,
        device,
        'tasks',
        _shell(index: 3, child: _tasksScreen()),
      );
      await _shoot(
        tester,
        device,
        'schedules',
        _shell(index: 4, child: _schedulesScreen()),
      );
      await _shoot(
        tester,
        device,
        'inventory',
        _shell(index: 4, child: _inventoryScreen()),
      );
      await _shoot(
        tester,
        device,
        'map',
        _shell(
          index: 1,
          child: FarmMapScreen(
            mapFuture: Future<ProjectedFarmMap>.value(map!),
          ),
        ),
      );
    }
  });
}

Future<void> _shoot(
  WidgetTester tester,
  ({String dir, Size logical, double dpr}) device,
  String name,
  Widget app,
) async {
  await tester.pumpWidget(RepaintBoundary(key: _rootKey, child: app));
  await tester.pumpAndSettle();
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_rootKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: device.dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('store_screenshots/${device.dir}/$name.png')
      ..createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${file.path} (${image.width}x${image.height})');
  });
  // Reset the tree between shots so controllers dispose cleanly.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

/// Shell chrome (top bar + floating navigation) around a section screen so
/// the screenshots look exactly like the running app.
Widget _shell({required int index, required Widget child}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: OperationalContextScope(
        contextData: _operational,
        child: Scaffold(
          extendBody: true,
          bottomNavigationBar:
              WahatNavigation(index: index, onSelected: (_) {}),
          body: Column(
            children: <Widget>[
              const WahatTopBar(),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );

final _operational = OperationalContext(
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
);

final _epoch = DateTime(2026, 8);

final _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: <FarmSection>[
    for (final code in <String>['A', 'B', 'C'])
      FarmSection(
        id: 'section-$code',
        farmId: 'farm-id',
        code: code,
        name: 'Section $code',
        sortOrder: code.codeUnitAt(0),
        isActive: true,
        createdAt: _epoch,
        updatedAt: _epoch,
      ),
  ],
  zones: <IrrigationZone>[
    for (var i = 1; i <= 4; i++)
      IrrigationZone(
        id: 'zone-$i',
        sectionId: 'section-A',
        code: 'ZCV-A-0$i',
        name: 'Zone A$i',
        isActive: true,
        createdAt: _epoch,
        updatedAt: _epoch,
      ),
  ],
  trees: const <FarmTreeRecord>[],
);

Widget _tasksScreen() {
  final store = InMemoryTaskStore();
  final manager = FakeTaskRepository(
    store: store,
    viewerProfileId: 'manager-id',
    canManage: true,
  );
  final drafts = <TaskDraft>[
    TaskDraft(
      farmId: 'farm-id',
      type: TaskType.irrigation,
      title: 'Open the north irrigation valve',
      sectionId: 'section-A',
      scheduledFor: DateTime(2026, 8, 3),
      plannedStartTime: '06:30:00',
      assigneeProfileIds: const <String>['worker-id'],
    ),
    TaskDraft(
      farmId: 'farm-id',
      type: TaskType.fertilization,
      title: 'Calcium feed for zones A1 and A2',
      targets: const <TaskTarget>[
        TaskTarget(irrigationZoneId: 'zone-1'),
        TaskTarget(irrigationZoneId: 'zone-2'),
      ],
      scheduledFor: DateTime(2026, 8, 3),
      plannedStartTime: '08:00:00',
      priority: TaskPriority.high,
      assigneeProfileIds: const <String>['worker-id'],
    ),
    TaskDraft(
      farmId: 'farm-id',
      type: TaskType.pestControl,
      title: 'Inspect and spray Section B palms',
      sectionId: 'section-B',
      scheduledFor: DateTime(2026, 8, 3),
      assigneeProfileIds: const <String>['worker-id'],
    ),
    TaskDraft(
      farmId: 'farm-id',
      type: TaskType.treeInspection,
      title: 'Weekly inspection walk, Section C',
      sectionId: 'section-C',
      scheduledFor: DateTime(2026, 8, 3),
    ),
  ];
  for (final draft in drafts) {
    manager.create(draft);
  }
  final workspace = TaskWorkspaceController(
    repository: manager,
    farmId: 'farm-id',
  );
  workspace.load();
  return TasksScreen(
    controller: workspace,
    role: FarmRole.owner,
    hierarchy: _hierarchy,
    now: () => DateTime(2026, 8, 3),
  );
}

Widget _schedulesScreen() {
  final repo = FakeScheduleRepository();
  repo.createPlan(OperationPlanDraft(
    farmId: 'farm-id',
    type: OperationPlanType.fertilization,
    title: 'Friday calcium feed',
    scheduleType: PlanScheduleType.weekly,
    startsOn: DateTime(2026, 8, 3),
    endsOn: DateTime(2026, 8, 28),
    daysOfWeek: const <int>[5],
    scheduledStartTime: '08:00:00',
    status: OperationPlanStatus.active,
    targets: const <PlanTarget>[
      PlanTarget(irrigationZoneId: 'zone-1'),
      PlanTarget(irrigationZoneId: 'zone-2'),
    ],
    taskGrouping: TaskGrouping.combined,
  ));
  repo.createPlan(OperationPlanDraft(
    farmId: 'farm-id',
    type: OperationPlanType.irrigation,
    title: 'Daily morning irrigation',
    scheduleType: PlanScheduleType.daily,
    startsOn: DateTime(2026, 8, 3),
    endsOn: DateTime(2026, 8, 31),
    scheduledStartTime: '06:00:00',
    status: OperationPlanStatus.active,
  ));
  repo.createPlan(OperationPlanDraft(
    farmId: 'farm-id',
    type: OperationPlanType.pestControl,
    title: 'Section B pest spray round',
    scheduleType: PlanScheduleType.weekly,
    startsOn: DateTime(2026, 8, 3),
    endsOn: DateTime(2026, 8, 30),
    daysOfWeek: const <int>[1, 4],
    status: OperationPlanStatus.paused,
  ));
  final controller = SchedulesController(repository: repo, farmId: 'farm-id');
  controller.load();
  return SchedulesScreen(controller: controller);
}

Widget _inventoryScreen() {
  final repo = FakeInventoryRepository();
  final fertilizer =
      repo.seedCategory('fertilizer', appliesTo: 'fertilization');
  final pesticide = repo.seedCategory('pesticide', appliesTo: 'pest_control');
  final tools = repo.seedCategory('tool');
  repo.seedItem('Calcium nitrate',
      categoryId: fertilizer,
      quantity: 310,
      minimumStock: 100,
      unit: InventoryUnit.liter);
  repo.seedItem('NPK 20-20-20',
      categoryId: fertilizer,
      quantity: 45,
      minimumStock: 60,
      unit: InventoryUnit.kilogram);
  repo.seedItem('Neem oil',
      categoryId: pesticide,
      quantity: 294.4,
      minimumStock: 50,
      unit: InventoryUnit.liter);
  repo.seedItem('Pruning saws', categoryId: tools, quantity: 12);
  final controller = InventoryController(repository: repo, farmId: 'farm-id');
  controller.load();
  return InventoryScreen(controller: controller);
}
