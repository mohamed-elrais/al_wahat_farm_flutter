import 'package:al_wahat_farm_flutter/core/cache/local_cache_store.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/planting_pits/domain/planting_pit.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingDataSource implements FarmHierarchyDataSource {
  @override
  Future<List<Map<String, Object?>>> fetchSections(String farmId) async =>
      throw StateError('offline');

  @override
  Future<List<Map<String, Object?>>> fetchZones(
          List<String> sectionIds) async =>
      throw StateError('offline');

  @override
  Future<List<Map<String, Object?>>> fetchTrees(String farmId) async =>
      throw StateError('offline');
}

void main() {
  test('persisted hierarchy round-trips through the cache store', () async {
    final store = InMemoryCacheStore();
    final cache = PersistentFarmHierarchyCache(store);

    await cache.write(_hierarchy);
    final restored = await cache.read('farm-id');

    expect(restored, isNotNull);
    expect(restored!.farmId, 'farm-id');
    expect(restored.sections.single.code, 'A');
    expect(restored.zones.single.id, 'zone-1');
    final tree = restored.trees.single;
    expect(tree.treeCode, 'A-1');
    expect(tree.latitude, 28.2971234);
    expect(tree.healthStatus, TreeHealthStatus.healthy);
    expect(restored.plantingPits.single.pitCode, 'PIT-A-R01-001');
    expect(restored.plantingPits.single.status, PlantingPitStatus.marked);
  });

  test('reading a corrupt cache entry drops it and returns null', () async {
    final store = InMemoryCacheStore();
    await store.write(
      PersistentFarmHierarchyCache.keyFor('farm-id'),
      'not-json',
    );
    final cache = PersistentFarmHierarchyCache(store);

    expect(await cache.read('farm-id'), isNull);
    expect(
      await store.read(PersistentFarmHierarchyCache.keyFor('farm-id')),
      isNull,
    );
  });

  test('repository falls back to the persisted cache when the network fails',
      () async {
    final store = InMemoryCacheStore();
    final cache = PersistentFarmHierarchyCache(store);
    await cache.write(_hierarchy);
    final repository =
        DefaultFarmHierarchyRepository(_ThrowingDataSource(), cache);

    final snapshot = await repository.load('farm-id');

    expect(snapshot.source, FarmHierarchySource.cache);
    expect(snapshot.isStale, isTrue);
    expect(snapshot.hierarchy.trees.single.treeCode, 'A-1');
  });

  test('repository rethrows when the network fails and no cache exists',
      () async {
    final repository = DefaultFarmHierarchyRepository(
      _ThrowingDataSource(),
      PersistentFarmHierarchyCache(InMemoryCacheStore()),
    );

    expect(() => repository.load('farm-id'), throwsA(isA<StateError>()));
  });
}

final _now = DateTime.utc(2026, 7, 13);

final _hierarchy = FarmHierarchy(
  farmId: 'farm-id',
  sections: <FarmSection>[
    FarmSection(
      id: 'section-1',
      farmId: 'farm-id',
      code: 'A',
      name: 'Section A',
      sortOrder: 1,
      isActive: true,
      createdAt: _now,
      updatedAt: _now,
    ),
  ],
  zones: <IrrigationZone>[
    IrrigationZone(
      id: 'zone-1',
      sectionId: 'section-1',
      code: 'A1',
      name: 'Zone A1',
      isActive: true,
      createdAt: _now,
      updatedAt: _now,
    ),
  ],
  trees: <FarmTreeRecord>[
    FarmTreeRecord(
      id: 'tree-1',
      farmId: 'farm-id',
      sectionId: 'section-1',
      irrigationZoneId: 'zone-1',
      treeCode: 'A-1',
      rowNumber: 1,
      treeNumber: 1,
      latitude: 28.2971234,
      longitude: 28.7501234,
      healthStatus: TreeHealthStatus.healthy,
      type: 'medjool',
      isActive: true,
      createdAt: _now,
      updatedAt: _now,
    ),
  ],
  plantingPits: <PlantingPit>[
    PlantingPit(
      id: 'pit-1',
      farmId: 'farm-id',
      sectionId: 'section-1',
      irrigationZoneId: 'zone-1',
      pitCode: 'PIT-A-R01-001',
      rowNumber: 1,
      pitNumber: 1,
      latitude: 28.2972,
      longitude: 28.7502,
      status: PlantingPitStatus.marked,
      markedAt: _now,
      createdByProfileId: 'profile-1',
      createdAt: _now,
      updatedAt: _now,
    ),
  ],
);
