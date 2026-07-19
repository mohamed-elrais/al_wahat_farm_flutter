/// Units of measurement for inventory items (mirrors `public.inventory_unit`).
enum InventoryUnit {
  gram,
  kilogram,
  liter,
  milliliter,
  piece,
  meter;

  String get wireValue => name;

  factory InventoryUnit.fromJson(String value) => switch (value) {
        'gram' => gram,
        'kilogram' => kilogram,
        'liter' => liter,
        'milliliter' => milliliter,
        'piece' => piece,
        'meter' => meter,
        _ => throw FormatException('Unknown inventory unit: $value'),
      };

  String get label => switch (this) {
        gram => 'Grams',
        kilogram => 'Kilograms',
        liter => 'Liters',
        milliliter => 'Milliliters',
        piece => 'Pieces',
        meter => 'Meters',
      };
}

/// Ledger entry kinds (mirrors `public.inventory_transaction_type`).
enum InventoryTransactionType {
  addition,
  consumption,
  adjustment,
  reversal;

  String get wireValue => name;

  factory InventoryTransactionType.fromJson(String value) => switch (value) {
        'addition' => addition,
        'consumption' => consumption,
        'adjustment' => adjustment,
        'reversal' => reversal,
        _ => throw FormatException('Unknown transaction type: $value'),
      };

  String get label => switch (this) {
        addition => 'Stock added',
        consumption => 'Consumed by task',
        adjustment => 'Adjustment',
        reversal => 'Consumption reversed',
      };
}

class InventoryCategory {
  const InventoryCategory({
    required this.id,
    required this.farmId,
    required this.code,
    required this.name,
    required this.isConsumable,
    required this.isActive,
    this.appliesToOperation,
  });

  final String id;
  final String farmId;
  final String code;
  final String name;
  final bool isConsumable;
  final bool isActive;
  final String? appliesToOperation;

  factory InventoryCategory.fromJson(Map<String, Object?> json) =>
      InventoryCategory(
        id: json['id']! as String,
        farmId: json['farm_id']! as String,
        code: json['code']! as String,
        name: json['name']! as String,
        isConsumable: json['is_consumable']! as bool,
        isActive: json['is_active']! as bool,
        appliesToOperation: json['applies_to_operation'] as String?,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'farm_id': farmId,
        'code': code,
        'name': name,
        'is_consumable': isConsumable,
        'is_active': isActive,
        'applies_to_operation': appliesToOperation,
      };
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.farmId,
    required this.categoryId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.attributes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.minimumStock,
    this.imageBucketId,
    this.imagePath,
  });

  final String id;
  final String farmId;
  final String categoryId;
  final String name;
  final InventoryUnit unit;
  final double quantity;
  final double? minimumStock;
  final String? description;
  final Map<String, Object?> attributes;
  final String? imageBucketId;
  final String? imagePath;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowStock => minimumStock != null && quantity <= minimumStock!;

  factory InventoryItem.fromJson(Map<String, Object?> json) => InventoryItem(
        id: json['id']! as String,
        farmId: json['farm_id']! as String,
        categoryId: json['category_id']! as String,
        name: json['name']! as String,
        unit: InventoryUnit.fromJson(json['unit']! as String),
        quantity: (json['quantity']! as num).toDouble(),
        minimumStock: (json['minimum_stock'] as num?)?.toDouble(),
        description: json['description'] as String?,
        attributes: Map<String, Object?>.unmodifiable(
          Map<String, Object?>.from(
            json['attributes'] as Map? ?? const <String, Object?>{},
          ),
        ),
        imageBucketId: json['image_bucket_id'] as String?,
        imagePath: json['image_path'] as String?,
        isActive: json['is_active']! as bool,
        createdAt: DateTime.parse(json['created_at']! as String),
        updatedAt: DateTime.parse(json['updated_at']! as String),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'farm_id': farmId,
        'category_id': categoryId,
        'name': name,
        'unit': unit.wireValue,
        'quantity': quantity,
        'minimum_stock': minimumStock,
        'description': description,
        'attributes': attributes,
        'image_bucket_id': imageBucketId,
        'image_path': imagePath,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class InventoryTransaction {
  const InventoryTransaction({
    required this.id,
    required this.farmId,
    required this.inventoryItemId,
    required this.type,
    required this.quantityDelta,
    required this.resultingQuantity,
    required this.actorProfileId,
    required this.createdAt,
    this.taskId,
    this.note,
  });

  final String id;
  final String farmId;
  final String inventoryItemId;
  final InventoryTransactionType type;
  final double quantityDelta;
  final double resultingQuantity;
  final String actorProfileId;
  final String? taskId;
  final String? note;
  final DateTime createdAt;

  factory InventoryTransaction.fromJson(Map<String, Object?> json) =>
      InventoryTransaction(
        id: json['id']! as String,
        farmId: json['farm_id']! as String,
        inventoryItemId: json['inventory_item_id']! as String,
        type: InventoryTransactionType.fromJson(
          json['transaction_type']! as String,
        ),
        quantityDelta: (json['quantity_delta']! as num).toDouble(),
        resultingQuantity: (json['resulting_quantity']! as num).toDouble(),
        actorProfileId: json['actor_profile_id']! as String,
        taskId: json['task_id'] as String?,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['created_at']! as String),
      );
}

/// Draft for creating a new inventory item via `create_inventory_item`.
class InventoryItemDraft {
  const InventoryItemDraft({
    required this.farmId,
    required this.categoryId,
    required this.name,
    required this.unit,
    this.description,
    this.minimumStock,
    this.attributes = const <String, Object?>{},
    this.initialQuantity = 0,
    this.imagePath,
  });

  final String farmId;
  final String categoryId;
  final String name;
  final InventoryUnit unit;
  final String? description;
  final double? minimumStock;
  final Map<String, Object?> attributes;
  final double initialQuantity;
  final String? imagePath;

  String? validate() {
    if (farmId.trim().isEmpty) return 'Farm identity is required';
    if (categoryId.trim().isEmpty) return 'Category is required';
    if (name.trim().isEmpty) return 'Item name is required';
    if (initialQuantity < 0) return 'Initial quantity cannot be negative';
    if (minimumStock != null && minimumStock! < 0) {
      return 'Minimum stock cannot be negative';
    }
    return null;
  }

  Map<String, Object?> toRpcParameters() => <String, Object?>{
        'p_farm_id': farmId,
        'p_category_id': categoryId,
        'p_name': name.trim(),
        'p_unit': unit.wireValue,
        'p_description': description,
        'p_minimum_stock': minimumStock,
        'p_attributes': attributes,
        'p_initial_quantity': initialQuantity,
        'p_image_path': imagePath,
      };
}
