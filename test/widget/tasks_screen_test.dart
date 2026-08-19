import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/tasks_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_fakes.dart';

void main() {
  testWidgets('manager sees role-filtered tasks and create action',
      (tester) async {
    final store = InMemoryTaskStore();
    final repository = _manager(store);
    final taskId = await repository.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.irrigation,
        title: 'Inspect irrigation line',
        scheduledFor: DateTime(2026, 7, 13),
      ),
    );
    final workspace = TaskWorkspaceController(
      repository: repository,
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();
    String? opened;
    var createTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TasksScreen(
          controller: workspace,
          role: FarmRole.owner,
          hierarchy: _hierarchy,
          now: () => DateTime(2026, 7, 13),
          onOpenTask: (value) => opened = value,
          onCreateTask: () => createTapped = true,
        ),
      ),
    );

    expect(find.text('Inspect irrigation line'), findsOneWidget);
    expect(find.byKey(const Key('create-task-button')), findsOneWidget);
    expect(find.byKey(const Key('open-review-queue-button')), findsOneWidget);
    await tester.tap(find.byKey(Key('task-$taskId')));
    expect(opened, taskId);
    await tester.tap(find.byKey(const Key('create-task-button')));
    expect(createTapped, isTrue);

    await tester.tap(find.byKey(const Key('tasks-calendar-view')));
    await tester.pump();
    expect(find.byKey(const Key('create-task-button')), findsOneWidget);
    expect(find.byKey(const Key('open-review-queue-button')), findsOneWidget);
  });

  testWidgets('a task pending sync shows the badge and is not openable',
      (tester) async {
    final store = InMemoryTaskStore();
    final createdAt = DateTime(2026, 7, 13);
    store.tasks['${localTaskIdPrefix}op1'] = FarmTask(
      id: '${localTaskIdPrefix}op1',
      farmId: 'farm-id',
      type: TaskType.irrigation,
      title: 'Queued offline task',
      priority: TaskPriority.medium,
      status: TaskStatus.assigned,
      instructions: const <String, Object?>{},
      requiresEngineerReview: false,
      createdByProfileId: '',
      createdAt: createdAt,
      updatedAt: createdAt,
      scheduledFor: createdAt,
    );
    final workspace = TaskWorkspaceController(
      repository: _manager(store),
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();
    var openedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TasksScreen(
            controller: workspace,
            role: FarmRole.owner,
            hierarchy: _hierarchy,
            now: () => createdAt,
            onOpenTask: (_) => openedCount++,
          ),
        ),
      ),
    );

    expect(find.text('Queued offline task'), findsOneWidget);
    expect(find.byKey(const Key('task-pending-sync-badge')), findsOneWidget);

    await tester.tap(find.byKey(const Key('task-${localTaskIdPrefix}op1')));
    await tester.pump();
    expect(openedCount, 0); // pending tasks do not navigate
    expect(find.text('This task opens once it syncs to the farm.'),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('tasks-calendar-view')));
    await tester.pump();
    await _scrollToCalendarResults(tester);
    await tester.tap(find.byKey(const Key('task-${localTaskIdPrefix}op1')));
    await tester.pump();
    expect(openedCount, 0);
  });

  testWidgets('worker does not see manager create action', (tester) async {
    final store = InMemoryTaskStore();
    await _manager(store).create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.general,
        title: 'Assigned work',
        scheduledFor: DateTime(2026, 7, 13),
        assigneeProfileIds: const <String>['worker-id'],
      ),
    );
    final workspace = TaskWorkspaceController(
      repository: FakeTaskRepository(
        store: store,
        viewerProfileId: 'worker-id',
        canManage: false,
      ),
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TasksScreen(
          controller: workspace,
          role: FarmRole.worker,
          hierarchy: _hierarchy,
          now: () => DateTime(2026, 7, 13),
          onOpenTask: (_) {},
        ),
      ),
    );

    expect(find.text('Assigned work'), findsOneWidget);
    expect(find.byKey(const Key('create-task-button')), findsNothing);

    await tester.tap(find.byKey(const Key('tasks-calendar-view')));
    await tester.pump();
    expect(find.byKey(const Key('create-task-button')), findsNothing);
    expect(find.byKey(const Key('open-review-queue-button')), findsNothing);
  });

  testWidgets('switches views and initially selects today', (tester) async {
    final store = InMemoryTaskStore();
    final repository = _manager(store);
    await repository.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.general,
        title: 'Today task',
        scheduledFor: DateTime(2026, 7, 13),
      ),
    );
    await repository.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.general,
        title: 'Tomorrow task',
        scheduledFor: DateTime(2026, 7, 14),
      ),
    );
    final workspace = TaskWorkspaceController(
      repository: repository,
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();

    await _pumpTasks(
      tester,
      workspace: workspace,
      role: FarmRole.owner,
      now: DateTime(2026, 7, 13),
    );

    expect(find.byKey(const Key('tasks-today-filter')), findsOneWidget);
    expect(find.byKey(const Key('tasks-calendar-grid')), findsNothing);

    await tester.tap(find.byKey(const Key('tasks-calendar-view')));
    await tester.pump();

    expect(find.byKey(const Key('tasks-calendar-grid')), findsOneWidget);
    expect(find.byKey(const Key('tasks-today-filter')), findsNothing);
    final today = tester.widget<Semantics>(
      find.byKey(const Key('tasks-calendar-day-2026-07-13')),
    );
    expect(today.properties.selected, isTrue);

    await tester.tap(find.byKey(const Key('tasks-list-view')));
    await tester.pump();
    expect(find.byKey(const Key('tasks-today-filter')), findsOneWidget);
    expect(find.text('Today task'), findsOneWidget);
    expect(find.text('Tomorrow task'), findsNothing);

    await tester.tap(find.byKey(const Key('tasks-all-filter')));
    await tester.pump();
    expect(find.text('Tomorrow task'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tasks-calendar-view')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tasks-list-view')));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('tasks-all-filter')))
          .selected,
      isTrue,
    );
    expect(find.text('Tomorrow task'), findsOneWidget);
  });

  testWidgets('navigates months and Today restores the current date',
      (tester) async {
    final store = InMemoryTaskStore();
    final workspace = TaskWorkspaceController(
      repository: _manager(store),
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();
    await _pumpTasks(
      tester,
      workspace: workspace,
      role: FarmRole.owner,
      now: DateTime(2026, 7, 13),
    );
    await tester.tap(find.byKey(const Key('tasks-calendar-view')));
    await tester.pump();

    expect(_monthTitle(tester), 'July 2026');
    await tester.tap(find.byKey(const Key('tasks-calendar-next-month')));
    await tester.pump();
    expect(_monthTitle(tester), 'August 2026');
    await tester.tap(find.byKey(const Key('tasks-calendar-previous-month')));
    await tester.pump();
    expect(_monthTitle(tester), 'July 2026');
    await tester.tap(find.byKey(const Key('tasks-calendar-next-month')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tasks-calendar-today')));
    await tester.pump();
    expect(_monthTitle(tester), 'July 2026');
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const Key('tasks-calendar-day-2026-07-13')),
          )
          .properties
          .selected,
      isTrue,
    );
  });

  testWidgets('shows counts, selects a date, and opens its existing task card',
      (tester) async {
    final store = InMemoryTaskStore();
    final repository = _manager(store);
    final scheduledId = await repository.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.irrigation,
        title: 'Scheduled on the fifteenth',
        scheduledFor: DateTime(2026, 7, 15),
      ),
    );
    await repository.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.general,
        title: 'Due on the fifteenth',
        dueAt: DateTime(2026, 7, 15, 10),
      ),
    );
    final workspace = TaskWorkspaceController(
      repository: repository,
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();
    String? opened;
    await _pumpTasks(
      tester,
      workspace: workspace,
      role: FarmRole.owner,
      now: DateTime(2026, 7, 13),
      onOpenTask: (id) => opened = id,
    );
    await tester.tap(find.byKey(const Key('tasks-calendar-view')));
    await tester.pump();

    final count = find.byKey(
      const Key('tasks-calendar-count-2026-07-15'),
    );
    expect(count, findsOneWidget);
    expect(
        find.descendant(of: count, matching: find.text('2')), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const Key('tasks-calendar-day-2026-07-15')),
          )
          .properties
          .label,
      contains('2 tasks'),
    );

    await tester.tap(
      find.byKey(const Key('tasks-calendar-day-2026-07-15')),
    );
    await tester.pumpAndSettle();
    final selectedDateTitle =
        find.byKey(const Key('tasks-calendar-selected-date-title'));
    final selectedDateTitleRect = tester.getRect(selectedDateTitle);
    expect(selectedDateTitleRect.top, greaterThanOrEqualTo(0));
    expect(selectedDateTitleRect.bottom, lessThanOrEqualTo(600));
    expect(find.text('Scheduled on the fifteenth'), findsOneWidget);
    expect(find.text('Due on the fifteenth'), findsOneWidget);

    final taskTile = find.byKey(Key('task-$scheduledId'));
    await tester.tap(taskTile);
    expect(opened, scheduledId);
  });

  testWidgets('shows a localized empty state for a date without tasks',
      (tester) async {
    final store = InMemoryTaskStore();
    final workspace = TaskWorkspaceController(
      repository: _manager(store),
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();
    await _pumpTasks(
      tester,
      workspace: workspace,
      role: FarmRole.owner,
      now: DateTime(2026, 7, 13),
    );
    await tester.tap(find.byKey(const Key('tasks-calendar-view')));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('tasks-calendar-day-2026-07-16')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tasks on this date'), findsOneWidget);
    expect(
        find.text('Choose another date or create a new task.'), findsOneWidget);
  });

  testWidgets('calendar is localized and laid out RTL in Arabic',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = InMemoryTaskStore();
    final workspace = TaskWorkspaceController(
      repository: _manager(store),
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();
    await _pumpTasks(
      tester,
      workspace: workspace,
      role: FarmRole.worker,
      now: DateTime(2026, 7, 13),
      locale: const Locale('ar'),
    );

    await tester.tap(find.byKey(const Key('tasks-calendar-view')));
    await tester.pump();

    expect(find.text('التقويم'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.byKey(const Key('tasks-calendar-grid'))),
      ),
      TextDirection.rtl,
    );
    await _scrollToCalendarResults(tester);
    expect(find.text('لا توجد مهام في هذا التاريخ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull-to-refresh remains available in Calendar view',
      (tester) async {
    final store = InMemoryTaskStore();
    final repository = _manager(store);
    final workspace = TaskWorkspaceController(
      repository: repository,
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();
    expect(repository.listCalls, 1);
    await _pumpTasks(
      tester,
      workspace: workspace,
      role: FarmRole.owner,
      now: DateTime(2026, 7, 13),
    );
    await tester.tap(find.byKey(const Key('tasks-calendar-view')));
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('tasks-list')),
      const Offset(0, 320),
    );
    await tester.pumpAndSettle();

    expect(repository.listCalls, 2);
  });
}

Future<void> _pumpTasks(
  WidgetTester tester, {
  required TaskWorkspaceController workspace,
  required FarmRole role,
  required DateTime now,
  Locale locale = const Locale('en'),
  ValueChanged<String>? onOpenTask,
}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TasksScreen(
            controller: workspace,
            role: role,
            hierarchy: _hierarchy,
            now: () => now,
            onOpenTask: onOpenTask ?? (_) {},
          ),
        ),
      ),
    );

String _monthTitle(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const Key('tasks-calendar-month-title')))
    .data!;

Future<void> _scrollToCalendarResults(WidgetTester tester) async {
  await tester.drag(
    find.byKey(const Key('tasks-list')),
    const Offset(0, -500),
  );
  await tester.pump();
}

FakeTaskRepository _manager(InMemoryTaskStore store) => FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );

final _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: const <FarmSection>[],
  zones: const <IrrigationZone>[],
  trees: const <FarmTreeRecord>[],
);
