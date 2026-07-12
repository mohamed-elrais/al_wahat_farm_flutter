import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class EngineerReviewRepository {
  Future<List<EngineerReview>> listForTask(String taskId);

  Future<String> review(ReviewTaskDraft draft);
}

class SupabaseEngineerReviewRepository implements EngineerReviewRepository {
  const SupabaseEngineerReviewRepository(this._client);

  static const reviewColumns =
      'id, task_id, tree_issue_id, reviewer_profile_id, decision, notes, '
      'reviewed_at, created_at';

  final SupabaseClient _client;

  @override
  Future<List<EngineerReview>> listForTask(String taskId) async {
    final result = await _client
        .from('engineer_reviews')
        .select(reviewColumns)
        .eq('task_id', taskId)
        .order('reviewed_at', ascending: false);
    return result.map(EngineerReview.fromJson).toList(growable: false);
  }

  @override
  Future<String> review(ReviewTaskDraft draft) async {
    final Object? result = await _client.rpc(
      'review_task',
      params: draft.toRpcParameters(),
    );
    return result! as String;
  }
}
