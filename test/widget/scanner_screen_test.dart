import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/map/presentation/scanner_screen.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/scanned_tree.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
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

  testWidgets('an insecure web page explains why the camera is unavailable',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ScannerScreen(
          repository: FakeTreeQrRepository(result: scanned),
          isSecureContext: () => false,
        ),
      ),
    );

    expect(find.byKey(const Key('scanner-insecure-context')), findsOneWidget);
    expect(find.text(AppLocalizationsEn().scanCameraInsecure), findsOneWidget);
  });

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

  testWidgets('the camera is released while another tab is shown', (
    tester,
  ) async {
    // StatefulShellRoute.indexedStack keeps the scan tab mounted with tickers
    // disabled while another tab is active; the camera view must not survive.
    final events = <String>[];
    var active = true;
    late StateSetter setActive;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) {
            setActive = setState;
            return TickerMode(
              enabled: active,
              child: ScannerScreen(
                repository: FakeTreeQrRepository(result: scanned),
                scannerBuilder: (_, __) => _CameraProbe(events),
              ),
            );
          },
        ),
      ),
    );
    expect(events, <String>['start']);

    setActive(() => active = false);
    await tester.pump();
    expect(events, <String>['start', 'stop']);

    setActive(() => active = true);
    await tester.pump();
    expect(events, <String>['start', 'stop', 'start']);
  });
}

class _CameraProbe extends StatefulWidget {
  const _CameraProbe(this.events);

  final List<String> events;

  @override
  State<_CameraProbe> createState() => _CameraProbeState();
}

class _CameraProbeState extends State<_CameraProbe> {
  @override
  void initState() {
    super.initState();
    widget.events.add('start');
  }

  @override
  void dispose() {
    widget.events.add('stop');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
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
