import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/widgets/app_shell.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/login_screen.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/reviews/presentation/review_queue_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/tasks_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/task_fakes.dart';

/// Phase 8 fidelity certification screenshots. Login is captured at every
/// mandated device size (390x844, 430x932, a common Android 360x800, and the
/// 1024x1366 tablet); core content screens are captured at the primary phone
/// size for the design-language comparison recorded in FIDELITY_REPORT.md.
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

  const sizes = <String, Size>{
    'login_390x844': Size(390, 844),
    'login_430x932': Size(430, 932),
    'login_android_360x800': Size(360, 800),
    'login_tablet_1024x1366': Size(1024, 1366),
  };

  sizes.forEach((name, size) {
    testWidgets(
        'login visual at ${size.width.toInt()} by ${size.height.toInt()}',
        (tester) async {
      _setSize(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const LoginScreen(
            config: AppConfig(supabaseUrl: '', anonKey: ''),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/$name.png'),
      );
    });
  });

  testWidgets('phone shell composition at 430 by 932', (tester) async {
    _setSize(tester, const Size(430, 932));
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: <Widget>[
              const WahatTopBar(),
              Expanded(
                child: PaperBackground(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: WahatCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Eyebrow('Today at Al Wahat'),
                            const SizedBox(height: 8),
                            Text(
                              'Your farm.\nTree by tree.',
                              textAlign: TextAlign.center,
                              style: AppTheme.light.textTheme.headlineLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: WahatNavigation(index: 0, onSelected: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/shell_430x932.png'),
    );
  });

  testWidgets('worker task list at 390 by 844', (tester) async {
    _setSize(tester, const Size(390, 844));
    final store = InMemoryTaskStore();
    final manager = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    await manager.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.irrigation,
        title: 'Open the north irrigation valve',
        scheduledFor: DateTime(2026, 7, 13),
        plannedStartTime: '07:30:00',
        assigneeProfileIds: const <String>['worker-id'],
      ),
    );
    await manager.create(
      TaskDraft(
        farmId: 'farm-id',
        type: TaskType.treeInspection,
        title: 'Inspect Section C drip lines',
        scheduledFor: DateTime(2026, 7, 13),
        priority: TaskPriority.high,
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
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: TasksScreen(
            controller: workspace,
            role: FarmRole.worker,
            hierarchy: _emptyHierarchy,
            now: () => DateTime(2026, 7, 13),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/tasks_worker_390x844.png'),
    );
  });

  testWidgets('manager review queue at 390 by 844', (tester) async {
    _setSize(tester, const Size(390, 844));
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
        title: 'Inspect north palms',
        assigneeProfileIds: <String>['worker-id'],
      ),
    );
    final worker = FakeTaskRepository(
      store: store,
      viewerProfileId: 'worker-id',
      canManage: false,
    );
    await worker.start(taskId);
    await worker.complete(taskId, requiresEngineerReview: true);
    final workspace = TaskWorkspaceController(
      repository: manager,
      farmId: 'farm-id',
    );
    addTearDown(workspace.dispose);
    await workspace.load();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: ReviewQueueScreen(
          controller: workspace,
          role: FarmRole.owner,
          hierarchy: _emptyHierarchy,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../goldens/review_queue_390x844.png'),
    );
  });
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

final _emptyHierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: const <FarmSection>[],
  zones: const <IrrigationZone>[],
  trees: const <FarmTreeRecord>[],
);
