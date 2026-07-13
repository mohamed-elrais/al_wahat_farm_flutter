import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:al_wahat_farm_flutter/features/trees/presentation/tree_detail_sheet.dart';
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
}

void _noop() {}
