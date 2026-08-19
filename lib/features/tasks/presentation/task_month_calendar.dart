import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:al_wahat_farm_flutter/core/l10n/l10n.dart';
import 'package:al_wahat_farm_flutter/core/widgets/wahat_card.dart';
import 'package:flutter/material.dart';

class TaskMonthCalendar extends StatelessWidget {
  const TaskMonthCalendar({
    required this.visibleMonth,
    required this.selectedDate,
    required this.today,
    required this.taskCounts,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    super.key,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final DateTime today;
  final Map<DateTime, int> taskCounts;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final weekdayLabels = List<String>.generate(
      DateTime.daysPerWeek,
      (index) => material.narrowWeekdays[
          (material.firstDayOfWeekIndex + index) % DateTime.daysPerWeek],
      growable: false,
    );
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final firstDaySundayIndex = firstDay.weekday % DateTime.daysPerWeek;
    final leadingDays =
        (firstDaySundayIndex - material.firstDayOfWeekIndex + 7) % 7;
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: WahatCard(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 500;
              final controls = Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    key: const Key('tasks-calendar-previous-month'),
                    tooltip: context.l10n.tasksCalendarPreviousMonth,
                    onPressed: onPreviousMonth,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  TextButton(
                    key: const Key('tasks-calendar-today'),
                    onPressed: onToday,
                    child: Text(context.l10n.tasksCalendarToday),
                  ),
                  IconButton(
                    key: const Key('tasks-calendar-next-month'),
                    tooltip: context.l10n.tasksCalendarNextMonth,
                    onPressed: onNextMonth,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              );
              final monthTitle = Text(
                material.formatMonthYear(visibleMonth),
                key: const Key('tasks-calendar-month-title'),
                style: Theme.of(context).textTheme.titleLarge,
              );
              final cellWidth = constraints.maxWidth / DateTime.daysPerWeek;
              final cellHeight = constraints.maxWidth >= 600 ? 64.0 : 48.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              monthTitle,
                              const SizedBox(height: 4),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: controls,
                              ),
                            ],
                          )
                        : Row(
                            children: <Widget>[
                              Expanded(child: monthTitle),
                              controls,
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: weekdayLabels
                        .map(
                          (label) => Expanded(
                            child: Center(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 4),
                  GridView.builder(
                    key: const Key('tasks-calendar-grid'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cellCount,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: DateTime.daysPerWeek,
                      mainAxisSpacing: 4,
                      childAspectRatio: cellWidth / cellHeight,
                    ),
                    itemBuilder: (context, index) {
                      final dayNumber = index - leadingDays + 1;
                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox.shrink();
                      }
                      final date = DateTime(
                        visibleMonth.year,
                        visibleMonth.month,
                        dayNumber,
                      );
                      return _CalendarDay(
                        date: date,
                        count: taskCounts[date] ?? 0,
                        isToday: _sameDay(date, today),
                        isSelected: _sameDay(date, selectedDate),
                        onTap: () => onDateSelected(date),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.count,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final int count;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final dateLabel = material.formatFullDate(date);
    final semanticsParts = <String>[
      if (isToday) context.l10n.tasksCalendarToday,
      dateLabel,
      if (count > 0) context.l10n.tasksCalendarTaskCount(count),
    ];
    final background = isSelected
        ? AppColors.green
        : isToday
            ? AppColors.softGreen
            : Colors.transparent;
    final foreground = isSelected ? Colors.white : AppColors.ink;
    final borderColor = isToday
        ? AppColors.orange
        : isSelected
            ? AppColors.green
            : Colors.transparent;

    return Semantics(
      key: Key('tasks-calendar-day-${_dateKey(date)}'),
      button: true,
      selected: isSelected,
      label: semanticsParts.join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Text(
                '${date.day}',
                style: TextStyle(
                  color: foreground,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
              if (count > 0)
                PositionedDirectional(
                  top: 3,
                  end: 3,
                  child: DecoratedBox(
                    key: Key('tasks-calendar-count-${_dateKey(date)}'),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: 17,
                      child: Center(
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? AppColors.green : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _dateKey(DateTime date) => '${date.year}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
