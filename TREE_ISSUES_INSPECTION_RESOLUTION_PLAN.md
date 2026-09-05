# Tree Issues, Inspection, and Worker Resolution Plan

Status: implementation in progress; the backend foundation and audited manager
takeover are deployed to the linked Al Wahat Farm Supabase project and verified
through 2026-09-04. Flutter source changes have not been pushed or released by
this work.

Repositories:

- Flutter: `al_wahat_farm_flutter`
- Backend: `Al-Wahat-Farm-supabase`

## Implementation checkpoint — 2026-09-04

Completed locally in this checkpoint:

- Additive backend schema, active-bucket constraint, audit events,
  task-to-issue work items, exclusive claims, inspection snapshots, explicit
  grants/RLS, and idempotent report/claim/inspection/resolution RPCs.
- Detection-review approval now confirms an issue; individual resolution and
  unable-to-fix outcomes never affect unrelated issues.
- Deterministic Flutter route planning from tree `001` (or the lowest existing
  planted number), paired-row snake stations, manager inspection creation,
  assigned inspection runner, required severity/photo handling, and offline
  station/photo replay.
- Active Issues entry points on Home and Tasks, safe worker claim queue, issue
  halos and matching-only mode on normal/full-screen maps, and individually
  linked Resolve/Unable controls in task detail.
- Authorized issue detail now shows the private issue record, inspection
  observations, linked-task summaries, attributable private evidence, and the
  event timeline, with manager-only severity-change and dismissal controls.
  The safe summary contract remains separate and includes only tree/section
  identity, issue state, claim state, and per-tree active counts.
- Managers now have a separately authorized, offline-cached issue register with
  active/history views; status, type, severity, section, age, assignment, and
  source filters; accountable-worker labels; and atomic online assignment that
  creates one linked resolution task for the selected operational farm member.
  The task's engineer-review setting is chosen explicitly during assignment.
- Offline issue mutations and photos use the existing outbox, pending-photo
  store, Sync Center, and private cache. Self-claim remains deliberately
  online-only and is visibly disabled with localized guidance while offline.
- Offline inspection creation now writes a complete provisional task, session,
  and immutable route snapshot. Dependent start/save/photo/submit operations
  resolve the provisional IDs after creation replay, and unsaved station form
  values plus photo bytes survive process death and app restart.
- English/Arabic localization output regenerated. Existing task list/calendar,
  QR reporting, map/tree/pit details, task lifecycle, and review behavior remain
  present.
- Plain legacy `tree_inspection` tasks remain standard Start/Complete tasks.
  Only guided inspections carrying route metadata open the station runner; the
  standard task form now links clearly to the guided setup, and stale direct
  runner links return to the task with a specific explanation.
- Task member loading and shell-section refreshes are deferred until after the
  current frame, eliminating the build-phase listener exceptions found during
  the signed-in simulator smoke test.
- Canonical route tests now cover every planted A-G section: A 298/185,
  B 330/176, C 185/107, D 303/161, F 351/192, and G 72/36
  trees/stations. Section E is correctly blocked as empty; G starts at its
  lowest existing tree, `TREE-G-037`, because no G tree `001` exists.
- The runner now loads exact saved station observations, supports Previous
  navigation, preserves saved and queued photos when reviewing a station, and
  presents a final review step before submission.
- Manager creation now accepts section deep links from the map and Issues
  workspace, requires assignee/schedule/priority, and previews the real
  coordinate-based row/corridor route before task creation on phone and tablet.
- Manager takeover is an explicit online-only, audited action. It atomically
  replaces the active task assignment and immediately removes the previous
  inspector's edit authority; submitted and cancelled sessions remain closed.
- Runner cards now prioritize tree code and retain section, imported row/tree,
  coordinate, physical-side, and active-issue context. Review details show
  every linked issue outcome read-only and explain the per-issue approval scope.
- Quick reporting distinguishes a newly created issue from confirmation of an
  existing active bucket. Successful sync replay refreshes Issues, Tasks, Home
  counts, and the map issue layer without requiring an app restart.
- Issue-marked map trees and the route preview now expose localized semantics;
  physical route geometry remains fixed when the surrounding UI is RTL.
- Verification: clean local database reset, 295 pgTAP tests, Flutter static
  analysis, 327 Flutter tests, and affected goldens pass. Six credential-gated
  live Flutter tests remain skipped by design. Database lint has only two
  pre-existing warnings in `private.generate_plan_run_group`.
- Remote migrations `20260902091954`, `20260904094333`, and the explicit ACL
  correction `20260904120301` are applied and remote migration history matches
  local. The takeover RPC is `SECURITY DEFINER` with an empty `search_path`, is
  executable by `authenticated` only, and returns database-level permission
  denial to `anon`. Remote database lint reports only the same two pre-existing
  warnings in `private.generate_plan_run_group`. The latest Flutter build is
  running on the iPhone simulator against the remote project.

Still required before rollout:

- Farm-staff validation of every A–G walking route and a real-device offline
  pilot, including restart/reconnect behavior.
- The remaining real-account integration and field-accessibility checks listed
  in the rollout validation matrix below.
- A signed-in owner/engineer and worker smoke test of the remote authorization
  paths before releasing the Flutter build.
- A separate review of pre-existing remote advisor warnings, especially legacy
  trigger/helper functions still executable by `anon`, before production
  hardening. The takeover function is not among those anonymous-access warnings.

Checklist notation: `[x]` means the complete checklist statement is supported
by the current code and verification evidence. `[ ]` includes both untouched
and partially implemented statements; the text is left unchecked whenever any
material part remains.

## Goal

Extend the current tree-issue workflow into a secure, offline-capable system for
active issue buckets, section inspections, map visibility, worker claiming, and
individual issue resolution. All existing app features and entry points remain
available, including quick issue reporting, QR scanning, tree details, the
five-tab shell, the Tasks list/calendar, task review, photos, and offline sync.

The attached AI-generated proposal is a source of ideas only. The current
Flutter and Supabase implementations, the actual farm data, and the decisions
recorded below are authoritative.

## Approved product decisions

### Issue definitions and lifecycle

- Keep the seven current issue types unchanged:
  - `insufficient_irrigation`
  - `clogged_dripper`
  - `leak_or_dripper_damage`
  - `harmful_weed`
  - `pest_or_disease`
  - `tree_damage`
  - `other`
- Keep the current severities: `low`, `medium`, `high`, and `urgent`.
- Severity is required for every new issue occurrence.
- Confirming an active issue does not change its severity unless the inspector
  explicitly selects a severity change.
- “No issue” means “no new issue found during this observation.” It never
  resolves or dismisses an existing issue.
- Only one active issue bucket may exist for one farm, tree, and issue type.
- A resolved or dismissed occurrence remains in history. A later detection may
  create a new occurrence of the same type.
- Current issue records were deleted by the user. No merge or historical-data
  migration is required. Deployment must still assert that no active duplicate
  buckets exist before adding the uniqueness rule.
- Engineer approval confirms a reported issue and makes it `open`; approval no
  longer resolves an issue.
- Resolution and dismissal are always explicit actions.

### Roles and visibility

- Owners and agricultural engineers may create and assign inspections.
- An assigned worker runs an inspection.
- Owners and agricultural engineers may assign an inspection to themselves and
  run it.
- Only one person edits an inspection session at a time.
- Owners and agricultural engineers can see all issue details and history.
- A worker keeps full visibility for issues they reported and receives full
  visibility for issues assigned to their tasks.
- Other operational workers may see safe active-issue summaries and counts so
  they can find work, but not private notes or photos before claiming.
- Accountants have no issue access.
- Only owners and agricultural engineers may dismiss an issue.
- Workers may report, confirm, claim, resolve assigned issues, or record that an
  assigned issue could not be fixed. They may not dismiss issues.

### Claiming and resolution

- Workers may self-claim an unassigned, confirmed active issue.
- Self-claiming is one issue at a time and creates or assigns a single-issue
  resolution task.
- Self-claim requires a network connection because exclusive assignment cannot
  be guaranteed between disconnected devices.
- Inspection and work on an already assigned issue remain fully offline-capable.
- Self-created claim tasks require engineer review by default. A manager-created
  task reuses its existing `requires_engineer_review` setting.
- Claims do not expire automatically while a worker may be offline. Managers
  can reassign or release them through the existing task-management flow.
- There is no “Resolve all” action. It must not appear in UI, localization, RPCs,
  or tests.
- Every linked issue must receive its own Resolve or Unable to fix action.
- A batch task is allowed, but completing it cannot close unrelated issues on
  the same tree or issues that are not explicitly linked to the task.
- When `requires_engineer_review` is false, an individual Resolve action closes
  that issue immediately.
- When `requires_engineer_review` is true, Resolve submits the individual issue
  for review and the issue remains active until approval. A returned resolution
  remains active.
- Unable to fix always leaves the issue active and requires one of:
  - `replacement_part_required`
  - `specialist_required`
  - `additional_worker_required`
  - `equipment_unavailable`
  - `tree_inaccessible`
  - `suspected_incorrect_issue`
  - `other`
- `other` requires notes. A photo is optional for every unable-to-fix reason.

### Inspection route

- Inspection begins at the unique tree code ending in `001`, for example
  `TREE-A-001`. If `001` is not planted, it begins at the lowest existing tree
  number on that same starting edge; the current G data therefore begins at
  `TREE-G-037`. The duplicated `row_number + tree_number` fields are not a safe
  identity or ordering key.
- The inspector walks between two physical rows and inspects the trees on both
  sides of the path at the same time.
- Adjacent physical rows form a corridor. Each station contains a left tree, a
  right tree, or one tree when an outside/unmatched row has no pair.
- Corridors use a snake order: the next corridor reverses walking direction.
- Sections A-G use the same direction convention.
- The route is generated from coordinates, previewed before task creation, and
  saved as an immutable session snapshot.
- GPS tracking is not required.
- Existing active issues are preselected during inspection. Saving a selected
  issue records confirmation. Deselecting an existing issue records “not
  observed” but does not resolve it.

### App behavior and evidence

- Keep the existing five main tabs.
- Add an active-issues card/action to Home, an Issues shortcut from Tasks, and a
  dedicated `/issues` route.
- Keep irrigation-zone colors as the default map visualization.
- Issue filters add a halo/badge around affected trees. Nonmatching trees are
  faded by default, with a “show matching only” toggle.
- Issue and tree details must still open from both normal and full-screen map
  modes.
- Detection, confirmation, and resolution photos are optional by default.
- An inspection or resolution task may explicitly require the applicable
  photo. Unable to fix never requires a photo.
- English, Arabic, RTL, phone, and tablet layouts are part of the first release.
- Full offline support is required for the first release except for the atomic
  self-claim action described above.

## Current implementation constraints

- `public.tree_issues` already represents issue occurrences and has useful
  reporter, reviewer, resolver, status, task, timestamp, and idempotency data.
  It should be extended, not replaced.
- Active statuses are currently `open` and `in_review`; terminal statuses are
  `resolved` and `dismissed`.
- `report_tree_issue` currently creates a new row and an engineer-review task.
  Its return contract is used by the Flutter photo flow and must remain
  compatible.
- `review_task(approved)` currently resolves its linked issue. This transition
  must change to confirmation for detection/review tasks, while resolution-task
  approval must explicitly close only its linked submitted issues.
- Tasks currently expose one legacy `related_tree_issue_id`, while
  `task_targets` already supports multiple same-kind targets. An additive join
  is required for multi-issue tasks.
- Direct issue writes are already RPC-oriented. The new design must continue
  RPC-only mutations with operation IDs for offline replay.
- The existing RLS helper gives managers, reporters, and assigned workers full
  issue visibility. Safe farm-wide worker summaries require a separate limited
  read API; broadening base-table RLS would expose notes and other private data.
- The Flutter app already has a SQLite cache, serialized outbox, pending photo
  storage, mutation executors, failed-operations UI, and sync engine. Extend
  these components instead of building a second offline system.
- The approved full-farm fixture contains 1,539 trees. All have coordinates,
  but 130 `(section, row_number, tree_number)` combinations are duplicated
  because numbering restarts across physical blocks. `tree_code` is unique.
- Supabase now treats API object grants and RLS as separate controls. Every new
  public table/RPC must include explicit least-privilege grants in the same
  migration as its RLS setup.

## Target domain model

### Active bucket rule

Keep `public.tree_issues` as the occurrence and current-state row. Add a partial
unique index equivalent to:

```sql
unique (farm_id, tree_id, issue_type)
where status in ('open', 'in_review')
```

All reporting and inspection RPCs must use an atomic insert-or-confirm path.
They must not perform an application-side select followed by insert. Concurrent
detections must produce one active occurrence and separate observation events.

### Append-only issue history

Add `public.tree_issue_events` as the audit timeline. Planned fields include:

- UUID, farm, issue, tree, actor, and server timestamp.
- Event type, previous/new status, observed severity, and optional new severity.
- Optional inspection session/item, task, reason code, notes, and photo link.
- Client observation timestamp for offline field context.
- Unique nullable `client_operation_id` for idempotent replay.

Planned event types include detection, confirmation, not observed, severity
changed, fix attempted, unable to fix, resolution submitted, resolved,
dismissed, and review returned. Events are never edited or deleted by clients.

If one event needs photos, reuse the current task-photo/storage security model
and add a narrow event-to-photo association. Do not introduce a second public
storage bucket or expose raw storage paths to summary readers.

### Task-to-issue work items

Add `public.task_tree_issues` as the authoritative many-to-many work list:

- `task_id` and `tree_issue_id`, unique as a pair.
- Per-issue work state, assignee/action actor, timestamps, resolution notes,
  photo requirement, and optional unable-to-fix reason.
- Foreign-key indexes for both directions.

Retain `tasks.related_tree_issue_id` and `tree_issues.linked_task_id` for
backward compatibility:

- New single-issue tasks populate the legacy fields and the join row.
- Batch tasks use the join table as authoritative.
- Existing screens continue to work while new screens read the full join.
- No destructive column removal is part of this feature.

Add an active-claim record or equivalent enforceable reservation with a partial
unique rule ensuring that one issue has at most one active worker claim. Task
status alone cannot safely enforce this rule across tables.

### Inspection sessions and route snapshot

Add the following additive structures:

1. `inspection_sessions`
   - Farm, section, task, assigned inspector, creator, status, and progress.
   - Start/pause/resume/submit timestamps.
   - Route algorithm version, starting tree, counts, and photo policy.
   - Client operation ID and optimistic revision.
2. `inspection_session_items`
   - One immutable row per tree in the session.
   - Station index, corridor index, left/right/single side, sequence, tree ID,
     and a snapshot of display identity/coordinates.
   - Mutable observation state and inspector timestamp kept separate from route
     identity fields.
   - Unique `(session_id, tree_id)` plus indexes for ordered session loading.
3. `inspection_issue_observations`
   - Item, issue type, outcome, active issue reference, observed severity,
     explicit severity-change flag, notes, and operation ID.
   - Outcomes distinguish new detection, confirmation, and not observed.

The server validates farm/section/tree membership, unique tree coverage, one
assigned editor, and valid station ordering. It does not recompute geometry;
the tested Flutter planner submits the reviewed immutable order.

### State-transition rules

| Action | Issue result |
| --- | --- |
| New quick report | `in_review`; review task created |
| New inspected issue with review required | `in_review` |
| New inspected issue without review required | `open` |
| Engineer approves a detection | `open`, never `resolved` |
| Confirm an active issue | Status unchanged; severity unchanged by default |
| Explicit severity change | Active status unchanged; change recorded as event |
| “No issue” or “not observed” | Existing issue status unchanged |
| Resolve without required review | `resolved` immediately |
| Resolve with required review | Remains active until approval |
| Engineer approves submitted resolution | `resolved` |
| Engineer returns submitted resolution | Active; work item returned |
| Unable to fix | Active; reason/event recorded |
| Manager dismisses | `dismissed` with audit event |

## Backend implementation plan

### Phase BE-0 — Contract and deployment preflight

- [x] Record the current RPC signatures, grants, RLS policies, enum values, and
      pgTAP contract expectations before changing them.
- [x] Confirm the target remote project and compare local/remote migration
      history.
- [x] Verify the user-confirmed empty `tree_issues` state immediately before
      deployment.
- [x] Add a migration guard that aborts with a clear error if active duplicate
      buckets exist; do not silently merge, delete, or rewrite them.
- [x] Generate each imperative migration with the Supabase CLI rather than
      inventing migration filenames.

### Phase BE-1 — Additive schema and constraints

- [x] Add issue-event, task-issue, active-claim, inspection-session,
      session-item, and inspection-observation enums/tables.
- [x] Add the active-bucket partial unique index.
- [x] Add checks for severity-change intent, unable-to-fix reasons, timestamps,
      immutable route identity, and valid status/outcome combinations.
- [x] Add all foreign-key indexes and composite indexes used by farm/status,
      tree/status, session/order, task/work-state, and claim lookups.
- [x] Reuse the existing `updated_at` trigger only on mutable rows; event rows
      remain append-only.
- [x] Keep existing issue/task columns and enum values intact.

### Phase BE-2 — Secure read surfaces

- [x] Preserve full base issue access for managers, the reporter, and assigned
      workers.
- [x] Add a limited summary RPC/view returning only tree ID/code, section,
      issue type, severity, age/status, claim state, and aggregate counts.
- [x] Do not include descriptions, notes, actors, or photo paths in worker
      summaries.
- [x] Add manager/tree history and assigned-work detail reads with explicit
      authorization.
- [x] Enable RLS on every new public table.
- [x] Keep internal authorization helpers in `private`, set an empty
      `search_path`, check `auth.uid()` explicitly, and revoke unintended
      execution.
- [x] Revoke raw client mutation privileges and grant only required SELECT or
      RPC EXECUTE access to `authenticated`; grant nothing to `anon`.
- [x] Verify accountant denial and cross-farm isolation at both summary and
      detail levels.

### Phase BE-3 — Reporting and review semantics

- [x] Replace report insertion with one atomic active-bucket operation.
- [x] Preserve `report_tree_issue` parameter compatibility and its
      `(tree_issue_id, task_id)` return needed by the current photo workflow.
- [x] For a new occurrence, create the issue, event, engineer-review task,
      task target, and task-issue link in one short transaction.
- [x] For an existing active bucket, append a confirmation/detection event,
      preserve severity by default, and return/create a compatible review task
      for evidence without duplicating the issue row.
- [x] Add an explicit manager/inspector severity-change mutation.
- [x] Change detection-review approval from `resolved` to `open`.
- [x] Keep returned/follow-up detections active and audited.
- [x] Add explicit manager-only dismissal with a required audit note.
- [x] Update old pgTAP tests that intentionally expected duplicate active rows;
      retain op-ID replay coverage and replace the old expectation with active
      bucket and concurrency tests.

### Phase BE-4 — Inspection RPCs

- [x] Add an atomic `create_section_inspection` flow that creates/reuses the
      existing `tree_inspection` task type, section target, session, and full
      route snapshot.
- [x] Validate every submitted tree belongs to the section and appears exactly
      once; reject extra, missing, or duplicate tree IDs.
- [x] Support manager self-assignment and worker assignment using current role
      rules.
- [x] Add idempotent start, pause, resume, save-station, and submit mutations.
- [x] Save both sides of one walking station in one transaction so partial
      paired observations cannot occur.
- [x] On save, atomically create-or-confirm active buckets and append all
      observation events.
- [x] Require severity only for a new occurrence. Require an explicit flag to
      update severity for an existing occurrence.
- [x] Record an empty selection as “no new issue found” and active deselections
      as “not observed,” without state changes.
- [x] Reject edits from anyone other than the session inspector or an
      authorized manager takeover; audit any manager takeover.
- [x] Submit only after every snapshot tree has an observation result.
- [x] Apply the inspection task’s review setting to newly detected issues and
      the existing task completion/review lifecycle.

### Phase BE-5 — Claiming and individual resolution RPCs

- [x] Add an online-only atomic claim RPC that locks the issue, verifies it is
      active/confirmed/unclaimed, creates or assigns a single-issue task, adds
      assignment/target/link/claim rows, and returns the task in one transaction.
- [x] Make concurrent claims deterministic: one succeeds and the other receives
      a typed conflict; do not rely on Flutter-side availability checks.
- [x] Default an automatically created self-claim task to
      `requires_engineer_review = true`.
- [x] Prevent overlapping active claims when a manager creates or reassigns a
      resolution task.
- [x] Add one-issue Resolve and Unable to fix RPCs. Each must verify that the
      issue is explicitly linked to the worker’s assigned task.
- [x] Enforce photo policy for Resolve, but never for Unable to fix.
- [x] Require the approved reason enum and notes when the reason is `other`.
- [x] Leave unable-to-fix issues active and release/requeue them only according
      to the completed task outcome or an explicit manager action.
- [x] Block task completion until every linked issue has one explicit outcome
      for that task; never infer completion from tree or filter membership.
- [x] Resolve immediately when review is not required.
- [x] When review is required, record a pending resolution and resolve only the
      included issue when the engineer approves it. Return keeps it active.
- [x] Ensure no bulk resolve function or broad `UPDATE ... WHERE tree_id = ...`
      exists.

### Phase BE-6 — Backend verification

- [x] Add pgTAP schema, enum, constraint, FK-index, grant, and RLS tests.
- [x] Test owner, engineer, assigned worker, reporter, unrelated worker,
      accountant, anonymous, and cross-farm access.
- [x] Test new report, repeated confirmation, explicit severity change, no
      issue, not observed, dismissal, new occurrence after resolution, and
      review transitions.
- [x] Add concurrent tests for duplicate detection and worker claim races.
- [x] Test inspection route validation, paired atomic saves, single editor,
      full coverage, replay, pause/resume, and submission.
- [x] Test single and batch task work, per-issue resolution, unable-to-fix,
      required photos, review approval/return, and unrelated-issue protection.
- [x] Run clean local reset, full pgTAP suite, database lint/advisors, and direct
      grant/RLS inspection before remote deployment.

## Flutter implementation plan

### Phase FE-0 — Domain and service boundaries

- [x] Extend issue models with safe summaries, events/history, active bucket
      state, claim state, work-item state, and typed unable-to-fix reasons.
- [x] Add inspection session, station, side, item, observation, progress, and
      route-version models.
- [x] Keep the current `TreeIssueDraft`, report screen, report controller, and
      repository interface behavior compatible while extending return/detail
      handling.
- [x] Separate summary reads from authorized detail reads so the UI cannot
      accidentally request private fields for unassigned workers.
- [x] Add repositories/controllers through the existing `AppServices` wiring;
      do not add a second dependency-injection or state-management system.

### Phase FE-1 — Deterministic paired-row route planner

- [x] Build a pure-Dart route planner from the section’s cached tree coordinates
      and unique `tree_code` values.
- [x] Convert coordinates to a stable local plane, infer the dominant row axis,
      cluster physical rows using farm spacing, and sort trees along each row.
- [x] Anchor the first corridor and direction to tree code `001`, or the lowest
      existing planted tree number when `001` is absent.
- [x] Pair adjacent physical rows into corridors and pair nearest progress
      positions into left/right stations.
- [x] Reverse every following corridor to produce the snake route.
- [x] Emit one-sided stations for unmatched outside rows or unequal row lengths.
- [x] Validate that every tree appears exactly once and the start anchor exists.
- [x] Version the algorithm and serialize the complete immutable route snapshot
      in the create-inspection outbox operation.
- [x] Add a manager preview showing row lines, corridor arrows, station count,
      left/right sides, and the `001` starting point before creation.
- [x] Validate complete, unique, paired station routes for every planted A-G
      section against the canonical full-farm fixture. Section E shows a clear
      localized no-trees state and cannot create a route.
- [ ] Confirm the generated physical path for each planted section with farm
      staff before rollout.

### Phase FE-2 — Offline data and synchronization

- [x] Reuse the local SQLite key/value cache schema for issue
      summaries/details/events, inspection snapshots/items/observations,
      task-issue work items, and claims partitioned by farm and authorized user;
      no table-shape schema bump is required for these serialized records.
- [x] Never retain manager-only notes/photos in a cache later opened under an
      unrelated worker session.
- [x] Add outbox operation types for report/confirm, severity change, inspection
      create/start/pause/resume/save/submit, dismissal, resolve, unable to fix,
      and manager task creation/reassignment.
- [x] Give every mutation a stable UUID operation ID and preserve current replay
      behavior for older report/task operations.
- [x] Support local temporary inspection task/session IDs and dependency
      mapping so photos and later observations wait for their parent server
      IDs.
- [ ] Add equivalent dependency mapping if a future workflow creates
      provisional issue IDs; current report/confirm replay receives no local
      issue ID for dependent UI actions.
- [ ] Save a paired inspection station locally in one transaction before moving
      forward.
- [x] Queue photos through the existing pending-photo store and upload them
      before replaying operations that require their registered evidence.
- [x] Make inspection progress, previously assigned issue work, and resolution
      available with no network.
- [x] Disable self-claim while offline with a direct localized explanation; do
      not queue a misleading provisional claim.
- [x] Surface uniqueness, stale assignment, deleted task, and authorization
      failures in the existing Sync Center without losing the worker’s notes or
      prepared photos.
- [x] Refresh issue summaries, task links, and map/home counts after successful
      replay.

### Phase FE-3 — Issues workspace and existing entry points

- [x] Add `/issues` without adding a sixth navigation tab.
- [x] Add a Home active-issues card/action while preserving current section,
      tree, irrigation-zone, map, and QR content.
- [x] Add a Tasks shortcut/filter for inspections and issue-resolution tasks;
      preserve the current list/calendar switch and task cards.
- [x] Build manager issue filters for status, type, severity, section, age,
      assigned/unassigned, and inspection source.
- [x] Build the worker summary/claim queue from the limited summary contract.
- [x] Show active issue buckets and historical occurrences separately.
- [x] Add issue detail/history for authorized users with events, observations,
      linked tasks, evidence, and resolution state.
- [x] Add active issue summary and history to existing tree detail screen/sheet
      without removing report/create-task actions.
- [x] Keep the current quick report screen available from QR, tree detail, and
      map flows. Explain when a submission confirmed an existing bucket instead
      of creating a duplicate.

### Phase FE-4 — Map issue layer

- [x] Add active issue summaries to map state independently of tree/zone data.
- [x] Keep zone fill/color as the default tree marker appearance.
- [x] Draw an outer severity halo and compact count badge for trees with active
      issues; do not hide planting pits or change pit counts.
- [x] Add type/severity/status filters, fade nonmatches by default, and add the
      approved “show matching only” toggle.
- [x] Keep section chips, layer controls, focus, reset, zoom, full-screen mode,
      and task creation behavior unchanged.
- [x] Ensure tree/pit hit testing and details sheets open above both normal and
      full-screen map overlays.
- [x] Add accessible semantics for issue-marked trees and localized filter
      descriptions.

### Phase FE-5 — Inspection creation and field runner

- [x] Add manager creation from a section, the Issues workspace, and eligible
      task creation flows using the existing `tree_inspection` task type.
- [x] Require assignee, section, schedule/priority, review setting, and optional
      issue-photo requirement; show route preview before save.
- [x] Support offline creation from a cached hierarchy and queue the complete
      route snapshot for server validation.
- [x] Open assigned inspection tasks in a dedicated runner while preserving the
      normal task-detail route and activity/evidence history.
- [x] Present one walking station at a time with two independent left/right tree
      cards, or one card for a one-sided station.
- [x] Show tree code as the primary identity and retain section, source row/tree
      labels, issue badges, and coordinates as secondary context.
- [x] Preselect current active issues on each tree.
- [x] Require severity for every newly selected issue.
- [x] Show existing severity without changing it and require an explicit
      “Change severity” action before sending an update.
- [x] Saving selected existing issues records confirmation; deselecting them
      records not observed; an empty selection records no new issue.
- [x] Enforce task photo policy only for selected detection/confirmation
      observations.
- [x] Add Previous, Save and next, Pause, Resume, progress, pending-sync, and
      final review controls. Do not use device GPS.
- [x] Prevent final submission until every tree in the immutable snapshot has
      been handled.
- [x] Make all runner actions and prepared photos durable across process death,
      connectivity changes, and app restart; securely clear them on logout with
      the rest of the authenticated private cache.

### Phase FE-6 — Worker resolution flow

- [x] Allow an eligible worker to open an unassigned confirmed issue summary and
      claim it only while online.
- [x] Navigate a successful claim to its single-issue task/detail.
- [x] Show all explicitly linked issue work items in manager-created batch
      tasks, each with its own status and action controls.
- [x] Provide a Resolve action on each issue with optional notes and an
      optional photo unless the task requires it.
- [x] Provide Unable to fix with the approved fixed reasons, required notes for
      Other, and an optional photo.
- [x] Remove/avoid every Resolve all label, callback, menu item, repository
      method, and RPC contract.
- [x] Enable task completion only after every linked issue has individually been
      resolved/submitted or marked unable to fix.
- [x] Clearly distinguish resolved, awaiting engineer review, returned, and
      still-active/unable outcomes.
- [x] Reuse the existing review queue/detail UI, extending it with per-issue
      outcomes and preventing approval from affecting unrelated issues.

### Phase FE-7 — Localization, accessibility, and verification

- [x] Add English and Arabic copy for issue types, states, filters, claim
      conflicts, route preview, station sides, inspection outcomes, reason
      codes, photo requirements, and sync states.
- [x] Regenerate localization output and remove hard-coded domain labels from
      the new UI.
- [x] Verify RTL station sides semantically: physical left/right must not be
      accidentally reversed only because text direction changes.
- [ ] Add semantics, 48dp targets, scalable text, focus order, contrast, and
      reduced-motion behavior.
- [ ] Add unit tests for models, JSON, repositories, route generation, route
      serialization, permissions, filters, progress, and offline replay.
- [x] Test that each planted A-G route starts at `001` or its lowest existing
      planted number, snakes, pairs both sides, and includes every fixture tree
      exactly once despite duplicated row numbers.
- [ ] Add widget tests for Home, Tasks shortcut, Issues workspace, tree history,
      map halos/filter/full-screen sheets, route preview, paired runner,
      severity intent, no issue, individual Resolve, unable-to-fix, and reviews.
- [ ] Cover English/Arabic, RTL, narrow phones, tablets, loading/error/empty,
      offline, pending-sync, and authorization states.
- [ ] Add integration tests for quick report-to-confirmation, full inspection,
      online claim, offline assigned resolution, required review, returned work,
      and new occurrence after resolution.
- [x] Keep existing QR, quick report, task list/calendar, map, planting-pit,
      task lifecycle, review, cache, and sync tests passing.
- [x] Run formatting, localization generation, `dart analyze`, focused tests,
      and the full Flutter suite.

## Rollout validation matrix

Automated route evidence from the canonical full-farm fixture:

| Section | Trees | Walking stations | Automated result | Staff field walk |
| --- | ---: | ---: | --- | --- |
| A | 298 | 185 | Pass; starts at `TREE-A-001` | Pending |
| B | 330 | 176 | Pass; starts at `TREE-B-001` | Pending |
| C | 185 | 107 | Pass; starts at `TREE-C-001` | Pending |
| D | 303 | 161 | Pass; starts at `TREE-D-001` | Pending |
| E | 0 | 0 | Pass; creation blocked as an empty section | Not applicable |
| F | 351 | 192 | Pass; starts at `TREE-F-001` | Pending |
| G | 72 | 36 | Pass; starts at lowest planted `TREE-G-037` | Pending |

The checks below require real accounts, devices, or farm staff and therefore
remain deliberately unchecked after automated implementation:

- [x] Deploy `20260904094333_add_inspection_manager_takeover.sql` and
      `20260904120301_tighten_inspection_takeover_grants.sql`, refresh the
      API schema, and smoke-test owner/engineer takeover against the linked
      project at the migration/ACL level. A real signed-in role smoke test is
      tracked separately below.
- [ ] Confirm each planted route on the ground with a farm staff member,
      including corridor direction and the physical left/right labels.
- [ ] On a real phone, create and start an assigned inspection online, save a
      paired station, enable airplane mode, and continue for several stations.
- [ ] Force-close and reopen while offline; verify the exact station, selected
      issues, severities, notes, and prepared photos are restored.
- [ ] Reconnect and verify ordered replay, no duplicate bucket, task/issue/home
      count refresh, map halo refresh, and an empty Sync Center.
- [ ] Claim one confirmed issue online, then resolve or mark each task issue
      Unable to fix separately while offline and replay on reconnect.
- [ ] Approve and return individual resolution outcomes as an engineer; verify
      unrelated active issues on the same tree remain unchanged.
- [ ] Repeat the critical runner and map flow in Arabic at 100% and 200% text
      scale, checking physical sides, focus order, labels, and 48dp targets.
- [ ] Verify worker-safe summary access and accountant denial with real remote
      accounts before distributing the Flutter build.

## Rollout sequence

1. Complete backend schema/RPC tests locally without deploying.
2. Implement Flutter models, repositories, cache, and route planner against the
   local backend.
3. Validate route previews for every planted A-G section with farm staff.
4. Finish issue workspace/map, inspection runner, and resolution UI.
5. Run the complete local backend and Flutter regression suites.
6. Deploy additive backend migrations first and verify grants, RLS, RPCs,
   advisors, and active-duplicate preflight remotely.
7. Release the compatible Flutter build after the backend contract is live.
8. Pilot one section and one worker through online claim, offline inspection,
   offline resolution, reconnect, and engineer review.
9. Review the pilot audit timeline and route accuracy before enabling all
   sections.

Backend additions must be compatible with the currently released app during
the staggered deployment. Do not deploy a changed RPC result shape or required
parameter before the compatible Flutter build is ready.

## Acceptance criteria

1. The seven current issue types and all old app features remain available.
2. Concurrent detections produce one active tree/type bucket and multiple audit
   events, not duplicate active issue rows.
3. Confirmation never changes severity without explicit user intent.
4. “No issue” and “not observed” never close an active issue.
5. Detection approval opens/confirms an issue; only resolution approval or an
   authorized immediate Resolve action closes it.
6. Owners/engineers, reporters, assigned workers, other workers, accountants,
   and cross-farm users receive exactly the approved visibility.
7. A section route starts at tree code `001`, or the lowest planted tree number
   when `001` is absent, snakes through paired physical rows, and includes every
   tree exactly once.
8. One inspector can complete the saved snapshot offline from start through
   submission, including optional/required photos.
9. Workers can self-claim one confirmed issue online, while assigned issue work
   remains usable offline.
10. Every issue in a task is acknowledged separately. No Resolve all action or
    broad resolution update exists.
11. Resolve respects `requires_engineer_review`; Unable to fix keeps the issue
    active and records the approved reason.
12. Issue halos and filters work in normal/full-screen maps without breaking
    tree or pit selection/details.
13. Home, Tasks list/calendar, QR report, tree detail, review queue, and offline
    Sync Center continue to work in English and Arabic.
14. Local/remote database verification, RLS/grant tests, concurrency tests,
    static analysis, and Flutter regression tests pass before full rollout.

## Explicitly out of scope

- Adding, removing, or splitting issue types.
- Migrating or merging historical issue records.
- Removing the current quick report or task workflows.
- GPS-based inspector tracking or automatic location progression.
- Multiple people simultaneously editing one inspection session.
- Automatic resolution based on “No issue” or “not observed.”
- Offline provisional self-claim with first-sync-wins behavior.
- Automatic claim expiry while assigned workers may be offline.
- Resolve all, tree-wide resolution, or filter-wide resolution.
- Treating planting pits as trees or including empty-section pits in tree
  inspection sessions.
