import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_fakes.dart';

void main() {
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
}

final _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: const <FarmSection>[],
  zones: const <IrrigationZone>[],
  trees: const <FarmTreeRecord>[],
);
