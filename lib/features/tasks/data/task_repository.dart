import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class TaskRepository {
  Future<String> create(TaskDraft draft);
  Future<void> setAssignments(String taskId, List<String> profileIds);
  Future<void> start(String taskId, {String? note});
  Future<void> complete(
    String taskId, {
    String? note,
    bool requiresEngineerReview = false,
  });
}

class SupabaseTaskRepository implements TaskRepository {
  const SupabaseTaskRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<String> create(TaskDraft draft) async {
    final validation = draft.validate();
    if (validation != null) throw ArgumentError(validation);
    final Object? result = await _client.rpc(
      'create_farm_task',
      params: draft.toRpcParameters(),
    );
    return result as String;
  }

  @override
  Future<void> setAssignments(String taskId, List<String> profileIds) async {
    await _client.rpc<Object?>(
      'set_task_assignments',
      params: <String, Object?>{
        'p_task_id': taskId,
        'p_assignee_profile_ids': profileIds,
      },
    );
  }

  @override
  Future<void> start(String taskId, {String? note}) async {
    await _client.rpc<Object?>(
      'start_assigned_task',
      params: <String, Object?>{'p_task_id': taskId, 'p_note': note},
    );
  }

  @override
  Future<void> complete(
    String taskId, {
    String? note,
    bool requiresEngineerReview = false,
  }) async {
    await _client.rpc<Object?>(
      'complete_task',
      params: <String, Object?>{
        'p_task_id': taskId,
        'p_note': note,
        'p_requires_engineer_review': requiresEngineerReview,
      },
    );
  }
}
