# Al Wahat Farm — Offline-First Plan

Goal: the app is **fully usable with no internet** — browse the farm, scan, create
and run tasks, report issues, review work, attach photos — and everything **syncs
automatically and safely when connectivity returns**, with no duplicated or lost data.

Decisions locked with the operator (2026-07-18):
1. **Backend idempotency** — the Supabase RPCs will accept a client operation id so
   queued writes can be replayed without creating duplicates. (Migrations land in the
   separate Supabase repo; this Flutter repo treats `supabase/` as read-only reference.)
2. **Storage engine** — add `sqflite` for the cached read store and a durable mutation
   outbox. Codegen-free; pin to a release that resolves on Flutter 3.13.9 / Dart 3.1.5
   (see [[toolchain-constraints]] — verify with `flutter pub get` before committing).
3. **Scope** — everything works offline, including photo evidence (captured locally,
   uploaded on sync).

This supersedes the Phase 7 stance ("no offline mutation queue"): that rule required
backend duplicate-prevention, which decision (1) now provides.

---

## 1. Principles

- **Offline-first reads**: the UI always reads from the local database; the network
  refreshes the local database in the background. No screen depends on a live call.
- **Replay-safe writes**: every mutation carries a client-generated `op_id` (UUIDv4).
  The backend applies each `op_id` at most once and returns the same result on replay.
  A lost response is therefore always safe to retry.
- **Optimistic UI**: a queued write is reflected immediately from local state (with a
  "pending sync" marker) and confirmed/reconciled after it commits.
- **No silent loss**: a mutation that cannot apply (permanent conflict/authorization)
  surfaces to the user; it is never dropped quietly.
- **Honest state**: pending / syncing / failed is always visible per item and globally.
- **Privacy**: the outbox stores no tokens; photos live in private app storage; logout
  clears the outbox, cached data, and local photos.

---

## 2. Architecture

```
UI (controllers)
  │  read                         write
  ▼                                 │
LocalStore (sqflite)  ◄────────── Outbox (sqflite)  ── enqueue op {op_id, kind, payload, deps}
  ▲  refresh                        │
  │                                 ▼
SyncEngine  ── drains outbox in dependency order, calls Supabase RPCs with op_id,
  │           reconciles temp→real ids, then re-pulls affected entities into LocalStore
  ▼
Supabase (RPC + Storage)  — idempotent on op_id
```

- **`LocalStore`** — sqflite tables mirroring the domain: `farms`, `sections`, `zones`,
  `trees`, `tasks`, `task_assignments`, `task_activity`, `task_photos`, `tree_issues`,
  `engineer_reviews`, plus `operational_context` (profile/role/membership) so the app
  opens fully offline. Repositories become **read-through**: read local first, trigger a
  network refresh that upserts into local, notify listeners.
- **`Outbox`** — ordered, durable queue of pending mutations. Columns:
  `op_id (uuid, pk)`, `kind`, `payload (json)`, `depends_on (op_id?)`, `status
  (pending|inflight|failed|done)`, `attempts`, `last_error`, `created_at`.
- **`PendingPhotos`** — captured image bytes/blobs awaiting upload, keyed by `op_id`.
- **`SyncEngine`** — a single serialized worker that drains the outbox FIFO respecting
  `depends_on`, calls the RPC with `op_id`, maps temp ids → server ids, upserts results,
  and retries with backoff. Triggered by: connectivity regained, app resume, manual
  "Sync now", and immediately after enqueue when online.

Repositories keep their current interfaces (`TaskRepository`, `TreeIssueRepository`,
`EngineerReviewRepository`, `TreeQrRepository`, `FarmHierarchyRepository`) so
controllers barely change. We add offline-aware implementations that wrap the existing
Supabase ones (same decorator pattern as `CachingTaskRepository`).

---

## 3. Backend idempotency contract (Supabase repo)

Each **creating** RPC gains a `p_op_id uuid` parameter and dedupes on it; each affected
table gets a `client_operation_id uuid` column with a partial unique index.

| RPC | Change |
|---|---|
| `create_farm_task` | add `p_op_id`; `insert … on conflict (client_operation_id) do nothing`; if the row already exists, return its id. |
| `report_tree_issue` | add `p_op_id`; store on the created `tree_issues` row (and reuse for the generated review task); on replay return the same `(tree_issue_id, task_id)`. |
| `review_task` | add `p_op_id`; unique on `engineer_reviews.client_operation_id`; on replay return the existing review id and skip the duplicate status transition. |
| `start_assigned_task` / `complete_task` / `set_task_assignments` | add `p_op_id` for uniformity; these are already guarded by state, but the op-id makes "already applied" a clean no-op returning success instead of a confusing conflict. |
| `add_task_photo` / `add_tree_issue_photo` | already idempotent on storage path; accept `p_op_id` too for consistent bookkeeping. |

Client sends `p_op_id` on **every** call (online and offline) so behaviour is identical
either way. A shared `private.claim_operation(p_op_id, p_actor)` helper or per-table
unique index is the mechanism; the exact SQL is authored and verified (pgTAP) in the
Supabase repo. **This Flutter repo cannot deploy it** — the plan flags it as an external
dependency and gates offline-write release on its deployment.

---

## 4. Optimistic UI & temp-id reconciliation

Offline creation can't know the server id, so:

1. On offline create, mint a **temp id** `local:<op_id>` and write a provisional row to
   `LocalStore` (marked `pending`). The UI shows it immediately with a "not yet synced"
   badge.
2. Dependent actions reference the temp id and are queued with `depends_on` set (e.g.
   create task → set assignments → add photo → complete, all before first sync).
3. On sync, the create returns the real id; the SyncEngine records a `temp→real` mapping,
   rewrites the ids in all dependent queued payloads and in `LocalStore`, then proceeds.
4. After each op commits, re-pull the affected entity (`loadDetails`, list) to replace the
   provisional row with authoritative server data.

This lets a worker do a full **create → assign → start → photo → complete** chain fully
offline; it replays in order and converges to the same state as if done online.

---

## 5. Per-action offline behaviour

| Action | Offline behaviour |
|---|---|
| Browse map / trees / sections / zones | Local read; map geometry already bundled. |
| Scan QR | Resolve token → tree **locally** from cached trees (extend `resolveTreeQrToken` + a local lookup); fall back to RPC when online for unknown tokens. |
| View tasks / task detail / reviews | Local read; "stale/offline" indicator when not fresh. |
| Create task | Temp id + outbox; visible immediately; syncs on reconnect. |
| Set assignments / start / complete | Outbox (depends_on create if applicable); optimistic status change. |
| Report issue (+ photo) | Temp issue+review-task ids; photo stored locally; outbox. |
| Review decision (+ photo) | Outbox; optimistic status; photo local until sync. |
| Add photo evidence | Bytes stored in `PendingPhotos`; on sync upload → register. |

---

## 6. Photos offline

Capture path today: `image_picker` → compress → upload to Storage → register via RPC.
Offline path: capture → compress → **persist bytes** (app-documents dir via
`path_provider`, referenced from `PendingPhotos`) → outbox `upload+register` op. On sync:
upload to the private bucket at the exact `{uid}/{farm}/{task}/file` path, then call the
(idempotent) register RPC. Storage-path dedup already prevents double registration.

---

## 7. Offline app-open (auth & context)

- `supabase_flutter` already persists the session, so a returning user is authenticated
  offline (token refresh simply waits for network).
- **New**: cache the resolved `OperationalContext` (profile, memberships, role, selected
  farm) in `LocalStore` so `AuthenticatedGate` can bootstrap from cache when offline
  instead of blocking on the network. Online, refresh and reconcile.

---

## 8. Sync engine details

- **Trigger**: `connectivity_plus` regained, `AppLifecycleState.resumed`, manual button,
  and post-enqueue when online.
- **Order**: FIFO by `created_at`, honouring `depends_on`; a blocked dependency defers its
  dependents.
- **Retry**: exponential backoff on transient/`offline`/`unexpected`; cap attempts.
- **Terminal failures**: `authorization` / `invalidInput` / unrecoverable `conflict` mark
  the op `failed` with a readable reason; surfaced for user review (retry or discard).
  Never auto-dropped.
- **Concurrency**: single in-flight worker (serialized) to keep ordering and avoid races.
- **Conflict policy**: reads are server-wins on refresh. For transition writes that the
  server rejects because state moved (e.g. task already completed by a manager), the op is
  marked failed with an explanatory message and the local row is reconciled to server
  truth.

---

## 9. Sync-state UI

- Per-item **"pending sync" / "sync failed"** badges on task/issue/review cards and detail.
- Global sync status in **More** (extends the current tile): online/offline, N pending, N
  failed, last-synced time, **Sync now**, and a **failed-operations** screen to retry or
  discard with the reason shown.
- All new strings go through the l10n pipeline (en + ar) — see [[localization-architecture]].

---

## 10. Security & privacy

- Outbox payloads contain domain data only — **no tokens** (SafeLog rules still apply).
- Pending photos live in private app storage, not the gallery.
- **Logout** clears: outbox, pending photos, all cached entities, and the operational
  context — reusing the Phase 7 `clearPrivateData` sweep (extended to the sqflite store).

---

## 11. Testing strategy

- Sync engine unit tests over an in-memory/temp sqflite db: enqueue → drain → assert RPC
  calls carry `op_id`, ordering/`depends_on` honoured, temp→real reconciliation.
- **Replay-safety**: simulate a lost response (op applied server-side, client retries) and
  assert no duplicate via op-id (fake RPC that records applied op-ids).
- Offline→online round trips per action (create/assign/start/complete/report/review/photo).
- Conflict cases (state moved server-side) → op failed + reconciled, not lost.
- Offline reads: QR resolves locally; app opens from cached context.
- Logout clears outbox + photos + cache.
- Keep the default suite green on Flutter 3.13.9; live sync verified in the opt-in suite.

---

## 12. Dependencies & toolchain

- Add `sqflite` and `path_provider`, pinned to releases resolvable on Dart 3.1.5 (verify
  with `flutter pub get`; do not raise the SDK floor). No code generation.
- No change to the Supabase client key model or the read-only `supabase/` reference.

---

## 13. Phased rollout (each phase gated, tests green before the next)

- **O0 — Foundations** ✅ (2026-07-18): added `sqflite`/`path_provider`/`path` (+ dev
  `sqflite_common_ffi`), all resolving on Flutter 3.13.9 / Dart 3.1.5. `AppDatabase`
  (sqflite, KV `cache_entries` table) backs a `SqfliteCacheStore` implementing the
  existing `LocalCacheStore`, so every Phase 7 read cache now persists in the DB;
  production wiring switched from shared-preferences to sqflite. Added operational-context
  serialization + `CachingOperationalContextRepository` (write-through online, cache
  fallback offline, never masks a blocked verdict) so `AuthenticatedGate` bootstraps
  offline. Gate met: app opens and browses fully offline (context + hierarchy + tasks all
  cached). `flutter analyze` clean; `flutter test` 150 passed, 6 skipped.
- **O1 — Outbox + SyncEngine (idempotent transitions first)** ✅ (2026-07-18): added the
  `outbox` table (AppDatabase v2), `PendingMutation` domain, and `OutboxStore` (sqflite +
  in-memory). `SyncEngine` drains FIFO when online, classifies transient (offline/unexpected
  → retry, stop to preserve order, cap at maxAttempts) vs terminal (authorization/invalid/
  conflict/not-found → mark failed, continue), is replay-safe (a committed op is never
  re-run), and auto-syncs on reconnect. `OfflineTaskRepository` queues start/complete/
  set-assignments when offline with an optimistic cached-status patch and replays via a
  `TaskMutationExecutor`; wired into `AuthenticatedGate`, and logout now clears the outbox.
  Photos deferred to a later slice (need the pending-photo blob store). Gate met for
  transitions: offline start/complete → replays exactly once; failed-op surfacing works.
  `flutter analyze` clean; `flutter test` 168 passed, 6 skipped.
- **O2 — Optimistic creates + reconciliation**: temp ids, `depends_on`, temp→real rewrite;
  offline **create task** and **report issue** (with local photos). Depends on the backend
  idempotency migrations being deployed. Gate: full offline create→…→complete chain
  converges; replay-safe under lost-response simulation.
- **O3 — Review offline + conflict handling**: `review_task` offline; conflict/terminal
  failure policy; server-wins reconciliation. Gate: worker/role and conflict tests pass.
- **O4 — Sync UX + hardening**: per-item badges, global sync center, Sync-now, failed-ops
  screen, l10n (en+ar), logout wipe, accessibility. Gate: fidelity + privacy + a11y checks.

---

## 14. External dependency & risks

- **Backend migrations (op-id dedup)** are the critical path for O2/O3; offline *creates*
  can't ship safely until they're deployed and pgTAP-verified in the Supabase repo.
- sqflite/path_provider must resolve on the pinned toolchain — verify first.
- Large photo backlogs: cap local storage and warn; consider count/size limits.
- Clock/ordering: rely on server timestamps on refresh; `created_at` for local ordering.
```
