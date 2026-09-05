import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_create_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_create_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_fakes.dart';

void main() {
  testWidgets('generic tree inspection stays available and links guided setup',
      (tester) async {
    final store = InMemoryTaskStore();
    final controller = TaskCreateController(
      repository: FakeTaskRepository(
        store: store,
        viewerProfileId: 'manager-id',
        canManage: true,
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TaskCreateScreen(
          controller: controller,
          hierarchy: _hierarchy,
          role: FarmRole.owner,
          farmId: 'farm-id',
          assignableMembers: store.members,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('task-type-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tree inspection').last);
    await tester.pumpAndSettle();

    expect(
        find.byKey(const Key('use-guided-inspection-button')), findsOneWidget);
  });

  testWidgets('manager create form validates then persists task',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryTaskStore();
    final repository = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final controller = TaskCreateController(repository: repository);
    addTearDown(controller.dispose);
    String? createdTaskId;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TaskCreateScreen(
          controller: controller,
          hierarchy: _hierarchy,
          role: FarmRole.owner,
          farmId: 'farm-id',
          assignableMembers: store.members,
          onCreated: (value) => createdTaskId = value,
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('task-submit-button')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('task-submit-button'))),
      alignment: 0.5,
    );
    final submit = tester.widget<FilledButton>(
      find.byKey(const Key('task-submit-button')),
    );
    submit.onPressed!();
    await tester.pump();
    expect(find.text('Enter a task title'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('task-title-field')),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Flush irrigation line',
    );
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.byKey(const Key('task-submit-button')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('task-submit-button'))),
      alignment: 0.5,
    );
    await tester.pump();
    tester
        .widget<FilledButton>(find.byKey(const Key('task-submit-button')))
        .onPressed!();
    await tester.pumpAndSettle();

    expect(createdTaskId, isNotNull);
    expect(store.tasks[createdTaskId]!.title, 'Flush irrigation line');
    expect(repository.createCalls, 1);
  });

  testWidgets('zone scope collects multiple targets as one draft',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryTaskStore();
    final repository = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final controller = TaskCreateController(repository: repository);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TaskCreateScreen(
          controller: controller,
          hierarchy: _zonedHierarchy,
          role: FarmRole.owner,
          farmId: 'farm-id',
          assignableMembers: store.members,
          onCreated: (_) {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Flush both zones',
    );
    tester.testTextInput.hide();

    await tester.tap(find.byKey(const Key('task-scope-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Irrigation zone').last);
    await tester.pumpAndSettle();

    Future<void> addZone(String label) async {
      await tester.tap(
        find.byKey(ValueKey<String>(
          'task-target-field-${_targetChipCount(tester)}',
        )),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await addZone('Z1 · Zone One');
    await addZone('Z2 · Zone Two');

    expect(find.byKey(const Key('task-target-chip-zone-1')), findsOneWidget);
    expect(find.byKey(const Key('task-target-chip-zone-2')), findsOneWidget);
    expect(find.text('2 targets'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('task-submit-button')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('task-submit-button'))),
      alignment: 0.5,
    );
    tester
        .widget<FilledButton>(find.byKey(const Key('task-submit-button')))
        .onPressed!();
    await tester.pumpAndSettle();

    final draft = repository.lastCreateDraft!;
    expect(
      draft.targets.map((target) => target.irrigationZoneId),
      <String>['zone-1', 'zone-2'],
    );
    expect(draft.sectionId, isNull);
    expect(draft.treeId, isNull);
  });

  testWidgets('worker route is intentionally role blocked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TaskCreateScreen(
          controller: TaskCreateController(
            repository: FakeTaskRepository(
              store: InMemoryTaskStore(),
              viewerProfileId: 'worker-id',
              canManage: false,
            ),
          ),
          hierarchy: _hierarchy,
          role: FarmRole.worker,
          farmId: 'farm-id',
        ),
      ),
    );

    expect(find.text('Your farm role cannot create or assign tasks.'),
        findsOneWidget);
  });
}

final _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: const <FarmSection>[],
  zones: const <IrrigationZone>[],
  trees: const <FarmTreeRecord>[],
);

int _targetChipCount(WidgetTester tester) => tester
    .widgetList(find.byWidgetPredicate(
      (widget) =>
          widget.key is Key &&
          widget.key.toString().contains('task-target-chip-'),
    ))
    .length;

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
