import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract interface class InventoryRepository {
  Future<List<InventoryCategory>> listCategories(String farmId);
  Future<List<InventoryItem>> listItems(String farmId);
  Future<List<InventoryTransaction>> listTransactions(String itemId);
  Future<String> createItem(InventoryItemDraft draft);
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
  });
  Future<String> recordTransaction(
    String itemId, {
    required InventoryTransactionType type,
    required double quantity,
    String? note,
  });
  Future<String> createCategory(
    String farmId, {
    required String code,
    required String name,
    String? appliesToOperation,
    bool isConsumable = true,
  });
}

class SupabaseInventoryRepository implements InventoryRepository {
  SupabaseInventoryRepository(this._client, {Uuid uuid = const Uuid()})
      : _uuid = uuid;

  static const categoryColumns =
      'id, farm_id, code, name, applies_to_operation, is_consumable, '
      'is_active';
  static const itemColumns =
      'id, farm_id, category_id, name, description, unit, quantity, '
      'minimum_stock, attributes, image_bucket_id, image_path, is_active, '
      'created_at, updated_at';
  static const transactionColumns =
      'id, farm_id, inventory_item_id, transaction_type, quantity_delta, '
      'resulting_quantity, task_id, actor_profile_id, note, created_at';

  final SupabaseClient _client;
  final Uuid _uuid;

  @override
  Future<List<InventoryCategory>> listCategories(String farmId) =>
      _guard(() async {
        final rows = await _client
            .from('inventory_categories')
            .select(categoryColumns)
            .eq('farm_id', farmId)
            .eq('is_active', true)
            .order('code');
        return rows.map(InventoryCategory.fromJson).toList(growable: false);
      });

  @override
  Future<List<InventoryItem>> listItems(String farmId) => _guard(() async {
        final rows = await _client
            .from('inventory_items')
            .select(itemColumns)
            .eq('farm_id', farmId)
            .eq('is_active', true)
            .order('name');
        return rows.map(InventoryItem.fromJson).toList(growable: false);
      });

  @override
  Future<List<InventoryTransaction>> listTransactions(String itemId) =>
      _guard(() async {
        final rows = await _client
            .from('inventory_transactions')
            .select(transactionColumns)
            .eq('inventory_item_id', itemId)
            .order('created_at', ascending: false)
            .limit(100);
        return rows.map(InventoryTransaction.fromJson).toList(growable: false);
      });

  @override
  Future<String> createItem(InventoryItemDraft draft) {
    final validation = draft.validate();
    if (validation != null) {
      return Future<String>.error(
        OperationFailure(OperationFailureKind.invalidInput, validation),
      );
    }
    return _guard(() async {
      final params = Map<String, Object?>.of(draft.toRpcParameters());
      params['p_op_id'] = _uuid.v4();
      final Object? result =
          await _client.rpc('create_inventory_item', params: params);
      return result! as String;
    });
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
  }) =>
      _guard(() async {
        await _client.rpc<Object?>('update_inventory_item', params: {
          'p_item_id': itemId,
          'p_name': name,
          'p_category_id': categoryId,
          'p_description': description,
          'p_clear_description': clearDescription,
          'p_minimum_stock': minimumStock,
          'p_clear_minimum_stock': clearMinimumStock,
          'p_attributes': attributes,
          'p_image_path': imagePath,
          'p_clear_image': clearImage,
          'p_is_active': isActive,
        });
      });

  @override
  Future<String> recordTransaction(
    String itemId, {
    required InventoryTransactionType type,
    required double quantity,
    String? note,
  }) =>
      _guard(() async {
        final Object? result =
            await _client.rpc('record_inventory_transaction', params: {
          'p_item_id': itemId,
          'p_transaction_type': type.wireValue,
          'p_quantity': quantity,
          'p_note': note,
          'p_op_id': _uuid.v4(),
        });
        return result! as String;
      });

  @override
  Future<String> createCategory(
    String farmId, {
    required String code,
    required String name,
    String? appliesToOperation,
    bool isConsumable = true,
  }) =>
      _guard(() async {
        final Object? result =
            await _client.rpc('create_inventory_category', params: {
          'p_farm_id': farmId,
          'p_code': code,
          'p_name': name,
          'p_applies_to_operation': appliesToOperation,
          'p_is_consumable': isConsumable,
        });
        return result! as String;
      });
}

Future<T> _guard<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on PostgrestException catch (error) {
    throw _translateInventoryError(error);
  }
}

OperationFailure _translateInventoryError(PostgrestException error) =>
    switch (error.code) {
      '42501' => OperationFailure(
          OperationFailureKind.authorization,
          'Your farm role is not authorized for this inventory action.',
          cause: error,
        ),
      '23514' => OperationFailure(
          OperationFailureKind.invalidInput,
          error.message,
          cause: error,
        ),
      '23505' => OperationFailure(
          OperationFailureKind.conflict,
          'An inventory record with this name already exists.',
          cause: error,
        ),
      'P0002' => OperationFailure(
          OperationFailureKind.notFound,
          'The inventory record could not be found.',
          cause: error,
        ),
      _ => OperationFailure(
          OperationFailureKind.unexpected,
          'The farm could not save this inventory action.',
          cause: error,
        ),
    };

/// Caches the read surfaces so the inventory stays browsable offline;
/// mutations always require the network (manager actions).
class CachingInventoryRepository implements InventoryRepository {
  const CachingInventoryRepository({
    required InventoryRepository inner,
    required LocalCacheStore store,
  })  : _inner = inner,
        _store = store;

  static const itemsKeyPrefix = '${privateCachePrefix}inventory_items:';
  static const categoriesKeyPrefix =
      '${privateCachePrefix}inventory_categories:';

  final InventoryRepository _inner;
  final LocalCacheStore _store;

  static String itemsKeyFor(String farmId) => '$itemsKeyPrefix$farmId';
  static String categoriesKeyFor(String farmId) =>
      '$categoriesKeyPrefix$farmId';

  @override
  Future<List<InventoryItem>> listItems(String farmId) async {
    try {
      final items = await _inner.listItems(farmId);
      await _store.write(
        itemsKeyFor(farmId),
        jsonEncode(items.map((item) => item.toJson()).toList(growable: false)),
      );
      return items;
    } catch (error) {
      final cached = await _readCached(
        itemsKeyFor(farmId),
        InventoryItem.fromJson,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<InventoryCategory>> listCategories(String farmId) async {
    try {
      final categories = await _inner.listCategories(farmId);
      await _store.write(
        categoriesKeyFor(farmId),
        jsonEncode(
          categories.map((item) => item.toJson()).toList(growable: false),
        ),
      );
      return categories;
    } catch (error) {
      final cached = await _readCached(
        categoriesKeyFor(farmId),
        InventoryCategory.fromJson,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<T>?> _readCached<T>(
    String key,
    T Function(Map<String, Object?>) fromJson,
  ) async {
    final raw = await _store.read(key);
    if (raw == null) return null;
    try {
      final rows = jsonDecode(raw) as List<Object?>;
      return List<T>.unmodifiable(
        rows.map((row) => fromJson(Map<String, Object?>.from(row! as Map))),
      );
    } catch (error) {
      SafeLog.event(
        'inventory_cache_dropped',
        data: <String, Object?>{'error': error.runtimeType},
      );
      await _store.remove(key);
      return null;
    }
  }

  @override
  Future<List<InventoryTransaction>> listTransactions(String itemId) =>
      _inner.listTransactions(itemId);

  @override
  Future<String> createItem(InventoryItemDraft draft) =>
      _inner.createItem(draft);

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
  }) =>
      _inner.updateItem(
        itemId,
        name: name,
        categoryId: categoryId,
        description: description,
        clearDescription: clearDescription,
        minimumStock: minimumStock,
        clearMinimumStock: clearMinimumStock,
        attributes: attributes,
        imagePath: imagePath,
        clearImage: clearImage,
        isActive: isActive,
      );

  @override
  Future<String> recordTransaction(
    String itemId, {
    required InventoryTransactionType type,
    required double quantity,
    String? note,
  }) =>
      _inner.recordTransaction(
        itemId,
        type: type,
        quantity: quantity,
        note: note,
      );

  @override
  Future<String> createCategory(
    String farmId, {
    required String code,
    required String name,
    String? appliesToOperation,
    bool isConsumable = true,
  }) =>
      _inner.createCategory(
        farmId,
        code: code,
        name: name,
        appliesToOperation: appliesToOperation,
        isConsumable: isConsumable,
      );
}
