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
}

class SupabaseTreeIssueRepository implements TreeIssueRepository {
  const SupabaseTreeIssueRepository(this._client);

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
    final Object? result = await _client.rpc(
      'report_tree_issue',
      params: draft.toRpcParameters(),
    );
    final rows = result! as List<Object?>;
    if (rows.isEmpty) {
      throw const FormatException('Issue RPC returned no result');
    }
    final row = rows.first! as Map<String, Object?>;
    return ReportedTreeIssue(
      issueId: row['tree_issue_id']! as String,
      taskId: row['task_id']! as String,
    );
  }
}
