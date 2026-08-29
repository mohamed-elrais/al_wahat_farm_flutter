import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase farm hierarchy query contract', () {
    test('uses final tree terminology and every required tree field', () {
      const columns = SupabaseFarmHierarchyDataSource.treeColumns;

      expect(columns, contains('tree_code'));
      expect(columns, contains('tree_number'));
      expect(columns, contains('health_status'));
      expect(columns, contains('irrigation_zone_id'));
      expect(columns, contains('type'));
      expect(columns, isNot(contains('palm')));
    });

    test('pages past the default thousand-row response size', () {
      expect(SupabaseFarmHierarchyDataSource.treePageSize, 1000);
    });

    test('loads independent planting pits with lifecycle fields', () {
      const columns = SupabaseFarmHierarchyDataSource.plantingPitColumns;

      expect(columns, contains('pit_code'));
      expect(columns, contains('section_id'));
      expect(columns, contains('status'));
      expect(columns, contains('completed_at'));
      expect(columns, isNot(contains('tree_id')));
      expect(SupabaseFarmHierarchyDataSource.plantingPitPageSize, 1000);
    });
  });
}
