import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class TaskRepository {
  Future<List<FarmTask>> listForFarm(String farmId);
  Future<TaskDetails> loadDetails(String taskId);
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

  static const taskColumns =
      'id, farm_id, section_id, irrigation_zone_id, tree_id, '
      'related_tree_issue_id, task_type, title, description, priority, status, '
      'scheduled_for, planned_start_time, planned_duration_minutes, due_at, '
      'instructions, requires_engineer_review, created_by_profile_id, '
      'completed_by_profile_id, completed_at, approved_by_profile_id, '
      'approved_at, cancelled_by_profile_id, cancelled_at, '
      'cancellation_reason, created_at, updated_at';
  static const assignmentColumns =
      'id, task_id, assignee_profile_id, assigned_by_profile_id, assigned_at, '
      'is_active, unassigned_at, created_at';
  static const activityColumns =
      'id, task_id, actor_profile_id, action, old_status, new_status, note, '
      'metadata, created_at';
  static const photoColumns =
      'id, task_id, task_activity_log_id, engineer_review_id, '
      'storage_bucket_id, storage_path, photo_type, caption, '
      'uploaded_by_profile_id, taken_at, created_at';

  final SupabaseClient _client;

  @override
  Future<List<FarmTask>> listForFarm(String farmId) async {
    final result = await _client
        .from('tasks')
        .select(taskColumns)
        .eq('farm_id', farmId)
        .order('created_at', ascending: false);
    return result.map(FarmTask.fromJson).toList(growable: false);
  }

  @override
  Future<TaskDetails> loadDetails(String taskId) async {
    final taskJson = await _client
        .from('tasks')
        .select(taskColumns)
        .eq('id', taskId)
        .single();
    final assignmentsJson = await _client
        .from('task_assignments')
        .select(assignmentColumns)
        .eq('task_id', taskId)
        .order('assigned_at');
    final activityJson = await _client
        .from('task_activity_log')
        .select(activityColumns)
        .eq('task_id', taskId)
        .order('created_at', ascending: false);
    final photosJson = await _client
        .from('task_photos')
        .select(photoColumns)
        .eq('task_id', taskId)
        .order('created_at');
    return TaskDetails(
      task: FarmTask.fromJson(taskJson),
      assignments:
          assignmentsJson.map(TaskAssignment.fromJson).toList(growable: false),
      activity: activityJson.map(TaskActivity.fromJson).toList(growable: false),
      photos: photosJson.map(TaskPhoto.fromJson).toList(growable: false),
    );
  }

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

class TaskDetails {
  TaskDetails({
    required this.task,
    required List<TaskAssignment> assignments,
    required List<TaskActivity> activity,
    required List<TaskPhoto> photos,
  })  : assignments = List<TaskAssignment>.unmodifiable(assignments),
        activity = List<TaskActivity>.unmodifiable(activity),
        photos = List<TaskPhoto>.unmodifiable(photos);

  final FarmTask task;
  final List<TaskAssignment> assignments;
  final List<TaskActivity> activity;
  final List<TaskPhoto> photos;
}
