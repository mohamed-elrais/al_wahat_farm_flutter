import 'package:al_wahat_farm_flutter/features/planting_pits/domain/planting_pit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class PlantingPitRepository {
  Future<String> create(PlantingPitDraft draft);

  Future<void> advanceStatus(String pitId, PlantingPitStatus status);

  Future<void> cancel(String pitId);
}

class SupabasePlantingPitRepository implements PlantingPitRepository {
  const SupabasePlantingPitRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<String> create(PlantingPitDraft draft) async {
    final row = await _client
        .from('planting_pits')
        .insert(draft.toInsertJson())
        .select('id')
        .single();
    return row['id']! as String;
  }

  @override
  Future<void> advanceStatus(
    String pitId,
    PlantingPitStatus status,
  ) async {
    await _client
        .from('planting_pits')
        .update(<String, Object?>{'status': status.wireValue}).eq('id', pitId);
  }

  @override
  Future<void> cancel(String pitId) =>
      advanceStatus(pitId, PlantingPitStatus.cancelled);
}
