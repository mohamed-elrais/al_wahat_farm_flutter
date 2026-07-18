# Supabase Change Spec — Op-ID Idempotency for Offline Sync

This is the backend work the Flutter offline outbox depends on (OFFLINE_PLAN.md §3).
It lives in the **separate Supabase repo**; the Flutter repo only consumes these RPCs.

## Why

The app queues mutations while offline and replays them on reconnect. A replay can
happen after a **lost response** (the RPC committed, but the client never saw the
result), so every queued write must be **safe to run more than once**. Today the
creating RPCs (`create_farm_task`, `report_tree_issue`, `review_task`) insert a new row
on every call — a replay would create duplicates. We fix this by having each mutating
RPC accept a **client-generated operation id** (`p_op_id uuid`) and apply each op id **at
most once**, returning the *same* result on replay.

## Hard invariants (do not violate)

1. **Backward compatible.** `p_op_id` is added as the **last parameter with
   `DEFAULT NULL`**. When it is null, behaviour is exactly as today (no dedup). Online
   callers that don't pass it keep working.
2. **Return shapes are unchanged.** Same types/columns as today:
   - `create_farm_task` → `uuid` (task id)
   - `report_tree_issue` → record/table `(tree_issue_id uuid, task_id uuid)`
   - `review_task` → `uuid` (engineer review id)
   - `start_assigned_task` / `complete_task` / `set_task_assignments` → unchanged (void).
3. **Replay returns the original result and causes no additional side effects** (no extra
   task/issue/review row, no second status transition, no duplicate activity-log entry,
   no duplicate assignment/photo).
4. **Concurrency-safe.** Two in-flight calls with the same `p_op_id` must not both apply.
   Rely on a UNIQUE constraint + `unique_violation` handling, not a read-then-write gap.
5. Preserve every existing check: `security definer`, `set search_path = ''` (so keep all
   refs schema-qualified — `public.` / `private.` / `auth.`), auth/role/RLS guards, error
   codes (`42501`, `23514`, `P0002`, …), and grants.
6. **Never edit a deployed migration.** Add new, timestamped migration file(s). Additive
   only (add columns/indexes/params); don't drop or repurpose existing objects.

## P0 — Creating RPCs (required for the offline "create" phases)

Add a nullable `client_operation_id uuid` to each created table + a partial unique index,
and short-circuit the RPC when the op id was already applied.

### Schema
```sql
alter table public.tasks           add column if not exists client_operation_id uuid;
alter table public.tree_issues     add column if not exists client_operation_id uuid;
alter table public.engineer_reviews add column if not exists client_operation_id uuid;

create unique index if not exists tasks_client_operation_id_key
  on public.tasks (client_operation_id) where client_operation_id is not null;
create unique index if not exists tree_issues_client_operation_id_key
  on public.tree_issues (client_operation_id) where client_operation_id is not null;
create unique index if not exists engineer_reviews_client_operation_id_key
  on public.engineer_reviews (client_operation_id) where client_operation_id is not null;
```

### `create_farm_task` — add `p_op_id uuid default null`
Short-circuit BEFORE creating the task (and before assignments/activity):
```sql
if p_op_id is not null then
  select id into v_task_id from public.tasks
   where client_operation_id = p_op_id;
  if found then
    return v_task_id;              -- replay: same task, no new rows
  end if;
end if;
-- ... existing validation/authorization ...
-- when inserting the task row, also set client_operation_id = p_op_id
-- guard the race:
begin
  insert into public.tasks (... , client_operation_id) values (... , p_op_id)
  returning id into v_task_id;
exception when unique_violation then
  select id into v_task_id from public.tasks where client_operation_id = p_op_id;
  return v_task_id;               -- concurrent replay won the insert
end;
-- ... then the existing assignment + activity-log inserts (run once) ...
return v_task_id;
```

### `report_tree_issue` — add `p_op_id uuid default null`
It creates a `tree_issue` **and** a linked review `task`. Dedup on the issue; return both
ids on replay (the task is found via `tasks.related_tree_issue_id`).
```sql
if p_op_id is not null then
  select ti.id, t.id into v_issue_id, v_task_id
    from public.tree_issues ti
    join public.tasks t on t.related_tree_issue_id = ti.id
   where ti.client_operation_id = p_op_id;
  if found then
    return query select v_issue_id, v_task_id;   -- replay
  end if;
end if;
-- ... create the issue with client_operation_id = p_op_id (wrap the insert in the same
--     unique_violation guard), then create its review task as today ...
```

### `review_task` — add `p_op_id uuid default null`
It inserts an `engineer_reviews` row **and** transitions the task + updates the linked
issue (+ optional photo + activity). Short-circuit at the very top so none of those side
effects repeat:
```sql
if p_op_id is not null then
  select id into v_review_id from public.engineer_reviews
   where client_operation_id = p_op_id;
  if found then
    return v_review_id;           -- replay: no re-transition, no dup review
  end if;
end if;
-- ... existing manager/auth + status-eligibility checks ...
-- insert engineer_reviews (... , client_operation_id => p_op_id) with unique_violation
--     guard returning the existing id, then the existing task/issue/photo/activity work.
```

## P1 — Transition RPCs (makes offline replay of start/complete/assign fully safe)

These are state-guarded, but a lost-response replay currently raises `23514`
("cannot complete from completed"), which the client would surface as a spurious failure.
Make a replay of an already-applied op a **success no-op** via a small ledger.

```sql
create table if not exists private.applied_operations (
  op_id uuid primary key,
  applied_at timestamptz not null default now()
);
```
At the top of `start_assigned_task`, `complete_task`, `set_task_assignments`
(each gains `p_op_id uuid default null`):
```sql
if p_op_id is not null then
  insert into private.applied_operations (op_id) values (p_op_id)
    on conflict (op_id) do nothing;
  if not found then           -- 0 rows inserted → already applied
    return;                   -- idempotent success
  end if;
end if;
-- ... existing transition logic ...
```
(Insert the ledger row only after auth passes, or delete it if the transition later
raises, so a genuinely rejected op can be retried — your call; simplest is to claim after
the auth/eligibility checks and before the state change.)

## P2 — Photo RPCs (optional)

`add_task_photo` / `add_tree_issue_photo` are already idempotent on storage path. Adding
`p_op_id uuid default null` for uniform bookkeeping is optional and not required by the
client.

## Function replacement mechanics

Adding a parameter changes the signature, so `CREATE OR REPLACE` alone will create an
overload. For each function: `DROP FUNCTION IF EXISTS public.<fn>(<old arg types>);` then
`CREATE FUNCTION` with `p_op_id uuid default null` appended, and re-apply the existing
`REVOKE ALL ... ; GRANT EXECUTE ... TO authenticated;` grants. Keep `security definer` and
`set search_path = ''`.

## What the client will send

The Flutter client passes `p_op_id` (a v4 UUID string) by name on every mutating call
once these are deployed, e.g. `create_farm_task(..., p_op_id: '<uuid>')`. The same op id
is reused verbatim across retries of the same queued mutation. No other client change is
needed from the backend side.

## Verification (please report back)

- Clean DB reset + all migrations apply in order.
- **pgTAP** proving idempotency, e.g. for each create RPC:
  - calling it twice with the **same** `p_op_id` returns the **same** id and leaves exactly
    **one** row (task/issue/review), one linked review-task for issues, and no duplicate
    activity-log/assignment rows;
  - calling with `p_op_id => null` behaves as today (each call creates a new row);
  - two concurrent same-`p_op_id` calls yield one row (unique_violation path).
  - transitions: replaying `complete_task` with the same `p_op_id` returns success and does
    not error or double-log.
- `supabase db lint` and the advisor checks are clean for the new migration.
- Confirm return types/columns are byte-for-byte the same as before.

## Handback

Reply with: the new migration filename(s), the pgTAP output, lint/advisor results, and
confirmation that deployment is done (or staged), so the Flutter side can flip on sending
`p_op_id` for the offline create/review phases (O2/O3).
