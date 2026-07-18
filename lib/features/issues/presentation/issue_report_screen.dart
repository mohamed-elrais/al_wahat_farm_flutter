import 'package:al_wahat_farm_flutter/core/app_services.dart';
import 'package:al_wahat_farm_flutter/core/l10n/domain_labels.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/paper_background.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_photo_service.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/offline_issue_queue.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/tree_issue_repository.dart';
import 'package:al_wahat_farm_flutter/features/sync/presentation/sync_scope.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_report_controller.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IssueReportScreen extends StatefulWidget {
  const IssueReportScreen({
    required this.treeId,
    this.tree,
    this.controller,
    super.key,
  });

  final String treeId;
  final TreeIdentity? tree;
  final IssueReportController? controller;

  @override
  State<IssueReportScreen> createState() => _IssueReportScreenState();
}

class _IssueReportScreenState extends State<IssueReportScreen> {
  final _description = TextEditingController();
  TreeIssueType _type = TreeIssueType.insufficientIrrigation;
  IssueSeverity _severity = IssueSeverity.medium;
  IssueReportController? _controller;
  TreeIdentity? _tree;
  bool _ownsController = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final hierarchy = FarmHierarchyScope.maybeOf(context)?.hierarchy;
    _tree = widget.tree ??
        (hierarchy == null
            ? null
            : TreeIdentity.fromHierarchy(hierarchy, widget.treeId));
    final injected = widget.controller;
    if (injected != null) {
      _controller = injected;
      return;
    }
    final tree = _tree;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (tree?.farmId == null || userId == null) return;
    final client = Supabase.instance.client;
    final services = AppServicesScope.maybeOf(context);
    final syncEngine = SyncScope.maybeOf(context);
    final offlineQueue = (services != null && syncEngine != null)
        ? OutboxIssueQueue(
            outbox: services.outbox,
            pendingPhotos: services.pendingPhotos,
            syncEngine: syncEngine,
          )
        : null;
    _ownsController = true;
    _controller = IssueReportController(
      repository: SupabaseTreeIssueRepository(client),
      photoPicker: DeviceIssuePhotoPicker(),
      photoStorage: SupabaseIssuePhotoStorage(client),
      userId: userId,
      farmId: tree!.farmId!,
      treeId: tree.id,
      connectivity: services?.connectivity,
      offlineQueue: offlineQueue,
    );
  }

  @override
  void dispose() {
    _description.dispose();
    if (_ownsController) _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final tree = _tree;
    if (controller == null || tree == null) {
      return const _IssueUnavailable();
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => PaperBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(
                  tooltip: context.l10n.commonBack,
                  onPressed: controller.isBusy ? null : context.pop,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    context.l10n.reportIssueTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            WahatCard(
              child: Row(
                children: <Widget>[
                  const Icon(Icons.park_outlined, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          tree.code,
                          key: const Key('issue-tree-code'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          context.l10n.issueSectionRow(
                            tree.sectionCode,
                            tree.rowNumber?.toString() ?? '—',
                            tree.treeNumber?.toString() ?? '—',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            WahatCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DropdownButtonFormField<TreeIssueType>(
                    key: const Key('issue-type'),
                    value: _type,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.issueTypeLabel,
                    ),
                    items: TreeIssueType.values
                        .map(
                          (value) => DropdownMenuItem<TreeIssueType>(
                            value: value,
                            child: Text(value.localizedLabel(context.l10n)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: controller.isBusy
                        ? null
                        : (value) => setState(() => _type = value ?? _type),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<IssueSeverity>(
                    key: const Key('issue-severity'),
                    value: _severity,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.issueSeverityLabel,
                    ),
                    items: IssueSeverity.values
                        .map(
                          (value) => DropdownMenuItem<IssueSeverity>(
                            value: value,
                            child: Text(value.localizedLabel(context.l10n)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: controller.isBusy
                        ? null
                        : (value) =>
                            setState(() => _severity = value ?? _severity),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('issue-description'),
                    controller: _description,
                    enabled: !controller.isBusy,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: context.l10n.issueObservationLabel,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PhotoSelector(controller: controller),
                ],
              ),
            ),
            if (controller.isBusy) ...<Widget>[
              const SizedBox(height: 14),
              LinearProgressIndicator(
                key: const Key('issue-submit-progress'),
                semanticsLabel: _stageLabel(context, controller.stage),
              ),
              const SizedBox(height: 6),
              Text(
                _stageLabel(context, controller.stage),
                textAlign: TextAlign.center,
              ),
            ],
            if (controller.message != null) ...<Widget>[
              const SizedBox(height: 12),
              _SubmissionMessage(controller: controller),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('issue-submit'),
              onPressed: !controller.canSubmit
                  ? null
                  : () => controller.submit(
                        type: _type,
                        severity: _severity,
                        description: _description.text,
                      ),
              icon: const Icon(Icons.send_outlined),
              label: Text(
                controller.result == null
                    ? context.l10n.reportIssueButton
                    : context.l10n.issueReportedButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSelector extends StatelessWidget {
  const _PhotoSelector({required this.controller});

  final IssueReportController controller;

  @override
  Widget build(BuildContext context) {
    final photo = controller.photo;
    if (photo != null) {
      return ListTile(
        key: const Key('issue-photo-selected'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.image_outlined),
        title: Text(photo.filename),
        subtitle: Text(
          context.l10n.issueKibPrepared((photo.bytes.length / 1024).ceil()),
        ),
        trailing: IconButton(
          tooltip: context.l10n.issueRemovePhoto,
          onPressed: controller.canSubmit ? controller.removePhoto : null,
          icon: const Icon(Icons.close),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton.icon(
          key: const Key('issue-photo-camera'),
          onPressed: controller.canSubmit
              ? () => controller.pickPhoto(IssuePhotoSource.camera)
              : null,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(context.l10n.commonCamera),
        ),
        OutlinedButton.icon(
          key: const Key('issue-photo-gallery'),
          onPressed: controller.canSubmit
              ? () => controller.pickPhoto(IssuePhotoSource.gallery)
              : null,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(context.l10n.commonGallery),
        ),
      ],
    );
  }
}

class _SubmissionMessage extends StatelessWidget {
  const _SubmissionMessage({required this.controller});

  final IssueReportController controller;

  @override
  Widget build(BuildContext context) {
    final partial = controller.stage == IssueSubmissionStage.partialSuccess;
    final success = controller.stage == IssueSubmissionStage.success;
    return WahatCard(
      child: Column(
        children: <Widget>[
          Icon(
            success ? Icons.check_circle_outline : Icons.info_outline,
            color: success ? Colors.green : null,
          ),
          const SizedBox(height: 8),
          Text(
            controller.message!.call(context.l10n),
            key: const Key('issue-submit-message'),
            textAlign: TextAlign.center,
          ),
          if (partial) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('issue-photo-retry'),
              onPressed: controller.retryPhoto,
              child: Text(context.l10n.issueRetryPhoto),
            ),
          ],
        ],
      ),
    );
  }
}

class _IssueUnavailable extends StatelessWidget {
  const _IssueUnavailable();

  @override
  Widget build(BuildContext context) => PaperBackground(
        child: Center(
          child: WahatCard(
            child: Text(
              context.l10n.issueUnavailable,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
}

String _stageLabel(BuildContext context, IssueSubmissionStage stage) =>
    switch (stage) {
      IssueSubmissionStage.pickingPhoto =>
        context.l10n.issueStagePreparingPhoto,
      IssueSubmissionStage.reporting => context.l10n.issueStageReporting,
      IssueSubmissionStage.uploadingPhoto =>
        context.l10n.issueStageUploadingPhoto,
      IssueSubmissionStage.registeringPhoto =>
        context.l10n.issueStageRegisteringPhoto,
      _ => '',
    };
