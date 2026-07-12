import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/farm_hierarchy_fixture.dart';

void main() {
  group('DefaultFarmHierarchyRepository', () {
    late CanonicalFarmHierarchyDataSource dataSource;
    late MemoryFarmHierarchyCache cache;
    late DefaultFarmHierarchyRepository repository;

    setUp(() {
      dataSource = CanonicalFarmHierarchyDataSource.load();
      cache = MemoryFarmHierarchyCache();
      repository = DefaultFarmHierarchyRepository(dataSource, cache);
    });

    test('loads the isolated canonical 12/1567 fixture', () async {
      final result = await repository.load(
        CanonicalFarmHierarchyDataSource.farmId,
      );

      expect(result.source, FarmHierarchySource.network);
      expect(result.hierarchy.sections, hasLength(12));
      expect(result.hierarchy.trees, hasLength(1567));
      expect(result.hierarchy.zones, hasLength(56));
      expect(
        dataSource.requestedSectionIds,
        <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'L', 'M', 'N', 'O', 'Q'],
      );
    });

    test('returns the last verified hierarchy when refresh fails', () async {
      final first = await repository.load(
        CanonicalFarmHierarchyDataSource.farmId,
      );
      dataSource.fail = true;

      final cached = await repository.load(
        CanonicalFarmHierarchyDataSource.farmId,
      );

      expect(cached.source, FarmHierarchySource.cache);
      expect(cached.isStale, isTrue);
      expect(cached.hierarchy, same(first.hierarchy));
    });

    test('does not hide refresh failures when fallback is disabled', () async {
      dataSource.fail = true;

      await expectLater(
        repository.load(
          CanonicalFarmHierarchyDataSource.farmId,
          allowCachedFallback: false,
        ),
        throwsStateError,
      );
    });
  });

  test('FarmHierarchy rejects a zone outside its section set', () {
    final now = DateTime.utc(2026);
    expect(
      () => FarmHierarchy(
        farmId: 'farm',
        sections: <FarmSection>[
          FarmSection(
            id: 'section',
            farmId: 'farm',
            code: 'A',
            name: 'Section A',
            sortOrder: 1,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        zones: <IrrigationZone>[
          IrrigationZone(
            id: 'zone',
            sectionId: 'missing',
            code: 'A-01',
            name: 'A-01',
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        ],
        trees: const <FarmTreeRecord>[],
      ),
      throwsFormatException,
    );
  });
}
