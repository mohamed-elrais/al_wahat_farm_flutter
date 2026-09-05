# Planting Pits Implementation Plan

## Goal

Add independently managed planting pits for currently empty farm sections. A
pit is not a tree, does not link to a tree, and must never affect tree counts,
tree health, QR codes, issues, agricultural schedules, or product dosing.

## Decisions

- Store pits in a separate `public.planting_pits` table.
- Do not add a foreign key between pits and `public.trees`.
- Use section-level tasks in the first release; do not extend task targets yet.
- Treat `completed` as the terminal successful pit state. It records that the
  pit workflow finished, but does not identify a resulting tree.
- Keep pit coordinates in live Supabase data instead of the bundled map JSON.
- Owners and agricultural engineers manage pits; all active farm members can
  view them.
- Prefer cancellation to deletion so field history is retained.

## Lifecycle

`planned -> marked -> dug -> prepared -> completed`

Any non-terminal state may move to `cancelled`. Direct database writes will be
protected by row validation; the app will expose only forward transitions and
cancellation.

## Phase 1 — Backend foundation

- [x] Generate an imperative migration with the Supabase CLI.
- [x] Add a `planting_pit_status` enum.
- [x] Add `public.planting_pits` with:
  - UUID identity and farm/section/optional irrigation-zone foreign keys.
  - Stable `pit_code`, optional row and pit numbers, coordinates, planned date,
    notes, lifecycle timestamps, creator, and audit timestamps.
  - Coordinate, code, positive-number, hierarchy, and timestamp constraints.
- [x] Add indexes for farm, section, zone, status, and creator lookups.
- [x] Reuse the shared `set_updated_at` trigger.
- [x] Validate that the section belongs to the farm and the optional zone
  belongs to the section.
- [x] Enable RLS and add explicit Data API grants.
- [x] Add policies matching existing farm permissions:
  - Active farm members can select.
  - Owners and agricultural engineers can insert and update.
  - Owners may delete only as an administrative escape hatch; the UI cancels.
- [x] Add pgTAP coverage for schema constraints, hierarchy validation, grants,
  RLS allow/deny behavior, and lifecycle timestamps.
- [x] Run a clean local database reset and the database test suite.

## Phase 2 — Flutter data layer

- [x] Add `PlantingPit` and `PlantingPitStatus` domain types.
- [x] Add Supabase-backed planting-pit reads and mutations.
- [x] Integrate loading and refresh with the existing farm hierarchy
  controller, and keep section/layer selection in the map state.
- [x] Include pits in the farm hierarchy snapshot and persistent offline cache,
  while keeping them separate from `hierarchy.trees`.
- [x] Add unit tests for JSON parsing, status handling, hierarchy validation,
  cache round trips, and repository query behavior.

## Phase 3 — Map presentation

- [x] Project live pit coordinates onto the existing map canvas.
- [x] Add a Planting Pits layer toggle.
- [x] Draw visually distinct pit markers by lifecycle status.
- [ ] Add per-marker accessibility semantics and keyboard selection.
- [x] Add pit hit testing and a responsive details sheet.
- [x] Show selected-section pit totals.
- [ ] Add selected-section counts grouped by lifecycle status.
- [x] Keep the existing unplanted-section and tree behavior intact.
- [x] Add widget tests for the layer toggle, empty sections, marker selection,
  details, role-based controls, and narrow phone layouts.
- [ ] Add planting-pit-specific wide-layout and RTL widget tests.

## Phase 4 — Management workflows

- [x] Add manager-only manual pit creation.
- [ ] Add pit editing.
- [x] Add validated lifecycle actions: mark, dig, prepare, complete, cancel.
- [ ] Add bulk CSV import with a preview and row-level validation errors.
- [ ] Add bulk status updates for selected pits.
- [x] Keep worker access read-only in the first release.
- [x] Add English and Arabic localization.
- [ ] Complete planting-pit-specific RTL verification.

## Phase 5 — Verification and rollout

- [x] Keep pits out of tree collections, active-tree counts, schedules, and
  dosing code paths; cover tree-row isolation in the pgTAP suite.
- [x] Run Flutter formatting, static analysis, unit tests, and widget tests.
- [x] Run Supabase database tests and database advisors.
- [x] Deploy the verified planting-pits migration to the linked Supabase
  project and confirm the remote schema.
- [ ] Pilot one empty section before importing all empty-section layouts.
- [ ] Validate the approved field layout, row direction, spacing, boundaries,
  and irrigation-zone assignments before bulk import.

## Deferred choices

- Individual pit task targets (`task_targets.planting_pit_id`).
- Worker pit-status mutation through assigned tasks.
- Pit QR codes.
- Offline pit creation and mutation queues.
- Automatic grid generation from section polygons.
- PostGIS geometry and spatial constraints.
- Any future relationship between a completed pit and a tree.

## Acceptance criteria for the first usable increment

1. The database securely stores independent pits for an empty section.
2. The Flutter app loads and caches pits without treating them as trees.
3. Pits appear on the farm map and can be filtered and inspected.
4. Managers can create and advance a pit through its lifecycle.
5. Workers can view pits but cannot modify them.
6. Existing tree, task, schedule, inventory, issue, and dosing tests continue to
   pass unchanged.

## Current verification status — 2026-08-28

- `flutter analyze` passes with no issues.
- The focused planting-pit, hierarchy, cache, map, and role-based widget tests
  pass (26 tests).
- The broader Flutter run reached 277 passing tests and 6 intentional live-test
  skips. One unrelated existing task-list golden differs from its baseline;
  the planting-pit tests and map goldens passed.
- Both repository diffs pass `git diff --check`.
- A clean `supabase db reset --local` applies every migration successfully,
  including `20260827124809_add_planting_pits.sql`.
- The planting-pit pgTAP suite passes all 30 tests. The complete backend suite
  passes all 205 tests across 9 files.
- Local database advisors report no security or performance issues. Database lint
  reports only two pre-existing warnings in `private.generate_plan_run_group`;
  there are no planting-pit lint findings.
- A direct local query confirms the table exists, has no `tree_id`, has RLS
  enabled, and has four policies.
- Migration `20260827124809_add_planting_pits.sql` is deployed to the linked
  remote project. Remote migration history is synchronized, and a direct
  remote query confirms the same table shape and four RLS policies.
- Remote advisors report pre-existing project-wide warnings for older
  `SECURITY DEFINER` functions and disabled leaked-password protection; none
  reference planting pits.
