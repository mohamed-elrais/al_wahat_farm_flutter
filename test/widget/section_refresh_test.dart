import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/tasks_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_fakes.dart';

Widget _app(
        {required bool visible, required TaskWorkspaceController controller}) =>
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        // Mirrors the shell's IndexedStack: hidden branches keep state
        // but have their tickers disabled.
        body: TickerMode(
          enabled: visible,
          child: TasksScreen(
            controller: controller,
            role: FarmRole.worker,
            hierarchy: FarmHierarchy(
              farmId: 'farm-id',
              sections: const <FarmSection>[],
              zones: const <IrrigationZone>[],
              trees: const <FarmTreeRecord>[],
            ),
            now: () => DateTime(2026, 7, 29),
          ),
        ),
      ),
    );

void main() {
  testWidgets('returning to the tasks section re-queries the repository',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeTaskRepository(
      store: InMemoryTaskStore(),
      viewerProfileId: 'worker-id',
      canManage: false,
    );
    final controller = TaskWorkspaceController(
      repository: repository,
      farmId: 'farm-id',
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(repository.listCalls, 1);

    await tester.pumpWidget(_app(visible: true, controller: controller));
    await tester.pumpAndSettle();
    // Mounting alone must not double-fire the initial request.
    expect(repository.listCalls, 1);

    // Leave the section, then return: exactly one refresh runs.
    await tester.pumpWidget(_app(visible: false, controller: controller));
    await tester.pumpAndSettle();
    expect(repository.listCalls, 1); // leaving does not query
    await tester.pumpWidget(_app(visible: true, controller: controller));
    await tester.pumpAndSettle();
    expect(repository.listCalls, 2);
    expect(tester.takeException(), isNull);

    // Rapid toggles: each return refreshes once, never more.
    await tester.pumpWidget(_app(visible: false, controller: controller));
    await tester.pump();
    await tester.pumpWidget(_app(visible: true, controller: controller));
    await tester.pumpAndSettle();
    expect(repository.listCalls, 3);
    expect(tester.takeException(), isNull);
  });
}
