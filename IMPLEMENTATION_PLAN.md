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
`dart format --set-exit-if-changed .` reports 43 files and 0 changes;
`flutter analyze` reports no issues; all 28 unit/widget/golden tests pass; and a
Chrome debug launch connects successfully. The Xcode 14.2 iOS simulator build also
passes and the app renders on an iPhone 14 Pro Max simulator. Phase 1 is complete.

## Phase 2 — Supabase domain foundation (in progress)

- [ ] Add immutable models for profile, membership, farm, section, zone, tree, task,
  issue, activity, photo, and review. Profile, membership, and farm context models are
  implemented; remaining operational models are pending.
- [ ] Add repository interfaces, Supabase services, cache boundary, and deterministic
  fakes. Auth bootstrap service/repository and fakes are implemented; caching remains.
- [x] Implement auth bootstrap and role capability policy, including intentional
  profile-missing, inactive-profile, no-operational-membership, loading, retry, and
  failure states.
- [ ] Query active profile, memberships, selected farm, 12 sections, zones, and trees.
- [ ] Add repository and exact RPC payload-contract tests.
- [ ] Keep live credentials optional and production fixtures isolated from providers.

Gate: authenticated context resolves role/farm and 12/120/1,567 against live backend,
or 12/1,567 with the isolated fixture while the unverified live 120-zone gate remains
clearly reported.

Evidence (2026-07-12): authenticated routes now resolve the signed-in profile and all
active operational memberships before showing the app shell; the profile screen uses
the resolved name, role, and farm. Five new repository/controller tests pass. Full
suite: 28 tests; formatter: 43 files, 0 changed; analyzer: no issues. Authenticated
live-data and 120-zone verification remain pending.

## Phase 3 — Coordinate map

- [ ] Copy canonical JSON to `assets/data/al_wahat_map_data.json`.
- [ ] Implement parser, projection, precomputed paths/points, and spatial hit index.
- [ ] Implement custom painter with exact layer order and styles.
- [ ] Add pan/zoom/reset, section fit, filters, layer toggles, and selection.
- [ ] Reconcile live trees by UUID then code and expose discrepancy diagnostics.
- [ ] Add count, projection, hit-test, painter, filter, and selection tests.
- [ ] Profile map responsiveness and isolate painter in `RepaintBoundary`.

Gate: exact counts render, known trees in A/B/C/D/F/G select, unplanted sections remain,
and controls/tests pass.

## Phase 4 — Tree selection, QR, and issues

- [ ] Implement draggable tree sheet and routed detail.
- [ ] Integrate camera permissions and `mobile_scanner` with `scan_tree_by_qr`.
- [ ] Implement enum-backed issue form and image preparation/upload progress.
- [ ] Resolve the audited issue-photo RPC sequencing defect with a new migration only
  if backend change is authorized by the verified defect.
- [ ] Implement `report_tree_issue` and refresh issue/task/review providers.
- [ ] Add happy, validation, permission, offline, authorization, and upload-failure tests.

Gate: real test token opens the correct tree; issue creates persisted issue and task;
optional evidence works through a safe verified contract.

## Phase 5 — Tasks

- [ ] Implement role-filtered task list, detail, and immutable activity history.
- [ ] Implement all-scope create form and `create_farm_task`.
- [ ] Implement assignment editing through `set_task_assignments`.
- [ ] Implement start/complete transitions and evidence uploads/metadata.
- [ ] Add validation, RPC contract, refresh, transition, and persistence tests.

Gate: created task survives restart, appears for assignee, transitions correctly, and
records evidence/activity.

## Phase 6 — Engineer/owner review

- [ ] Implement role-gated queue and review detail with linked issue/evidence.
- [ ] Call `review_task` for approve, return, and follow-up.
- [ ] Refresh task, activity, review, and issue state after decisions.
- [ ] Test capabilities and backend authorization translation, including worker denial.

Gate: manager decisions persist and worker cannot review at either UI or RPC boundary.

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
