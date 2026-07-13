import 'package:al_wahat_farm_flutter/features/trees/data/tree_qr_repository.dart';
import 'package:al_wahat_farm_flutter/features/trees/domain/scanned_tree.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scan_tree_by_qr contract parses the final tree row', () {
    final tree = ScannedTree.fromJson(<String, Object?>{
      'tree_id': 'tree-id',
      'farm_id': 'farm-id',
      'section_id': 'section-id',
      'section_code': 'B',
      'section_name': 'Section B',
      'irrigation_zone_id': 'zone-id',
      'tree_code': 'TREE-B-120',
      'row_number': 4,
      'tree_number': 120,
      'health_status': 'healthy',
      'type': 'date_palm',
    });

    expect(SupabaseTreeQrRepository.scanRpc, 'scan_tree_by_qr');
    expect(SupabaseTreeQrRepository.tokenParameter, 'p_qr_token');
    expect(tree.id, 'tree-id');
    expect(tree.code, 'TREE-B-120');
    expect(tree.sectionCode, 'B');
    expect(tree.treeNumber, 120);
  });
}
