# Schedules — improvement plan

**Goal:** make schedules ready for the farm's first real use: repeat patterns the farm actually follows, schedules that can be edited and run for a whole season, tasks that always reach workers, and a schedule page that shows what happened.

Status: **in progress** (started 2026-10-15). Analysis and owner answers below; phases S1–S5 follow.

---

## 1. Findings (2026-10-15)

- **Never used:** the live database has no schedules. The hourly generator job runs without errors, but writes ~48 empty log rows a day (2,358 so far).
- **No editing:** the detail screen offers only Pause / Archive / Generate now. The database `update_operation_plan` already accepts title, dates, repeat, time, duration, targets, workers, product and grouping.
- **One-month cap** on schedule length (`private.assert_plan_schedule_dates`, form, draft validation).
- **No "every 2nd/3rd week"** (owner request) and no "every N days".
- **Tasks without workers:** a schedule with no default workers creates `draft` tasks no worker can see.
- **Expired schedules stay "Active"**; nothing completes them.
- **No history:** the detail page shows no generated tasks, missed dates or stock-blocked dates; blocked dates are lost after a day with no alert.
- **Display bugs:**
  - the dose shows as `100 / per_feddan`, with no unit or product name;
  - duration is a bare number;
  - validation errors are English-only;
  - the selected weekday chip is dark text on dark green (unreadable, seen on the iPhone);
  - the end date is labelled "(optional)" though it is required;
  - archive has no confirmation;
  - "Generate today's tasks" on one schedule's page runs every schedule.
- **Zone picker:** a 160 px scroll box of bare zone codes.
- **Thin tests:** 5 widget tests, none for the detail screen.

## 2. Owner answers (2026-10-15)

| # | Question | Answer |
|---|---|---|
| A1 | Why unused? | Not started yet. |
| A2 | Keep the one-month cap? | No (it was not the owner's rule). |
| A3 | Schedule with no default workers? | Assign the tasks to **all workers**. |
| A4 | Repeat patterns | Weekly needs on/off weeks: "one Wednesday on, one off" (every 2 weeks), "one on, two off" (every 3 weeks). |

## 3. Decisions taken in this plan (change if wrong)

- **Repeat every N** (`repeat_every`, 1–12):
  - Weekly = every N weeks on the chosen days. Daily = every N days, e.g. irrigation every 3 days.
  - For weekly, the "on" week is the week of the first run on or after the start date, so the first run is never pushed out by the rule.
- **End date stays required, up to one year** after the start (the cap only guards against typos like 2062). The label says "(required)". An end date keeps the stock totals meaningful and stops forgotten schedules running forever; an expired schedule can be copied to continue.
- **"All workers" is decided when each task is created**: every active member with the worker role at that moment, so new workers are included.
- **Expired schedules become "Completed"** automatically by the hourly job.

## 4. Phases

Each phase: tests and analyze green, commit, deploy staging and production. Database changes go to the shared live project **before** the app that uses them (the app keeps working against both).

### S1 — Database
- `operation_plans.repeat_every smallint not null default 1` (1–12; `once` must be 1).
- One shared rule `private.plan_runs_on(...)`, used by generation, `check_operation_plan_inventory` and `get_operation_plan_calendar` (today each repeats the matching logic).
- Date rules: drop the one-month cap and allow up to one year.
- `create_operation_plan` / `update_operation_plan` gain `p_repeat_every`.
- No default workers → all active workers; no workers at all → draft, as today.
- The hourly job completes expired active schedules, and skips farms with no active schedule (no more empty log rows).
- Verified against live data inside a rolled-back transaction (no records kept); `schedule_rules.test.sql` updated.

### S2 — App: repeat, dates, fixes
- Model and `planOccurrences` support `repeatEvery` with the same anchor rule as the database (unit tests mirror the SQL cases).
- Form:
  - "Every [1] [2] [3] [4] weeks/days" picker;
  - one-year end date;
  - "(required)" label;
  - readable selected weekday chips;
  - workers hint "Nobody chosen → all workers".
- The review card states the pattern ("Every 2 weeks · Wed") and lists the run dates.
- Validation errors in Arabic and English.

### S3 — Schedule page
- **Edit** (same form, prefilled) using `update_operation_plan`.
- Product name, dose with unit and basis label, duration in minutes, workers (names or "All workers").
- **History:** past runs with their task status (done, in progress, not started, skipped for stock), linked to the tasks; the next run dates.
- **Archive** asks for confirmation; **Copy** starts a new schedule from this one (for the next season).
- "Generate today's tasks" says it covers all schedules.

### S4 — Alerts and the list
- Schedules list: a pattern line ("Every 2 weeks · Wed · 08:00") and warnings for blocked (low stock) runs.
- Archived schedules can be shown with a filter.

### S5 — Easier targets
- Zones grouped by section, with "all zones in this section".

## 5. Progress

| Phase | State | Notes |
|---|---|---|
| S1 | Done | Al-Wahat-Farm-supabase `a900ef5`, migration `20261015103812`, applied after a rolled-back dry run on live data (every 2/3 weeks on Wed, Mon+Thu every 2 weeks, every 3 days, 3-month accepted / 13-month rejected, no-worker schedule assigned to both workers, expired schedule completed). pgTAP `schedule_rules` updated (not run: no Docker). |
| S2 | Done | `planOccurrences` mirrors `plan_runs_on` (unit tests reuse the live dry-run cases; dates step by calendar day across DST). Form: how-often picker, one-year limit, "Ends on" label, all-workers hint and review line, Arabic/English validation errors. Theme: selected chips get white text app-wide (the unreadable "Wed"). |
| S3 | Done | Edit (same form, prefilled; type fixed; unchanged start date and targets are not resent, so running schedules keep their history), Copy (same length, from today), history of past runs with task status or "Skipped: not enough stock" (tap opens the task), product name, dose in words, duration in minutes, workers or "All workers", archive confirmation, "Create today's tasks for all schedules". |
| S4 | — | |
| S5 | — | |
