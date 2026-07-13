import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_report_controller.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_report_screen.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/scanner_screen.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/scanned_tree.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/phase4_fakes.dart';

void main() {
  testWidgets('worker scans a tree and reports a persisted issue',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const scanned = ScannedTree(
      id: 'tree-id',
      farmId: 'farm-id',
      sectionId: 'section-id',
      sectionCode: 'B',
      sectionName: 'Section B',
      code: 'TREE-B-120',
      healthStatus: 'healthy',
      type: 'date_palm',
      rowNumber: 4,
      treeNumber: 120,
    );
    final issueRepository = FakeTreeIssueRepository();
    final issueController = IssueReportController(
      repository: issueRepository,
      photoPicker: FakeIssuePhotoPicker(),
      photoStorage: FakeIssuePhotoStorage(),
      userId: 'worker-id',
      farmId: 'farm-id',
      treeId: 'tree-id',
    );
    addTearDown(issueController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: _WorkerFlow(
          scannerRepository: FakeTreeQrRepository(result: scanned),
          issueController: issueController,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('integration-emit-qr')));
    await tester.pumpAndSettle();
    expect(find.text('TREE-B-120'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('issue-submit')));
    await tester.tap(find.byKey(const Key('issue-submit')));
    await tester.pumpAndSettle();

    expect(issueRepository.reportedDraft?.treeId, 'tree-id');
    expect(
      find.text('Issue reported and engineer review task created.'),
      findsOneWidget,
    );
  });
}

class _WorkerFlow extends StatefulWidget {
  const _WorkerFlow({
    required this.scannerRepository,
    required this.issueController,
  });

  final FakeTreeQrRepository scannerRepository;
  final IssueReportController issueController;

  @override
  State<_WorkerFlow> createState() => _WorkerFlowState();
}

class _WorkerFlowState extends State<_WorkerFlow> {
  ScannedTree? _tree;

  @override
  Widget build(BuildContext context) {
    final tree = _tree;
    if (tree == null) {
      return ScannerScreen(
        repository: widget.scannerRepository,
        scannerBuilder: (_, onToken) => Center(
          child: ElevatedButton(
            key: const Key('integration-emit-qr'),
            onPressed: () => onToken('test-token'),
            child: const Text('Scan'),
          ),
        ),
        onTreeFound: (value) => setState(() => _tree = value),
      );
    }
    return IssueReportScreen(
      treeId: tree.id,
      tree: TreeIdentity(
        id: tree.id,
        farmId: tree.farmId,
        code: tree.code,
        sectionCode: tree.sectionCode,
        zoneLabel: tree.irrigationZoneId,
        rowNumber: tree.rowNumber,
        treeNumber: tree.treeNumber,
        healthStatus: tree.healthStatus,
        type: tree.type,
      ),
      controller: widget.issueController,
    );
  }
}
