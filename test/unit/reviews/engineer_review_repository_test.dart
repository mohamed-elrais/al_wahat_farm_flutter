import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/reviews/data/engineer_review_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('translateReviewError', () {
    test('RLS denial at the review RPC boundary becomes authorization', () {
      final failure = translateReviewError(
        const PostgrestException(
          message: 'Only the owner or agricultural engineer can review tasks',
          code: '42501',
        ),
      );

      expect(failure.kind, OperationFailureKind.authorization);
      expect(failure.message, contains('owner or agricultural engineer'));
    });

    test('ineligible task status becomes invalid input', () {
      final failure = translateReviewError(
        const PostgrestException(
          message: 'Only completed or review-needed tasks can be reviewed',
          code: '23514',
        ),
      );

      expect(failure.kind, OperationFailureKind.invalidInput);
    });

    test('missing task becomes not found', () {
      final failure = translateReviewError(
        const PostgrestException(message: 'Task not found', code: 'P0002'),
      );

      expect(failure.kind, OperationFailureKind.notFound);
    });

    test('unknown codes become an unexpected failure', () {
      final failure = translateReviewError(
        const PostgrestException(message: 'boom', code: 'XX000'),
      );

      expect(failure.kind, OperationFailureKind.unexpected);
    });
  });
}
