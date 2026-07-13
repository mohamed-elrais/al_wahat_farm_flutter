import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue.dart';
import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportedTreeIssue {
  const ReportedTreeIssue({required this.issueId, required this.taskId});
  final String issueId;
  final String taskId;
}

abstract interface class TreeIssueRepository {
  Future<List<TreeIssue>> listForFarm(String farmId);
  Future<ReportedTreeIssue> report(TreeIssueDraft draft);
  Future<String> addPhoto({
    required String issueId,
    required String storagePath,
    String? caption,
  });
}

class SupabaseTreeIssueRepository implements TreeIssueRepository {
  const SupabaseTreeIssueRepository(this._client);

  static const reportRpc = 'report_tree_issue';
  static const addPhotoRpc = 'add_tree_issue_photo';

  static const issueColumns =
      'id, farm_id, tree_id, issue_type, severity, status, description, '
      'reported_by_profile_id, reported_at, reviewed_by_profile_id, '
      'reviewed_at, resolved_by_profile_id, resolved_at, resolution_notes, '
      'linked_task_id, created_at, updated_at';

  final SupabaseClient _client;

  @override
  Future<List<TreeIssue>> listForFarm(String farmId) async {
    final result = await _client
        .from('tree_issues')
        .select(issueColumns)
        .eq('farm_id', farmId)
        .order('reported_at', ascending: false);
    return result.map(TreeIssue.fromJson).toList(growable: false);
  }

  @override
  Future<ReportedTreeIssue> report(TreeIssueDraft draft) async {
    final validation = draft.validate();
    if (validation != null) {
      throw OperationFailure(OperationFailureKind.invalidInput, validation);
    }
    try {
      final Object? result = await _client.rpc(
        reportRpc,
        params: draft.toRpcParameters(),
      );
      final rows = result! as List<Object?>;
      if (rows.isEmpty) {
        throw const FormatException('Issue RPC returned no result');
      }
      final row = Map<String, Object?>.from(rows.first! as Map);
      return ReportedTreeIssue(
        issueId: row['tree_issue_id']! as String,
        taskId: row['task_id']! as String,
      );
    } on PostgrestException catch (error) {
      throw _translateIssueError(error);
    }
  }

  @override
  Future<String> addPhoto({
    required String issueId,
    required String storagePath,
    String? caption,
  }) async {
    try {
      final result = await _client.rpc<Object?>(
        addPhotoRpc,
        params: <String, Object?>{
          'p_tree_issue_id': issueId,
          'p_storage_path': storagePath,
          'p_caption': caption,
        },
      );
      return result! as String;
    } on PostgrestException catch (error) {
      throw _translateIssueError(error);
    }
  }
}

OperationFailure _translateIssueError(PostgrestException error) =>
    switch (error.code) {
      '42501' => OperationFailure(
          OperationFailureKind.authorization,
          'Your farm role is not authorized for this issue action.',
          cause: error,
        ),
      '23514' => OperationFailure(
          OperationFailureKind.invalidInput,
          'The evidence path did not pass the farm security rules.',
          cause: error,
        ),
      '23505' => OperationFailure(
          OperationFailureKind.conflict,
          'This evidence file is already registered elsewhere.',
          cause: error,
        ),
      'P0002' => OperationFailure(
          OperationFailureKind.notFound,
          'The tree issue, task, or uploaded evidence could not be found.',
          cause: error,
        ),
      _ => OperationFailure(
          OperationFailureKind.unexpected,
          'The farm could not save this issue action.',
          cause: error,
        ),
    };
