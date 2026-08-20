# Tasks Calendar View Implementation

## Goal

Add a localized, accessible month calendar to the Tasks page while preserving
the existing Today/All list, task cards, permissions, review queue, refresh,
loading, error, offline-sync, and navigation behavior.

## Constraints

- Do not change the task data model or backend schema.
- Do not add a calendar dependency; use Flutter widgets and
  `MaterialLocalizations`.
- A task belongs to `scheduledFor`, falling back to local `dueAt` only when no
  scheduled date exists.
- Reuse the existing task tile and task-opening behavior in both views.
- Preserve unrelated worktree changes.

## Implementation checklist

- [x] Centralize effective task-date grouping in `TaskWorkspaceController`.
- [x] Add controller coverage for scheduled-date precedence, local due-date
      fallback, and monthly counts.
- [x] Add a responsive `TaskMonthCalendar` presentation component.
- [x] Add accessible List/Calendar switching near the Today/All filters.
- [x] Initialize Calendar to today and add previous, next, and Today controls.
- [x] Distinguish today and the selected day and show compact task counts.
- [x] Scroll the Tasks list to the selected-day results when a date is tapped.
- [x] Render the selected day's tasks with the existing task-card design and
      pending-sync restrictions.
- [x] Preserve create/review permissions, refresh, loading, and error states in
      both modes.
- [x] Add English and Arabic strings and regenerate localization output.
- [x] Add widget tests for switching, initialization, month navigation,
      indicators, date selection, navigation, empty state, RTL, permissions,
      and pending-sync behavior.
- [x] Run formatting, static analysis, controller tests, and Tasks widget tests.

## Planned files

- `lib/features/tasks/presentation/tasks_screen.dart`
- `lib/features/tasks/presentation/task_month_calendar.dart` (new)
- `lib/features/tasks/presentation/task_workspace_controller.dart`
- `lib/l10n/arb/app_en.arb`
- `lib/l10n/arb/app_ar.arb`
- `lib/l10n/gen/app_localizations*.dart` (generated)
- `test/unit/tasks/task_controllers_test.dart`
- `test/widget/tasks_screen_test.dart`

## Acceptance criteria

- List remains the default view and Today/All behavior is unchanged.
- Calendar opens on the month containing today with today selected.
- Month controls and date selection work in English and Arabic/RTL.
- Selecting a date smoothly scrolls its task section into view.
- Calendar counts and selected-day tasks use the controller's effective-date
  rules.
- Task cards behave identically in List and Calendar modes.
- Manager/worker permissions, review access, pull-to-refresh, error/loading
  states, and pending-sync restrictions remain intact.
- Relevant tests and static analysis pass without a new dependency or schema
  change.

## Verification commands

```sh
flutter gen-l10n
dart format lib/features/tasks test/unit/tasks/task_controllers_test.dart \
  test/widget/tasks_screen_test.dart
dart analyze
flutter test test/unit/tasks/task_controllers_test.dart \
  test/widget/tasks_screen_test.dart
```

## Verification result

- `dart analyze`: no issues found.
- Controller, Tasks, review queue, and task detail suites: 23 tests passed.
- Responsive Arabic/RTL coverage runs at 360×800 without layout exceptions.
