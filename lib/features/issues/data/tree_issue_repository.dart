import 'package:al_wahat_farm_flutter/features/issues/domain/tree_issue_draft.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportedTreeIssue {
  const ReportedTreeIssue({required this.issueId, required this.taskId});
  final String issueId;
  final String taskId;
}

abstract interface class TreeIssueRepository {
  Future<ReportedTreeIssue> report(TreeIssueDraft draft);
}

class SupabaseTreeIssueRepository implements TreeIssueRepository {
  const SupabaseTreeIssueRepository(this._client);
  final SupabaseClient _client;

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
