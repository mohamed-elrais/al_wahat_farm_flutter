import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/supabase/auth_repository.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/data/operational_context_repository.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/auth_bootstrap_controller.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OperationalContextScope extends InheritedWidget {
  const OperationalContextScope({
    required this.contextData,
    required super.child,
    super.key,
  });

  final OperationalContext contextData;

  static OperationalContext? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<OperationalContextScope>()
      ?.contextData;

  @override
  bool updateShouldNotify(OperationalContextScope oldWidget) =>
      oldWidget.contextData != contextData;
}

class AuthenticatedGate extends StatefulWidget {
  const AuthenticatedGate({required this.child, super.key});

  final Widget child;

  @override
  State<AuthenticatedGate> createState() => _AuthenticatedGateState();
}

class _AuthenticatedGateState extends State<AuthenticatedGate> {
  late final AuthBootstrapController _controller;
  TaskRepository? _taskRepository;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _controller = AuthBootstrapController(
      DefaultOperationalContextRepository(
        SupabaseAuthBootstrapDataSource(client),
      ),
    );
    final userId = client.auth.currentUser?.id;
    if (userId != null) _controller.load(userId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_taskRepository != null) return;
    final base = SupabaseTaskRepository(Supabase.instance.client);
    final store = AppServicesScope.maybeOf(context)?.cacheStore;
    _taskRepository =
        store == null ? base : CachingTaskRepository(inner: base, store: store);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.state) {
          AuthBootstrapReady(:final context) => OperationalContextScope(
              contextData: context,
              child: FarmHierarchyGate(
                farmId: context.selectedMembership.farm.id,
                child: TaskWorkspaceProvider(
                  farmId: context.selectedMembership.farm.id,
                  repository: _taskRepository ??
                      SupabaseTaskRepository(Supabase.instance.client),
                  child: widget.child,
                ),
              ),
            ),
          AuthBootstrapBlocked(:final reason) => _BlockedAccess(reason: reason),
          AuthBootstrapFailure() => _LoadFailure(onRetry: _retry),
          _ => const Scaffold(
              body: PaperBackground(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        },
      );

  void _retry() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) _controller.load(userId);
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _MessageCard(
        title: 'Unable to load farm access',
        message: 'Check your connection and try again.',
        action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
      );
}

class _BlockedAccess extends StatelessWidget {
  const _BlockedAccess({required this.reason});
  final BootstrapBlockReason reason;

  @override
  Widget build(BuildContext context) => _MessageCard(
        title: 'Farm access unavailable',
        message: switch (reason) {
          BootstrapBlockReason.profileMissing =>
            'Your account profile has not been provisioned.',
          BootstrapBlockReason.profileInactive => 'Your account is inactive.',
          BootstrapBlockReason.noActiveOperationalMembership =>
            'No active operational farm membership is assigned.',
        },
        action: Builder(
          builder: (context) => OutlinedButton(
            onPressed: () => AuthRepository(
              Supabase.instance.client,
              onSignOut: AppServicesScope.maybeOf(context)?.clearPrivateData,
            ).signOut(),
            child: const Text('Log out'),
          ),
        ),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.message,
    required this.action,
  });
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PaperBackground(
          child: Center(
            child: WahatCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  action,
                ],
              ),
            ),
          ),
        ),
      );
}
