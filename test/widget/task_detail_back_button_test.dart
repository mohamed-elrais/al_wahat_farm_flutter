import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/app_shell.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_screen.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/task_fakes.dart';

/// Regression for the task-detail back arrow: rendered inside the full
/// shell chrome, with real status-bar insets, Arabic RTL and a long
/// wrapping title, the button must sit anchored at the header's top and
/// respond across its entire >=48x48 area.
void main() {
  testWidgets('back arrow is top-anchored and tappable across its area',
      (tester) async {
    // iPhone 14 Pro-like metrics with a real status-bar inset.
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    tester.view.padding = const FakeViewPadding(top: 177, bottom: 102);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    final store = InMemoryTaskStore();
    final manager = FakeTaskRepository(
      store: store,
      viewerProfileId: 'manager-id',
      canManage: true,
    );
    final taskId = await manager.create(
      const TaskDraft(
        farmId: 'farm-id',
        type: TaskType.pestControl,
        title: 'حشرات — مكافحة الحشرات في القسم الشمالي بالكامل مع المتابعة',
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
          builder: (_, __) => Scaffold(
            extendBody: true,
            bottomNavigationBar: WahatNavigation(index: 3, onSelected: (_) {}),
            body: Column(
              children: <Widget>[
                const WahatTopBar(),
                Expanded(
                  child: TaskDetailScreen(
                    taskId: taskId,
                    controller: controller,
                    hierarchy: FarmHierarchy(
                      farmId: 'farm-id',
                      sections: const <FarmSection>[],
                      zones: const <IrrigationZone>[],
                      trees: const <FarmTreeRecord>[],
                    ),
                    role: FarmRole.owner,
                    userId: 'manager-id',
                    farmId: 'farm-id',
                  ),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/tasks',
          builder: (_, __) => const Scaffold(body: Text('tasks-root')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byType(WahatBackButton);
    expect(button, findsOneWidget);

    // Guaranteed touch target and top anchoring: the button must hug the
    // header's top (below the ~119dp shell top bar + 20dp list padding),
    // not float at the middle of the tall wrapped title as before.
    final rect = tester.getRect(button);
    expect(rect.width, greaterThanOrEqualTo(48));
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(rect.top, lessThan(180));

    // Center and near-edge taps all trigger the same navigation.
    final targets = <Offset>[
      rect.center,
      rect.topLeft + const Offset(4, 4),
      rect.topRight + const Offset(-4, 4),
      rect.bottomLeft + const Offset(4, -4),
      rect.bottomRight + const Offset(-4, -4),
    ];
    for (final point in targets) {
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(find.text('tasks-root'), findsOneWidget,
          reason: 'tap at $point must navigate back');
      router.go('/detail');
      await tester.pumpAndSettle();
    }
  });
}
