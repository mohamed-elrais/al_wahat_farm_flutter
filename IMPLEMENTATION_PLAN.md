# Al Wahat Farm Flutter Implementation Plan

Only one phase is in progress at a time. A phase is checked only after its gate is
verified; partial implementation remains explicitly unchecked.

## Phase 0 — Reference audit and baseline

- [x] Locate and inspect required React, CSS, map JSON, and generator files.
- [x] Inspect existing Flutter sources, tests, package configuration, and repo state.
- [x] Inspect all Supabase migrations and resolve the final tree-based contracts.
- [x] Validate 12 sections, exact per-section counts, and 1,567 trees.
- [x] Attempt and record baseline tests and analyzer result.
- [x] Create `REFERENCE_AUDIT.md`.
- [x] Create `FIDELITY_CHECKLIST.md`.
- [x] Record architecture decisions and verified backend/data discrepancies.

Evidence: `REFERENCE_AUDIT.md`. The data gate passes. The local Flutter 3.13.9 SDK was
not modified. Final compatibility verification uses that declared Flutter 3.13.9 /
Dart 3.1.5 toolchain; the previously downloaded isolated SDK remains separate.

## Phase 1 — App shell and design system

- [x] Establish an isolated working Flutter/Dart toolchain without modifying the local
  Flutter 3.13.9 installation.
- [x] Update dependency constraints and declare current production packages.
- [x] Bundle authentic variable Inter and Libre Baskerville TTFs and exact immutable
  design tokens; no runtime font download is required.
- [x] Add themed card/button/sheet/top-bar/navigation primitives.
- [x] Configure Supabase from `--dart-define` with committed empty example only.
- [x] Implement router, splash/session redirect, login, and five-tab shell.
- [ ] Resolve profile/membership state and route inactive accounts. This is the first
  Phase 2 auth-bootstrap item because it depends on the domain/repository foundation.
- [x] Implement phone/tablet responsive breakpoints for Home and Map foundations.
- [x] Add login/session and five-destination navigation widget tests.
- [x] Add login, phone-shell, and focused top-bar goldens using the bundled fonts.
- [x] Inspect Phase 1 390x844 phone goldens against the reference language. The login,
  warm grid, serif/sans hierarchy, navigation proportions, and branded top bar pass the
  Phase 1 visual check; broader breakpoint certification remains Phase 8.

Additional staged foundation now verified by tests: the canonical asset, strict map
parser, reference projection, precomputed painter geometry, deterministic spatial
index, layer toggles, section filter/fit, scanner RPC call, task/issue payload models,
and related unit/widget tests. These do not complete Phases 2–4 by themselves.

Gate evidence (2026-07-12): after the authorized Flutter 3.13 compatibility pass,
dependency resolution passes on Flutter 3.13.9 / Dart 3.1.5;
`dart format --set-exit-if-changed .` reports 84 files and 0 changes;
`flutter analyze` reports no issues; all 65 default unit/widget/golden/fake-integration
tests pass; and a
Chrome debug launch connects successfully. The Xcode 14.2 iOS simulator build also
passes and the app renders on an iPhone 14 Pro Max simulator. Phase 1 is complete.

## Phase 2 — Supabase domain foundation

- [x] Add immutable models for profile, membership, farm, section, zone, tree, task,
  assignment, issue, activity, photo, and review using the final tree columns/enums.
- [x] Add repository interfaces, Supabase data sources, an explicit hierarchy cache
  boundary, and deterministic test fakes. Persistent offline storage remains Phase 7.
- [x] Implement auth bootstrap and role capability policy, including intentional
  profile-missing, inactive-profile, no-operational-membership, loading, retry, and
  failure states.
- [x] Query active profile, memberships, selected farm, sections, zones, and paginated
  active trees. The authenticated shell waits for this hierarchy before rendering.
- [x] Add repository, parsing, query-column, and exact RPC payload-contract tests.
- [x] Keep public project configuration optional and canonical fixtures isolated under
  `test/`; no fake operational rows are wired into production providers.

Gate: authenticated context resolves role/farm and 12/122/1,567 against the live
backend, or 12/1,567 with the isolated fixture while any live zone-count discrepancy
remains clearly reported.

Evidence (2026-07-13): authenticated routes resolve the active profile/memberships and
then load the selected farm's active sections, zones, and trees before showing the app
shell. Tree reads page in 1,000-row chunks so 1,567 rows cannot be silently truncated.
The isolated canonical fixture passes 12 sections and 1,567 UUID trees and reports the
known asset-only 56-zone-ID discrepancy. A disposable authenticated owner account also
passed the live RLS gate and returned 12 active sections, 1,567 active trees, and 122
active irrigation zones. The farm operator confirmed that 122 is the authoritative
count, superseding the earlier 120-zone requirement; no live rows required changes.
Default suite: 65 passed and 3 opt-in live tests skipped; formatter: 84 files, 0
changed; analyzer: no issues. The explicitly configured live suite verifies the
RLS/12-section/122-zone/1,567-tree gate and a real active QR token. Phase 2 is complete
under both the isolated fixture alternative and authenticated live verification.

## Phase 3 — Coordinate map

- [x] Copy canonical JSON to `assets/data/al_wahat_map_data.json`.
- [x] Implement parser, projection, precomputed paths/points, and spatial hit index.
- [x] Implement custom painter with reference layer order and styles.
- [x] Add pan/zoom/reset, section fit, filters, layer toggles, and selection.
- [x] Reconcile live trees by UUID then code, retain unmatched canonical geometry,
  never fabricate unexpected live rows, and expose manager-only diagnostics.
- [x] Add count, projection, reconciliation, hit-test, painter structure, filter,
  layer-toggle, and planted-section selection tests.
- [ ] Capture profile-mode map performance on a physical device. Painter isolation in
  `RepaintBoundary`, 1024-wide tablet structure, and a real iPhone-simulator debug
  pan flow with all 1,567 points pass. Flutter 3.13 does not support iOS profile builds
  for simulators, and no physical iPhone is available to Codex.

Gate: exact counts render, known trees in A/B/C/D/F/G select, unplanted sections remain,
and controls/tests pass.

Evidence (2026-07-13): UUID-first/code-second reconciliation passes exact-match,
ID-mismatch, missing/unexpected, and coordinate-drift tests. A known tree in every
planted section is deterministically selected; the single painter owns 1,567 points,
is inside a `RepaintBoundary`, and independent layer state passes at the tablet
breakpoint. The iPhone 14 Pro Max simulator integration flow builds, launches, pans the
complete map twice, and passes. A profile attempt genuinely failed at Flutter 3.13's
physical-device-only iOS AOT boundary, so Phase 3 remains in progress for that evidence.

## Phase 4 — Tree selection, QR, and issues

- [x] Implement reusable draggable tree sheet and routed live-tree detail, including
  manager-only task action and issue reporting for operational users.
- [x] Integrate existing camera permissions and `mobile_scanner` with a typed
  `scan_tree_by_qr` repository. A read-only live test resolves a real active token to
  the same live tree without logging the token.
- [x] Implement enum-backed issue form, JPEG preparation, private scoped upload stages,
  honest partial-success state, cleanup attempt, and safe photo retry.
- [x] Resolve the audited issue-photo RPC sequencing defect in the separate Supabase
  repository. This Flutter repository treats its copied `supabase/` directory as
  read-only schema reference material. The scoped, authenticated, idempotent
  `add_tree_issue_photo` RPC is implemented and locally verified in the owning
  repository; remote deployment remains separately controlled there.
- [ ] Implement `report_tree_issue` and refresh issue/task/review providers. The RPC,
  exact result parsing, post-commit invalidation hook, and fake persistence flow are
  implemented; concrete task/review providers arrive in Phases 5–6.
- [x] Add happy, validation, role/authorization, offline, upload-failure, duplicate-
  submission, tree-sheet, scanner, and fake-backed worker-flow tests.

Gate: real test token opens the correct tree; issue creates persisted issue and task;
optional evidence works through a safe verified contract.

Evidence (2026-07-13): 16 new Phase 4 tests pass within the 65-test default suite, and
the 3-test authenticated live suite passes hierarchy, authoritative counts, and a real
QR lookup. The worker scan → report flow is deterministic and fake-backed so it does
not create operational records. The authoritative Supabase repository reports a clean
reset, 13 passing pgTAP assertions, migration listing, database advisors, and database
lint for `20260713080541_add_tree_issue_photo_rpc.sql`; the copied SQL here is read-only
evidence. It has not been remotely deployed. Real camera/gallery capture is also
hardware-only evidence. Phase 4 remains in progress for live deployment/integration,
real-device capture, and the provider work explicitly deferred to Phases 5–6.

## Phase 5 — Tasks

- [x] Implement role-filtered task list, detail, and immutable activity history.
- [x] Implement all-scope create form and `create_farm_task`.
- [x] Implement assignment editing through `set_task_assignments`.
- [x] Implement start/complete transitions and evidence uploads/metadata.
- [x] Add validation, RPC contract, refresh, transition, and persistence tests.

Gate: created task survives restart, appears for assignee, transitions correctly, and
records evidence/activity.

Evidence (2026-07-13): the authenticated shell owns a shared paginated task workspace;
the Home and Tasks views consume repository refreshes rather than temporary cards. The
manager form covers farm/section/zone/tree scope, active operational assignees, schedule,
priority, duration, instructions, and review requirements. Detail actions call only the
declared lifecycle RPCs, reload persisted detail/activity, and preserve evidence state
across an unconfirmed completion response so a retry cannot upload twice. The private
evidence path and metadata contracts are exact. A shared-store integration test creates
and assigns a tree task, reconstructs the worker workspace to simulate restart, starts
and completes it, and verifies the persisted activity/photo metadata. The Flutter 3.13.9
default suite passes 81 tests with 5 opt-in live checks skipped; the separate configured
read-only Supabase suite passes all 4 hierarchy/count/QR/task checks.

Gate evidence (2026-07-13): with explicit operator authorization, the opt-in live suite
created one clearly labeled persistent tree task through `create_farm_task`, assigned an
active real worker through `set_task_assignments`, started it, uploaded valid private
Storage evidence, registered it through `add_task_photo`, and completed it. A new
repository instance found the completed task after reload and verified its active worker
assignment, private photo metadata, and created/assigned/started/photo-added/completed
activity history. The test uses a fixed title and resumes the same row, preventing repeat
runs from creating duplicate tasks. It passed on the first run. No Supabase migration or
copied schema file was changed. Phase 5 is complete.

## Phase 6 — Engineer/owner review

- [x] Implement role-gated queue and review detail with linked issue/evidence.
- [x] Call `review_task` for approve, return, and follow-up.
- [x] Refresh task, activity, review, and issue state after decisions.
- [x] Test capabilities and backend authorization translation, including worker denial.

Gate: manager decisions persist and worker cannot review at either UI or RPC boundary.

Evidence (2026-07-13): the reviews feature adds a role-gated queue that lists only
`needs_engineer_review` tasks, and a review detail that shows the task summary, a linked
tree-issue indicator, registered evidence, prior review decisions, and the three review
actions. The `ReviewController` records decisions through the `review_task` contract and
reloads task detail plus the review list, then refreshes the shared workspace; the linked
tree issue's status transition is performed server-side by the RPC. The client mirrors the
authoritative SQL exactly: approved → `approved` (sets `approved_by/at`), returned →
`returned`, follow-up → stays `needs_engineer_review`; activity logs `reviewed_approved`
for approvals and `reviewed_returned` otherwise. Worker denial is proven at both boundaries:
a capability widget test shows a worker the restricted card with no action buttons, and a
repository unit test translates the RPC's `42501` into an authorization failure (the same
denial a worker hits at the RLS boundary). The Flutter 3.13.9 default suite passes 99 tests
with 6 opt-in live checks skipped; formatter reports 107 files and 0 changes; analyzer
reports no issues. An opt-in `live_review_lifecycle_test.dart` (gated on
`RUN_LIVE_REVIEW_MUTATION=true`) drives a persistent task through completion and approval
against the deployed `review_task`; it is skipped by default and has not been executed here,
so the live persistence gate remains opt-in like the Phase 4/5 live suites. The copied
`review_task` SQL in `supabase/` is read-only reference material and was not changed.

## Phase 7 — Offline, accessibility, and production hardening

- [ ] Cache farm hierarchy, trees, task list, and task detail.
- [ ] Add visible online/offline/sync state and conservative mutation rules.
- [ ] Verify image orientation/compression, upload cleanup, and privacy-safe logging.
- [ ] Add semantic labels, 44 dp targets, text-scale and reduced-motion behavior.
- [ ] Verify logout clears private cached data.

Gate: required cached reads, privacy, accessibility, and logout tests pass.

## Phase 8 — Fidelity certification

- [ ] Generate/inspect 390×844 and 430×932 phone screenshots.
- [ ] Generate/inspect a common Android phone screenshot.
- [ ] Generate/inspect 1024×1366 tablet screenshot.
- [ ] Compare tokens, type, radii, borders, spacing, navigation, map layer order,
  selected-tree sheet, forms, and async states.
- [ ] Create `FIDELITY_REPORT.md` with all known mismatches.
- [ ] Run formatter, analyzer, unit/widget/golden tests, and integration flows.

Gate: all definition-of-done items are evidenced or explicitly listed as remaining;
completion is never claimed with an unverified item.

## Architecture decisions

- Feature-first presentation (`features/<name>/`) with shared app/core infrastructure.
- Lean widgets consume immutable controller state behind repository interfaces.
- Repository interfaces isolate Supabase and local caching; services own raw SDK calls.
- Optional domain/use-case classes only for reusable transformation, projection,
  reconciliation, hit testing, task transitions, and sync rules.
- No code generation until it offers clear type-safety value beyond hand-written models.
- No service-role key, direct RPC-equivalent writes, permanent fake production data, or
  unsafe offline mutation queue.
