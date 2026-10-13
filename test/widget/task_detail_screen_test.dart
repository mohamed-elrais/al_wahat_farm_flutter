import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_photo_viewer.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/task_fakes.dart';

void main() {
  testWidgets('plain tree task retains normal actions without guided runner',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryTaskStore();
    final manager = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final taskId = await manager.create(
      const TaskDraft(
        farmId: 'farm-id',
        type: TaskType.treeInspection,
        title: 'Invalid generic inspection',
        sectionId: 'section-1',
        assigneeProfileIds: <String>['worker-id'],
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

    await tester.scrollUntilVisible(
      find.byKey(const Key('create-valid-inspection-button')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
        find.byKey(const Key('open-inspection-runner-button')), findsNothing);
    expect(find.byKey(const Key('create-valid-inspection-button')),
        findsOneWidget);
    expect(find.byKey(const Key('task-start-button')), findsOneWidget);
  });

  testWidgets('guided tree inspection opens only the dedicated runner',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryTaskStore();
    final manager = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final taskId = await manager.create(
      const TaskDraft(
        farmId: 'farm-id',
        type: TaskType.treeInspection,
        title: 'Guided inspection',
        sectionId: 'section-1',
        instructions: <String, Object?>{'inspection_route_version': 1},
        assigneeProfileIds: <String>['worker-id'],
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

    await tester.scrollUntilVisible(
      find.byKey(const Key('open-inspection-runner-button')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const Key('open-inspection-runner-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('task-start-button')), findsNothing);
    expect(find.byKey(const Key('task-complete-button')), findsNothing);
  });

  testWidgets('assigned worker starts task and activity refreshes',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryTaskStore();
    final taskId = await FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    ).create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.irrigation,
        title: 'Open north valve',
        scheduledFor: DateTime(2026, 7, 13),
        assigneeProfileIds: const <String>['worker-id'],
      ),
    );
    final worker = FakeTaskRepository(
      store: store,
      viewerProfileId: 'worker-id',
      canManage: false,
    );
    final controller = TaskDetailController(
      repository: worker,
      evidencePicker: FakeTaskEvidencePicker(),
      evidenceStorage: FakeTaskEvidenceStorage(),
      taskId: taskId,
      farmId: 'farm-id',
      userId: 'worker-id',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TaskDetailScreen(
          taskId: taskId,
          controller: controller,
          hierarchy: _hierarchy,
          role: FarmRole.worker,
          userId: 'worker-id',
          farmId: 'farm-id',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assigned'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('task-start-button')));
    await tester.tap(find.byKey(const Key('task-start-button')));
    await tester.pumpAndSettle();

    expect(controller.details!.task.status, TaskStatus.inProgress);
    await tester.scrollUntilVisible(
      find.text('In progress'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('In progress'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Work started'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Work started'), findsOneWidget);
    expect(find.byKey(const Key('task-edit-assignments-button')), findsNothing);
  });

  testWidgets('multi-target task lists every target as a chip', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryTaskStore();
    final manager = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final taskId = await manager.create(
      const TaskDraft(
        farmId: 'farm-id',
        type: TaskType.fertilization,
        title: 'Feed both zones',
        targets: <TaskTarget>[
          TaskTarget(irrigationZoneId: 'zone-1'),
          TaskTarget(irrigationZoneId: 'zone-2'),
        ],
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

    final router = GoRouter(
      initialLocation: '/detail',
      routes: <RouteBase>[
        GoRoute(
          path: '/detail',
          builder: (_, __) => TaskDetailScreen(
            taskId: taskId,
            controller: controller,
            hierarchy: _zonedHierarchy,
            role: FarmRole.owner,
            userId: 'manager-id',
            farmId: 'farm-id',
          ),
        ),
        GoRoute(
          path: '/map',
          builder: (_, GoRouterState state) => Scaffold(
            body: Text(
              'map-stub:${state.uri.queryParameters['focus']}',
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 targets'), findsOneWidget);
    expect(find.byKey(const Key('task-target-zone-1')), findsOneWidget);
    expect(find.byKey(const Key('task-target-zone-2')), findsOneWidget);
    expect(find.text('Zone Z1'), findsOneWidget);
    expect(find.text('Zone Z2'), findsOneWidget);

    // A target chip deep-links to the map focused on that target.
    await tester.tap(find.byKey(const Key('task-target-zone-2')));
    await tester.pumpAndSettle();
    expect(find.text('map-stub:zone:zone-2'), findsOneWidget);
  });

  testWidgets('evidence photos open in the full-screen viewer with error retry',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryTaskStore();
    final manager = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final taskId = await manager.create(
      const TaskDraft(
        farmId: 'farm-id',
        type: TaskType.irrigation,
        title: 'Task with photos',
      ),
    );
    store.photos[taskId] = <TaskPhoto>[
      TaskPhoto(
        id: 'photo-1',
        taskId: taskId,
        storageBucketId: 'farm-evidence',
        storagePath: 'u/f/t/one.jpg',
        photoType: TaskPhotoType.after,
        uploadedByProfileId: 'worker-id',
        createdAt: DateTime(2026, 7, 28, 14, 33),
      ),
      TaskPhoto(
        id: 'photo-2',
        taskId: taskId,
        storageBucketId: 'farm-evidence',
        storagePath: 'u/f/t/two.jpg',
        photoType: TaskPhotoType.before,
        uploadedByProfileId: 'worker-id',
        createdAt: DateTime(2026, 7, 28, 14, 40),
      ),
    ];
    final urls = _FakePhotoUrls();
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
        theme: AppTheme.light,
        home: TaskDetailScreen(
          taskId: taskId,
          controller: controller,
          hierarchy: _hierarchy,
          role: FarmRole.owner,
          userId: 'manager-id',
          farmId: 'farm-id',
          photoUrls: urls,
        ),
      ),
    );
    await tester.pumpAndSettle();
    _drainImageErrors(tester);

    await tester.scrollUntilVisible(
      find.byKey(const Key('evidence-photo-0')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('evidence-photo-0')));
    await tester.pumpAndSettle();
    _drainImageErrors(tester);

    // Viewer is open, shows the multi-photo counter, and (since the test
    // HTTP client refuses network) the error state with a retry.
    expect(find.byKey(const Key('photo-viewer')), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byKey(const Key('photo-viewer-error')), findsWidgets);
    final urlCallsBeforeRetry = urls.calls;
    await tester.tap(find.byKey(const Key('photo-viewer-retry')).first);
    await tester.pumpAndSettle();
    _drainImageErrors(tester);
    expect(urls.refreshes, 1); // retry requests a FRESH signed URL
    expect(urls.calls, greaterThan(urlCallsBeforeRetry));

    // Closing returns to the intact task detail screen.
    await tester.tap(find.byKey(const Key('photo-viewer-close')));
    await tester.pumpAndSettle();
    _drainImageErrors(tester);
    expect(find.byKey(const Key('photo-viewer')), findsNothing);
    expect(find.byKey(const Key('task-detail-list')), findsOneWidget);
    expect(find.byKey(const Key('evidence-photo-1')), findsOneWidget);
  });

  testWidgets('instructions hide generator metadata but show human content',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryTaskStore();
    final manager = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final taskId = await manager.create(
      const TaskDraft(
        farmId: 'farm-id',
        type: TaskType.fertilization,
        title: 'Generated feeding task',
        instructions: <String, Object?>{
          'text': 'Wear gloves near the pump.',
          'watering_depth': '30 cm',
          'operation_plan_id': '251134fe-c199-4933-8678-07f62165b2c2',
          'operation_plan_run_ids': <String>[
            '6f115981-d00f-431d-b412-d1cf97aef0d4',
          ],
          'inventory_item_id': '8e387609-b060-4c92-9e99-83ace40ccc96',
          'required_quantity': 42.133,
          'required_unit': 'liter',
          'application_method': null,
          'inspection_route_version': 2,
          'inspection_requires_issue_photo': false,
        },
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

    // The note and custom keys are readable ...
    expect(find.text('Wear gloves near the pump.'), findsOneWidget);
    expect(find.text('watering depth'), findsOneWidget);
    expect(find.text('30 cm'), findsOneWidget);
    // ... while the machine metadata never renders.
    expect(
      find.textContaining('251134fe-c199-4933-8678-07f62165b2c2'),
      findsNothing,
    );
    expect(find.textContaining('operation_plan'), findsNothing);
    expect(find.textContaining('inventory_item_id'), findsNothing);
    expect(find.textContaining('inspection route'), findsNothing);
    expect(find.textContaining('issue photo'), findsNothing);
  });
}

/// The test HttpClient answers every request with 400, so image loads
/// fail by design; the UI handles them via errorBuilder, and the pending
/// exceptions just need consuming so the test framework ignores them.
void _drainImageErrors(WidgetTester tester) {
  while (tester.takeException() != null) {}
}

class _FakePhotoUrls implements TaskPhotoUrlProvider {
  int calls = 0;
  int refreshes = 0;

  @override
  Future<String> urlFor(TaskPhoto photo, {bool refresh = false}) async {
    calls++;
    if (refresh) refreshes++;
    return 'http://localhost/${photo.storagePath}';
  }
}

final _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: const <FarmSection>[],
  zones: const <IrrigationZone>[],
  trees: const <FarmTreeRecord>[],
);

final _epoch = DateTime(2026);

final _zonedHierarchy = FarmHierarchy(
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
