import 'package:al_wahat_farm_flutter/core/errors/operation_failure.dart';
import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ScheduleRepository {
  Future<List<OperationPlan>> listPlans(String farmId);
  Future<String> createPlan(OperationPlanDraft draft);
  Future<void> updatePlan(
    String planId, {
    String? title,
    String? description,
    OperationPlanStatus? status,
    String? scheduledStartTime,
    int? plannedDurationMinutes,
    List<int>? daysOfWeek,
    List<PlanTarget>? targets,
    List<String>? assigneeProfileIds,
    double? applicationRate,
  });
  Future<List<PlanInventoryCheck>> checkInventory(
    String planId, {
    int horizonDays = 30,
  });
  Future<int> generateNow(String farmId);
}

class SupabaseScheduleRepository implements ScheduleRepository {
  const SupabaseScheduleRepository(this._client);

  static const planColumns =
      'id, farm_id, operation_type, title, description, status, '
      'schedule_type, starts_on, ends_on, scheduled_start_time, '
      'planned_duration_minutes, days_of_week, inventory_item_id, '
      'application_method, application_rate, rate_basis, rate_unit, '
      'default_assignee_profile_ids, task_grouping, repeat_every';
  static const targetColumns =
      'id, operation_plan_id, section_id, irrigation_zone_id, tree_id';

  final SupabaseClient _client;

  @override
  Future<List<OperationPlan>> listPlans(String farmId) => _guard(() async {
        final planRows = await _client
            .from('operation_plans')
            .select(planColumns)
            .eq('farm_id', farmId)
            .neq('status', 'archived')
            .order('created_at', ascending: false);
        if (planRows.isEmpty) return const <OperationPlan>[];
        final planIds =
            planRows.map((row) => row['id']! as String).toList(growable: false);
        final targetRows = await _client
            .from('operation_plan_targets')
            .select(targetColumns)
            .inFilter('operation_plan_id', planIds)
            .eq('is_active', true);
        final targetsByPlan = <String, List<PlanTarget>>{};
        for (final row in targetRows) {
          (targetsByPlan[row['operation_plan_id']! as String] ??=
                  <PlanTarget>[])
              .add(PlanTarget.fromJson(row));
        }
        return planRows
            .map(
              (row) => OperationPlan.fromJson(
                row,
                targets:
                    targetsByPlan[row['id']! as String] ?? const <PlanTarget>[],
              ),
            )
            .toList(growable: false);
      });

  @override
  Future<String> createPlan(OperationPlanDraft draft) {
    final validation = draft.validate();
    if (validation != null) {
      return Future<String>.error(
        OperationFailure(OperationFailureKind.invalidInput, validation.message),
      );
    }
    return _guard(() async {
      final Object? result = await _client.rpc(
        'create_operation_plan',
        params: draft.toRpcParameters(),
      );
      return result! as String;
    });
  }

  @override
  Future<void> updatePlan(
    String planId, {
    String? title,
    String? description,
    OperationPlanStatus? status,
    String? scheduledStartTime,
    int? plannedDurationMinutes,
    List<int>? daysOfWeek,
    List<PlanTarget>? targets,
    List<String>? assigneeProfileIds,
    double? applicationRate,
  }) =>
      _guard(() async {
        await _client.rpc<Object?>('update_operation_plan', params: {
          'p_operation_plan_id': planId,
          'p_title': title,
          'p_description': description,
          'p_status': status?.wireValue,
          'p_scheduled_start_time': scheduledStartTime,
          'p_planned_duration_minutes': plannedDurationMinutes,
          'p_days_of_week': daysOfWeek,
          'p_replace_targets': targets != null,
          'p_targets': targets
              ?.map((target) => target.toRpcJson())
              .toList(growable: false),
          'p_application_rate': applicationRate,
          'p_default_assignee_profile_ids': assigneeProfileIds,
        });
      });

  @override
  Future<List<PlanInventoryCheck>> checkInventory(
    String planId, {
    int horizonDays = 30,
  }) =>
      _guard(() async {
        final Object? rows = await _client.rpc(
          'check_operation_plan_inventory',
          params: {
            'p_operation_plan_id': planId,
            'p_horizon_days': horizonDays,
          },
        );
        return (rows! as List<Object?>)
            .map(
              (row) => PlanInventoryCheck.fromJson(
                Map<String, Object?>.from(row! as Map),
              ),
            )
            .toList(growable: false);
      });

  @override
  Future<int> generateNow(String farmId) => _guard(() async {
        final Object? result = await _client.rpc(
          'generate_farm_tasks_now',
          params: {'p_farm_id': farmId},
        );
        return (result! as num).toInt();
      });
}

Future<T> _guard<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on PostgrestException catch (error) {
    throw switch (error.code) {
      '42501' => OperationFailure(
          OperationFailureKind.authorization,
          'Your farm role is not authorized for schedules.',
          cause: error,
        ),
      '23514' => OperationFailure(
          OperationFailureKind.invalidInput,
          error.message,
          cause: error,
        ),
      'P0002' => OperationFailure(
          OperationFailureKind.notFound,
          'The schedule could not be found.',
          cause: error,
        ),
      _ => OperationFailure(
          OperationFailureKind.unexpected,
          'The farm could not save this schedule.',
          cause: error,
        ),
    };
  }
}
