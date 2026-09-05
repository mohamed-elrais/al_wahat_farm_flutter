import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/connectivity/connectivity_service.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_workspace_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_detail_screen.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issues_screen.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 9, 2, 10, 30);

class _Repository implements IssueWorkspaceRepository {
  _Repository(this.details, {this.summaries = const <TreeIssueSummary>[]});

  final TreeIssueDetails details;
  final List<TreeIssueSummary> summaries;

  @override
  Future<TreeIssueDetails> loadDetails(String issueId) async => details;

  @override
  Future<List<TreeIssueOccurrence>> listTreeHistory(String treeId) async =>
      const <TreeIssueOccurrence>[];

  @override
  Future<List<TreeIssueSummary>> listSummaries(
    String farmId, {
    IssueSummaryFilter filter = const IssueSummaryFilter(),
  }) async =>
      summaries.where((issue) => issue.isActive).toList(growable: false);

  @override
  Future<List<TreeIssueSummary>> listManagerIssues(String farmId) async =>
      summaries;

  @override
  Future<List<TaskTreeIssueWork>> listTaskWork(String taskId) async =>
      const <TaskTreeIssueWork>[];

  @override
  Future<String> claim(String issueId) => throw UnimplementedError();

  @override
  Future<String> assign({
    required String issueId,
    required String assigneeProfileId,
    required bool requiresEngineerReview,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> changeSeverity(
    String issueId,
    IssueSeverity severity, {
    String? notes,
    String? opId,
  }) async {}

  @override
  Future<void> dismiss(
    String issueId,
    String notes, {
    String? opId,
  }) async {}

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

class _OfflineConnectivity implements ConnectivityService {
  @override
  Future<NetworkStatus> current() async => NetworkStatus.offline;

  @override
  Stream<NetworkStatus> get changes => const Stream<NetworkStatus>.empty();
}

void main() {
  testWidgets('authorized manager sees history and lifecycle controls',
      (tester) async {
    await _pump(tester, FarmRole.owner);

    expect(find.text('Clogged dripper'), findsOneWidget);
    expect(find.text('Section A · TREE-A-001'), findsOneWidget);
    expect(find.text('Confirmed during inspection'), findsOneWidget);
    expect(find.text('Replace blocked emitter'), findsOneWidget);
    expect(find.text('Issue evidence (1)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Issue detected'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Issue detected'), findsOneWidget);
    expect(find.text('Emitter blocked'), findsWidgets);
    expect(
        find.byKey(const Key('change-issue-severity-button')), findsOneWidget);
    expect(find.byKey(const Key('dismiss-issue-button')), findsOneWidget);
  });

  testWidgets('authorized worker history does not expose manager actions',
      (tester) async {
    await _pump(tester, FarmRole.worker);

    expect(find.text('Issue detected'), findsOneWidget);
    expect(find.byKey(const Key('change-issue-severity-button')), findsNothing);
    expect(find.byKey(const Key('dismiss-issue-button')), findsNothing);
  });

  testWidgets('worker self-claim is disabled with an offline explanation',
      (tester) async {
    await _pump(tester, FarmRole.worker, showIssues: true);

    final finder = find.byKey(const Key('issue-claim-offline-issue-id'));
    expect(finder, findsOneWidget);
    expect(tester.widget<OutlinedButton>(finder).onPressed, isNull);
    expect(find.text('Connect to the internet to claim this issue'),
        findsOneWidget);
  });

  testWidgets('manager separates active issues from history with full filters',
      (tester) async {
    await _pump(tester, FarmRole.owner, showIssues: true);

    expect(find.text('Active (1)'), findsOneWidget);
    expect(find.text('History (1)'), findsOneWidget);
    expect(find.text('Issue age'), findsOneWidget);
    expect(find.text('Assignment'), findsOneWidget);
    expect(find.text('Source'), findsOneWidget);
    expect(
        find.byKey(const Key('issue-assign-offline-issue-id')), findsOneWidget);

    await tester.tap(find.byKey(const Key('issues-history-view')));
    await tester.pumpAndSettle();

    expect(find.text('Tree damage'), findsOneWidget);
    expect(find.text('Resolved'), findsWidgets);
    expect(find.byKey(const Key('issue-assign-offline-past-issue-id')),
        findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester,
  FarmRole role, {
  bool showIssues = false,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final details = TreeIssueDetails(
    issue: TreeIssue(
      id: 'issue-id',
      farmId: 'farm-id',
      treeId: 'tree-id',
      type: TreeIssueType.cloggedDripper,
      severity: IssueSeverity.high,
      status: TreeIssueStatus.open,
      reportedByProfileId: 'worker-id',
      reportedAt: _now,
      createdAt: _now,
      updatedAt: _now,
      description: 'Emitter blocked',
    ),
    events: <TreeIssueEvent>[
      TreeIssueEvent(
        id: 'event-id',
        issueId: 'issue-id',
        treeId: 'tree-id',
        actorProfileId: 'worker-id',
        type: TreeIssueEventType.detected,
        observedSeverity: IssueSeverity.high,
        notes: 'Emitter blocked',
        createdAt: _now,
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
        notes: 'Emitter remains blocked',
        observedByProfileId: 'worker-id',
        observedAt: _now,
        createdAt: _now,
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
        createdAt: _now,
      ),
    ],
  );
  final repository = _Repository(
    details,
    summaries: showIssues
        ? <TreeIssueSummary>[
            TreeIssueSummary(
              id: 'issue-id',
              farmId: 'farm-id',
              treeId: 'tree-id',
              treeCode: 'TREE-A-001',
              sectionId: 'section-id',
              sectionCode: 'A',
              type: TreeIssueType.cloggedDripper,
              severity: IssueSeverity.high,
              status: TreeIssueStatus.open,
              reportedAt: _now,
              activeIssueCount: 1,
              isClaimed: false,
              claimedByCurrentUser: false,
              canViewDetails: false,
              source: IssueSource.quickReport,
            ),
            TreeIssueSummary(
              id: 'past-issue-id',
              farmId: 'farm-id',
              treeId: 'tree-id',
              treeCode: 'TREE-A-001',
              sectionId: 'section-id',
              sectionCode: 'A',
              type: TreeIssueType.treeDamage,
              severity: IssueSeverity.medium,
              status: TreeIssueStatus.resolved,
              reportedAt: _now.subtract(const Duration(days: 40)),
              activeIssueCount: 1,
              isClaimed: false,
              claimedByCurrentUser: false,
              canViewDetails: true,
              closedAt: _now,
              assignedProfileId: 'worker-id',
              assignedName: 'Issue Worker',
              source: IssueSource.inspection,
            ),
          ]
        : const <TreeIssueSummary>[],
  );
  final controller = IssueWorkspaceController(
    farmId: 'farm-id',
    repository: repository,
    isManager: role.canManageTasks,
  );
  addTearDown(controller.dispose);
  final connectivity = ConnectivityController(_OfflineConnectivity());
  await connectivity.start();
  addTearDown(connectivity.dispose);
  if (showIssues) await controller.load();
  final contextData = OperationalContext(
    profile: const UserProfile(
      id: 'profile-id',
      fullName: 'Farm member',
      isActive: true,
    ),
    memberships: <FarmMembership>[
      FarmMembership(
        id: 'membership-id',
        profileId: 'profile-id',
        role: role,
        isActive: true,
        farm: const FarmSummary(
          id: 'farm-id',
          name: 'Al Wahat',
          code: 'AL-WAHAT',
          timezone: 'Africa/Cairo',
        ),
      ),
    ],
  );
  final hierarchy = FarmHierarchy(
    farmId: 'farm-id',
    sections: <FarmSection>[
      FarmSection(
        id: 'section-id',
        farmId: 'farm-id',
        code: 'A',
        name: 'Section A',
        sortOrder: 1,
        isActive: true,
        createdAt: _now,
        updatedAt: _now,
      ),
    ],
    zones: const <IrrigationZone>[],
    trees: <FarmTreeRecord>[
      FarmTreeRecord(
        id: 'tree-id',
        farmId: 'farm-id',
        sectionId: 'section-id',
        treeCode: 'TREE-A-001',
        healthStatus: TreeHealthStatus.needsMonitoring,
        type: 'date_palm',
        isActive: true,
        createdAt: _now,
        updatedAt: _now,
      ),
    ],
  );

  await tester.pumpWidget(
    OperationalContextScope(
      contextData: contextData,
      child: FarmHierarchyScope(
        snapshot: FarmHierarchySnapshot(
          hierarchy: hierarchy,
          source: FarmHierarchySource.network,
        ),
        child: IssueWorkspaceScope(
          controller: controller,
          child: MaterialApp(
            theme: AppTheme.light,
            home: showIssues
                ? IssuesScreen(connectivity: connectivity)
                : const IssueDetailScreen(issueId: 'issue-id'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
