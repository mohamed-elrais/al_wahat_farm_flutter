import 'dart:convert';

import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/core/logging/safe_log.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/planting_pits/domain/planting_pit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class FarmHierarchyDataSource {
  Future<List<Map<String, Object?>>> fetchSections(String farmId);

  Future<List<Map<String, Object?>>> fetchZones(List<String> sectionIds);

  Future<List<Map<String, Object?>>> fetchTrees(String farmId);
}

/// Optional extension implemented by data sources that can load planting
/// pits. Keeping it separate preserves compatibility with lightweight test
/// and offline data sources that predate the feature.
abstract interface class PlantingPitHierarchyDataSource {
  Future<List<Map<String, Object?>>> fetchPlantingPits(String farmId);
}

class SupabaseFarmHierarchyDataSource
    implements FarmHierarchyDataSource, PlantingPitHierarchyDataSource {
  const SupabaseFarmHierarchyDataSource(this._client);

  static const sectionColumns =
      'id, farm_id, code, name, sort_order, area_m2, notes, is_active, '
      'created_at, updated_at';
  static const zoneColumns =
      'id, section_id, code, name, valve_code, notes, is_active, '
      'created_at, updated_at';
  static const treeColumns =
      'id, farm_id, section_id, irrigation_zone_id, tree_code, row_number, '
      'tree_number, planted_on, latitude, longitude, health_status, type, '
      'notes, is_active, created_at, updated_at';
  static const plantingPitColumns =
      'id, farm_id, section_id, irrigation_zone_id, pit_code, row_number, '
      'pit_number, latitude, longitude, planned_for, status, marked_at, '
      'dug_at, prepared_at, completed_at, cancelled_at, notes, '
      'created_by_profile_id, created_at, updated_at';
  static const treePageSize = 1000;
  static const plantingPitPageSize = 1000;

  final SupabaseClient _client;

  @override
  Future<List<Map<String, Object?>>> fetchSections(String farmId) async {
    final result = await _client
        .from('farm_sections')
        .select(sectionColumns)
        .eq('farm_id', farmId)
        .eq('is_active', true)
        .order('sort_order');
    return _rows(result);
  }

  @override
  Future<List<Map<String, Object?>>> fetchZones(
    List<String> sectionIds,
  ) async {
    if (sectionIds.isEmpty) return const <Map<String, Object?>>[];
    final result = await _client
        .from('irrigation_zones')
        .select(zoneColumns)
        .inFilter('section_id', sectionIds)
        .eq('is_active', true)
        .order('code');
    return _rows(result);
  }

  @override
  Future<List<Map<String, Object?>>> fetchTrees(String farmId) async {
    final rows = <Map<String, Object?>>[];
    var offset = 0;
    while (true) {
      final result = await _client
          .from('trees')
          .select(treeColumns)
          .eq('farm_id', farmId)
          .eq('is_active', true)
          .order('tree_code')
          .range(offset, offset + treePageSize - 1);
      final page = _rows(result);
      rows.addAll(page);
      if (page.length < treePageSize) break;
      offset += treePageSize;
    }
    return List<Map<String, Object?>>.unmodifiable(rows);
  }

  @override
  Future<List<Map<String, Object?>>> fetchPlantingPits(String farmId) async {
    final rows = <Map<String, Object?>>[];
    var offset = 0;
    while (true) {
      final result = await _client
          .from('planting_pits')
          .select(plantingPitColumns)
          .eq('farm_id', farmId)
          .order('pit_code')
          .range(offset, offset + plantingPitPageSize - 1);
      final page = _rows(result);
      rows.addAll(page);
      if (page.length < plantingPitPageSize) break;
      offset += plantingPitPageSize;
    }
    return List<Map<String, Object?>>.unmodifiable(rows);
  }
}

abstract interface class FarmHierarchyCache {
  Future<FarmHierarchy?> read(String farmId);

  Future<void> write(FarmHierarchy hierarchy);

  Future<void> clear(String farmId);
}

class MemoryFarmHierarchyCache implements FarmHierarchyCache {
  final Map<String, FarmHierarchy> _entries = <String, FarmHierarchy>{};

  @override
  Future<FarmHierarchy?> read(String farmId) async => _entries[farmId];

  @override
  Future<void> write(FarmHierarchy hierarchy) async {
    _entries[hierarchy.farmId] = hierarchy;
  }

  @override
  Future<void> clear(String farmId) async {
    _entries.remove(farmId);
  }
}

/// Persists the farm hierarchy as JSON under a private cache key so the map and
/// tree data survive an app restart and remain readable offline. The bundled
/// map geometry asset is unaffected; only this session-derived data is cached.
class PersistentFarmHierarchyCache implements FarmHierarchyCache {
  const PersistentFarmHierarchyCache(this._store);

  static const keyPrefix = '${privateCachePrefix}hierarchy:';

  final LocalCacheStore _store;

  static String keyFor(String farmId) => '$keyPrefix$farmId';

  @override
  Future<FarmHierarchy?> read(String farmId) async {
    final raw = await _store.read(keyFor(farmId));
    if (raw == null) return null;
    try {
      return FarmHierarchy.fromCacheJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } catch (error) {
      // A corrupt or outdated cache entry must never crash a read; drop it.
      SafeLog.event(
        'farm_hierarchy_cache_dropped',
        data: <String, Object?>{'error': error.runtimeType},
      );
      await _store.remove(keyFor(farmId));
      return null;
    }
  }

  @override
  Future<void> write(FarmHierarchy hierarchy) async {
    await _store.write(
      keyFor(hierarchy.farmId),
      jsonEncode(hierarchy.toCacheJson()),
    );
  }

  @override
  Future<void> clear(String farmId) => _store.remove(keyFor(farmId));
}

enum FarmHierarchySource { network, cache }

class FarmHierarchySnapshot {
  const FarmHierarchySnapshot({
    required this.hierarchy,
    required this.source,
  });

  final FarmHierarchy hierarchy;
  final FarmHierarchySource source;

  bool get isStale => source == FarmHierarchySource.cache;
}

abstract interface class FarmHierarchyRepository {
  Future<FarmHierarchySnapshot> load(
    String farmId, {
    bool allowCachedFallback = true,
  });
}

class DefaultFarmHierarchyRepository implements FarmHierarchyRepository {
  const DefaultFarmHierarchyRepository(this._dataSource, this._cache);

  final FarmHierarchyDataSource _dataSource;
  final FarmHierarchyCache _cache;

  @override
  Future<FarmHierarchySnapshot> load(
    String farmId, {
    bool allowCachedFallback = true,
  }) async {
    try {
      final sectionRows = await _dataSource.fetchSections(farmId);
      final sections =
          sectionRows.map(FarmSection.fromJson).toList(growable: false);
      final zoneRows = await _dataSource.fetchZones(
        sections.map((section) => section.id).toList(growable: false),
      );
      final treeRows = await _dataSource.fetchTrees(farmId);
      final pitRows = _dataSource is PlantingPitHierarchyDataSource
          ? await (_dataSource as PlantingPitHierarchyDataSource)
              .fetchPlantingPits(farmId)
          : const <Map<String, Object?>>[];
      final hierarchy = FarmHierarchy(
        farmId: farmId,
        sections: sections,
        zones: zoneRows.map(IrrigationZone.fromJson).toList(growable: false),
        trees: treeRows.map(FarmTreeRecord.fromJson).toList(growable: false),
        plantingPits: pitRows.map(PlantingPit.fromJson).toList(growable: false),
      );
      await _cache.write(hierarchy);
      return FarmHierarchySnapshot(
        hierarchy: hierarchy,
        source: FarmHierarchySource.network,
      );
    } catch (_) {
      if (allowCachedFallback) {
        final cached = await _cache.read(farmId);
        if (cached != null) {
          return FarmHierarchySnapshot(
            hierarchy: cached,
            source: FarmHierarchySource.cache,
          );
        }
      }
      rethrow;
    }
  }
}

List<Map<String, Object?>> _rows(List<Map<String, dynamic>> result) => result
    .map<Map<String, Object?>>((row) => Map<String, Object?>.from(row))
    .toList(growable: false);
