import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_controller.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/inventory_fakes.dart';

void main() {
  testWidgets('inventory list shows items, categories, and low-stock badges',
      (tester) async {
    final repo = FakeInventoryRepository();
    final fertilizer = repo.seedCategory('fertilizer');
    repo.seedCategory('tool');
    repo.seedItem('Calcium nitrate',
        categoryId: fertilizer, quantity: 5, minimumStock: 10);
    repo.seedItem('Urea', categoryId: fertilizer, quantity: 100);
    final controller = InventoryController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: InventoryScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calcium nitrate'), findsOneWidget);
    expect(find.text('Urea'), findsOneWidget);
    expect(find.byKey(const Key('inventory-low-stock-banner')), findsOneWidget);
    expect(find.text('1 item below minimum stock'), findsOneWidget);
    expect(
        find.byKey(const Key('inventory-filter-fertilizer')), findsOneWidget);
    // No operational context in this harness -> read-only (no FAB).
    expect(find.byKey(const Key('inventory-add-item')), findsNothing);
  });

  testWidgets('search filters the list', (tester) async {
    final repo = FakeInventoryRepository();
    final fertilizer = repo.seedCategory('fertilizer');
    repo.seedItem('Calcium nitrate', categoryId: fertilizer, quantity: 10);
    repo.seedItem('Urea', categoryId: fertilizer, quantity: 10);
    final controller = InventoryController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: InventoryScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('inventory-search')), 'urea');
    await tester.pumpAndSettle();

    expect(find.text('Urea'), findsOneWidget);
    expect(find.text('Calcium nitrate'), findsNothing);
  });
}
