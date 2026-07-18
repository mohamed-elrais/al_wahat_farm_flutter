import 'dart:typed_data';

import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/reviews/data/engineer_review_repository.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';

class InMemoryTaskStore {
  InMemoryTaskStore({List<TaskAssignee>? members})
      : members = members ??
            const <TaskAssignee>[
              TaskAssignee(
                profileId: 'manager-id',
                fullName: 'Farm Manager',
                role: 'owner',
              ),
              TaskAssignee(
                profileId: 'worker-id',
                fullName: 'Field Worker',
                role: 'worker',
              ),
            ];

  final Map<String, FarmTask> tasks = <String, FarmTask>{};
  final Map<String, List<TaskAssignment>> assignments =
      <String, List<TaskAssignment>>{};
  final Map<String, List<TaskActivity>> activity =
      <String, List<TaskActivity>>{};
  final Map<String, List<TaskPhoto>> photos = <String, List<TaskPhoto>>{};
  final Map<String, List<EngineerReview>> reviews =
      <String, List<EngineerReview>>{};
  final List<TaskAssignee> members;
  int sequence = 0;

  String nextId(String prefix) => '$prefix-${++sequence}';

  DateTime get now => DateTime.utc(2026, 7, 13, 8, sequence);
}

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository({
    required this.store,
    required this.viewerProfileId,
    required this.canManage,
  });

  final InMemoryTaskStore store;
  final String viewerProfileId;
  final bool canManage;
  Object? listFailure;
  Object? detailFailure;
  Object? addPhotoFailureAfterCommit;
  int completeFailuresRemaining = 0;
  int createCalls = 0;
  String? lastCreateOpId;
  String? lastStartOpId;
  String? lastCompleteOpId;
  String? lastSetAssignmentsOpId;
  int uploadRegistrations = 0;

  @override
  Future<List<FarmTask>> listForFarm(String farmId) async {
    if (listFailure != null) throw listFailure!;
    final result = store.tasks.values.where((task) {
      if (task.farmId != farmId) return false;
      if (canManage) return true;
      return _isAssigned(task.id, viewerProfileId) && !task.status.isClosed;
    }).toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return result;
  }

  @override
  Future<TaskDetails> loadDetails(String taskId) async {
    if (detailFailure != null) throw detailFailure!;
    final task = store.tasks[taskId];
    if (task == null || (!canManage && !_isAssigned(taskId, viewerProfileId))) {
      throw const OperationFailure(
        OperationFailureKind.authorization,
        'Task is not visible to this farm member.',
      );
    }
    return TaskDetails(
      task: task,
      assignments: store.assignments[taskId] ?? const <TaskAssignment>[],
      activity: List<TaskActivity>.of(
        store.activity[taskId] ?? const <TaskActivity>[],
      ).reversed.toList(growable: false),
      photos: store.photos[taskId] ?? const <TaskPhoto>[],
    );
  }

  @override
  Future<List<TaskAssignee>> listAssignableMembers(String farmId) async {
    _requireManager();
    return List<TaskAssignee>.of(store.members);
  }

  @override
  Future<String> create(TaskDraft draft, {String? opId}) async {
    _requireManager();
    final validation = draft.validate();
    if (validation != null) {
      throw OperationFailure(OperationFailureKind.invalidInput, validation);
    }
    createCalls++;
    lastCreateOpId = opId;
    final taskId = store.nextId('task');
    final createdAt = store.now;
    final task = FarmTask(
      id: taskId,
      farmId: draft.farmId,
      sectionId: draft.sectionId,
      irrigationZoneId: draft.irrigationZoneId,
      treeId: draft.treeId,
      relatedTreeIssueId: draft.relatedTreeIssueId,
      type: draft.type,
      title: draft.title.trim(),
      description: draft.description,
      priority: draft.priority,
      status: draft.assigneeProfileIds.isEmpty
          ? TaskStatus.draft
          : TaskStatus.assigned,
      scheduledFor: draft.scheduledFor,
      plannedStartTime: draft.plannedStartTime,
      plannedDurationMinutes: draft.plannedDurationMinutes,
      dueAt: draft.dueAt,
      instructions: Map<String, Object?>.of(draft.instructions),
      requiresEngineerReview: draft.requiresEngineerReview,
      createdByProfileId: viewerProfileId,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    store.tasks[taskId] = task;
    store.assignments[taskId] = <TaskAssignment>[
      for (final profileId in draft.assigneeProfileIds)
        TaskAssignment(
          id: store.nextId('assignment'),
          taskId: taskId,
          assigneeProfileId: profileId,
          assignedByProfileId: viewerProfileId,
          assignedAt: store.now,
          isActive: true,
          createdAt: store.now,
        ),
    ];
    store.activity[taskId] = <TaskActivity>[
      _activity(
        taskId: taskId,
        action: TaskActivityAction.created,
        newStatus: task.status,
      ),
    ];
    store.photos[taskId] = <TaskPhoto>[];
    return taskId;
  }

  @override
  Future<void> setAssignments(
    String taskId,
    List<String> profileIds, {
    String? opId,
  }) async {
    lastSetAssignmentsOpId = opId;
    _requireManager();
    final task = _task(taskId);
    if (task.status.isClosed) {
      throw const OperationFailure(
        OperationFailureKind.conflict,
        'Assignments are closed for this task.',
      );
    }
    final previous = store.assignments[taskId] ?? <TaskAssignment>[];
    store.assignments[taskId] = <TaskAssignment>[
      for (final assignment in previous)
        if (!assignment.isActive ||
            profileIds.contains(assignment.assigneeProfileId))
          assignment
        else
          TaskAssignment(
            id: assignment.id,
            taskId: assignment.taskId,
            assigneeProfileId: assignment.assigneeProfileId,
            assignedByProfileId: assignment.assignedByProfileId,
            assignedAt: assignment.assignedAt,
            isActive: false,
            unassignedAt: store.now,
            createdAt: assignment.createdAt,
          ),
      for (final profileId in profileIds)
        if (!previous.any(
          (assignment) =>
              assignment.isActive && assignment.assigneeProfileId == profileId,
        ))
          TaskAssignment(
            id: store.nextId('assignment'),
            taskId: taskId,
            assigneeProfileId: profileId,
            assignedByProfileId: viewerProfileId,
            assignedAt: store.now,
            isActive: true,
            createdAt: store.now,
          ),
    ];
    final nextStatus = profileIds.isEmpty && task.status == TaskStatus.assigned
        ? TaskStatus.draft
        : profileIds.isNotEmpty && task.status == TaskStatus.draft
            ? TaskStatus.assigned
            : task.status;
    store.tasks[taskId] = _copyTask(task, status: nextStatus);
    store.activity[taskId]!.add(
      _activity(
        taskId: taskId,
        action: profileIds.isEmpty
            ? TaskActivityAction.unassigned
            : TaskActivityAction.assigned,
        oldStatus: task.status,
        newStatus: nextStatus,
      ),
    );
  }

  @override
  Future<void> start(String taskId, {String? note, String? opId}) async {
    lastStartOpId = opId;
    final task = _task(taskId);
    _requireAccess(taskId);
    if (!task.status.canStart) {
      throw const OperationFailure(
        OperationFailureKind.conflict,
        'Task cannot be started from its current status.',
      );
    }
    store.tasks[taskId] = _copyTask(task, status: TaskStatus.inProgress);
    store.activity[taskId]!.add(
      _activity(
        taskId: taskId,
        action: TaskActivityAction.started,
        oldStatus: task.status,
        newStatus: TaskStatus.inProgress,
        note: note,
      ),
    );
  }

  @override
  Future<void> complete(
    String taskId, {
    String? note,
    bool requiresEngineerReview = false,
    String? opId,
  }) async {
    lastCompleteOpId = opId;
    final task = _task(taskId);
    _requireAccess(taskId);
    if (!task.status.canComplete) {
      throw const OperationFailure(
        OperationFailureKind.conflict,
        'Task cannot be completed from its current status.',
      );
    }
    if (completeFailuresRemaining > 0) {
      completeFailuresRemaining--;
      throw const OperationFailure(
        OperationFailureKind.unexpected,
        'Completion response was not confirmed.',
      );
    }
    final next = requiresEngineerReview
        ? TaskStatus.needsEngineerReview
        : TaskStatus.completed;
    store.tasks[taskId] = _copyTask(
      task,
      status: next,
      completedByProfileId: viewerProfileId,
      completedAt: store.now,
    );
    store.activity[taskId]!.add(
      _activity(
        taskId: taskId,
        action: requiresEngineerReview
            ? TaskActivityAction.flaggedForReview
            : TaskActivityAction.completed,
        oldStatus: task.status,
        newStatus: next,
        note: note,
      ),
    );
  }

  @override
  Future<String> addPhoto(TaskEvidenceRegistration registration) async {
    _task(registration.taskId);
    _requireAccess(registration.taskId);
    uploadRegistrations++;
    final existing = store.photos[registration.taskId]!.where(
      (photo) => photo.storagePath == registration.storagePath,
    );
    if (existing.isNotEmpty) return existing.first.id;
    final photoId = store.nextId('photo');
    store.photos[registration.taskId]!.add(
      TaskPhoto(
        id: photoId,
        taskId: registration.taskId,
        storageBucketId: 'farm-evidence',
        storagePath: registration.storagePath,
        photoType: registration.type,
        caption: registration.caption,
        uploadedByProfileId: viewerProfileId,
        createdAt: store.now,
      ),
    );
    store.activity[registration.taskId]!.add(
      _activity(
        taskId: registration.taskId,
        action: TaskActivityAction.photoAdded,
      ),
    );
    if (addPhotoFailureAfterCommit != null) throw addPhotoFailureAfterCommit!;
    return photoId;
  }

  bool _isAssigned(String taskId, String profileId) =>
      (store.assignments[taskId] ?? const <TaskAssignment>[]).any(
        (assignment) =>
            assignment.isActive && assignment.assigneeProfileId == profileId,
      );

  void _requireManager() {
    if (!canManage) {
      throw const OperationFailure(
        OperationFailureKind.authorization,
        'Only a task manager can perform this action.',
      );
    }
  }

  void _requireAccess(String taskId) {
    if (!canManage && !_isAssigned(taskId, viewerProfileId)) {
      throw const OperationFailure(
        OperationFailureKind.authorization,
        'Task is not assigned to this worker.',
      );
    }
  }

  FarmTask _task(String id) {
    final task = store.tasks[id];
    if (task == null) {
      throw const OperationFailure(
        OperationFailureKind.notFound,
        'Task not found.',
      );
    }
    return task;
  }

  TaskActivity _activity({
    required String taskId,
    required TaskActivityAction action,
    TaskStatus? oldStatus,
    TaskStatus? newStatus,
    String? note,
  }) =>
      TaskActivity(
        id: store.nextId('activity'),
        taskId: taskId,
        actorProfileId: viewerProfileId,
        action: action,
        oldStatus: oldStatus,
        newStatus: newStatus,
        note: note,
        metadata: const <String, Object?>{},
        createdAt: store.now,
      );
}

class FakeTaskEvidencePicker implements TaskEvidencePicker {
  FakeTaskEvidencePicker({PreparedTaskEvidence? evidence})
      : evidence = evidence ??
            PreparedTaskEvidence(
              bytes: Uint8List.fromList(<int>[1, 2, 3]),
              filename: 'task.jpg',
              contentType: 'image/jpeg',
            );

  PreparedTaskEvidence? evidence;
  Object? failure;
  int pickCount = 0;

  @override
  Future<PreparedTaskEvidence?> pick(TaskEvidenceSource source) async {
    pickCount++;
    if (failure != null) throw failure!;
    return evidence;
  }
}

class FakeTaskEvidenceStorage implements TaskEvidenceStorage {
  String uploadedPath = 'worker-id/farm-id/task-1/123_task.jpg';
  Object? failure;
  int uploadCount = 0;

  @override
  Future<String> upload({
    required String userId,
    required String farmId,
    required String taskId,
    required PreparedTaskEvidence evidence,
  }) async {
    uploadCount++;
    if (failure != null) throw failure!;
    return uploadedPath.replaceFirst('task-1', taskId);
  }
}

FarmTask _copyTask(
  FarmTask task, {
  required TaskStatus status,
  String? completedByProfileId,
  DateTime? completedAt,
  String? approvedByProfileId,
  DateTime? approvedAt,
  DateTime? updatedAt,
}) =>
    FarmTask(
      id: task.id,
      farmId: task.farmId,
      sectionId: task.sectionId,
      irrigationZoneId: task.irrigationZoneId,
      treeId: task.treeId,
      relatedTreeIssueId: task.relatedTreeIssueId,
      type: task.type,
      title: task.title,
      description: task.description,
      priority: task.priority,
      status: status,
      scheduledFor: task.scheduledFor,
      plannedStartTime: task.plannedStartTime,
      plannedDurationMinutes: task.plannedDurationMinutes,
      dueAt: task.dueAt,
      instructions: task.instructions,
      requiresEngineerReview: task.requiresEngineerReview,
      createdByProfileId: task.createdByProfileId,
      completedByProfileId: completedByProfileId ?? task.completedByProfileId,
      completedAt: completedAt ?? task.completedAt,
      approvedByProfileId: approvedByProfileId ?? task.approvedByProfileId,
      approvedAt: approvedAt ?? task.approvedAt,
      cancelledByProfileId: task.cancelledByProfileId,
      cancelledAt: task.cancelledAt,
      cancellationReason: task.cancellationReason,
      createdAt: task.createdAt,
      updatedAt: updatedAt ?? completedAt ?? task.updatedAt,
    );

/// Fake `review_task` backend mirroring the RPC's status transitions, activity
/// logging, optional review photo, and manager-only authorization. Non-managers
/// are rejected with an authorization failure, exactly like RLS `42501`.
class FakeEngineerReviewRepository implements EngineerReviewRepository {
  FakeEngineerReviewRepository({
    required this.store,
    required this.reviewerProfileId,
    required this.canReview,
  });

  final InMemoryTaskStore store;
  final String reviewerProfileId;
  final bool canReview;
  int reviewFailuresRemaining = 0;
  int reviewCalls = 0;
  String? lastReviewOpId;

  @override
  Future<List<EngineerReview>> listForTask(String taskId) async {
    final recorded = store.reviews[taskId] ?? const <EngineerReview>[];
    return List<EngineerReview>.of(recorded).reversed.toList(growable: false);
  }

  @override
  Future<String> review(ReviewTaskDraft draft, {String? opId}) async {
    lastReviewOpId = opId;
    if (!canReview) {
      throw const OperationFailure(
        OperationFailureKind.authorization,
        'Only the owner or agricultural engineer can review tasks.',
      );
    }
    final task = store.tasks[draft.taskId];
    if (task == null) {
      throw const OperationFailure(
        OperationFailureKind.notFound,
        'The task to review could not be found.',
      );
    }
    if (task.status != TaskStatus.completed &&
        task.status != TaskStatus.needsEngineerReview) {
      throw const OperationFailure(
        OperationFailureKind.invalidInput,
        'Only completed or review-needed tasks can be reviewed.',
      );
    }
    if (reviewFailuresRemaining > 0) {
      reviewFailuresRemaining--;
      throw const OperationFailure(
        OperationFailureKind.unexpected,
        'Review decision response was not confirmed.',
      );
    }
    reviewCalls++;
    final reviewId = store.nextId('review');
    final decision = draft.decision;
    final approved = decision == EngineerReviewDecision.approved;
    final newStatus = switch (decision) {
      EngineerReviewDecision.approved => TaskStatus.approved,
      EngineerReviewDecision.returnedForCorrection => TaskStatus.returned,
      EngineerReviewDecision.followUpRequired => TaskStatus.needsEngineerReview,
    };
    (store.reviews[draft.taskId] ??= <EngineerReview>[]).add(
      EngineerReview(
        id: reviewId,
        taskId: draft.taskId,
        treeIssueId: task.relatedTreeIssueId,
        reviewerProfileId: reviewerProfileId,
        decision: decision,
        notes: draft.notes,
        reviewedAt: store.now,
        createdAt: store.now,
      ),
    );
    store.tasks[draft.taskId] = _copyTask(
      task,
      status: newStatus,
      approvedByProfileId: approved ? reviewerProfileId : null,
      approvedAt: approved ? store.now : null,
      updatedAt: store.now,
    );
    if (draft.photoStoragePath != null) {
      (store.photos[draft.taskId] ??= <TaskPhoto>[]).add(
        TaskPhoto(
          id: store.nextId('photo'),
          taskId: draft.taskId,
          engineerReviewId: reviewId,
          storageBucketId: 'farm-evidence',
          storagePath: draft.photoStoragePath!,
          photoType: TaskPhotoType.review,
          uploadedByProfileId: reviewerProfileId,
          createdAt: store.now,
        ),
      );
    }
    (store.activity[draft.taskId] ??= <TaskActivity>[]).add(
      TaskActivity(
        id: store.nextId('activity'),
        taskId: draft.taskId,
        actorProfileId: reviewerProfileId,
        action: approved
            ? TaskActivityAction.reviewedApproved
            : TaskActivityAction.reviewedReturned,
        oldStatus: task.status,
        newStatus: newStatus,
        note: draft.notes,
        metadata: <String, Object?>{
          'engineer_review_id': reviewId,
          'decision': decision.wireValue,
        },
        createdAt: store.now,
      ),
    );
    return reviewId;
  }
}
