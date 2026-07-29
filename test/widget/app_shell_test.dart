import 'package:al_wahat_farm_flutter/app/app.dart';
import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _shellRouter() => GoRouter(
      initialLocation: '/tasks',
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (_, __, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: <StatefulShellBranch>[
            StatefulShellBranch(routes: <RouteBase>[
              GoRoute(
                path: '/home',
                builder: (_, __) => const Text('home-root'),
              ),
            ]),
            StatefulShellBranch(routes: <RouteBase>[
              GoRoute(
                path: '/map',
                builder: (_, __) => const Text('map-root'),
              ),
            ]),
            StatefulShellBranch(routes: <RouteBase>[
              GoRoute(
                path: '/scan',
                builder: (_, __) => const Text('scan-root'),
              ),
            ]),
            StatefulShellBranch(routes: <RouteBase>[
              GoRoute(
                path: '/tasks',
                builder: (_, __) => const Text('tasks-root'),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':taskId',
                    builder: (_, __) => const Text('task-detail'),
                  ),
                ],
              ),
            ]),
            StatefulShellBranch(routes: <RouteBase>[
              GoRoute(
                path: '/more',
                builder: (_, __) => const Text('more-root'),
              ),
            ]),
          ],
        ),
      ],
    );

void main() {
  testWidgets('missing configuration restores to the intentional login state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const AlWahatApp(
        config: AppConfig(supabaseUrl: '', anonKey: ''),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to\nAl Wahat.'), findsOneWidget);
    expect(find.textContaining('Supabase is not configured'), findsOneWidget);
  });

  testWidgets('five-item navigation exposes labels and selects Map', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var selectedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: WahatNavigation(
            index: 0,
            onSelected: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    for (final label in <String>['Home', 'Map', 'Scan', 'Tasks', 'More']) {
      final destination = find.byKey(Key('nav-${label.toLowerCase()}'));
      expect(destination, findsOneWidget);
      expect(tester.getSemantics(destination).label, label);
    }

    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pump();

    expect(selectedIndex, 1);
    semantics.dispose();
  });

  testWidgets('switching sections always opens the section root', (
    tester,
  ) async {
    final router = _shellRouter();
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(find.text('tasks-root'), findsOneWidget);

    // Tasks -> Task Details -> More -> back to Tasks: the detail screen
    // must NOT resurface; the branch stack was reset to its root.
    router.go('/tasks/42');
    await tester.pumpAndSettle();
    expect(find.text('task-detail'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-more')));
    await tester.pumpAndSettle();
    expect(find.text('more-root'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('tasks-root'), findsOneWidget);
    expect(find.text('task-detail'), findsNothing);

    // Same flow through the Map section (deep-linked detail -> Map ->
    // Tasks) — consistent everywhere.
    router.go('/tasks/42');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-map')));
    await tester.pumpAndSettle();
    expect(find.text('map-root'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('tasks-root'), findsOneWidget);
    expect(find.text('task-detail'), findsNothing);

    // Re-selecting the ACTIVE section from a sub-page returns to its root.
    router.go('/tasks/42');
    await tester.pumpAndSettle();
    expect(find.text('task-detail'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('tasks-root'), findsOneWidget);
    expect(find.text('task-detail'), findsNothing);
  });
}
