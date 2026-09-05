import 'dart:async';
import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_workspace_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/outbox_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/data/pending_photo_store.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/mutation_executor.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/pending_mutation.dart';
import 'package:al_wahat_farm_flutter/features/sync/domain/sync_engine.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:flutter_test/flutter_test.dart';

class _OfflineConnectivity implements ConnectivityService {
  @override
  Future<NetworkStatus> current() async => NetworkStatus.offline;

  @override
  Stream<NetworkStatus> get changes => const Stream<NetworkStatus>.empty();
}

class _NoopExecutor implements MutationExecutor {
  @override
  Future<void> execute(PendingMutation mutation) async {}
}

class _FakeWorkspace implements IssueWorkspaceRepository {
  int claimCalls = 0;
  int assignCalls = 0;
  TreeIssueDetails? details;
  bool failDetails = false;
  List<TreeIssueOccurrence> treeHistory = const <TreeIssueOccurrence>[];
  bool failTreeHistory = false;
  List<TreeIssueSummary> managerIssues = const <TreeIssueSummary>[];
  bool failManagerIssues = false;

  @override
  Future<TreeIssueDetails> loadDetails(String issueId) async {
    if (failDetails) {
      throw const OperationFailure(
        OperationFailureKind.offline,
        'Offline',
      );
    }
    return details!;
  }

  @override
  Future<List<TreeIssueOccurrence>> listTreeHistory(String treeId) async {
    if (failTreeHistory) {
      throw const OperationFailure(OperationFailureKind.offline, 'Offline');
    }
    return treeHistory;
  }

  @override
  Future<String> claim(String issueId) async {
    claimCalls++;
    return 'task-id';
  }

  @override
  Future<String> assign({
    required String issueId,
    required String assigneeProfileId,
    required bool requiresEngineerReview,
  }) async {
    assignCalls++;
    return 'task-id';
  }

  @override
  Future<void> changeSeverity(String issueId, IssueSeverity severity,
      {String? notes, String? opId}) async {}

  @override
  Future<void> dismiss(String issueId, String notes, {String? opId}) async {}

  @override
  Future<List<TreeIssueSummary>> listSummaries(String farmId,
          {IssueSummaryFilter filter = const IssueSummaryFilter()}) async =>
      const <TreeIssueSummary>[];

  @override
  Future<List<TreeIssueSummary>> listManagerIssues(String farmId) async =>
      failManagerIssues
          ? throw const OperationFailure(
              OperationFailureKind.offline,
              'Offline',
            )
          : managerIssues;

  @override
  Future<List<TaskTreeIssueWork>> listTaskWork(String taskId) async =>
      const <TaskTreeIssueWork>[];

  @override
  Future<void> resolve({
    required String taskId,
    required String issueId,
    String? notes,
    String? photoStoragePath,
    PreparedIssuePhoto? preparedPhoto,
    String? userId,
    String? farmId,
    String? opId,
  }) async {}

  @override
  Future<void> unableToFix({
    required String taskId,
    required String issueId,
    required TreeIssueUnableReason reason,
    String? notes,
    String? photoStoragePath,
    PreparedIssuePhoto? preparedPhoto,
    String? userId,
    String? farmId,
    String? opId,
  }) async {}
}

class _FakePhotoStorage implements IssuePhotoStorage {
  @override
  Future<void> delete(String storagePath) async {}

  @override
  Future<String> upload({
    required String userId,
    required String farmId,
    required String taskId,
    required PreparedIssuePhoto photo,
  }) async =>
      '$userId/$farmId/$taskId/photo.jpg';
}

void main() {
  late ConnectivityController connectivity;
  late InMemoryOutboxStore outbox;
  late _FakeWorkspace base;
  late InMemoryPendingPhotoStore pendingPhotos;
  late OfflineIssueWorkspaceRepository repository;

  setUp(() async {
    connectivity = ConnectivityController(_OfflineConnectivity());
    await connectivity.start();
    outbox = InMemoryOutboxStore();
    base = _FakeWorkspace();
    pendingPhotos = InMemoryPendingPhotoStore();
    final engine = SyncEngine(
      outbox: outbox,
      executor: _NoopExecutor(),
      connectivity: connectivity,
    );
    repository = OfflineIssueWorkspaceRepository(
      inner: base,
      cache: InMemoryCacheStore(),
      outbox: outbox,
      connectivity: connectivity,
      syncEngine: engine,
      photoStorage: _FakePhotoStorage(),
      pendingPhotos: pendingPhotos,
      userId: 'user-id',
    );
  });

  tearDown(() => connectivity.dispose());

  test('safe summary retains server-provided location and active count', () {
    final summary = TreeIssueSummary.fromJson(<String, Object?>{
      'tree_issue_id': 'issue-id',
      'farm_id': 'farm-id',
      'tree_id': 'tree-id',
      'tree_code': 'TREE-A-001',
      'section_id': 'section-id',
      'section_code': 'A',
      'issue_type': 'clogged_dripper',
      'severity': 'high',
      'status': 'open',
      'reported_at': '2026-09-02T10:30:00Z',
      'active_issue_count': 2,
      'is_claimed': false,
      'claimed_by_current_user': false,
      'can_view_details': false,
    });

    expect(summary.treeCode, 'TREE-A-001');
    expect(summary.sectionCode, 'A');
    expect(summary.activeIssueCount, 2);
    expect(TreeIssueSummary.fromJson(summary.toJson()).activeIssueCount, 2);
  });

  test('manager workspace separates history and combines all manager filters',
      () async {
    final now = DateTime.utc(2026, 9, 3);
    TreeIssueSummary issue({
      required String id,
      required String section,
      required TreeIssueType type,
      required IssueSeverity severity,
      required TreeIssueStatus status,
      required int ageDays,
      required IssueSource source,
      String? assignee,
    }) =>
        TreeIssueSummary(
          id: id,
          farmId: 'farm-id',
          treeId: 'tree-$id',
          treeCode: 'TREE-$id',
          sectionId: section,
          sectionCode: section,
          type: type,
          severity: severity,
          status: status,
          reportedAt: now.subtract(Duration(days: ageDays)),
          activeIssueCount: status == TreeIssueStatus.open ? 1 : 0,
          isClaimed: assignee != null && status == TreeIssueStatus.open,
          claimedByCurrentUser: false,
          canViewDetails: true,
          assignedProfileId: assignee,
          assignedName: assignee,
          source: source,
        );

    base.managerIssues = <TreeIssueSummary>[
      issue(
        id: 'recent',
        section: 'section-a',
        type: TreeIssueType.other,
        severity: IssueSeverity.low,
        status: TreeIssueStatus.inReview,
        ageDays: 2,
        source: IssueSource.quickReport,
      ),
      issue(
        id: 'target',
        section: 'section-b',
        type: TreeIssueType.cloggedDripper,
        severity: IssueSeverity.high,
        status: TreeIssueStatus.open,
        ageDays: 40,
        source: IssueSource.inspection,
        assignee: 'Worker',
      ),
      issue(
        id: 'past',
        section: 'section-b',
        type: TreeIssueType.treeDamage,
        severity: IssueSeverity.medium,
        status: TreeIssueStatus.resolved,
        ageDays: 100,
        source: IssueSource.inspection,
        assignee: 'Worker',
      ),
    ];
    final controller = IssueWorkspaceController(
      farmId: 'farm-id',
      repository: base,
      isManager: true,
      now: () => now,
    );
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.issues, hasLength(2));
    expect(controller.activeCount, 2);
    expect(controller.historyCount, 1);

    controller.setView(IssueWorkspaceView.history);
    expect(controller.issues.single.id, 'past');

    controller.setView(IssueWorkspaceView.active);
    controller.setSection('section-b');
    controller.setAge(IssueAgeFilter.thirtyDays);
    controller.setAssignment(IssueAssignmentFilter.assigned);
    controller.setSource(IssueSource.inspection);
    await controller.setType(TreeIssueType.cloggedDripper);
    await controller.setSeverity(IssueSeverity.high);
    controller.setStatus(TreeIssueStatus.open);
    expect(controller.issues.single.id, 'target');

    controller.resetManagerFilters();
    expect(controller.issues, hasLength(2));
  });

  test('authorized tree history is cached for offline tree details', () async {
    final now = DateTime.utc(2026, 9, 3);
    base.treeHistory = <TreeIssueOccurrence>[
      TreeIssueOccurrence(
        id: 'past-issue',
        type: TreeIssueType.treeDamage,
        severity: IssueSeverity.medium,
        status: TreeIssueStatus.resolved,
        reportedAt: now,
        closedAt: now,
      ),
    ];

    expect(
        (await repository.listTreeHistory('tree-id')).single.id, 'past-issue');
    base.failTreeHistory = true;
    expect(
        (await repository.listTreeHistory('tree-id')).single.id, 'past-issue');
  });

  test('self-claim is rejected offline and is never queued', () async {
    await expectLater(
      repository.claim('issue-id'),
      throwsA(isA<OperationFailure>().having(
        (error) => error.kind,
        'kind',
        OperationFailureKind.offline,
      )),
    );

    expect(base.claimCalls, 0);
    expect(await outbox.pending(), isEmpty);
  });

  test('manager register is cached for offline browsing', () async {
    base.managerIssues = <TreeIssueSummary>[
      TreeIssueSummary(
        id: 'history-id',
        farmId: 'farm-id',
        treeId: 'tree-id',
        treeCode: 'TREE-A-001',
        sectionId: 'section-id',
        sectionCode: 'A',
        type: TreeIssueType.treeDamage,
        severity: IssueSeverity.high,
        status: TreeIssueStatus.resolved,
        reportedAt: DateTime.utc(2026, 7),
        activeIssueCount: 0,
        isClaimed: false,
        claimedByCurrentUser: false,
        canViewDetails: true,
        closedAt: DateTime.utc(2026, 8),
        assignedProfileId: 'worker-id',
        assignedName: 'Worker',
        source: IssueSource.inspection,
      ),
    ];

    expect((await repository.listManagerIssues('farm-id')).single.source,
        IssueSource.inspection);
    base.failManagerIssues = true;
    final cached = await repository.listManagerIssues('farm-id');
    expect(cached.single.assignedName, 'Worker');
    expect(cached.single.closedAt, DateTime.utc(2026, 8));
  });

  test('manager assignment is rejected offline and is never queued', () async {
    await expectLater(
      repository.assign(
        issueId: 'issue-id',
        assigneeProfileId: 'worker-id',
        requiresEngineerReview: true,
      ),
      throwsA(isA<OperationFailure>().having(
        (error) => error.kind,
        'kind',
        OperationFailureKind.offline,
      )),
    );

    expect(base.assignCalls, 0);
    expect(await outbox.pending(), isEmpty);
  });

  test('individual resolution queues exactly one idempotent action', () async {
    await repository.resolve(
      taskId: 'task-id',
      issueId: 'issue-id',
      notes: 'Dripper replaced',
    );

    final pending = await outbox.pending();
    expect(pending, hasLength(1));
    expect(pending.single.kind, PendingMutationKind.resolveIssue);
    expect(pending.single.payload['issueId'], 'issue-id');
    expect(pending.single.payload['taskId'], 'task-id');
    expect(pending.single.opId, isNotEmpty);
  });

  test('unable-to-fix preserves its typed reason and optional photo', () async {
    await repository.unableToFix(
      taskId: 'task-id',
      issueId: 'issue-id',
      reason: TreeIssueUnableReason.specialistRequired,
      notes: 'Needs agronomist',
      farmId: 'farm-id',
      preparedPhoto: PreparedIssuePhoto(
        bytes: Uint8List.fromList(<int>[4, 5, 6]),
        filename: 'unable.jpg',
        contentType: 'image/jpeg',
      ),
    );

    final pending = await outbox.pending();
    expect(pending.single.kind, PendingMutationKind.unableToFixIssue);
    expect(pending.single.payload['reason'], 'specialist_required');
    expect(await pendingPhotos.get(pending.single.opId), isNotNull);
  });

  test('required resolution photo is stored beside its offline op', () async {
    await repository.resolve(
      taskId: 'task-id',
      issueId: 'issue-id',
      farmId: 'farm-id',
      preparedPhoto: PreparedIssuePhoto(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        filename: 'resolution.jpg',
        contentType: 'image/jpeg',
      ),
    );

    final op = (await outbox.pending()).single;
    expect(op.payload['hasPendingPhoto'], isTrue);
    expect(await pendingPhotos.get(op.opId), isNotNull);
  });

  test('authorized issue details and event history fall back to private cache',
      () async {
    final now = DateTime.utc(2026, 9, 2, 10, 30);
    base.details = TreeIssueDetails(
      issue: TreeIssue(
        id: 'issue-id',
        farmId: 'farm-id',
        treeId: 'tree-id',
        type: TreeIssueType.cloggedDripper,
        severity: IssueSeverity.high,
        status: TreeIssueStatus.open,
        reportedByProfileId: 'worker-id',
        reportedAt: now,
        createdAt: now,
        updatedAt: now,
        description: 'Blocked emitter',
      ),
      events: <TreeIssueEvent>[
        TreeIssueEvent(
          id: 'event-id',
          issueId: 'issue-id',
          treeId: 'tree-id',
          actorProfileId: 'worker-id',
          type: TreeIssueEventType.detected,
          observedSeverity: IssueSeverity.high,
          newStatus: TreeIssueStatus.open,
          notes: 'Observed offline',
          createdAt: now,
        ),
      ],
      observations: <InspectionIssueObservation>[
        InspectionIssueObservation(
          id: 'observation-id',
          sessionId: 'session-id',
          itemId: 'item-id',
          issueId: 'issue-id',
          type: TreeIssueType.cloggedDripper,
          outcome: InspectionObservationOutcome.confirmed,
          observedSeverity: IssueSeverity.high,
          severityChanged: false,
          notes: 'Confirmed during the section walk',
          observedByProfileId: 'worker-id',
          observedAt: now,
          createdAt: now,
        ),
      ],
      linkedTasks: const <IssueLinkedTask>[
        IssueLinkedTask(
          taskId: 'task-id',
          title: 'Replace blocked emitter',
          status: TaskStatus.assigned,
          taskType: 'dripper_maintenance',
          canOpen: true,
        ),
      ],
      evidence: <TaskPhoto>[
        TaskPhoto(
          id: 'photo-id',
          taskId: 'task-id',
          storageBucketId: 'farm-evidence',
          storagePath: 'user/farm/task/photo.jpg',
          photoType: TaskPhotoType.issue,
          uploadedByProfileId: 'worker-id',
          createdAt: now,
        ),
      ],
    );

    final online = await repository.loadDetails('issue-id');
    base.failDetails = true;
    final cached = await repository.loadDetails('issue-id');

    expect(online.issue.description, 'Blocked emitter');
    expect(cached.events.single.type, TreeIssueEventType.detected);
    expect(cached.events.single.observedSeverity, IssueSeverity.high);
    expect(cached.events.single.notes, 'Observed offline');
    expect(cached.observations.single.outcome,
        InspectionObservationOutcome.confirmed);
    expect(cached.linkedTasks.single.status, TaskStatus.assigned);
    expect(cached.evidence.single.storagePath, 'user/farm/task/photo.jpg');
  });
}
