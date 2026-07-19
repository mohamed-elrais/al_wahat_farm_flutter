import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/features/inventory/data/inventory_repository.dart';
import 'package:al_wahat_farm_flutter/features/inventory/domain/inventory_models.dart';
import 'package:flutter/foundation.dart';

enum InventoryStatus { idle, loading, ready, failure }

/// Loads and filters the farm inventory (items + categories) and runs the
/// manager mutations. Reads fall back to cache offline via the repository.
class InventoryController extends ChangeNotifier {
  InventoryController({
    required InventoryRepository repository,
    required this.farmId,
  }) : _repository = repository;

  final InventoryRepository _repository;
  final String farmId;

  InventoryStatus _status = InventoryStatus.idle;
  List<InventoryItem> _items = const <InventoryItem>[];
  List<InventoryCategory> _categories = const <InventoryCategory>[];
  Object? _error;
  bool _busy = false;
  String Function(AppLocalizations)? _message;
  String _search = '';
  String? _categoryFilter;

  InventoryStatus get status => _status;
  List<InventoryCategory> get categories => _categories;
  Object? get error => _error;
  bool get isBusy => _busy;
  String Function(AppLocalizations)? get message => _message;
  String? get categoryFilter => _categoryFilter;
  String get search => _search;

  List<InventoryItem> get items {
    Iterable<InventoryItem> result = _items;
    if (_categoryFilter != null) {
      result = result.where((item) => item.categoryId == _categoryFilter);
    }
    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where(
        (item) =>
            item.name.toLowerCase().contains(query) ||
            (item.description?.toLowerCase().contains(query) ?? false),
      );
    }
    return result.toList(growable: false);
  }

  int get lowStockCount => _items.where((item) => item.isLowStock).length;

  InventoryItem? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  InventoryCategory? categoryById(String id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Future<void> load() async {
    _status = InventoryStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        _repository.listItems(farmId),
        _repository.listCategories(farmId),
      ]);
      _items = results[0] as List<InventoryItem>;
      _categories = results[1] as List<InventoryCategory>;
      _status = InventoryStatus.ready;
    } catch (error) {
      _error = error;
      _status = InventoryStatus.failure;
    }
    notifyListeners();
  }

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _categoryFilter = categoryId;
    notifyListeners();
  }

  Future<List<InventoryTransaction>> loadTransactions(String itemId) =>
      _repository.listTransactions(itemId);

  Future<String?> createItem(InventoryItemDraft draft) => _mutate(() async {
        final id = await _repository.createItem(draft);
        _message = (l10n) => l10n.inventoryMsgItemCreated;
        return id;
      });

  Future<String?> updateItem(
    String itemId, {
    String? name,
    String? categoryId,
    String? description,
    bool clearDescription = false,
    double? minimumStock,
    bool clearMinimumStock = false,
    Map<String, Object?>? attributes,
    bool? isActive,
  }) =>
      _mutate(() async {
        await _repository.updateItem(
          itemId,
          name: name,
          categoryId: categoryId,
          description: description,
          clearDescription: clearDescription,
          minimumStock: minimumStock,
          clearMinimumStock: clearMinimumStock,
          attributes: attributes,
          isActive: isActive,
        );
        _message = (l10n) => l10n.inventoryMsgItemUpdated;
        return itemId;
      });

  Future<String?> recordTransaction(
    String itemId, {
    required InventoryTransactionType type,
    required double quantity,
    String? note,
  }) =>
      _mutate(() async {
        final id = await _repository.recordTransaction(
          itemId,
          type: type,
          quantity: quantity,
          note: note,
        );
        _message = (l10n) => l10n.inventoryMsgStockRecorded;
        return id;
      });

  Future<String?> _mutate(Future<String> Function() action) async {
    if (_busy) return null;
    _busy = true;
    _message = null;
    notifyListeners();
    try {
      final result = await action();
      await load();
      return result;
    } catch (error) {
      _message = error is OperationFailure
          ? ((_) => error.message)
          : ((l10n) => l10n.inventoryErrGeneric);
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
