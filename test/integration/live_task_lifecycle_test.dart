import 'dart:convert';

import 'package:al_wahat_farm_flutter/features/auth/data/operational_context_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_evidence_service.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_draft.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/task_evidence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _testEmail = String.fromEnvironment('TEST_EMAIL');
const _testPassword = String.fromEnvironment('TEST_PASSWORD');
const _runLiveMutation = bool.fromEnvironment('RUN_LIVE_TASK_MUTATION');
const _taskTitle = '[CODEX LIVE TEST] Phase 5 lifecycle 2026-07-13';
const _evidenceCaption = '[CODEX LIVE TEST] Phase 5 private evidence';

const _hasLiveConfiguration = _supabaseUrl != '' &&
    _supabaseAnonKey != '' &&
    _testEmail != '' &&
    _testPassword != '';

void main() {
  test(
    'authorized live task survives reload and records assignment, evidence, and activity',
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
        membership.role.canManageTasks,
        isTrue,
        reason:
            'The live lifecycle requires an owner or engineer test account.',
      );

      final repository = SupabaseTaskRepository(client);
      final members =
          await repository.listAssignableMembers(membership.farm.id);
      final worker =
          members.where((member) => member.role == 'worker').firstOrNull;
      if (worker == null) {
        fail(
            'The live-test farm has no active worker available for assignment.');
      }

      final existing = (await repository.listForFarm(membership.farm.id))
          .where((task) => task.title == _taskTitle)
          .firstOrNull;
      final taskId = existing?.id ??
          await repository.create(
            TaskDraft(
              farmId: membership.farm.id,
              type: TaskType.treeInspection,
              title: _taskTitle,
              description:
                  'Authorized persistent test record for the Flutter Phase 5 gate.',
              treeId: await _firstActiveTreeId(client, membership.farm.id),
              scheduledFor: DateTime(2026, 7, 13),
              plannedStartTime: '12:00:00',
              plannedDurationMinutes: 5,
              dueAt: DateTime(2026, 7, 14, 17),
              priority: TaskPriority.low,
              instructions: const <String, Object?>{
                'text':
                    'No farm action required. Persistent automated test only.',
                'test_marker': 'codex_phase_5_live_20260713',
              },
            ),
          );

      var details = await repository.loadDetails(taskId);
      final assignedWorker = details.assignments.any(
        (assignment) =>
            assignment.isActive &&
            assignment.assigneeProfileId == worker.profileId,
      );
      if (!assignedWorker && !details.task.status.isClosed) {
        await repository.setAssignments(taskId, <String>[worker.profileId]);
        details = await repository.loadDetails(taskId);
      }

      if (details.task.status.canStart) {
        await repository.start(
          taskId,
          note: '[CODEX LIVE TEST] Starting lifecycle verification.',
        );
        details = await repository.loadDetails(taskId);
      }

      if (!details.photos.any((photo) => photo.caption == _evidenceCaption)) {
        final storagePath = await SupabaseTaskEvidenceStorage(client).upload(
          userId: user.id,
          farmId: membership.farm.id,
          taskId: taskId,
          evidence: PreparedTaskEvidence(
            bytes: base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
              'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            ),
            filename: 'codex-live-phase5-evidence.png',
            contentType: 'image/png',
          ),
        );
        try {
          await repository.addPhoto(
            TaskEvidenceRegistration(
              taskId: taskId,
              storagePath: storagePath,
              type: TaskPhotoType.evidence,
              caption: _evidenceCaption,
            ),
          );
        } catch (_) {
          final reconciled = await repository.loadDetails(taskId);
          if (!reconciled.hasPhotoPath(storagePath)) rethrow;
        }
        details = await repository.loadDetails(taskId);
      }

      if (details.task.status.canComplete) {
        await repository.complete(
          taskId,
          note: '[CODEX LIVE TEST] Lifecycle verification complete.',
        );
      }

      final persisted =
          await SupabaseTaskRepository(client).loadDetails(taskId);
      expect(persisted.task.title, _taskTitle);
      expect(persisted.task.status, TaskStatus.completed);
      expect(
        persisted.assignments.any(
          (assignment) =>
              assignment.isActive &&
              assignment.assigneeProfileId == worker.profileId,
        ),
        isTrue,
      );
      expect(
        persisted.photos.any((photo) => photo.caption == _evidenceCaption),
        isTrue,
      );
      expect(
        persisted.activity.map((item) => item.action),
        containsAll(<TaskActivityAction>[
          TaskActivityAction.created,
          TaskActivityAction.assigned,
          TaskActivityAction.started,
          TaskActivityAction.photoAdded,
          TaskActivityAction.completed,
        ]),
      );

      final reloadedTasks =
          await SupabaseTaskRepository(client).listForFarm(membership.farm.id);
      expect(
        reloadedTasks.any(
          (task) => task.id == taskId && task.status == TaskStatus.completed,
        ),
        isTrue,
      );
    },
    skip: !_hasLiveConfiguration || !_runLiveMutation
        ? 'Requires ignored config.json credentials and explicit '
            'RUN_LIVE_TASK_MUTATION=true authorization.'
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
