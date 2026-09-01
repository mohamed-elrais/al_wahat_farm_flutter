import 'package:al_wahat_farm_flutter/features/auth/data/operational_context_repository.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/farm/data/farm_hierarchy_repository.dart';
import 'package:al_wahat_farm_flutter/features/farm/domain/farm_hierarchy.dart';
import 'package:al_wahat_farm_flutter/features/tasks/data/task_repository.dart';
import 'package:al_wahat_farm_flutter/features/tasks/domain/farm_task.dart';
import 'package:al_wahat_farm_flutter/features/trees/data/tree_qr_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _testEmail = String.fromEnvironment('TEST_EMAIL');
const _testPassword = String.fromEnvironment('TEST_PASSWORD');
const _requiredZoneCount = 122;

const _hasLiveConfiguration = _supabaseUrl != '' &&
    _supabaseAnonKey != '' &&
    _testEmail != '' &&
    _testPassword != '';

void main() {
  group(
    'live Supabase farm hierarchy',
    () {
      late SupabaseClient client;
      late OperationalContext operationalContext;
      late FarmHierarchy hierarchy;
      late List<FarmTask> visibleTasks;
      late List<TaskAssignee> assignableMembers;
      late String qrToken;
      late String qrTreeId;

      setUpAll(() async {
        client = SupabaseClient(_supabaseUrl, _supabaseAnonKey);
        final response = await client.auth.signInWithPassword(
          email: _testEmail,
          password: _testPassword,
        );
        final user = response.user;
        if (user == null) {
          fail('The disposable live-test account did not return a user.');
        }

        operationalContext = await DefaultOperationalContextRepository(
          SupabaseAuthBootstrapDataSource(client),
        ).load(user.id);
        final membership = operationalContext.selectedMembership;
        hierarchy = (await DefaultFarmHierarchyRepository(
          SupabaseFarmHierarchyDataSource(client),
          MemoryFarmHierarchyCache(),
        ).load(membership.farm.id, allowCachedFallback: false))
            .hierarchy;
        final taskRepository = SupabaseTaskRepository(client);
        visibleTasks = await taskRepository.listForFarm(membership.farm.id);
        assignableMembers =
            await taskRepository.listAssignableMembers(membership.farm.id);
        final qrRow = await client
            .from('tree_qr_codes')
            .select('qr_token, tree_id')
            .eq('is_active', true)
            .limit(1)
            .maybeSingle();
        if (qrRow == null) {
          fail(
              'The live-test farm has no active QR label visible to its owner.');
        }
        qrToken = qrRow['qr_token']! as String;
        qrTreeId = qrRow['tree_id']! as String;
      });

      tearDownAll(() async {
        await client.auth.signOut();
        client.dispose();
      });

      test('authenticated operational account passes RLS data gates', () {
        expect(operationalContext.profile.isActive, isTrue);
        expect(operationalContext.selectedMembership.isActive, isTrue);
        expect(
          operationalContext.selectedMembership.role.isOperational,
          isTrue,
        );
        expect(hierarchy.sections, hasLength(12));
        expect(hierarchy.trees, hasLength(1539));
        expect(hierarchy.plantingPits, hasLength(1876));
      });

      test('active zone count matches the declared product requirement', () {
        expect(
          hierarchy.zones,
          hasLength(_requiredZoneCount),
          reason:
              'The authoritative farm count requires exactly 122 active zones. '
              'Resolve any live-data discrepancy from the authoritative irrigation '
              'plan; never delete arbitrary rows just to satisfy this test.',
        );
      });

      test('an active real QR token resolves the correct live tree', () async {
        final tree = await SupabaseTreeQrRepository(client).scan(qrToken);

        expect(tree, isNotNull);
        expect(tree!.id, qrTreeId);
        expect(hierarchy.trees.any((record) => record.id == tree.id), isTrue);
      });

      test('task and active-assignee read contracts pass live RLS', () {
        final farmId = operationalContext.selectedMembership.farm.id;
        expect(visibleTasks.every((task) => task.farmId == farmId), isTrue);
        expect(assignableMembers, isNotEmpty);
        expect(
          assignableMembers.map((member) => member.profileId).toSet(),
          hasLength(assignableMembers.length),
        );
        expect(
          assignableMembers
              .every((member) => member.fullName.trim().isNotEmpty),
          isTrue,
        );
      });
    },
    skip: _hasLiveConfiguration
        ? false
        : 'Requires SUPABASE_URL, SUPABASE_ANON_KEY, TEST_EMAIL, and '
            'TEST_PASSWORD via --dart-define-from-file=config.json.',
  );
}
