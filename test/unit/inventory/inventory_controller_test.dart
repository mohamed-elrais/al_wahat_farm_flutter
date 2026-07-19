import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:al_wahat_farm_flutter/features/inventory/presentation/inventory_controller.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/inventory_fakes.dart';

final _en = AppLocalizationsEn();

void main() {
  test('loads items and categories, filters by search and category', () async {
    final repo = FakeInventoryRepository();
    final fertilizer = repo.seedCategory('fertilizer');
    final tools = repo.seedCategory('tool');
    repo.seedItem('Calcium nitrate', categoryId: fertilizer, quantity: 100);
    repo.seedItem('Urea', categoryId: fertilizer, quantity: 20);
    repo.seedItem('Shovel', categoryId: tools, quantity: 3);
    final controller = InventoryController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.status, InventoryStatus.ready);
    expect(controller.items, hasLength(3));

    controller.setCategoryFilter(fertilizer);
    expect(controller.items.map((item) => item.name),
        containsAll(<String>['Calcium nitrate', 'Urea']));
    expect(controller.items, hasLength(2));

    controller.setSearch('calc');
    expect(controller.items.single.name, 'Calcium nitrate');

    controller.setSearch('');
    controller.setCategoryFilter(null);
    expect(controller.items, hasLength(3));
  });

  test('low stock counts items at or below their minimum', () async {
    final repo = FakeInventoryRepository();
    final category = repo.seedCategory('fertilizer');
    repo.seedItem('Low', categoryId: category, quantity: 5, minimumStock: 10);
    repo.seedItem('Exact',
        categoryId: category, quantity: 10, minimumStock: 10);
    repo.seedItem('Fine', categoryId: category, quantity: 50, minimumStock: 10);
    repo.seedItem('NoMin', categoryId: category, quantity: 0);
    final controller = InventoryController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.lowStockCount, 2);
  });

  test('createItem validates, creates, and reloads', () async {
    final repo = FakeInventoryRepository();
    final category = repo.seedCategory('dripper');
    final controller = InventoryController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    await controller.load();

    final id = await controller.createItem(InventoryItemDraft(
      farmId: 'farm-id',
      categoryId: category,
      name: 'PC dripper 4lph',
      unit: InventoryUnit.piece,
      initialQuantity: 500,
    ));

    expect(id, isNotNull);
    expect(controller.itemById(id!)?.quantity, 500);
    expect(controller.message?.call(_en), _en.inventoryMsgItemCreated);
  });

  test('authorization failures surface the backend message', () async {
    final repo = FakeInventoryRepository(canManage: false);
    final category = repo.seedCategory('fertilizer');
    final controller = InventoryController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    await controller.load();

    final id = await controller.createItem(InventoryItemDraft(
      farmId: 'farm-id',
      categoryId: category,
      name: 'Nope',
      unit: InventoryUnit.gram,
    ));

    expect(id, isNull);
    expect(
      controller.message?.call(_en),
      'Your farm role is not authorized for this inventory action.',
    );
  });

  test('recordTransaction updates stock and blocks negative results', () async {
    final repo = FakeInventoryRepository();
    final category = repo.seedCategory('fertilizer');
    final item = repo.seedItem('Calcium', categoryId: category, quantity: 100);
    final controller = InventoryController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    await controller.load();

    await controller.recordTransaction(
      item,
      type: InventoryTransactionType.addition,
      quantity: 50,
    );
    expect(controller.itemById(item)?.quantity, 150);

    final failed = await controller.recordTransaction(
      item,
      type: InventoryTransactionType.adjustment,
      quantity: -500,
    );
    expect(failed, isNull);
    expect(controller.itemById(item)?.quantity, 150);
  });
}
