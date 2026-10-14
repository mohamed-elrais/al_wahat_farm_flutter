import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/widgets/option_visuals.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/inspections/data/inspection_repository.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_models.dart';
import 'package:al_wahat_farm_flutter/features/inspections/domain/inspection_route.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_repository_scope.dart';
import 'package:al_wahat_farm_flutter/features/inspections/presentation/inspection_runner_screen.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _InspectionRepository implements InspectionRepository {
  _InspectionRepository(this.details);

  final InspectionDetails details;
  List<InspectionTreeResult>? savedResults;
  int takeoverCalls = 0;

  @override
  Future<InspectionDetails> loadByTask(String taskId) async => details;

  @override
  Future<void> takeOver(String sessionId, {String? opId}) async {
    takeoverCalls++;
  }

  @override
  Future<InspectionCreationResult> create(
    InspectionCreationDraft draft, {
    String? opId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> saveStation(
    String sessionId,
    int stationIndex,
    List<InspectionTreeResult> results, {
    String? opId,
    Map<String, PreparedTaskEvidence> photos = const {},
    String? userId,
    String? farmId,
    String? taskId,
  }) async {
    savedResults = results;
  }

  @override
  Future<void> setStatus(
    String sessionId,
    InspectionSessionStatus status, {
    String? opId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> submit(
    String sessionId, {
    String? note,
    String? opId,
  }) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('paired station meets mobile accessibility guidelines',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final repository = _InspectionRepository(_activeStationDetails());

    await tester.pumpWidget(
      InspectionRepositoryScope(
        repository: repository,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const InspectionRunnerScreen(taskId: 'task-id'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TREE-A-001'), findsOneWidget);
    expect(find.text('TREE-A-002'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  testWidgets('paired station survives Arabic 200% text and reduced motion',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures.allOn;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );
    addTearDown(
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final semantics = tester.ensureSemantics();
    final repository = _InspectionRepository(_activeStationDetails());

    await tester.pumpWidget(
      InspectionRepositoryScope(
        repository: repository,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const InspectionRunnerScreen(taskId: 'task-id'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('TREE-A-001'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('TREE-A-001'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('TREE-A-002'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('TREE-A-002'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('TREE-A-001.*الجهة اليسرى فعليًا'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp('TREE-A-002.*الجهة اليمنى فعليًا'),
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('final review navigates backward through saved stations',
      (tester) async {
    final repository = _InspectionRepository(_completedDetails());
    await tester.pumpWidget(
      InspectionRepositoryScope(
        repository: repository,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const InspectionRunnerScreen(taskId: 'task-id'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review before submission'), findsOneWidget);
    expect(find.byKey(const Key('inspection-submit')), findsOneWidget);

    await tester.tap(find.byKey(const Key('inspection-review-previous')));
    await tester.pumpAndSettle();

    expect(find.text('Station 2 of 2'), findsOneWidget);
    expect(find.text('TREE-A-002'), findsOneWidget);
    expect(find.text('Edit issues'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inspection-report-tree-2')));
    await tester.pumpAndSettle();
    final damageChip = tester.widget<OptionTile>(
      find.widgetWithText(OptionTile, 'Tree damage'),
    );
    expect(damageChip.selected, isTrue);
    expect(find.text('Issue photo prepared'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inspection-issue-done')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('inspection-save-next')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('inspection-save-next')));
    await tester.pumpAndSettle();

    expect(
      repository.savedResults!.single.selectedIssues.single.photoStoragePath,
      'worker/farm-id/task-id/damage.jpg',
    );
    expect(find.text('Review before submission'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inspection-review-previous')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('inspection-previous')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('inspection-previous')));
    await tester.pumpAndSettle();

    expect(find.text('Station 1 of 2'), findsOneWidget);
    expect(find.text('TREE-A-001'), findsOneWidget);
  });

  testWidgets('manager can explicitly take over another inspector session',
      (tester) async {
    final repository = _InspectionRepository(_completedDetails());
    final operational = OperationalContext(
      profile: const UserProfile(
        id: 'manager-id',
        fullName: 'Farm manager',
        isActive: true,
      ),
      memberships: <FarmMembership>[
        const FarmMembership(
          id: 'membership-id',
          profileId: 'manager-id',
          role: FarmRole.owner,
          isActive: true,
          farm: FarmSummary(
            id: 'farm-id',
            name: 'Al Wahat',
            code: 'AL-WAHAT',
            timezone: 'Africa/Cairo',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      OperationalContextScope(
        contextData: operational,
        child: InspectionRepositoryScope(
          repository: repository,
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const InspectionRunnerScreen(taskId: 'task-id'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inspection-takeover')), findsOneWidget);
    expect(find.byKey(const Key('inspection-submit')), findsNothing);
    await tester.tap(find.byKey(const Key('inspection-takeover')));
    await tester.pumpAndSettle();

    expect(repository.takeoverCalls, 1);
  });
}

InspectionDetails _activeStationDetails() {
  final now = DateTime.utc(2026, 9, 5, 8);
  return InspectionDetails(
    session: InspectionSession(
      id: 'session-id',
      farmId: 'farm-id',
      sectionId: 'section-id',
      taskId: 'task-id',
      inspectorProfileId: 'worker-id',
      createdByProfileId: 'manager-id',
      startingTreeId: 'tree-1',
      status: InspectionSessionStatus.inProgress,
      routeVersion: 2,
      totalStations: 1,
      totalTrees: 2,
      inspectedTrees: 0,
      requiresIssuePhoto: false,
      revision: 0,
      createdAt: now,
      updatedAt: now,
    ),
    items: const <InspectionSessionItem>[
      InspectionSessionItem(
        id: 'item-1',
        sessionId: 'session-id',
        routeItem: InspectionRouteItem(
          treeId: 'tree-1',
          treeCode: 'TREE-A-001',
          sequenceIndex: 1,
          corridorIndex: 1,
          stationIndex: 1,
          side: InspectionRouteSide.left,
          rowNumber: 1,
          treeNumber: 1,
        ),
        status: InspectionItemStatus.pending,
        noNewIssueFound: false,
      ),
      InspectionSessionItem(
        id: 'item-2',
        sessionId: 'session-id',
        routeItem: InspectionRouteItem(
          treeId: 'tree-2',
          treeCode: 'TREE-A-002',
          sequenceIndex: 2,
          corridorIndex: 1,
          stationIndex: 1,
          side: InspectionRouteSide.right,
          rowNumber: 2,
          treeNumber: 2,
        ),
        status: InspectionItemStatus.pending,
        noNewIssueFound: false,
      ),
    ],
  );
}

InspectionDetails _completedDetails() {
  final now = DateTime.utc(2026, 9, 4, 8);
  const firstRoute = InspectionRouteItem(
    treeId: 'tree-1',
    treeCode: 'TREE-A-001',
    sequenceIndex: 1,
    corridorIndex: 1,
    stationIndex: 1,
    side: InspectionRouteSide.left,
  );
  const secondRoute = InspectionRouteItem(
    treeId: 'tree-2',
    treeCode: 'TREE-A-002',
    sequenceIndex: 2,
    corridorIndex: 1,
    stationIndex: 2,
    side: InspectionRouteSide.right,
  );
  return InspectionDetails(
    session: InspectionSession(
      id: 'session-id',
      farmId: 'farm-id',
      sectionId: 'section-id',
      taskId: 'task-id',
      inspectorProfileId: 'worker-id',
      createdByProfileId: 'manager-id',
      startingTreeId: 'tree-1',
      status: InspectionSessionStatus.inProgress,
      routeVersion: 1,
      totalStations: 2,
      totalTrees: 2,
      inspectedTrees: 2,
      requiresIssuePhoto: true,
      revision: 2,
      createdAt: now,
      updatedAt: now,
    ),
    items: <InspectionSessionItem>[
      InspectionSessionItem(
        id: 'item-1',
        sessionId: 'session-id',
        routeItem: firstRoute,
        status: InspectionItemStatus.inspected,
        noNewIssueFound: true,
        notes: 'Tree is clear',
        observedAt: now,
      ),
      InspectionSessionItem(
        id: 'item-2',
        sessionId: 'session-id',
        routeItem: secondRoute,
        status: InspectionItemStatus.inspected,
        noNewIssueFound: false,
        notes: 'Broken branch',
        observedAt: now,
      ),
    ],
    observations: <InspectionStationObservation>[
      InspectionStationObservation(
        id: 'observation-id',
        sessionId: 'session-id',
        itemId: 'item-2',
        treeIssueId: 'issue-id',
        type: TreeIssueType.treeDamage,
        outcome: InspectionStationObservationOutcome.confirmed,
        observedSeverity: IssueSeverity.high,
        severityChanged: false,
        notes: 'Broken branch',
        photoStoragePath: 'worker/farm-id/task-id/damage.jpg',
        observedAt: now,
      ),
    ],
  );
}
