import 'package:al_wahat_farm_flutter/features/schedules/domain/schedule_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The same cases were checked against the database rule
/// `private.plan_runs_on` on 2026-10-15, so the form preview and the
/// generated tasks agree.
void main() {
  String days(List<DateTime> dates) => dates
      .map((date) => '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}')
      .join(' ');

  List<DateTime> weekly(List<int> weekdays, int every, String start) =>
      planOccurrences(
        scheduleType: PlanScheduleType.weekly,
        startsOn: DateTime.parse(start),
        endsOn: DateTime(2026, 11, 20),
        daysOfWeek: weekdays,
        repeatEvery: every,
      );

  test('every 2 weeks on Wednesday: one on, one off', () {
    // 2026-10-15 is a Thursday; the first Wednesday is the 21st.
    expect(days(weekly(<int>[3], 2, '2026-10-15')), '10-21 11-04 11-18');
  });

  test('every 3 weeks on Wednesday: one on, two off', () {
    expect(days(weekly(<int>[3], 3, '2026-10-15')), '10-21 11-11');
  });

  test('every 2 weeks counts from the week of the first run', () {
    // Start Wednesday 14th with Monday + Thursday: the first run is
    // Thursday 15th, so that week is "on" and the next one is off.
    expect(
      days(weekly(<int>[1, 4], 2, '2026-10-14')),
      '10-15 10-26 10-29 11-09 11-12',
    );
  });

  test('every week is unchanged', () {
    expect(
      days(weekly(<int>[3], 1, '2026-10-15')),
      '10-21 10-28 11-04 11-11 11-18',
    );
  });

  test('every 3 days from the start date', () {
    expect(
      days(planOccurrences(
        scheduleType: PlanScheduleType.daily,
        startsOn: DateTime(2026, 10, 15),
        endsOn: DateTime(2026, 10, 25),
        repeatEvery: 3,
      )),
      '10-15 10-18 10-21 10-24',
    );
  });

  test('next runs from today keep the rhythm of the start date', () {
    final plan = OperationPlan(
      id: 'plan',
      farmId: 'farm',
      type: OperationPlanType.irrigation,
      title: 'Every 2 weeks',
      status: OperationPlanStatus.active,
      scheduleType: PlanScheduleType.weekly,
      startsOn: DateTime(2026, 10, 15),
      endsOn: DateTime(2026, 12, 31),
      daysOfWeek: const <int>[3],
      repeatEvery: 2,
      targets: const <PlanTarget>[PlanTarget()],
      defaultAssigneeProfileIds: const <String>[],
    );
    expect(days(plan.nextOccurrences(DateTime(2026, 10, 25), count: 3)),
        '11-04 11-18 12-02');
  });

  test('dates cross daylight-saving changes as calendar days', () {
    // Egypt moves its clocks on the last Thursday of October (2026-10-29).
    final dates = planOccurrences(
      scheduleType: PlanScheduleType.daily,
      startsOn: DateTime(2026, 10, 27),
      endsOn: DateTime(2026, 11, 1),
    );
    expect(days(dates), '10-27 10-28 10-29 10-30 10-31 11-01');
    expect(dates.every((date) => date.hour == 0 && date.minute == 0), isTrue);
  });

  group('validate', () {
    final today = DateTime(2026, 10, 15);
    OperationPlanDraft draft({
      DateTime? endsOn,
      int repeatEvery = 1,
    }) =>
        OperationPlanDraft(
          farmId: 'farm',
          type: OperationPlanType.irrigation,
          title: 'Irrigate',
          scheduleType: PlanScheduleType.weekly,
          startsOn: today,
          endsOn: endsOn,
          daysOfWeek: const <int>[3],
          repeatEvery: repeatEvery,
        );

    test('a season-long schedule is allowed (no one-month cap)', () {
      expect(draft(endsOn: DateTime(2027, 1, 31)).validate(today: today),
          isNull);
    });

    test('more than a year is a typo', () {
      expect(draft(endsOn: DateTime(2027, 10, 16)).validate(today: today),
          ScheduleDraftError.endTooLate);
      expect(draft(endsOn: DateTime(2027, 10, 15)).validate(today: today),
          isNull);
    });

    test('repeat every is 1 to 12', () {
      expect(
        draft(endsOn: DateTime(2026, 12, 1), repeatEvery: 13)
            .validate(today: today),
        ScheduleDraftError.repeatOutOfRange,
      );
    });

    test('the end date is still required', () {
      expect(draft().validate(today: today), ScheduleDraftError.endRequired);
    });

    test('repeat every is sent to the database (1 for once)', () {
      expect(
        draft(endsOn: DateTime(2026, 12, 1), repeatEvery: 2)
            .toRpcParameters()['p_repeat_every'],
        2,
      );
      expect(
        OperationPlanDraft(
          farmId: 'farm',
          type: OperationPlanType.irrigation,
          title: 'Once',
          scheduleType: PlanScheduleType.once,
          startsOn: today,
          endsOn: today,
          repeatEvery: 3,
        ).toRpcParameters()['p_repeat_every'],
        1,
      );
    });
  });
}
