import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/issue_photo.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_report_controller.dart';
import 'package:al_wahat_farm_flutter/features/issues/presentation/issue_report_screen.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/tree_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/phase4_fakes.dart';

const _tree = TreeIdentity(
  id: 'tree-id',
  farmId: 'farm-id',
  code: 'TREE-B-120',
  sectionCode: 'B',
  rowNumber: 4,
  treeNumber: 120,
  healthStatus: 'healthy',
  type: 'date_palm',
);

void main() {
  testWidgets('issue form persists issue and generated review task', (
    tester,
  ) async {
    final repository = FakeTreeIssueRepository();
    final controller = IssueReportController(
      repository: repository,
      photoPicker: FakeIssuePhotoPicker(),
      photoStorage: FakeIssuePhotoStorage(),
      userId: 'user-id',
      farmId: 'farm-id',
      treeId: 'tree-id',
    );
    addTearDown(controller.dispose);
    await _pumpForm(tester, controller);

    await tester.enterText(
      find.byKey(const Key('issue-description')),
      'Emitter is blocked',
    );
    await tester.ensureVisible(find.byKey(const Key('issue-submit')));
    await tester.tap(find.byKey(const Key('issue-submit')));
    await tester.pumpAndSettle();

    expect(find.text('TREE-B-120'), findsOneWidget);
    expect(repository.reportedDraft?.description, 'Emitter is blocked');
    expect(
      find.text('Issue reported and engineer review task created.'),
      findsOneWidget,
    );
  });

  testWidgets('photo failure reports honest partial success and retry', (
    tester,
  ) async {
    final picker = FakeIssuePhotoPicker(
      photo: PreparedIssuePhoto(
        bytes: Uint8List.fromList(<int>[1, 2, 3]),
        filename: 'issue.jpg',
        contentType: 'image/jpeg',
      ),
    );
    final storage = FakeIssuePhotoStorage()
      ..uploadFailure = const OperationFailure(
        OperationFailureKind.offline,
        'No connection.',
      );
    final controller = IssueReportController(
      repository: FakeTreeIssueRepository(),
      photoPicker: picker,
      photoStorage: storage,
      userId: 'user-id',
      farmId: 'farm-id',
      treeId: 'tree-id',
    );
    addTearDown(controller.dispose);
    await _pumpForm(tester, controller);

    await tester.ensureVisible(find.byKey(const Key('issue-photo-gallery')));
    await tester.tap(find.byKey(const Key('issue-photo-gallery')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('issue-submit')));
    await tester.tap(find.byKey(const Key('issue-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('issue-photo-retry')), findsOneWidget);
    expect(find.textContaining('issue and review task were saved'),
        findsOneWidget);
  });
}

Future<void> _pumpForm(
  WidgetTester tester,
  IssueReportController controller,
) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: IssueReportScreen(
        treeId: _tree.id,
        tree: _tree,
        controller: controller,
      ),
    ),
  );
  await tester.pump();
}
