import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class TaskRepository {
  Future<List<FarmTask>> listForFarm(String farmId);
  Future<TaskDetails> loadDetails(String taskId);
  Future<List<TaskAssignee>> listAssignableMembers(String farmId);
  Future<String> create(TaskDraft draft);
  Future<void> setAssignments(String taskId, List<String> profileIds);
  Future<void> start(String taskId, {String? note});
  Future<void> complete(
    String taskId, {
    String? note,
    bool requiresEngineerReview = false,
  });
  Future<String> addPhoto(TaskEvidenceRegistration registration);
}

class SupabaseTaskRepository implements TaskRepository {
  const SupabaseTaskRepository(this._client);

  static const createRpc = 'create_farm_task';
  static const assignmentsRpc = 'set_task_assignments';
  static const startRpc = 'start_assigned_task';
  static const completeRpc = 'complete_task';
  static const addPhotoRpc = 'add_task_photo';
  static const taskPageSize = 500;

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
  static const assignableMemberColumns =
      'profile_id, role, profiles!inner(full_name, is_active)';

  final SupabaseClient _client;

  @override
  Future<List<FarmTask>> listForFarm(String farmId) => _guard(() async {
        final tasks = <FarmTask>[];
        var offset = 0;
        while (true) {
          final result = await _client
              .from('tasks')
              .select(taskColumns)
              .eq('farm_id', farmId)
              .order('created_at', ascending: false)
              .range(offset, offset + taskPageSize - 1);
          final page = result.map(FarmTask.fromJson).toList(growable: false);
          tasks.addAll(page);
          if (page.length < taskPageSize) break;
          offset += taskPageSize;
        }
        return List<FarmTask>.unmodifiable(tasks);
      });

  @override
  Future<TaskDetails> loadDetails(String taskId) => _guard(() async {
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
          assignments: assignmentsJson
              .map(TaskAssignment.fromJson)
              .toList(growable: false),
          activity:
              activityJson.map(TaskActivity.fromJson).toList(growable: false),
          photos: photosJson.map(TaskPhoto.fromJson).toList(growable: false),
        );
      });

  @override
  Future<List<TaskAssignee>> listAssignableMembers(String farmId) =>
      _guard(() async {
        final result = await _client
            .from('farm_memberships')
            .select(assignableMemberColumns)
            .eq('farm_id', farmId)
            .eq('is_active', true)
            .eq('profiles.is_active', true)
            .inFilter(
          'role',
          const <String>['owner', 'agricultural_engineer', 'worker'],
        ).order('created_at');
        return List<TaskAssignee>.unmodifiable(
          result.map(TaskAssignee.fromMembershipJson),
        );
      });

  @override
  Future<String> create(TaskDraft draft) {
    final validation = draft.validate();
    if (validation != null) {
      return Future<String>.error(
        OperationFailure(OperationFailureKind.invalidInput, validation),
      );
    }
    return _guard(() async {
      final Object? result = await _client.rpc(
        createRpc,
        params: draft.toRpcParameters(),
      );
      return result! as String;
    });
  }

  @override
  Future<void> setAssignments(
    String taskId,
    List<String> profileIds,
  ) =>
      _guard(() async {
        await _client.rpc<Object?>(
          assignmentsRpc,
          params: <String, Object?>{
            'p_task_id': taskId,
            'p_assignee_profile_ids': profileIds,
          },
        );
      });

  @override
  Future<void> start(String taskId, {String? note}) => _guard(() async {
        await _client.rpc<Object?>(
          startRpc,
          params: <String, Object?>{
            'p_task_id': taskId,
            'p_note': _optionalText(note),
          },
        );
      });

  @override
  Future<void> complete(
    String taskId, {
    String? note,
    bool requiresEngineerReview = false,
  }) =>
      _guard(() async {
        await _client.rpc<Object?>(
          completeRpc,
          params: <String, Object?>{
            'p_task_id': taskId,
            'p_note': _optionalText(note),
            'p_requires_engineer_review': requiresEngineerReview,
          },
        );
      });

  @override
  Future<String> addPhoto(TaskEvidenceRegistration registration) =>
      _guard(() async {
        final Object? result = await _client.rpc(
          addPhotoRpc,
          params: registration.toRpcParameters(),
        );
        return result! as String;
      });
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

  bool hasPhotoPath(String path) =>
      photos.any((photo) => photo.storagePath == path);

  Map<String, Object?> toCacheJson() => <String, Object?>{
        'task': task.toJson(),
        'assignments':
            assignments.map((item) => item.toJson()).toList(growable: false),
        'activity':
            activity.map((item) => item.toJson()).toList(growable: false),
        'photos': photos.map((item) => item.toJson()).toList(growable: false),
      };

  factory TaskDetails.fromCacheJson(Map<String, Object?> json) => TaskDetails(
        task:
            FarmTask.fromJson(Map<String, Object?>.from(json['task']! as Map)),
        assignments: (json['assignments']! as List<Object?>)
            .map((row) => TaskAssignment.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false),
        activity: (json['activity']! as List<Object?>)
            .map((row) => TaskActivity.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false),
        photos: (json['photos']! as List<Object?>)
            .map((row) => TaskPhoto.fromJson(
                  Map<String, Object?>.from(row! as Map),
                ))
            .toList(growable: false),
      );
}

Future<T> _guard<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on PostgrestException catch (error) {
    throw _translateTaskError(error);
  }
}

OperationFailure _translateTaskError(PostgrestException error) =>
    switch (error.code) {
      '42501' => OperationFailure(
          OperationFailureKind.authorization,
          'Your farm role is not authorized for this task action.',
          cause: error,
        ),
      '23514' => OperationFailure(
          OperationFailureKind.invalidInput,
          error.message,
          cause: error,
        ),
      '23505' => OperationFailure(
          OperationFailureKind.conflict,
          'This task action conflicts with an existing record.',
          cause: error,
        ),
      'P0002' => OperationFailure(
          OperationFailureKind.notFound,
          'The task or related farm record could not be found.',
          cause: error,
        ),
      _ => OperationFailure(
          OperationFailureKind.unexpected,
          'The farm could not save this task action.',
          cause: error,
        ),
    };

String? _optionalText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
