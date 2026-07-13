import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_create_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_create_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_fakes.dart';

void main() {
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
