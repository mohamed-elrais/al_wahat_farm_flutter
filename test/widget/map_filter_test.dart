import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/issues/data/issue_workspace_repository.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_workspace_controller.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/map/domain/projected_map.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_screen.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/farm_map_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/farm_hierarchy_fixture.dart';
import '../support/projected_farm_map_fixture.dart';

class _IssueRepository implements IssueWorkspaceRepository {
  _IssueRepository(this.summaries);

  final List<TreeIssueSummary> summaries;

  @override
  Future<List<TreeIssueSummary>> listSummaries(
    String farmId, {
    IssueSummaryFilter filter = const IssueSummaryFilter(),
  }) async =>
      summaries;

  @override
  Future<List<TreeIssueSummary>> listManagerIssues(String farmId) async =>
      summaries;

  @override
  Future<List<TreeIssueOccurrence>> listTreeHistory(String treeId) async =>
      const <TreeIssueOccurrence>[];

  @override
  Future<TreeIssueDetails> loadDetails(String issueId) =>
      throw UnimplementedError();

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
  Future<void> dismiss(String issueId, String notes, {String? opId}) async {}

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

FarmMapPainter _mapPainter(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is FarmMapPainter,
  );
  return tester.widget<CustomPaint>(finder.last).painter! as FarmMapPainter;
}

void main() {
  testWidgets('section filter switches map heading to unplanted section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final map = await tester.runAsync(loadComposedFarmMap);
    final hierarchy = (await DefaultFarmHierarchyRepository(
      CanonicalFarmHierarchyDataSource.load(),
      MemoryFarmHierarchyCache(),
    ).load(CanonicalFarmHierarchyDataSource.farmId))
        .hierarchy;

    await tester.pumpWidget(
      FarmHierarchyScope(
        snapshot: FarmHierarchySnapshot(
          hierarchy: hierarchy,
          source: FarmHierarchySource.network,
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body:
                FarmMapScreen(mapFuture: Future<ProjectedFarmMap>.value(map!)),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('section-all')), findsOneWidget);
    final sectionE = find.byKey(const Key('section-E'));
    final sectionFilter = find.byKey(const Key('map-section-filter'));
    await tester.scrollUntilVisible(
      sectionE,
      200,
      scrollable: find.descendant(
        of: sectionFilter,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(sectionE);
    await tester.pumpAndSettle();
    expect(sectionE, findsOneWidget);
    await tester.tap(sectionE);
    await tester.pump();
    expect(find.text('Section E · Unplanted'), findsOneWidget);
  });

  testWidgets('issue markers, filters and full-screen controls stay in parity',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = await tester.runAsync(loadComposedFarmMap);
    final firstTree = map!.data.trees.first;
    final secondTree = map.data.trees.firstWhere(
        (tree) => tree.section == firstTree.section && tree != firstTree);
    final now = DateTime.utc(2026, 9, 3);
    TreeIssueSummary summary({
      required String id,
      required String treeId,
      required String treeCode,
      required TreeIssueType type,
      required IssueSeverity severity,
      required TreeIssueStatus status,
    }) =>
        TreeIssueSummary(
          id: id,
          farmId: 'farm-id',
          treeId: treeId,
          treeCode: treeCode,
          sectionId: 'section-id',
          sectionCode: firstTree.section,
          type: type,
          severity: severity,
          status: status,
          reportedAt: now,
          activeIssueCount: treeId == firstTree.id ? 2 : 1,
          isClaimed: false,
          claimedByCurrentUser: false,
          canViewDetails: false,
        );
    final controller = IssueWorkspaceController(
      farmId: 'farm-id',
      repository: _IssueRepository(<TreeIssueSummary>[
        summary(
          id: 'issue-1',
          treeId: firstTree.id,
          treeCode: firstTree.code,
          type: TreeIssueType.dripperProblem,
          severity: IssueSeverity.low,
          status: TreeIssueStatus.open,
        ),
        summary(
          id: 'issue-2',
          treeId: firstTree.id,
          treeCode: firstTree.code,
          type: TreeIssueType.pestOrDisease,
          severity: IssueSeverity.urgent,
          status: TreeIssueStatus.inReview,
        ),
        summary(
          id: 'issue-3',
          treeId: secondTree.id,
          treeCode: secondTree.code,
          type: TreeIssueType.treeDamage,
          severity: IssueSeverity.medium,
          status: TreeIssueStatus.open,
        ),
      ]),
    );
    await controller.load();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      IssueWorkspaceScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: FarmMapScreen(
              mapFuture: Future<ProjectedFarmMap>.value(map),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map-active-issue-layer')));
    await tester.pump();

    var painter = _mapPainter(tester);
    expect(painter.issueMarkers, hasLength(2));
    expect(painter.issueMarkers![firstTree.id]!.count, 2);
    expect(
      painter.issueMarkers![firstTree.id]!.severity,
      IssueSeverity.urgent,
    );
    expect(
      find.bySemanticsLabel(
        'Issue layer: 2 matching trees with 3 active issues',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('map-issue-filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-issue-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('map-issue-severity-filter')), findsOneWidget);
    expect(find.byKey(const Key('map-issue-status-filter')), findsOneWidget);
    expect(find.byKey(const Key('map-issue-section-filter')), findsOneWidget);
    await tester.tap(find.byKey(const Key('map-issue-type-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dripper problem').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('map-issue-matches-only')));
    await tester.tap(find.byKey(const Key('map-issue-filters-apply')));
    await tester.pumpAndSettle();

    painter = _mapPainter(tester);
    expect(painter.issueMarkers, hasLength(1));
    expect(painter.issueMarkers![firstTree.id]!.count, 1);
    expect(painter.showIssueMatchesOnly, isTrue);

    await tester.tap(find.byIcon(Icons.fullscreen));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fullscreen-map-issue-layer')), findsOneWidget);
    expect(
        find.byKey(const Key('fullscreen-map-issue-filters')), findsOneWidget);
    painter = _mapPainter(tester);
    expect(painter.issueMarkers, hasLength(1));
    expect(painter.showIssueMatchesOnly, isTrue);

    await tester.tap(find.byKey(const Key('fullscreen-map-issue-filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('map-issue-filters-sheet')), findsOneWidget);
  });
}
