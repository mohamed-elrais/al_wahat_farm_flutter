import 'dart:async';

import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:al_wahat_farm_flutter/core/supabase/auth_repository.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/web/web_platform.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/data/operational_context_repository.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/auth_bootstrap_controller.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_photo_service.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_workspace_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/tree_issue_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_repository_scope.dart';
import 'package:al_wahat_farm_flutter/features/reviews/data/engineer_review_repository.dart';
import 'package:al_wahat_farm_flutter/features/reviews/data/review_mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/composite_mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/sync_scope.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/caching_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/offline_task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_evidence_service.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_mutation_executor.dart';
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
  IssueWorkspaceRepository? _issueWorkspaceRepository;
  InspectionRepository? _inspectionRepository;
  SyncEngine? _syncEngine;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    unawaited(_requestDurableStorage());
    final client = Supabase.instance.client;
    final services = AppServicesScope.maybeOf(context);
    final store = services?.cacheStore;

    final base = SupabaseTaskRepository(client);
    final issueWorkspaceBase = SupabaseIssueWorkspaceRepository(client);
    final inspectionBase = SupabaseInspectionRepository(client);
    if (services != null && store != null) {
      final caching = CachingTaskRepository(inner: base, store: store);
      final taskExecutor = TaskMutationExecutor(
        caching,
        evidenceStorage: SupabaseTaskEvidenceStorage(client),
        pendingPhotos: services.pendingPhotos,
        cache: store,
      );
      final issueExecutor = IssueMutationExecutor(
        repository: SupabaseTreeIssueRepository(client),
        photoStorage: SupabaseIssuePhotoStorage(client),
        pendingPhotos: services.pendingPhotos,
      );
      final reviewExecutor = ReviewMutationExecutor(
        reviewRepository: SupabaseEngineerReviewRepository(client),
        evidenceStorage: SupabaseTaskEvidenceStorage(client),
        pendingPhotos: services.pendingPhotos,
        taskRepository: caching,
      );
      final resolutionPhotoStorage = SupabaseIssuePhotoStorage(client);
      final issueWorkspaceExecutor = IssueWorkspaceMutationExecutor(
        issueWorkspaceBase,
        photoStorage: resolutionPhotoStorage,
        pendingPhotos: services.pendingPhotos,
      );
      final inspectionEvidenceStorage = SupabaseTaskEvidenceStorage(client);
      final inspectionExecutor = InspectionMutationExecutor(
        inspectionBase,
        evidenceStorage: inspectionEvidenceStorage,
        pendingPhotos: services.pendingPhotos,
        cache: store,
        taskRepository: caching,
      );
      final syncEngine = SyncEngine(
        outbox: services.outbox,
        executor:
            CompositeMutationExecutor(<PendingMutationKind, MutationExecutor>{
          PendingMutationKind.startTask: taskExecutor,
          PendingMutationKind.completeTask: taskExecutor,
          PendingMutationKind.setAssignments: taskExecutor,
          PendingMutationKind.addTaskPhoto: taskExecutor,
          PendingMutationKind.createTask: taskExecutor,
          PendingMutationKind.reportIssue: issueExecutor,
          PendingMutationKind.reviewTask: reviewExecutor,
          PendingMutationKind.changeIssueSeverity: issueWorkspaceExecutor,
          PendingMutationKind.dismissIssue: issueWorkspaceExecutor,
          PendingMutationKind.resolveIssue: issueWorkspaceExecutor,
          PendingMutationKind.unableToFixIssue: issueWorkspaceExecutor,
          PendingMutationKind.createInspection: inspectionExecutor,
          PendingMutationKind.setInspectionStatus: inspectionExecutor,
          PendingMutationKind.saveInspectionStation: inspectionExecutor,
          PendingMutationKind.submitInspection: inspectionExecutor,
        }),
        connectivity: services.connectivity,
      )..start();
      _syncEngine = syncEngine;
      _taskRepository = OfflineTaskRepository(
        inner: caching,
        outbox: services.outbox,
        connectivity: services.connectivity,
        cache: store,
        syncEngine: syncEngine,
      );
      _issueWorkspaceRepository = OfflineIssueWorkspaceRepository(
        inner: issueWorkspaceBase,
        cache: store,
        outbox: services.outbox,
        connectivity: services.connectivity,
        syncEngine: syncEngine,
        photoStorage: resolutionPhotoStorage,
        pendingPhotos: services.pendingPhotos,
        userId: client.auth.currentUser!.id,
      );
      _inspectionRepository = OfflineInspectionRepository(
        inner: inspectionBase,
        cache: store,
        outbox: services.outbox,
        connectivity: services.connectivity,
        syncEngine: syncEngine,
        evidenceStorage: inspectionEvidenceStorage,
        pendingPhotos: services.pendingPhotos,
        stationLocalStore: services.inspectionStationLocalStore,
        userId: client.auth.currentUser!.id,
      );
    } else {
      _taskRepository = base;
      _issueWorkspaceRepository = issueWorkspaceBase;
      _inspectionRepository = inspectionBase;
    }

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

  /// On the web, asks the browser not to evict the offline database once a
  /// session exists. A no-op on native platforms.
  Future<void> _requestDurableStorage() async {
    final granted = await requestPersistentStorage();
    if (granted == null) return;
    SafeLog.event('storage_persist', data: <String, Object?>{
      'granted': granted,
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _syncEngine?.dispose();
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
              child: IssueWorkspaceProvider(
                farmId: context.selectedMembership.farm.id,
                isManager: context.selectedMembership.role.canManageTasks,
                syncEngine: _syncEngine,
                repository: _issueWorkspaceRepository ??
                    SupabaseIssueWorkspaceRepository(Supabase.instance.client),
                child: InspectionRepositoryScope(
                  repository: _inspectionRepository ??
                      SupabaseInspectionRepository(Supabase.instance.client),
                  child: TaskWorkspaceProvider(
                    farmId: context.selectedMembership.farm.id,
                    syncEngine: _syncEngine,
                    repository: _taskRepository ??
                        SupabaseTaskRepository(Supabase.instance.client),
                    child: _syncEngine == null
                        ? widget.child
                        : SyncScope(engine: _syncEngine!, child: widget.child),
                  ),
                ),
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
