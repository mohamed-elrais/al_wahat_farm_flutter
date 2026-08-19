import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
