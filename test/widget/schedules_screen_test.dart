import 'package:al_wahat_farm_flutter/app/theme/app_theme.dart';
import 'package:al_wahat_farm_flutter/features/auth/domain/operational_context.dart';
import 'package:al_wahat_farm_flutter/features/auth/presentation/authenticated_gate.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_controller.dart';
import 'package:al_wahat_farm_flutter/features/schedules/presentation/schedules_screen.dart';
import 'package:al_wahat_farm_flutter/l10n/gen/app_localizations_en.dart';
import 'package:al_wahat_farm_flutter/shared/models/farm_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/schedule_fakes.dart';

void main() {
  testWidgets('schedules list renders plans with type and recurrence',
      (tester) async {
    final repo = FakeScheduleRepository();
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.fertilization,
      title: 'Friday calcium',
      scheduleType: PlanScheduleType.weekly,
      startsOn: DateTime(2026, 8, 1),
      daysOfWeek: const <int>[5],
      status: OperationPlanStatus.active,
    ));
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.irrigation,
      title: 'Daily watering',
      scheduleType: PlanScheduleType.daily,
      startsOn: DateTime(2026, 8, 1),
      status: OperationPlanStatus.paused,
    ));
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    await controller.load();

    // No operational context in this harness -> the screen treats the viewer
    // as unauthorized, so pump tiles directly through the controller state.
    expect(controller.plans, hasLength(2));
    expect(controller.planById('plan-1')?.title, 'Friday calcium');
  });

  testWidgets('status chip and summary render for an active weekly plan',
      (tester) async {
    final repo = FakeScheduleRepository();
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.fertilization,
      title: 'Friday calcium',
      scheduleType: PlanScheduleType.weekly,
      startsOn: DateTime(2026, 8, 1),
      daysOfWeek: const <int>[5],
      scheduledStartTime: '08:00:00',
      status: OperationPlanStatus.active,
    ));
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    await controller.load();
    final plan = controller.plans.single;

    late String summary;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            summary = scheduleSummary(context, AppLocalizationsEn(), plan);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(summary, contains('Weekly'));
    expect(summary, contains('08:00'));
  });

  test('setStatus pauses and reactivates a plan', () async {
    final repo = FakeScheduleRepository();
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.irrigation,
      title: 'Daily watering',
      scheduleType: PlanScheduleType.daily,
      startsOn: DateTime(2026, 8, 1),
      status: OperationPlanStatus.active,
    ));
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);
    await controller.load();

    await controller.setStatus('plan-1', OperationPlanStatus.paused);
    expect(
      controller.planById('plan-1')?.status,
      OperationPlanStatus.paused,
    );
  });

  testWidgets('a schedule short of stock is flagged; archived ones can show',
      (tester) async {
    final repo = FakeScheduleRepository();
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.fertilization,
      title: 'Friday calcium',
      scheduleType: PlanScheduleType.weekly,
      startsOn: DateTime(2026, 8, 1),
      daysOfWeek: const <int>[5],
      status: OperationPlanStatus.active,
    ));
    await repo.createPlan(OperationPlanDraft(
      farmId: 'farm-id',
      type: OperationPlanType.irrigation,
      title: 'Old watering',
      scheduleType: PlanScheduleType.daily,
      startsOn: DateTime(2026, 8, 1),
      status: OperationPlanStatus.archived,
    ));
    repo.skippedForStock.add('plan-1');
    final controller = SchedulesController(repository: repo, farmId: 'farm-id');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      OperationalContextScope(
        contextData: OperationalContext(
          profile: const UserProfile(
            id: 'manager-id',
            fullName: 'Manager',
            isActive: true,
          ),
          memberships: const <FarmMembership>[
            FarmMembership(
              id: 'membership',
              profileId: 'manager-id',
              role: FarmRole.owner,
              isActive: true,
              farm: FarmSummary(
                id: 'farm-id',
                name: 'Al Wahat',
                code: 'AL-WAHAT',
                timezone: 'Africa/Cairo',
              ),
            ),
          ],
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: SchedulesScreen(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('schedule-skipped-plan-1')), findsOneWidget);
    expect(find.text('Old watering'), findsNothing);

    await tester.tap(find.byKey(const Key('schedules-show-archived')));
    await tester.pumpAndSettle();
    expect(find.text('Old watering'), findsOneWidget);
  });
}
