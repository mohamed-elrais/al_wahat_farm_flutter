import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class FarmHierarchyDataSource {
  Future<List<Map<String, Object?>>> fetchSections(String farmId);

  Future<List<Map<String, Object?>>> fetchZones(List<String> sectionIds);

  Future<List<Map<String, Object?>>> fetchTrees(String farmId);
}

class SupabaseFarmHierarchyDataSource implements FarmHierarchyDataSource {
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
  static const treePageSize = 1000;

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
      final hierarchy = FarmHierarchy(
        farmId: farmId,
        sections: sections,
        zones: zoneRows.map(IrrigationZone.fromJson).toList(growable: false),
        trees: treeRows.map(FarmTreeRecord.fromJson).toList(growable: false),
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
