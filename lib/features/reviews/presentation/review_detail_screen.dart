import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/reviews/data/engineer_review_repository.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/reviews/presentation/review_controller.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_evidence_service.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_widgets.dart';
import 'package:al_wahat_farm_flutter/features/tasks/presentation/task_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewDetailScreen extends StatefulWidget {
  const ReviewDetailScreen({
    required this.taskId,
    this.controller,
    this.workspace,
    this.hierarchy,
    this.role,
    this.userId,
    this.farmId,
    super.key,
  });

  final String taskId;
  final ReviewController? controller;
  final TaskWorkspaceController? workspace;
  final FarmHierarchy? hierarchy;
  final FarmRole? role;
  final String? userId;
  final String? farmId;

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  ReviewController? _controller;
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
    final workspace = widget.workspace ?? TaskWorkspaceScope.maybeOf(context);
    final contextData = OperationalContextScope.maybeOf(context);
    final userId = widget.userId ?? contextData?.profile.id;
    final farmId = widget.farmId ?? contextData?.selectedMembership.farm.id;
    if (workspace != null && userId != null && farmId != null) {
      final client = Supabase.instance.client;
      _controller = ReviewController(
        taskRepository: workspace.repository,
        reviewRepository: SupabaseEngineerReviewRepository(client),
        evidencePicker: DeviceTaskEvidencePicker(),
        evidenceStorage: SupabaseTaskEvidenceStorage(client),
        taskId: widget.taskId,
        farmId: farmId,
        userId: userId,
        onReviewed: workspace.refresh,
      );
      _ownsController = true;
      _controller!.load();
    }
  }

  FarmRole? get _role =>
      widget.role ??
      OperationalContextScope.maybeOf(context)?.selectedMembership.role;

  FarmHierarchy? get _hierarchy =>
      widget.hierarchy ?? FarmHierarchyScope.maybeOf(context)?.hierarchy;

  @override
  void dispose() {
    if (_ownsController) _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = _role;
    if (role != null && !role.canReview) {
      return _shell(const _DeniedReview());
    }
    final controller = _controller;
    if (controller == null || role == null) {
      return _shell(
        Center(child: Text(context.l10n.reviewWorkspaceUnavailable)),
      );
    }
    return _shell(
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _buildBody(context, controller),
      ),
    );
  }

  Widget _shell(Widget child) =>
      Scaffold(body: PaperBackground(child: SafeArea(child: child)));

  Widget _buildBody(BuildContext context, ReviewController controller) {
    if (controller.status == ReviewStatus.loading ||
        controller.status == ReviewStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    final details = controller.details;
    if (controller.status == ReviewStatus.failure || details == null) {
      return _FailureCard(
        message: controller.message?.call(context.l10n) ??
            context.l10n.unableToLoadReview,
        onRetry: controller.load,
      );
    }
    final task = details.task;
    return ListView(
      key: const Key('review-detail-list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              tooltip: context.l10n.backToReviewQueue,
              onPressed: () => context.go('/tasks/reviews'),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Eyebrow(context.l10n.reviewTaskEyebrow),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
            ),
            TaskStatusBadge(task.status),
          ],
        ),
        if (controller.isBusy) ...<Widget>[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 6),
          Text(_stageLabel(context.l10n, controller.stage)),
        ],
        if (controller.message != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            controller.message!.call(context.l10n),
            key: const Key('review-detail-message'),
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 14),
        WahatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SummaryRow(
                icon: Icons.place_outlined,
                label: context.l10n.detailTarget,
                value: taskTargetLabel(context.l10n, task, _hierarchy),
              ),
              _SummaryRow(
                icon: Icons.event_outlined,
                label: context.l10n.detailSchedule,
                value: taskScheduleLabel(context.l10n, task),
              ),
              _SummaryRow(
                icon: Icons.priority_high,
                label: context.l10n.detailPriority,
                value: task.priority.localizedLabel(context.l10n),
              ),
              if (task.completedAt != null)
                _SummaryRow(
                  icon: Icons.done_all_outlined,
                  label: context.l10n.reviewCompleted,
                  value: taskDateTimeLabel(task.completedAt!),
                ),
              if (task.relatedTreeIssueId != null) ...<Widget>[
                const Divider(height: 24),
                Row(
                  children: <Widget>[
                    const Icon(Icons.report_problem_outlined,
                        size: 20, color: AppColors.issue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.reviewLinkedIssue,
                        key: const Key('review-linked-issue'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _EvidenceCard(photos: details.photos),
        const SizedBox(height: 12),
        _ReviewHistoryCard(reviews: controller.reviews),
        const SizedBox(height: 12),
        _DecisionCard(
          controller: controller,
          onDecide: (decision) => _showDecisionSheet(controller, decision),
        ),
        const SizedBox(height: 12),
        _ActivityCard(activity: details.activity),
      ],
    );
  }

  Future<void> _showDecisionSheet(
    ReviewController controller,
    EngineerReviewDecision decision,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _DecisionSheet(controller: controller, decision: decision),
    );
  }
}

class _DeniedReview extends StatelessWidget {
  const _DeniedReview();

  @override
  Widget build(BuildContext context) => Center(
        key: const Key('review-detail-denied'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: WahatCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.lock_outline,
                    size: 38, color: AppColors.green),
                const SizedBox(height: 12),
                Text(context.l10n.reviewDeniedTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  context.l10n.reviewDeniedMessage,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.controller, required this.onDecide});

  final ReviewController controller;
  final ValueChanged<EngineerReviewDecision> onDecide;

  @override
  Widget build(BuildContext context) {
    final canDecide = controller.canDecide && !controller.isBusy;
    return WahatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(context.l10n.decisionTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          if (!controller.canDecide)
            Text(
              context.l10n.decisionNotAwaiting,
            )
          else ...<Widget>[
            Text(context.l10n.decisionPrompt),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('review-approve-button'),
              onPressed: canDecide
                  ? () => onDecide(EngineerReviewDecision.approved)
                  : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(EngineerReviewDecision.approved
                  .localizedActionLabel(context.l10n)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('review-return-button'),
              onPressed: canDecide
                  ? () => onDecide(EngineerReviewDecision.returnedForCorrection)
                  : null,
              icon: const Icon(Icons.undo_outlined),
              label: Text(EngineerReviewDecision.returnedForCorrection
                  .localizedActionLabel(context.l10n)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              key: const Key('review-follow-up-button'),
              onPressed: canDecide
                  ? () => onDecide(EngineerReviewDecision.followUpRequired)
                  : null,
              icon: const Icon(Icons.flag_outlined),
              label: Text(EngineerReviewDecision.followUpRequired
                  .localizedActionLabel(context.l10n)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DecisionSheet extends StatefulWidget {
  const _DecisionSheet({required this.controller, required this.decision});

  final ReviewController controller;
  final EngineerReviewDecision decision;

  @override
  State<_DecisionSheet> createState() => _DecisionSheetState();
}

class _DecisionSheetState extends State<_DecisionSheet> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(widget.decision.localizedActionLabel(context.l10n),
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: context.l10n.reviewNotesLabel,
                    hintText: context.l10n.reviewNotesHint,
                  ),
                ),
                const Divider(height: 28),
                Text(context.l10n.optionalReviewPhoto,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: widget.controller.isBusy
                          ? null
                          : () => widget.controller
                              .pickPhoto(TaskEvidenceSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(context.l10n.commonCamera),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.controller.isBusy
                          ? null
                          : () => widget.controller
                              .pickPhoto(TaskEvidenceSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(context.l10n.commonGallery),
                    ),
                  ],
                ),
                if (widget.controller.photo != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(context.l10n
                            .selectedFile(widget.controller.photo!.filename)),
                      ),
                      TextButton(
                        onPressed: widget.controller.isBusy
                            ? null
                            : widget.controller.removePhoto,
                        child: Text(context.l10n.commonRemove),
                      ),
                    ],
                  ),
                ],
                if (widget.controller.message != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(widget.controller.message!.call(context.l10n)),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('review-confirm-button'),
                  onPressed: widget.controller.isBusy ? null : _submit,
                  icon: const Icon(Icons.check),
                  label: Text(widget.controller.isBusy
                      ? _stageLabel(context.l10n, widget.controller.stage)
                      : context.l10n.confirmDecision(
                          widget.decision.localizedActionLabel(context.l10n))),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _submit() async {
    final success = await widget.controller.submit(
      decision: widget.decision,
      notes: _notesController.text,
    );
    if (success && mounted) Navigator.of(context).pop();
  }
}

class _ReviewHistoryCard extends StatelessWidget {
  const _ReviewHistoryCard({required this.reviews});

  final List<EngineerReview> reviews;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(context.l10n.reviewHistory(reviews.length),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (reviews.isEmpty)
              Text(context.l10n.noReviews)
            else
              for (final review in reviews)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_decisionIcon(review.decision)),
                  title: Text(review.decision.localizedLabel(context.l10n)),
                  subtitle: Text(
                    review.notes == null || review.notes!.isEmpty
                        ? taskDateTimeLabel(review.reviewedAt)
                        : '${review.notes}\n${taskDateTimeLabel(review.reviewedAt)}',
                  ),
                ),
          ],
        ),
      );
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.photos});

  final List<TaskPhoto> photos;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(context.l10n.evidenceCount(photos.length),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (photos.isEmpty)
              Text(context.l10n.noEvidence)
            else
              for (final photo in photos)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.softGreen,
                    child: Icon(Icons.photo_outlined),
                  ),
                  title: Text(photo.caption ??
                      photo.photoType.localizedLabel(context.l10n)),
                  subtitle: Text(
                    '${photo.photoType.localizedLabel(context.l10n)} · ${taskDateTimeLabel(photo.createdAt)}',
                  ),
                ),
          ],
        ),
      );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final List<TaskActivity> activity;

  @override
  Widget build(BuildContext context) => WahatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(context.l10n.activityTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (activity.isEmpty)
              Text(context.l10n.noActivity)
            else
              for (final item in activity)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: Text(item.action.localizedLabel(context.l10n)),
                  subtitle: Text(
                    item.note == null || item.note!.isEmpty
                        ? taskDateTimeLabel(item.createdAt)
                        : '${item.note}\n${taskDateTimeLabel(item.createdAt)}',
                  ),
                ),
          ],
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: AppColors.green),
            const SizedBox(width: 10),
            SizedBox(
              width: 92,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: WahatCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.sync_problem_outlined, size: 38),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                OutlinedButton(
                    onPressed: onRetry, child: Text(context.l10n.commonRetry)),
              ],
            ),
          ),
        ),
      );
}

IconData _decisionIcon(EngineerReviewDecision decision) => switch (decision) {
      EngineerReviewDecision.approved => Icons.check_circle_outline,
      EngineerReviewDecision.returnedForCorrection => Icons.undo_outlined,
      EngineerReviewDecision.followUpRequired => Icons.flag_outlined,
    };

String _stageLabel(AppLocalizations l10n, ReviewStage stage) => switch (stage) {
      ReviewStage.idle => l10n.stageReady,
      ReviewStage.pickingPhoto => l10n.reviewStagePickingPhoto,
      ReviewStage.uploadingPhoto => l10n.reviewStageUploadingPhoto,
      ReviewStage.submitting => l10n.reviewStageSubmitting,
    };
