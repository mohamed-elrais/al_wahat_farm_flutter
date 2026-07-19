import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/inventory/data/inventory_repository.dart';
import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';

class FakeInventoryRepository implements InventoryRepository {
  FakeInventoryRepository({this.canManage = true});

  final bool canManage;
  final List<InventoryCategory> categories = <InventoryCategory>[];
  final List<InventoryItem> items = <InventoryItem>[];
  final Map<String, List<InventoryTransaction>> transactions =
      <String, List<InventoryTransaction>>{};
  int _sequence = 0;
  Object? listFailure;

  String seedCategory(String code, {String? appliesTo}) {
    final id = 'cat-${++_sequence}';
    categories.add(InventoryCategory(
      id: id,
      farmId: 'farm-id',
      code: code,
      name: code,
      isConsumable: true,
      isActive: true,
      appliesToOperation: appliesTo,
    ));
    return id;
  }

  String seedItem(
    String name, {
    required String categoryId,
    double quantity = 0,
    double? minimumStock,
    InventoryUnit unit = InventoryUnit.gram,
  }) {
    final id = 'item-${++_sequence}';
    items.add(InventoryItem(
      id: id,
      farmId: 'farm-id',
      categoryId: categoryId,
      name: name,
      unit: unit,
      quantity: quantity,
      minimumStock: minimumStock,
      attributes: const <String, Object?>{},
      isActive: true,
      createdAt: DateTime.utc(2026, 7, 20),
      updatedAt: DateTime.utc(2026, 7, 20),
    ));
    return id;
  }

  void _requireManager() {
    if (!canManage) {
      throw const OperationFailure(
        OperationFailureKind.authorization,
        'Your farm role is not authorized for this inventory action.',
      );
    }
  }

  @override
  Future<List<InventoryCategory>> listCategories(String farmId) async {
    if (listFailure != null) throw listFailure!;
    return List<InventoryCategory>.of(categories);
  }

  @override
  Future<List<InventoryItem>> listItems(String farmId) async {
    if (listFailure != null) throw listFailure!;
    return List<InventoryItem>.of(items);
  }

  @override
  Future<List<InventoryTransaction>> listTransactions(String itemId) async =>
      List<InventoryTransaction>.of(
        transactions[itemId] ?? const <InventoryTransaction>[],
      );

  @override
  Future<String> createItem(InventoryItemDraft draft) async {
    _requireManager();
    final validation = draft.validate();
    if (validation != null) {
      throw OperationFailure(OperationFailureKind.invalidInput, validation);
    }
    return seedItem(
      draft.name,
      categoryId: draft.categoryId,
      quantity: draft.initialQuantity,
      minimumStock: draft.minimumStock,
      unit: draft.unit,
    );
  }

  @override
  Future<void> updateItem(
    String itemId, {
    String? name,
    String? categoryId,
    String? description,
    bool clearDescription = false,
    double? minimumStock,
    bool clearMinimumStock = false,
    Map<String, Object?>? attributes,
    String? imagePath,
    bool clearImage = false,
    bool? isActive,
  }) async {
    _requireManager();
    final index = items.indexWhere((item) => item.id == itemId);
    if (index < 0) {
      throw const OperationFailure(
        OperationFailureKind.notFound,
        'The inventory record could not be found.',
      );
    }
    final old = items[index];
    items[index] = InventoryItem(
      id: old.id,
      farmId: old.farmId,
      categoryId: categoryId ?? old.categoryId,
      name: name ?? old.name,
      unit: old.unit,
      quantity: old.quantity,
      minimumStock:
          clearMinimumStock ? null : (minimumStock ?? old.minimumStock),
      description: clearDescription ? null : (description ?? old.description),
      attributes: attributes ?? old.attributes,
      isActive: isActive ?? old.isActive,
      createdAt: old.createdAt,
      updatedAt: DateTime.utc(2026, 7, 20, 1),
    );
  }

  @override
  Future<String> recordTransaction(
    String itemId, {
    required InventoryTransactionType type,
    required double quantity,
    String? note,
  }) async {
    _requireManager();
    final index = items.indexWhere((item) => item.id == itemId);
    if (index < 0) {
      throw const OperationFailure(
        OperationFailureKind.notFound,
        'The inventory record could not be found.',
      );
    }
    final old = items[index];
    final next = old.quantity + quantity;
    if (next < 0) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'Adjustment would make stock negative',
      );
    }
    items[index] = InventoryItem(
      id: old.id,
      farmId: old.farmId,
      categoryId: old.categoryId,
      name: old.name,
      unit: old.unit,
      quantity: next,
      minimumStock: old.minimumStock,
      description: old.description,
      attributes: old.attributes,
      isActive: old.isActive,
      createdAt: old.createdAt,
      updatedAt: DateTime.utc(2026, 7, 20, 2),
    );
    final id = 'txn-${++_sequence}';
    (transactions[itemId] ??= <InventoryTransaction>[]).insert(
      0,
      InventoryTransaction(
        id: id,
        farmId: old.farmId,
        inventoryItemId: itemId,
        type: type,
        quantityDelta: quantity,
        resultingQuantity: next,
        actorProfileId: 'manager-id',
        note: note,
        createdAt: DateTime.utc(2026, 7, 20, 3),
      ),
    );
    return id;
  }

  @override
  Future<String> createCategory(
    String farmId, {
    required String code,
    required String name,
    String? appliesToOperation,
    bool isConsumable = true,
  }) async {
    _requireManager();
    return seedCategory(code, appliesTo: appliesToOperation);
  }
}
