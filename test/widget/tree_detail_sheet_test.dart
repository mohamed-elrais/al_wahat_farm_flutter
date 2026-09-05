import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_workspace.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:al_wahat_farm_flutter/features/trees/presentation/tree_detail_sheet.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tree = TreeIdentity(
    id: 'tree-id',
    farmId: 'farm-id',
    code: 'TREE-B-120',
    sectionCode: 'B',
    zoneLabel: 'B-ZCV-03',
    rowNumber: 4,
    treeNumber: 120,
    healthStatus: 'healthy',
    type: 'date_palm',
    latitude: 28.2933481,
    longitude: 28.7475982,
  );

  testWidgets('manager tree sheet shows details and both actions',
      (tester) async {
    var attached = false;
    var reported = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox.expand(
            child: TreeDetailSheet(
              tree: tree,
              onAttachTask: () => attached = true,
              onReportIssue: () => reported = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('TREE-B-120'), findsOneWidget);
    expect(find.text('28.2933481, 28.7475982'), findsOneWidget);
    expect(find.text('B-ZCV-03'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tree-attach-task')));
    await tester.tap(find.byKey(const Key('tree-report-issue')));
    expect(attached, isTrue);
    expect(reported, isTrue);
  });

  testWidgets('worker tree sheet omits manager task action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SizedBox.expand(
            child: TreeDetailSheet(
              tree: tree,
              onReportIssue: _noop,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('tree-attach-task')), findsNothing);
    expect(find.byKey(const Key('tree-report-issue')), findsOneWidget);
  });

  testWidgets('tree sheet separates active issues from past occurrences',
      (tester) async {
    final now = DateTime.utc(2026, 9, 3);
    var openedIssue = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TreeDetailSheet(
            tree: tree,
            activeIssues: <TreeIssueSummary>[
              TreeIssueSummary(
                id: 'active-issue',
                farmId: 'farm-id',
                treeId: 'tree-id',
                treeCode: tree.code,
                sectionId: 'section-id',
                sectionCode: tree.sectionCode,
                type: TreeIssueType.cloggedDripper,
                severity: IssueSeverity.high,
                status: TreeIssueStatus.open,
                reportedAt: now,
                activeIssueCount: 1,
                isClaimed: false,
                claimedByCurrentUser: false,
                canViewDetails: true,
              ),
            ],
            loadHistory: () async => <TreeIssueOccurrence>[
              TreeIssueOccurrence(
                id: 'resolved-issue',
                type: TreeIssueType.pestOrDisease,
                severity: IssueSeverity.medium,
                status: TreeIssueStatus.resolved,
                reportedAt: DateTime.utc(2026, 8, 1),
                closedAt: DateTime.utc(2026, 8, 4),
              ),
            ],
            onOpenIssue: (id) => openedIssue = id,
            onReportIssue: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tree-active-issues')), findsOneWidget);
    expect(find.text('Active issues (1)'), findsOneWidget);
    expect(find.text('Clogged dripper'), findsOneWidget);
    expect(find.text('Past issue occurrences'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pest or disease'),
      160,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Pest or disease'), findsOneWidget);

    await tester.tap(find.text('Clogged dripper'));
    expect(openedIssue, 'active-issue');
  });

  testWidgets('tree issue sections are localized and fit a narrow Arabic view',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.utc(2026, 9, 3);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TreeDetailSheet(
            tree: tree,
            activeIssues: <TreeIssueSummary>[
              TreeIssueSummary(
                id: 'active-issue',
                farmId: 'farm-id',
                treeId: 'tree-id',
                treeCode: tree.code,
                sectionId: 'section-id',
                sectionCode: tree.sectionCode,
                type: TreeIssueType.insufficientIrrigation,
                severity: IssueSeverity.urgent,
                status: TreeIssueStatus.inReview,
                reportedAt: now,
                activeIssueCount: 1,
                isClaimed: true,
                claimedByCurrentUser: false,
                canViewDetails: false,
              ),
            ],
            loadHistory: () async => const <TreeIssueOccurrence>[],
            onReportIssue: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('المشكلات النشطة (1)'), findsOneWidget);
    expect(find.text('المشكلات السابقة', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
