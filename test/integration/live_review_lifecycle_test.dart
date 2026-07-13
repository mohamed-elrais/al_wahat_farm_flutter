import 'package:al_wahat_farm_flutter/features/auth/data/operational_context_repository.dart';
import 'package:al_wahat_farm_flutter/features/reviews/data/engineer_review_repository.dart';
import 'package:al_wahat_farm_flutter/features/reviews/domain/engineer_review.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _testEmail = String.fromEnvironment('TEST_EMAIL');
const _testPassword = String.fromEnvironment('TEST_PASSWORD');
const _runLiveMutation = bool.fromEnvironment('RUN_LIVE_REVIEW_MUTATION');
const _taskTitle = '[CODEX LIVE TEST] Phase 6 review 2026-07-13';

const _hasLiveConfiguration = _supabaseUrl != '' &&
    _supabaseAnonKey != '' &&
    _testEmail != '' &&
    _testPassword != '';

void main() {
  test(
    'authorized live review approves a task and records an engineer review',
    () async {
      final client = SupabaseClient(_supabaseUrl, _supabaseAnonKey);
      addTearDown(() async {
        await client.auth.signOut();
        client.dispose();
      });
      final response = await client.auth.signInWithPassword(
        email: _testEmail,
        password: _testPassword,
      );
      final user = response.user;
      if (user == null) {
        fail('The disposable live-test account did not return a user.');
      }

      final operationalContext = await DefaultOperationalContextRepository(
        SupabaseAuthBootstrapDataSource(client),
      ).load(user.id);
      final membership = operationalContext.selectedMembership;
      expect(
        membership.role.canReview,
        isTrue,
        reason: 'The live review gate requires an owner or engineer account.',
      );

      final tasks = SupabaseTaskRepository(client);
      final reviews = SupabaseEngineerReviewRepository(client);
      final farmId = membership.farm.id;

      // Resume a dedicated review-test task so repeat runs never fork rows.
      var taskId = (await tasks.listForFarm(farmId))
          .where((task) => task.title == _taskTitle)
          .firstOrNull
          ?.id;
      taskId ??= await tasks.create(
        TaskDraft(
          farmId: farmId,
          type: TaskType.treeInspection,
          title: _taskTitle,
          description:
              'Authorized persistent test record for the Flutter Phase 6 gate.',
          treeId: await _firstActiveTreeId(client, farmId),
          scheduledFor: DateTime(2026, 7, 13),
          priority: TaskPriority.low,
          instructions: const <String, Object?>{
            'text': 'No farm action required. Persistent automated test only.',
            'test_marker': 'codex_phase_6_live_20260713',
          },
        ),
      );

      // Drive the task to a reviewable status, tolerating an already-approved
      // resume.
      var details = await tasks.loadDetails(taskId);
      if (details.task.status.canComplete) {
        if (details.task.status.canStart) {
          await tasks.start(taskId,
              note: '[CODEX LIVE TEST] Start for review.');
        }
        await tasks.complete(
          taskId,
          note: '[CODEX LIVE TEST] Complete for engineer review.',
          requiresEngineerReview: true,
        );
        details = await tasks.loadDetails(taskId);
      }

      if (details.task.status != TaskStatus.approved) {
        await reviews.review(
          ReviewTaskDraft(
            taskId: taskId,
            decision: EngineerReviewDecision.approved,
            notes: '[CODEX LIVE TEST] Approved by the Phase 6 review gate.',
          ),
        );
      }

      final persisted =
          await SupabaseTaskRepository(client).loadDetails(taskId);
      expect(persisted.task.status, TaskStatus.approved);
      expect(persisted.task.approvedByProfileId, user.id);

      final recorded = await reviews.listForTask(taskId);
      expect(recorded, isNotEmpty);
      expect(
        recorded.any(
          (review) => review.decision == EngineerReviewDecision.approved,
        ),
        isTrue,
      );
      expect(
        persisted.activity.map((item) => item.action),
        contains(TaskActivityAction.reviewedApproved),
      );
    },
    skip: !_hasLiveConfiguration || !_runLiveMutation
        ? 'Requires ignored config.json credentials and explicit '
            'RUN_LIVE_REVIEW_MUTATION=true authorization.'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<String> _firstActiveTreeId(SupabaseClient client, String farmId) async {
  final row = await client
      .from('trees')
      .select('id')
      .eq('farm_id', farmId)
      .eq('is_active', true)
      .order('tree_code')
      .limit(1)
      .single();
  return row['id']! as String;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}
