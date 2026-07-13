import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class EngineerReviewRepository {
  Future<List<EngineerReview>> listForTask(String taskId);

  Future<String> review(ReviewTaskDraft draft);
}

class SupabaseEngineerReviewRepository implements EngineerReviewRepository {
  const SupabaseEngineerReviewRepository(this._client);

  static const reviewRpc = 'review_task';
  static const reviewColumns =
      'id, task_id, tree_issue_id, reviewer_profile_id, decision, notes, '
      'reviewed_at, created_at';

  final SupabaseClient _client;

  @override
  Future<List<EngineerReview>> listForTask(String taskId) => _guard(() async {
        final result = await _client
            .from('engineer_reviews')
            .select(reviewColumns)
            .eq('task_id', taskId)
            .order('reviewed_at', ascending: false);
        return result.map(EngineerReview.fromJson).toList(growable: false);
      });

  @override
  Future<String> review(ReviewTaskDraft draft) => _guard(() async {
        final Object? result = await _client.rpc(
          reviewRpc,
          params: draft.toRpcParameters(),
        );
        return result! as String;
      });
}

Future<T> _guard<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on PostgrestException catch (error) {
    throw translateReviewError(error);
  }
}

/// Maps the `review_task` backend contract's error codes onto actionable
/// [OperationFailure]s. A worker who reaches the RPC boundary is rejected by
/// row-level security with `42501`, which surfaces here as an authorization
/// failure rather than an opaque database error.
@visibleForTesting
OperationFailure translateReviewError(PostgrestException error) =>
    switch (error.code) {
      '42501' => OperationFailure(
          OperationFailureKind.authorization,
          'Only the owner or agricultural engineer can review tasks.',
          cause: error,
        ),
      '23514' => OperationFailure(
          OperationFailureKind.invalidInput,
          'Only completed or review-needed tasks can be reviewed.',
          cause: error,
        ),
      'P0002' => OperationFailure(
          OperationFailureKind.notFound,
          'The task to review could not be found.',
          cause: error,
        ),
      _ => OperationFailure(
          OperationFailureKind.unexpected,
          'The farm could not record this review decision.',
          cause: error,
        ),
    };
