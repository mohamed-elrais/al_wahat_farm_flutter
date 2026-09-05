import 'package:al_wahat_farm_flutter/features/planting_pits/domain/planting_pit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlantingPitStatus', () {
    test('parses every backend value and exposes forward transitions', () {
      expect(
          PlantingPitStatus.fromJson('planned').next, PlantingPitStatus.marked);
      expect(PlantingPitStatus.fromJson('marked').next, PlantingPitStatus.dug);
      expect(
          PlantingPitStatus.fromJson('dug').next, PlantingPitStatus.prepared);
      expect(PlantingPitStatus.fromJson('prepared').next,
          PlantingPitStatus.completed);
      expect(PlantingPitStatus.fromJson('completed').next, isNull);
      expect(PlantingPitStatus.fromJson('cancelled').next, isNull);
    });

    test('rejects unknown backend values', () {
      expect(
        () => PlantingPitStatus.fromJson('planted'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('planting pit JSON round-trips without a tree relationship', () {
    final pit = PlantingPit.fromJson(_pitJson);

    expect(pit.id, 'pit-1');
    expect(pit.pitCode, 'PIT-E-R01-001');
    expect(pit.status, PlantingPitStatus.dug);
    expect(pit.rowNumber, 1);
    expect(pit.pitNumber, 1);
    expect(pit.hasCoordinates, isTrue);
    expect(pit.toJson(), _pitJson);
    expect(pit.toJson().containsKey('tree_id'), isFalse);
  });

  test('draft trims text and uses date-only planned_for', () {
    final json = PlantingPitDraft(
      farmId: 'farm-1',
      sectionId: 'section-e',
      pitCode: '  PIT-E-R01-002  ',
      plannedFor: DateTime(2026, 9, 4, 13, 30),
      notes: '  Field note  ',
    ).toInsertJson();

    expect(json['pit_code'], 'PIT-E-R01-002');
    expect(json['planned_for'], '2026-09-04');
    expect(json['notes'], 'Field note');
    expect(json.containsKey('status'), isFalse);
    expect(json.containsKey('tree_id'), isFalse);
  });
}

final _pitJson = <String, Object?>{
  'id': 'pit-1',
  'farm_id': 'farm-1',
  'section_id': 'section-e',
  'irrigation_zone_id': 'zone-e-1',
  'pit_code': 'PIT-E-R01-001',
  'row_number': 1,
  'pit_number': 1,
  'latitude': 28.2951,
  'longitude': 28.75018,
  'planned_for': '2026-09-01',
  'status': 'dug',
  'marked_at': '2026-08-27T08:00:00.000Z',
  'dug_at': '2026-08-27T09:00:00.000Z',
  'prepared_at': null,
  'completed_at': null,
  'cancelled_at': null,
  'notes': 'Ready for preparation',
  'created_by_profile_id': 'profile-1',
  'created_at': '2026-08-27T07:00:00.000Z',
  'updated_at': '2026-08-27T09:00:00.000Z',
};
