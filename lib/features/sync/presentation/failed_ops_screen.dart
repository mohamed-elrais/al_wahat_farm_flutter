import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/failed_ops_controller.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/sync_scope.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lets the user review the changes that failed to sync (rejected or out of
/// retries) and either retry or discard each one.
class FailedOpsScreen extends StatefulWidget {
  const FailedOpsScreen({this.controller, super.key});

  final FailedOpsController? controller;

  @override
  State<FailedOpsScreen> createState() => _FailedOpsScreenState();
}

class _FailedOpsScreenState extends State<FailedOpsScreen> {
  FailedOpsController? _controller;
  bool _ownsController = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final injected = widget.controller;
    if (injected != null) {
      _controller = injected;
      _controller!.load();
      return;
    }
    final services = AppServicesScope.maybeOf(context);
    final engine = SyncScope.maybeOf(context);
    if (services != null && engine != null) {
      _controller = FailedOpsController(
        syncEngine: engine,
        pendingPhotos: services.pendingPhotos,
        cache: services.cacheStore,
      );
      _ownsController = true;
      _controller!.load();
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: controller == null
              ? _Unavailable(message: context.l10n.failedOpsUnavailable)
              : ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => _body(context, controller),
                ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, FailedOpsController controller) {
    final l10n = context.l10n;
    final ops = controller.ops;
    return ListView(
      key: const Key('failed-ops-list'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Row(
          children: <Widget>[
            WahatBackButton(
              key: const Key('failed-ops-back'),
              tooltip: l10n.commonBack,
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Eyebrow(l10n.failedOpsEyebrow),
                  Text(
                    l10n.failedOpsTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (controller.isLoading && ops.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (ops.isEmpty)
          WahatCard(
            child: Column(
              children: <Widget>[
                const Icon(Icons.cloud_done_outlined,
                    size: 38, color: AppColors.green),
                const SizedBox(height: 12),
                Text(l10n.failedOpsEmptyTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(l10n.failedOpsEmptyMessage, textAlign: TextAlign.center),
              ],
            ),
          )
        else ...<Widget>[
          Text(l10n.failedOpsIntro),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('failed-ops-retry-all'),
            onPressed: controller.isBusy ? null : controller.retryAll,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.failedOpsRetryAll),
          ),
          const SizedBox(height: 12),
          for (final op in ops) ...<Widget>[
            _FailedOpCard(
              op: op,
              busy: controller.isBusy,
              onRetry: () => controller.retry(op.opId),
              onDiscard: () => _confirmDiscard(context, controller, op),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Future<void> _confirmDiscard(
    BuildContext context,
    FailedOpsController controller,
    PendingMutation op,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.failedOpsDiscardConfirmTitle),
        content: Text(l10n.failedOpsDiscardConfirmMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.failedOpsDiscard),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.discard(op);
  }
}

class _FailedOpCard extends StatelessWidget {
  const _FailedOpCard({
    required this.op,
    required this.busy,
    required this.onRetry,
    required this.onDiscard,
  });

  final PendingMutation op;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return WahatCard(
      key: Key('failed-op-${op.opId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.error_outline, color: AppColors.issue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _kindLabel(l10n, op.kind),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (op.lastError != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              op.lastError!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                key: Key('failed-op-retry-${op.opId}'),
                onPressed: busy ? null : onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.failedOpsRetry),
              ),
              OutlinedButton.icon(
                key: Key('failed-op-discard-${op.opId}'),
                onPressed: busy ? null : onDiscard,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.failedOpsDiscard),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: WahatCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.sync_problem_outlined, size: 38),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => context.go('/more'),
                child: Text(context.l10n.commonBack),
              ),
            ],
          ),
        ),
      );
}

String _kindLabel(AppLocalizations l10n, PendingMutationKind kind) =>
    switch (kind) {
      PendingMutationKind.startTask => l10n.failedOpsKindStartTask,
      PendingMutationKind.completeTask => l10n.failedOpsKindCompleteTask,
      PendingMutationKind.setAssignments => l10n.failedOpsKindSetAssignments,
      PendingMutationKind.addTaskPhoto => l10n.failedOpsKindAddTaskPhoto,
      PendingMutationKind.createTask => l10n.failedOpsKindCreateTask,
      PendingMutationKind.reportIssue => l10n.failedOpsKindReportIssue,
      PendingMutationKind.reviewTask => l10n.failedOpsKindReviewTask,
    };
