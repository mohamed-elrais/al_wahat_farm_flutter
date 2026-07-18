import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
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
  AuthBootstrapController? _controller;
  TaskRepository? _taskRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final client = Supabase.instance.client;
    final store = AppServicesScope.maybeOf(context)?.cacheStore;

    final base = SupabaseTaskRepository(client);
    _taskRepository =
        store == null ? base : CachingTaskRepository(inner: base, store: store);

    final OperationalContextRepository contextRepository =
        DefaultOperationalContextRepository(
      SupabaseAuthBootstrapDataSource(client),
    );
    _controller = AuthBootstrapController(
      store == null
          ? contextRepository
          : CachingOperationalContextRepository(
              inner: contextRepository,
              store: store,
            ),
    );
    final userId = client.auth.currentUser?.id;
    if (userId != null) _controller!.load(userId);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(
        body: PaperBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => switch (controller.state) {
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
  }

  void _retry() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) _controller?.load(userId);
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _MessageCard(
        title: context.l10n.gateLoadFailedTitle,
        message: context.l10n.gateLoadFailedMessage,
        action: FilledButton(
          onPressed: onRetry,
          child: Text(context.l10n.commonRetry),
        ),
      );
}

class _BlockedAccess extends StatelessWidget {
  const _BlockedAccess({required this.reason});
  final BootstrapBlockReason reason;

  @override
  Widget build(BuildContext context) => _MessageCard(
        title: context.l10n.gateAccessUnavailableTitle,
        message: switch (reason) {
          BootstrapBlockReason.profileMissing =>
            context.l10n.gateProfileMissing,
          BootstrapBlockReason.profileInactive =>
            context.l10n.gateProfileInactive,
          BootstrapBlockReason.noActiveOperationalMembership =>
            context.l10n.gateNoMembership,
        },
        action: Builder(
          builder: (context) => OutlinedButton(
            onPressed: () => AuthRepository(
              Supabase.instance.client,
              onSignOut: AppServicesScope.maybeOf(context)?.clearPrivateData,
            ).signOut(),
            child: Text(context.l10n.logout),
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
