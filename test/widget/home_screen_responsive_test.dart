import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/presentation/farm_hierarchy_gate.dart';
import 'package:al_wahat_farm_flutter/features/home/presentation/home_screen.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/farm_hierarchy_fixture.dart';

void main() {
  testWidgets('keeps the farm overview readable on an 11-inch iPad portrait',
      (tester) async {
    tester.view.physicalSize = const Size(820, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: HomeScreen()),
      ),
    );

    expect(tester.takeException(), isNull);

    final overviewTitle = find.text('Al Wahat farm overview');
    final operationsTitle = find.text('Today’s tasks');
    expect(overviewTitle, findsOneWidget);
    expect(operationsTitle, findsOneWidget);
    expect(tester.getSize(overviewTitle).width, greaterThan(300));
    expect(tester.getSize(operationsTitle).width, greaterThan(300));
  });

  testWidgets('farm overview shows every live hierarchy total', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1539'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('122'), findsOneWidget);
    expect(find.text('1876'), findsOneWidget);
    expect(find.text('Planting pits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date above the title is today, in the app language',
      (tester) async {
    Future<void> pumpIn(Locale locale) => tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: Scaffold(body: HomeScreen(today: DateTime(2026, 10, 13))),
          ),
        );

    await pumpIn(const Locale('en'));
    await tester.pumpAndSettle();
    expect(find.text('TUESDAY · 13 OCTOBER'), findsOneWidget);

    await pumpIn(const Locale('ar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('الثلاثاء'), findsOneWidget);
    expect(find.textContaining('أكتوبر'), findsOneWidget);
    expect(find.textContaining('يوليو'), findsNothing);
  });
}
