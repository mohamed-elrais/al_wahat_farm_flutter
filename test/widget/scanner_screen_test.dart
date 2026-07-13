import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/scanner_screen.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/scanned_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/phase4_fakes.dart';

void main() {
  const scanned = ScannedTree(
    id: 'tree-id',
    farmId: 'farm-id',
    sectionId: 'section-id',
    sectionCode: 'B',
    sectionName: 'Section B',
    irrigationZoneId: 'zone-id',
    code: 'TREE-B-120',
    rowNumber: 4,
    treeNumber: 120,
    healthStatus: 'healthy',
    type: 'date_palm',
  );

  testWidgets('valid QR opens the exact typed tree', (tester) async {
    final repository = FakeTreeQrRepository(result: scanned);
    ScannedTree? found;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ScannerScreen(
          repository: repository,
          scannerBuilder: _testScanner,
          onTreeFound: (tree) => found = tree,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('emit-qr')));
    await tester.pumpAndSettle();

    expect(repository.tokens, <String>['test-token']);
    expect(found?.id, 'tree-id');
    expect(found?.code, 'TREE-B-120');
  });

  testWidgets('offline scan displays an understandable retry message', (
    tester,
  ) async {
    final repository = FakeTreeQrRepository(
      failure: const OperationFailure(
        OperationFailureKind.offline,
        'Unable to scan while offline.',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ScannerScreen(
          repository: repository,
          scannerBuilder: _testScanner,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('emit-qr')));
    await tester.pumpAndSettle();

    expect(find.text('Unable to scan while offline.'), findsOneWidget);
  });
}

Widget _testScanner(
  BuildContext context,
  Future<void> Function(String token) onToken,
) =>
    Center(
      child: ElevatedButton(
        key: const Key('emit-qr'),
        onPressed: () => onToken('test-token'),
        child: const Text('Emit QR'),
      ),
    );
