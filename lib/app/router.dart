import 'dart:async';

import 'package:al_wahat_farm_flutter/core/config/app_config.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/login_screen.dart';
import 'package:al_wahat_farm_flutter/features/home/presentation/home_screen.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_item_screen.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_report_screen.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/scanner_screen.dart';
import 'package:al_wahat_farm_flutter/features/profile/presentation/profile_screen.dart';
import 'package:al_wahat_farm_flutter/features/reviews/presentation/review_detail_screen.dart';
import 'package:al_wahat_farm_flutter/features/reviews/presentation/review_queue_screen.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedule_detail_screen.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedule_form_screen.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_screen.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/failed_ops_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/tasks_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_create_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_detail_screen.dart';
import 'package:al_wahat_farm_flutter/features/trees/presentation/tree_detail_screen.dart';
import 'package:al_wahat_farm_flutter/core/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

GoRouter createRouter(AppConfig config) {
  final refresh = _AuthListenable(config);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      if (state.matchedLocation == '/splash') {
        return config.isConfigured &&
                Supabase.instance.client.auth.currentSession != null
            ? '/home'
            : '/login';
      }
      if (!config.isConfigured) {
        return state.matchedLocation == '/login' ? null : '/login';
      }
      final signedIn = Supabase.instance.client.auth.currentSession != null;
      if (!signedIn && state.matchedLocation != '/login') return '/login';
      if (signedIn && state.matchedLocation == '/login') return '/home';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (_, __) => const _SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (_, __) => LoginScreen(config: config),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => AuthenticatedGate(
          child: AppShell(navigationShell: navigationShell),
        ),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/map',
                builder: (_, state) => FarmMapScreen(
                  focus: state.uri.queryParameters['focus'],
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'tree/:treeId',
                    builder: (_, state) => TreeDetailScreen(
                      treeId: state.pathParameters['treeId']!,
                    ),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'report-issue',
                        builder: (_, state) => IssueReportScreen(
                          treeId: state.pathParameters['treeId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(path: '/scan', builder: (_, __) => const ScannerScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/tasks',
                builder: (_, __) => const TasksScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'create',
                    builder: (_, state) => TaskCreateScreen(
                      initialTreeId: state.uri.queryParameters['treeId'],
                      initialZoneId: state.uri.queryParameters['zoneId'],
                      initialSectionId: state.uri.queryParameters['sectionId'],
                    ),
                  ),
                  GoRoute(
                    path: 'reviews',
                    builder: (_, __) => const ReviewQueueScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: ':taskId',
                        builder: (_, state) => ReviewDetailScreen(
                          taskId: state.pathParameters['taskId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':taskId',
                    builder: (_, state) => TaskDetailScreen(
                      taskId: state.pathParameters['taskId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/more',
                builder: (_, __) => const ProfileScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'failed-ops',
                    builder: (_, __) => const FailedOpsScreen(),
                  ),
                  GoRoute(
                    path: 'schedules',
                    builder: (_, __) => const SchedulesScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'new',
                        builder: (_, __) => const ScheduleFormScreen(),
                      ),
                      GoRoute(
                        path: ':planId',
                        builder: (_, state) => ScheduleDetailScreen(
                          planId: state.pathParameters['planId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'inventory',
                    builder: (_, __) => const InventoryScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'new',
                        builder: (_, __) => const InventoryItemFormScreen(),
                      ),
                      GoRoute(
                        path: 'item/:itemId',
                        builder: (_, state) => InventoryItemScreen(
                          itemId: state.pathParameters['itemId']!,
                        ),
                        routes: <RouteBase>[
                          GoRoute(
                            path: 'edit',
                            builder: (_, state) => InventoryItemFormScreen(
                              itemId: state.pathParameters['itemId'],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(context.l10n.routeUnavailable(state.uri.path)),
      ),
    ),
  );
}

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(AppConfig config) {
    if (config.isConfigured) {
      _subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (_) => notifyListeners(),
      );
    }
  }

  StreamSubscription<AuthState>? _subscription;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
