# Inventory, Schedules, and Map-Task Integration — Implementation Plan

Planning document for the next phase. No implementation has started; this plan is
grounded in an audit of both repos (Flutter app + `Al-Wahat-Farm-supabase`) as of
`c1cdcdd` / migration `20260718121247`.

---

## 1. Current-state audit (what exists)

### Backend (Supabase)

**A dormant scheduling engine already exists** (migrations `20260701100756` +
`20260701120856`) — built, tested-in-schema, cron-wired, but unused by the app:

| Piece | State |
|---|---|
| `operation_plans` | type (`irrigation`/`fertilization`/`harmful_weed_control`), status lifecycle (`draft/active/paused/completed/archived`), `starts_on`/`ends_on`, `scheduled_start_time`, `planned_duration_minutes`, recurrence = `once/daily/weekly` + `days_of_week smallint[]` (ISO 1–7), `instructions jsonb` |
| `operation_plan_targets` | multi-target per plan: farm-wide / section / zone / tree rows, `num_nonnulls(...) <= 1` scope check, one-active-per-entity partial unique indexes, soft-deactivate |
| `operation_plan_runs` | **duplicate-safe generation ledger**: `UNIQUE (plan, target, operation_date)` + partial-unique `generated_task_id` |
| `generate_operation_tasks_for_date` | per active plan × active target × matching date: upserts a run, creates a `draft` task (`scheduled_for = date`, instructions merged with plan/target/run ids), logs activity. Granted **service_role only** |
| `private.generate_due_operation_tasks` | hourly pg_cron job, farm-timezone-aware, generates for today+tomorrow, writes `operation_task_generation_logs` |
| RPCs | `create_operation_plan` (manager-gated, `p_targets jsonb`), `update_operation_plan` (clear-flag pattern), `get_operation_plan_calendar` (read-only expansion) |
| `fertilizer_application_method` enum | `fertigation/soil_application/foliar_spray/manual_application` — **defined but unused** |

**Task workflow**: `tasks` has single-target columns (`section_id`/`irrigation_zone_id`/`tree_id`)
with CHECK `tasks_only_one_specific_target_check: num_nonnulls(...) <= 1` (all-null =
farm-wide) plus the `validate_task_scope` trigger (same-farm integrity). Writes go
through SECURITY DEFINER RPCs (`create_farm_task`, `set_task_assignments`,
`start_assigned_task`, `complete_task`, `review_task`, `report_tree_issue`,
`add_task_photo`) — all idempotent via `p_op_id` (`client_operation_id` columns for
creates, `private.applied_operations` ledger for transitions). `task_activity_log` is
the append-only audit trail. Roles gate through `private.is_operational_manager`
(owner + agricultural_engineer) and `private.can_operate_task` (manager or assignee).
There is **no cancel RPC** and the `accountant` role has no policies (dormant).

**Inventory**: nothing exists — no tables, columns, or RPCs (README roadmap only).

**Conventions to follow**: `public` = API surface, `private` = helpers/ledgers;
SECURITY DEFINER + `set search_path = ''`; errcodes `42501/23514/23505/P0002`;
RLS SELECT-only on workflow tables (writes via RPC); pgTAP tests with
`test.set_auth(uuid)`; storage bucket `farm-evidence` with enforced path
`{auth_uid}/{farm_id}/{task_id}/{file}`.

### Flutter app

- Roles: `FarmRole.canManageTasks` (owner+engineer) gates create/review/assign UI.
- Task detail: target is **display-only text** (`taskTargetLabel`); actions
  start/complete/evidence/assignments; offline-first via outbox + `SyncEngine` +
  `PendingMutationKind` executors; unsynced creates use `local:<opId>` ids.
- `TaskDraft.validate()` rejects >1 target; `toRpcParameters` sends the three
  single-target params.
- Map: `FarmMapPainter` already supports `selectedTreeId`, `highlightZoneUuids`,
  `highlightSubmains`, `highlightLine`; zone-valve sheet exists; tree sheet has
  `onAttachTask` → `/tasks/create?treeId=` (the only map→task entry). No task→map path.
- Hierarchy: `FarmSection.areaM2` exists; `IrrigationZone` has **no area**; trees have
  zone membership → per-zone tree counts derivable. Live loading is table selects with
  persistent cache.
- State pattern: ChangeNotifier + InheritedWidget scopes (`AppServicesScope`,
  `OperationalContextScope`, `FarmHierarchyScope`, `TaskWorkspaceScope`, `SyncScope`).
- Localization: ARB en/ar + `domain_labels.dart` enum-label extensions. 5 fixed nav
  tabs (home/map/scan/tasks/more).
- No quantity/unit/recurrence primitives anywhere.

## 2. Reuse vs. build

| Requirement | Verdict |
|---|---|
| Recurring schedules (fert/chem/irrigation) | **Extend `operation_plans`** — recurrence, targets, dedup, cron, calendar all exist. Add: product linkage, rate/basis, assignees, new chemical types, generator upgrades. Flutter UI is greenfield |
| Inventory | **Greenfield backend + Flutter**, following existing conventions (RPC-only writes, activity-ledger pattern like `task_activity_log`, `p_op_id` idempotency, `farm-evidence` storage pattern for images) |
| Multi-target tasks | **Mirror `operation_plan_targets`** as `task_targets` (same scope-check/partial-unique idiom); keep legacy columns for compat |
| Create task from map | Extend existing `?treeId=` pattern + existing zone sheet |
| Task → map | New `/map?focus=` param + existing painter highlight primitives |
| Same-category DB rule | New trigger on `task_targets` (existing CHECKs can't compare across rows) |

## 3. Decisions (CONFIRMED by owner, 2026-07-19)

1. **Area basis = tree count**: zone targets use the trees fed by the target's ZCV;
   **60 trees = 1 feddan** is the farm's conversion rule, so
   `feddans(target) = active_tree_count(target) / farms.trees_per_feddan` (new farm
   column, default 60, owner-configurable). Applied uniformly to per-feddan rates.
2. **Insufficient stock at generation → BLOCK**: the task is *not* created; the run
   row stays task-less so the hourly cron auto-generates it once stock is added.
   The UI must show **how many applications the current stock covers**
   (`floor(available / required_per_occurrence)`) at plan save time and on the
   schedules screen whenever generation is being blocked.
3. **Insufficient stock at completion → deduct available + record shortfall**
   (completion is never blocked in the field).
4. **Workers see inventory read-only** (items/categories); transactions + all
   mutations manager-only.
5. **Placement**: Inventory + Schedules under **More**. Inventory editing =
   owner/engineer only; Schedules visible to owner/engineer only (workers see only
   the generated tasks — matches existing plan RLS).
6. **Enum names**: `pest_control` (insecticides), `disease_control` (fungicides);
   herbicides remain `harmful_weed_control`. Confirmed.
7. **Units**: fixed enum `inventory_unit` = `gram, kilogram, liter, milliliter,
   piece, meter`; category-specific specs live in `attributes jsonb`.
8. **Rate bases**: `per_feddan | per_tree | absolute` — feddan (فدان) confirmed as
   the dosing unit; the area derives from tree count per decision 1, so surveyed
   `area_m2` is not used for dosing.
9. **Plan-generated tasks stay one-task-per-target**; multi-target applies to
   manually created tasks. Confirmed.
10. **Reversal semantics** (unobjected recommendation): `review_task(
    returned_for_correction)` auto-restores consumed stock; explicit
    `reverse_task_inventory` RPC for manual corrections.

### 3.1 Follow-up decisions (CONFIRMED by owner, 2026-07-19)

- **Feddan (فدان)** is the dosing unit — used in schema names (`per_feddan`,
  `trees_per_feddan`), UI labels, and ARB translations (en shows "feddan" too).
- **Unplanted sections compute zero product** on per-feddan schedules — confirmed
  correct (nothing to spray).
- **Blocked-generation catch-up stays within the today/tomorrow window** — older
  missed dates are intentionally NOT back-generated after a stock-out.

## 4. Database changes

### 4.1 New enums (own migration — enum values must commit before use)

```sql
alter type public.task_type add value 'pest_control';
alter type public.task_type add value 'disease_control';
alter type public.operation_plan_type add value 'pest_control';
alter type public.operation_plan_type add value 'disease_control';
create type public.inventory_unit as enum
  ('gram','kilogram','liter','milliliter','piece','meter');
create type public.inventory_transaction_type as enum
  ('addition','consumption','adjustment','reversal');
create type public.application_rate_basis as enum
  ('per_feddan','per_tree','absolute');  -- feddan (فدان) confirmed as the farm's unit
-- and the farm-level conversion rule (decision 1):
alter table public.farms
  add column trees_per_feddan numeric(6,2) not null default 60 check (trees_per_feddan > 0);
```

### 4.2 Inventory tables

```sql
create table public.inventory_categories (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms(id) on delete cascade,
  code text not null,                -- 'pipe','pipe_joint','fertilizer','dripper',
                                     -- 'insecticide','herbicide','fungicide','tool','other'
  name text not null,
  applies_to_operation public.operation_plan_type,  -- links category to plan type
  is_consumable boolean not null default true,
  is_active boolean not null default true,
  created_at/updated_at,
  unique (farm_id, code)
);
-- Seeded per farm (default set above); managers may add more (configurable categories).

create table public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms(id) on delete cascade,
  category_id uuid not null references public.inventory_categories(id) on delete restrict,
  name text not null,
  description text,
  unit public.inventory_unit not null,
  quantity numeric(14,3) not null default 0 check (quantity >= 0),
  minimum_stock numeric(14,3) check (minimum_stock >= 0),
  attributes jsonb not null default '{}'::jsonb,   -- pipe diameter_mm/length_m, joint angle_deg/
                                                   -- compatible_diameters_mm[], dripper flow_lph …
  image_bucket_id text, image_path text,
  is_active boolean not null default true,
  created_by_profile_id uuid not null references public.profiles(id) on delete restrict,
  client_operation_id uuid,          -- offline/idempotent create
  created_at/updated_at,
  unique (farm_id, name),
  partial unique on client_operation_id
);

create table public.inventory_transactions (   -- append-only ledger
  id uuid primary key default gen_random_uuid(),
  farm_id uuid not null references public.farms(id) on delete cascade,
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  transaction_type public.inventory_transaction_type not null,
  quantity_delta numeric(14,3) not null check (quantity_delta <> 0),
  resulting_quantity numeric(14,3) not null check (resulting_quantity >= 0),
  task_id uuid references public.tasks(id) on delete set null,
  actor_profile_id uuid not null references public.profiles(id) on delete restrict,
  note text,
  metadata jsonb not null default '{}'::jsonb,   -- e.g. {shortfall: 1.5, plan_id: …}
  client_operation_id uuid,
  created_at timestamptz not null default now(),
  -- sign discipline:
  check ((transaction_type in ('addition','reversal') and quantity_delta > 0)
      or (transaction_type = 'consumption' and quantity_delta < 0)
      or (transaction_type = 'adjustment')),
  partial unique on client_operation_id
);
create index on public.inventory_transactions (inventory_item_id, created_at desc);
create index on public.inventory_transactions (task_id) where task_id is not null;
```

**Double-deduction guard**: consumption is only permitted when the *net* consumed for
`(task_id, item_id)` is zero — computed inside `private.consume_inventory_for_task`
under `select … for update` of the item row. This allows the legal sequence
consume → reverse → consume again (task reopened and redone) while making a second
concurrent/replayed consumption a no-op. Grants: SELECT-only to `authenticated`;
all writes via RPCs (transactions table gets no UPDATE/DELETE grants at all — immutable).

### 4.3 Inventory RPCs

| Function | Access | Behavior |
|---|---|---|
| `create_inventory_item(p_farm_id, p_category_id, p_name, p_unit, …, p_op_id)` | manager | insert + optional initial `addition` transaction |
| `update_inventory_item(…, clear-flags)` | manager | metadata edits only — **never** edits `quantity` directly |
| `record_inventory_transaction(p_item_id, p_type addition/adjustment, p_quantity, p_note, p_op_id)` | manager | locks item row, applies delta, writes ledger row + `resulting_quantity` |
| `create_inventory_category(…)` / `update_inventory_category(…)` | manager | configurable categories |
| `private.consume_inventory_for_task(p_task_id)` | internal | called by `complete_task`; reads consumption spec from task `instructions` (`inventory_item_id`, `required_quantity`); net-zero guard; clamps to available, records shortfall |
| `reverse_task_inventory(p_task_id, p_note, p_op_id)` | manager | compensating `reversal` rows for the task's net consumption; also called by `review_task` on `returned_for_correction` |

`complete_task` and `review_task` are re-created (same signatures) to call these —
existing clients unaffected. Storage: item images go to `farm-evidence` under a new
validated path family `{auth_uid}/{farm_id}/inventory/{item_id}/{file}`
(extend `private.can_view_task_photo_path`-style helper + object policies).

### 4.4 Operation-plan extensions

```sql
alter table public.operation_plans
  add column inventory_item_id uuid references public.inventory_items(id) on delete restrict,
  add column application_method public.fertilizer_application_method,  -- existing enum, finally used
  add column application_rate numeric(12,4) check (application_rate > 0),
  add column rate_basis public.application_rate_basis,
  add column rate_unit public.inventory_unit,
  add column default_assignee_profile_ids uuid[] not null default '{}';

-- coherence: chemical/fertilization plans must carry product+rate; irrigation must not
alter table public.operation_plans add constraint operation_plans_product_coherence_check
  check (
    (operation_type = 'irrigation' and inventory_item_id is null)
    or (operation_type <> 'irrigation'
        and (inventory_item_id is null) = (application_rate is null)) );
```

`create_operation_plan` / `update_operation_plan` gain matching params (+ validation:
item's category `applies_to_operation` must equal plan type; assignees via existing
`private.assert_assignable_profiles`; item unit must equal `rate_unit` family).

New `check_operation_plan_inventory(p_plan_id, p_horizon_days) returns table(run_date,
target, required_qty, available_qty, sufficient)` — powers the UI warning ("clearly
warn when insufficient") before/after saving a plan.

### 4.5 Generator upgrades (`generate_operation_tasks_for_date` re-created)

Per generated task, additionally:
1. **Quantity calculation** — `required = application_rate × basis_factor(target)`,
   with tree count as the universal measure (decision 1):
   - `per_feddan`: `active_tree_count(target) / farms.trees_per_feddan` feddans —
     zone → trees whose `irrigation_zone_id` matches (the ZCV's trees);
     section → trees in the section; tree → 1/trees_per_acre; farm-wide → all
     active trees. Unplanted scopes compute to zero (nothing to treat).
   - `per_tree`: `active_tree_count(target)`.
   - `absolute`: rate as-is per occurrence.
   Stamped into task `instructions`: `inventory_item_id`, `required_quantity`,
   `required_unit`, `application_method`, plus existing plan/target/run ids.
2. **Availability gate (decision 2 — BLOCK)** — computed inside the same row-locked
   transaction: if `item.quantity < required`, the run row is upserted but **no task
   is created** (`generated_task_id` stays null) and a shortage entry is written to
   the generation log metadata (`required`, `available`, plan/target). Because the
   existing upsert guard fills task-less runs on later passes, the hourly cron
   **auto-recovers as soon as stock is added** — no manual retrigger needed.
   `check_operation_plan_inventory` returns per-occurrence `required`, `available`,
   and `applications_covered = floor(available / required)` so the UI can say
   "current stock covers N applications" at save time and on blocked schedules.
3. **Assignment** — if `default_assignee_profile_ids <> '{}'`: insert
   `task_assignments`, status `assigned` (not `draft`), log `assigned` (reuses the
   exact insert pattern from `create_farm_task`).
4. Grant a thin manager wrapper `generate_farm_tasks_now(p_farm_id, p_date)` to
   `authenticated` (cron remains the primary driver).

Dedup is untouched — the `(plan, target, date)` run key plus `generated_task_id`
guard already make generation idempotent under cron + manual invocation racing, and
now double as the blocked-run retry mechanism.

### 4.6 Multi-target tasks

```sql
create table public.task_targets (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  section_id uuid references public.farm_sections(id) on delete restrict,
  irrigation_zone_id uuid references public.irrigation_zones(id) on delete restrict,
  tree_id uuid references public.trees(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint task_targets_one_scope_check
    check (num_nonnulls(section_id, irrigation_zone_id, tree_id) = 1)
);
-- no duplicate target within a task:
create unique index on public.task_targets (task_id, section_id) where section_id is not null;
create unique index on public.task_targets (task_id, irrigation_zone_id) where irrigation_zone_id is not null;
create unique index on public.task_targets (task_id, tree_id) where tree_id is not null;
```

**Same-category rule in the DB** (requirement): trigger `validate_task_target_category`
on insert — derive the new row's kind (`section|zone|tree`), compare with any existing
row's kind for the task, raise `23514` on mismatch; also same-farm validation (reuse
`validate_task_scope` logic). CHECKs can't span rows; a trigger is the correct tool.

**Compatibility contract**: `tasks.section_id/irrigation_zone_id/tree_id` remain as the
**primary target** (first target), kept for old clients, existing indexes, labels, and
the reconciler. `create_farm_task` gains `p_targets jsonb default null` (same shape as
plan targets); when null, legacy single-target params are wrapped into one
`task_targets` row. Backfill migration inserts one `task_targets` row per existing
targeted task. RLS: `task_targets` SELECT via `private.can_view_task(task_id)`.

## 5. Safe recurring generation (how duplicates are prevented)

Already solved by the existing engine; the plan keeps it intact:
- one `operation_plan_runs` row per (plan, target, date) — `UNIQUE` key upserted with
  `on conflict … do update … where generated_task_id is null`;
- task creation happens only when the upsert returns a row with no task; the task id is
  then stamped onto the run (partial-unique);
- hourly cron + manual generation can race safely (row lock on the run upsert);
- plans paused/completed stop matching the generator's status/date filters;
- edits to a plan never touch already-generated tasks (runs are the boundary).

## 6. Auditable, transaction-safe inventory deduction

- All quantity changes are **ledger rows** (`inventory_transactions`) written in the
  same DB transaction as the `inventory_items.quantity` update, under
  `select … for update` on the item row.
- `complete_task` → `private.consume_inventory_for_task`: net-zero-consumption guard
  (idempotent under `p_op_id` replays *and* app retries), clamp-to-available with
  shortfall recorded (decision 3), activity-log metadata mirror.
- Reopen/correction: `review_task(returned_for_correction)` (and the manual
  `reverse_task_inventory` RPC) writes compensating `reversal` rows — never edits or
  deletes history. A re-completed task can consume again because net = 0.
- `resulting_quantity` snapshot on every row makes the ledger independently auditable.
- Offline: completion replays already carry `p_op_id`; deduction inherits that
  idempotency server-side. No inventory logic runs client-side.

## 7. Flutter design

New feature module `lib/features/inventory/` + `lib/features/schedules/` following the
existing layering (domain / data / presentation, repository + ChangeNotifier +
InheritedWidget scope, offline-aware caching via `LocalCacheStore`).

**Screens**
- `/more/inventory` — item list: search, category filter chips, low-stock badges
  (`quantity <= minimum_stock`), FAB (manager). Cached for offline read.
- `/more/inventory/item/:id` — detail: quantities, attributes, image, transaction
  history list; actions (manager): add stock, adjust, edit, deactivate.
- Item form — name/category/unit/min-stock/attributes (per-category dynamic fields from
  `attributes` templates)/image (reuse `DeviceTaskEvidencePicker` compression pipeline).
- `/more/schedules` — plan list grouped by type with status chips + inventory-shortage
  warnings (`check_operation_plan_inventory`).
- Schedule form (create/edit) — type, title, recurrence (once/daily/weekly + weekday
  picker), time + duration, date range, targets multi-select (sections/zones/trees
  bottom sheet, same-kind not required for *plans* — existing model allows mixing),
  product picker (items filtered by `applies_to_operation`), rate + basis with **live
  computed total per occurrence** and availability warning, assignees (reuse
  `FilterChip` member picker), instructions.
- `/more/schedules/:id` — plan detail + next-30-days calendar
  (`get_operation_plan_calendar`) + generated-task links + pause/resume/archive.
- Task detail additions — product/required-quantity card (from instructions), shortage
  banner; target row becomes tappable chips (feature 5); multi-target chip list.
- Task create — target section becomes a same-kind multi-select (chips with count +
  per-chip remove, mixing blocked in `TaskDraft.validate` mirroring the DB rule).
- Map — zone-valve sheet + section selection + tree sheet all gain a manager-gated
  "Create task" that routes `/tasks/create?treeId=|zoneId=|sectionId=`; task→map via
  `/map?focus=tree:<id>|zone:<uuid>|section:<id>` (map selects, fits, highlights via
  existing painter params, and opens the matching sheet).

**State**: `InventoryScope` + `ScheduleScope` provided under `AuthenticatedGate`
(mirroring `TaskWorkspaceProvider`). Both online-first with cache fallback; inventory
*mutations* and plan editing are online-only in this phase (managers; simpler
correctness) — task completion consumption stays offline-safe because it is server-side.

**i18n/a11y**: every new enum gets a `domain_labels.dart` extension + en/ar ARB keys;
Western digits per existing choice; golden + a11y passes per Phase-8 conventions.

## 8. Role permissions

| Capability | Owner | Engineer | Worker | Accountant |
|---|---|---|---|---|
| View inventory items/categories | ✅ | ✅ | ✅ (read-only) | ⛔ (this phase) |
| Create/edit items, categories, stock transactions | ✅ | ✅ | ⛔ | ⛔ |
| View transaction history | ✅ | ✅ | ⛔ | ⛔ |
| Create/edit/pause schedules | ✅ | ✅ | ⛔ (plans stay RLS-hidden) | ⛔ |
| Generated tasks: view/start/complete | per existing task rules (manager or assignee) | | | ⛔ |
| Reverse/adjust consumption | ✅ | ✅ | ⛔ | ⛔ |
| Multi-target task create / create-from-map | ✅ | ✅ | ⛔ (`canManageTasks`) | ⛔ |

Backend: reuse `private.is_operational_manager` / `is_operational_farm_member`.
Flutter: add `canManageInventory` / `canManageSchedules` getters (aliases of
`canManageTasks` today, kept separate for future divergence).

## 9. Milestones

**M0 — Enum + foundation migration** (backend, ½ day)
Scope: new enums (§4.1), `canManageInventory/Schedules` getters, plan doc committed.
Validation: enum-add migration separate from first use. Tests: pgTAP `has_type`.
Acceptance: migration applies + `db reset` green. Risk: enum adds are irreversible —
names confirmed first (decision 6).

**M1 — Inventory backend** (backend)
Scope: §4.2 tables + §4.3 RPCs + RLS + seeds of default categories per farm.
Validation: negative-stock impossible; idempotent replays (`p_op_id`); immutable ledger.
Tests: pgTAP — role matrix, ledger math (`resulting_quantity`), concurrency (dblink,
same pattern as `op_id_concurrency.test.sql`), double-consumption no-op.
Acceptance: 71-style suite green; advisors clean. Dependencies: M0.

**M2 — Inventory Flutter module**
Scope: repository + cache + scope; list/detail/form/transactions screens; image upload;
low-stock badges; ARB en/ar. Validation: offline read from cache, mutations disabled
offline with clear message; unit formatting. Tests: repository unit tests (fake),
widget tests (list/filter/low-stock/form validation), golden of list + item detail.
Acceptance: manager CRUD round-trip on device; worker sees read-only. Deps: M1.

**M3 — Schedules backend extensions**
Scope: §4.4 plan columns + RPC params, §4.5 generator upgrades (quantity calc,
shortage stamp, auto-assign), `check_operation_plan_inventory`, consumption on
`complete_task`, reversal on `review_task` + `reverse_task_inventory`.
Validation & edge cases: unit mismatch; tree-count feddan math (zone via ZCV trees,
trees_per_feddan configurable); plan edits not touching generated tasks; net-zero
re-consumption; clamp+shortfall at completion; **blocked generation + automatic
catch-up after restock**; cron + manual generation race. Tests: pgTAP — generation
math per basis, assignment insertion, shortage blocking then restock-recovery,
applications_covered math, consumption idempotency under dblink concurrency,
reversal→re-complete cycle. Acceptance: "100 g of calcium per feddan every Friday
8:00, Aug 1–Oct 31" over a 30-tree zone generates a task requiring 50 g
(30/60 feddan), blocks when stock is short with "covers N applications" surfaced,
and auto-generates after restock; "daily 16:00, 30 min irrigation" generates
deduplicated assigned tasks. Deps: M1 (items), M0.
Risk: `complete_task`/`review_task` re-creation — keep signatures identical; pgTAP
regression suite from `op_id_idempotency.test.sql` must stay green.

**M4 — Schedules Flutter UI**
Scope: plan list/form/detail/calendar; shortage warnings; task-detail product card.
Validation: recurrence form rules (weekly⇒weekdays), computed-quantity preview parity
with backend (display-only), timezone-correct date handling (farm TZ).
Tests: controller unit tests, widget tests for form validation + warning banner,
golden of schedule form + list (en/ar). Acceptance: manager creates the two example
schedules end-to-end on device; tasks appear for workers with product info. Deps: M2, M3.

**M5 — Multi-target tasks backend**
Scope: §4.6 table + trigger + backfill + `create_farm_task p_targets` + RLS.
Validation: same-category trigger (23514), same-farm, dup-target unique, legacy params
still work, primary-target columns populated. Tests: pgTAP matrix incl. replay with
`p_op_id` + mixed-category rejection; backfill count assertion.
Acceptance: old app version (current prod build) still creates tasks. Deps: M0.

**M6 — Multi-target Flutter**
Scope: `TaskDraft.targets` (+ same-kind validation + json), create-screen multi-select
UI (kind lock, count, per-chip remove), detail multi-target display, offline outbox
payload extension (replayed `create_task` sends `p_targets`), `FarmTask`/detail model
additive fields. Validation: offline create→replay with multiple targets; legacy
cached tasks render. Tests: unit (draft validation/json round-trip), widget
(multi-select interactions), offline replay test in `offline_create_test.dart` style.
Acceptance: single-target flows byte-identical for old data. Deps: M5.

**M7 — Map ↔ tasks integration**
Scope: map create-task entries (tree sheet exists; add zone sheet + selected-section
affordance) with query params `sectionId/zoneId`; `/map?focus=` deep link — parse,
select, fit (`_fit` exists for sections; add fit-to-point for trees/valves), highlight
(existing painter params), open sheet; task detail targets become tappable.
Validation: focus ids that no longer exist (graceful no-op + snackbar); RTL unaffected
(map stays LTR-locked). Tests: widget tests per focus kind (reuse
`map_zone_highlight_test` harness), router param tests, golden of focused states.
Acceptance: tap target on any task → map opens zoomed + highlighted + sheet open, for
tree/section/zone/ZCV. Deps: M6 (multi-target chips), independent of M1–M4.

**M8 — Certification & docs**
Scope: full en/ar sweep of new strings, a11y (tap targets, semantics, 200%-scale within
clamp), goldens, `FIDELITY_CHECKLIST`/`IMPLEMENTATION_PLAN` updates, live smoke test
via `config.json` gate. Acceptance: `dart format` / `flutter analyze` / full test
suite green on Flutter 3.13.9; pgTAP + `db lint` + advisors green.

## 10. Migration & backward compatibility

- **Additive-only** schema: new tables/columns/enum values; no renames/drops; existing
  RPC signatures preserved (only extended with defaulted params or re-created bodies).
- Existing tasks: untouched; backfill copies their single target into `task_targets`;
  legacy columns stay authoritative as "primary target" so the current app build,
  cached JSON, offline outbox entries, and the map reconciler all keep working.
- Offline outbox: old queued `create_task` payloads (no `targets`) replay through the
  legacy params path. New payloads add `targets` — old backend would reject them, so
  **M5 (backend) deploys before M6 (app)**, same discipline as the op-id rollout.
- Plans already generated: new generator honors old runs (dedup unchanged); plans
  without product columns behave exactly as today.
- Rollback posture: each milestone is an independent migration + pgTAP suite; Flutter
  features are screen-scoped and can ship dark (routes unreferenced) if needed.

## 11. Recommended order & progress checklist

Order: **M0 → M1 → M3 (backend track)** in parallel with **M2 (Flutter inventory)**,
then **M4**, then **M5 → M6 → M7 → M8**. Backend milestones always land (deployed +
pgTAP green) before their Flutter counterparts — proven pattern from the offline phase.

```
[x] M0  enums + role getters                       (backend + tiny Flutter)
[ ] M1  inventory tables/RPCs/RLS/pgTAP            (backend)
[ ] M2  inventory Flutter module                   (app)
[ ] M3  plan product/rate/assignees + generator +  (backend)
        consumption/reversal + pgTAP
[ ] M4  schedules Flutter UI + task product card   (app)
[ ] M5  task_targets + trigger + backfill + RPC    (backend)
[ ] M6  multi-target task UI + offline payload     (app)
[ ] M7  map → task create + task → map focus       (app)
[ ] M8  i18n/a11y/golden certification + docs      (both)
```

All §3 and §3.1 decisions are confirmed. The plan is fully unblocked; start at M0.
