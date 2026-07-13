# Al Wahat Farm Reference Audit

Audit date: 2026-07-12  
Phase: 0 — reference audit and baseline  
Reference web source: `reference_web_app/`  
Database source: all eight SQL files in `supabase/migrations/`

## Gate result

- [x] Required web files are present and inspected:
  - `reference_web_app/app/page.tsx`
  - `reference_web_app/app/globals.css`
  - `reference_web_app/public/map-data.json`
- [x] Map generator inspected: `reference_web_app/scripts/generate-map-data.mjs`.
- [x] All existing Flutter source, tests, package configuration, and repository instructions inspected.
- [x] Every migration under `supabase/migrations/` inspected in chronological order.
- [x] Reference data confirms exactly 12 sections and 1,567 trees.
- [x] Final database vocabulary is the tree-based model introduced by
  `20260708233205_rename_palm_to_tree_model.sql`.

Phase 0's reference-count gate passes. The original local Flutter 3.13.9 / Dart 3.1.5
baseline could not start in the restricted Codex CPU sandbox and was not modified.
Subsequent isolated-toolchain results are recorded in [Baseline verification](#baseline-verification).

## Existing repository baseline

The Flutter project is the stock counter template:

- one production file, `lib/main.dart`;
- one counter widget test, `test/widget_test.dart`;
- Flutter's default Material theme and no app architecture;
- no Supabase, routing, state-management, scanner, image, connectivity, cache, or
  local-database dependencies;
- no declared application assets or bundled application fonts.

The reference web project, Supabase migrations, `.agents/`, and `skills-lock.json`
were present as untracked user content at audit start. The web project was supplied as
`reference_web_app/Al-Wahat-Farm-test.zip`; it was extracted in place so the required
paths could be inspected. These sources must remain intact.

## Reference screens and overlays

The web prototype is one React screen, so several of the required Flutter routes are
new production workflows rather than existing prototype screens. The reusable visual
and interaction specification consists of:

| Reference surface | Content and behavior | Flutter translation |
|---|---|---|
| Sticky top bar | Palm mark, Al Wahat wordmark, role preview, notifications, avatar/name | Compact branded phone top bar; role comes from membership in production |
| Intro/summary panel | Date eyebrow, hero, lede, orange scan action, map totals | Role-aware Home hero and phone summary cards |
| Coordinate farm map | Section filters, zoom in/out/reset, layer menu, SVG geometry and clickable tree circles | Full routed map using one `CustomPainter` and transformation controller |
| Tree inspector | Identity, section, row/tree number, health, type, coordinates, task/issue actions | Draggable phone bottom sheet plus routed Tree Detail |
| Today's tasks | Role-specific simulated cards, status, time, manager create/worker report action | Persisted role-filtered task list and task routes |
| Weather | Current weather plus four-day simulated forecast | Clearly labelled isolated mock until a provider is configured |
| Farm insight | Changes to selected tree summary | Selected-tree/farm insight card |
| QR modal | Scan framing and simulated `TREE-B-120` result | Routed `mobile_scanner` camera flow using `scan_tree_by_qr` |
| Create-task modal | Title, free-text target, assignee, priority, date, instructions | Large mobile sheet with the complete RPC-backed task form |
| Report-issue modal | Tree, category, severity, observation, photo | Large mobile sheet with enum-backed fields and private evidence upload |
| Toast | Timed success messages | Accessible app feedback/snackbar wrapper |
| Mobile navigation | Home, Map, raised Scan, Tasks, More | Fixed five-destination application shell |

Required routed Flutter screens absent from the prototype but mandated by the product
brief are Splash/session restoration, Login, Home, Map, Scanner, Tree Detail, Create
Task, Report Issue, Today/All Tasks, Task Detail/history, Complete Task/evidence,
Review Queue, Review Detail, and More/Profile/sync state.

## Design system audit

### Immutable color tokens

| Token | Value | Reference use |
|---|---|---|
| `paper` | `#F8F4E9` | App background |
| `card` | `#FFFDF7` | Cards, controls, sheets |
| `ink` | `#173D28` | Primary type and dark navigation |
| `green` | `#285C36` | Selection and actions |
| `orange` | `#CC6637` | Scan, alerts, field emphasis |
| `muted` | `#6E7168` | Supporting text |
| `line` | `#E5DCC8` | Warm borders and dividers |
| `softGreen` | `#E8EFDE` | Selected/positive surfaces |
| `sand` | `#E8D6AE` | Map ground |
| `road` | `#B9A47D` | Road geometry |
| `issue` | `#B65535` | Issue/destructive emphasis |

The page adds warm secondary neutrals around these tokens and uses low-opacity green
and brown shadows. The background is a 28 px square green grid at 3.5% opacity.

### Typography

- Body, labels, controls, metadata, buttons, and numeric UI: Inter-like sans serif.
- Major headings and prominent values: Georgia in the web reference; Flutter must
  bundle Libre Baskerville or an equivalent Georgia-like serif.
- Eyebrows: compact uppercase, bold, approximately 0.15 em tracking.
- Hero: serif, tight line height and tracking, with green emphasis and a short orange
  underline.
- Runtime font downloading is forbidden. Font files are not currently present and
  must be bundled during Phase 1.

### Shape, spacing, and elevation

- Main cards use 16–22 dp radii, 1 dp warm sand borders, and very soft shadows.
- Controls use approximately 9–13 dp radii.
- Scan actions use an orange gradient and a larger 18 dp radius.
- Pills/chips use compact insets and selected green fill.
- Phone bottom navigation is dark green, rounded (about 19 dp), inset from edges, with
  a raised orange circular center action.
- Modal surfaces use a dark green translucent/blurred backdrop and 22–24 dp rounding.
- Minimum interactive target in Flutter is 44 dp even where the visual mark is smaller.

### Responsive behavior

- Above roughly 1260 CSS px: three regions — 238 px summary, dominant map, 330 px
  task/weather rail.
- Intermediate widths: two regions with the right rail moved below.
- At 820 px and below: one-column phone flow, fixed bottom navigation, horizontal
  section filters, and the selected-tree inspector fixed above navigation.
- The required Flutter tablet composition should preserve this hierarchy, while the
  phone implementation is a routed mobile product rather than the entire dashboard
  stacked into one scroll view.

## Interaction and state matrix

| Surface | Loading | Empty | Success/selected | Error/offline | Authorization |
|---|---|---|---|---|---|
| Session bootstrap | Branded splash | Signed-out routes to Login | Profile, membership, farm, role resolved | Retry and cached/offline status | Inactive profile/membership block screen |
| Home | Skeleton sections | No tasks/insight guidance | Role-aware task and farm summaries | Cached badge and retry | Manager actions absent for worker, backend errors still handled |
| Farm map | Geometry loader | Geometry remains; no-tree warning | Section filtering, fit, zoom/reset, layers, tree sheet | Immutable asset still renders; live-data warning | Operational members can view; RLS is final authority |
| Scanner | Camera permission/loading | No result yet | Exact tree opens | Permission, malformed/unknown token, offline retry | RPC may return no visible tree |
| Tree detail | Detail refresh | Not-found/inactive state | Full identity and context | Cached asset/live discrepancy warning | Attach task manager-only; issue action operational roles |
| Tasks | Refresh indicator | Role-specific empty message | Persisted list/detail/activity | Cached state and retry | Worker sees active assignments; manager sees farm operations |
| Create task | Members/targets loading | No valid assignee guidance | RPC succeeds, providers refresh | Inline retry without fake local task | Friendly translation of `42501`/RLS errors |
| Complete task | Evidence preparation/upload | Evidence optional unless policy says otherwise | Photo metadata + completion RPC reflected | Upload cleanup; unsafe mutation waits for connectivity | Active assignee or manager only per backend helper |
| Report issue | Tree preselected | Tree required | RPC returns both issue and review-task IDs | Upload/RPC failures retain form safely | Active operational farm member only |
| Reviews | Queue refresh | No work awaiting review | Approve/return/follow-up refreshes task and issue | Retry and cached evidence metadata | Owner/engineer only; worker denial tested |
| More/Profile | Profile/session loading | No farm guidance | Logout clears private cache | Sync state visible | Inactive state and role shown, never impersonated |

## Exact map data audit

### Projection contract

- Logical canvas: `820 × 880`.
- Padding: `24` logical units.
- Longitude is corrected by `cos(midLatitude)`.
- One common scale fits corrected longitude and latitude spans.
- Projection:
  - `x = offsetX + (longitude - minLongitude) * cos(midLatitude) * scale`
  - `y = offsetY + (maxLatitude - latitude) * scale`
- Section fit in the prototype uses the projected polygon bounds and 45 logical units
  of padding.

### Bounds and counts

| Fact | Audited value |
|---|---:|
| Minimum longitude | 28.747598 |
| Maximum longitude | 28.754600 |
| Minimum latitude | 28.293348 |
| Maximum latitude | 28.300016 |
| Sections | 12 |
| Planted sections | 6 |
| Trees | 1,567 |
| Distinct irrigation-zone UUIDs referenced by tree rows | 56 |
| Live active irrigation zones | 122 |

The asset has no standalone irrigation-zone collection. Therefore the irrigation-zone
total cannot be derived or validated from `map-data.json`; it must come from the live
`irrigation_zones` table. The reference UI hardcodes the stale value `120`. An
authenticated RLS-scoped query on 2026-07-13 returned 122 active zones, and the farm
operator subsequently confirmed 122 as the authoritative product count.

| Section | Trees | Planted | Area (m²) | Polygon points |
|---|---:|:---:|---:|---:|
| A | 298 | Yes | 20,185.34 | 11 |
| B | 330 | Yes | 23,084.08 | 5 |
| C | 168 | Yes | 18,407.70 | 5 |
| D | 303 | Yes | 20,007.35 | 6 |
| E | 0 | No | 16,837.10 | 13 |
| F | 360 | Yes | 24,317.17 | 5 |
| G | 108 | Yes | 26,960.12 | 5 |
| L | 0 | No | 24,052.51 | 5 |
| M | 0 | No | 17,202.08 | 8 |
| N | 0 | No | 16,202.77 | 12 |
| O | 0 | No | 12,341.07 | 10 |
| Q | 0 | No | 20,065.29 | 9 |

### Immutable geometry inventory

- Layout (7): farm boundary, main road, internal roads A–D, shared multi-purpose area.
- Utilities (12): four water tanks, mosque, two worker houses, pump/electrical control
  room, warehouse, owner rest house, house solar array, and pump solar array.
- Water network (11): one mainline and ten named submains.
- Each tree contains `id`, `code`, `section`, `zoneId`, `row`, `number`, `lat`, `lng`,
  `health`, `type`, and zone `color`.
- The generator reads the source KMZ/KML plus section and 1,567-tree CSV exports; it
  does not fabricate points.

### Reference render order and radii

1. Sand and subtle grid.
2. Farm boundary.
3. Roads and shared area.
4. Twelve section polygons.
5. Irrigation mainline and submains.
6. Utilities.
7. Section labels.
8. Trees.
9. Selected-tree highlight/overlays.

Tree radii are 2.7 logical units in overview, 4.4 in a filtered section, and 6.8 for
selection with a strong white outline. Flutter hit testing must use nearest eligible
projected point and an approximately 44 dp phone tolerance, not widget-per-tree taps.

## Final Supabase contract after all migrations

### Tables

| Area | Final public tables |
|---|---|
| Identity/farm | `profiles`, `farms`, `farm_memberships`, `farm_sections`, `irrigation_zones` |
| Trees | `trees`, `tree_qr_codes` |
| Work | `tasks`, `task_assignments`, `task_activity_log`, `task_photos` |
| Issues/review | `tree_issues`, `engineer_reviews` |
| Planning | `operation_plans`, `operation_plan_targets`, `operation_plan_runs`, `operation_task_generation_logs` |

`trees` has the final columns `tree_number`, `tree_id` references elsewhere, and a
non-null `type` text column defaulting to `medjool`. `farms.palm_variety` was removed.
The final 12-section bootstrap codes are A, B, C, D, E, F, G, L, M, N, O, and Q.

### Final enums relevant to the MVP

- `farm_role`: owner, agricultural_engineer, worker, accountant.
- `tree_health_status`: healthy, needs_monitoring, needs_engineer_review, inactive.
- `task_type`: irrigation, fertilization, harmful_weed_control,
  dripper_maintenance, tree_inspection, engineer_review, general.
- `task_status`: draft, assigned, in_progress, completed, needs_engineer_review,
  approved, returned, cancelled.
- `task_priority`: low, medium, high, urgent.
- `tree_issue_type`: insufficient_irrigation, clogged_dripper,
  leak_or_dripper_damage, harmful_weed, pest_or_disease, tree_damage, other.
- `issue_severity`: low, medium, high, urgent.
- `tree_issue_status`: open, in_review, resolved, dismissed.
- `engineer_review_decision`: approved, returned_for_correction,
  follow_up_required.
- `task_photo_type`: before, after, evidence, issue, review.

### Required final RPC signatures

```text
scan_tree_by_qr(p_qr_token uuid)
  -> tree_id, farm_id, section_id, section_code, section_name,
     irrigation_zone_id, tree_code, row_number, tree_number,
     health_status, type

create_farm_task(
  p_farm_id, p_task_type, p_title, p_description, p_section_id,
  p_irrigation_zone_id, p_tree_id, p_scheduled_for,
  p_planned_start_time, p_planned_duration_minutes, p_due_at,
  p_priority, p_instructions, p_requires_engineer_review,
  p_related_tree_issue_id, p_assignee_profile_ids
) -> uuid

set_task_assignments(p_task_id uuid, p_assignee_profile_ids uuid[]) -> void
start_assigned_task(p_task_id uuid, p_note text) -> void
complete_task(p_task_id uuid, p_note text,
  p_requires_engineer_review boolean) -> void
report_tree_issue(p_tree_id uuid, p_issue_type tree_issue_type,
  p_severity issue_severity, p_description text,
  p_photo_storage_path text) -> (tree_issue_id uuid, task_id uuid)
add_task_photo(p_task_id uuid, p_storage_path text,
  p_photo_type task_photo_type, p_caption text) -> uuid
add_tree_issue_photo(p_tree_issue_id uuid, p_storage_path text,
  p_caption text) -> uuid
review_task(p_task_id uuid, p_decision engineer_review_decision,
  p_notes text, p_photo_storage_path text) -> uuid
get_operation_plan_calendar(p_farm_id uuid, p_start_date date,
  p_end_date date) -> calendar rows
```

The client must use these final parameter names. Earlier palm-named RPCs are dropped.

### Roles, RLS, and transitions

- Operational members are owner, agricultural engineer, and worker; accountant is
  not included by operational helper functions.
- Owners/engineers are operational managers and may create/assign/review work.
- Workers can see and operate only actively assigned tasks. Managers can see/operate
  all farm tasks.
- Start accepts `assigned` or `returned` and moves to `in_progress`.
- Complete accepts `assigned`, `in_progress`, or `returned`; it moves to `completed`
  or `needs_engineer_review`.
- Review accepts `completed` or `needs_engineer_review`; decisions map to `approved`,
  `returned`, or `needs_engineer_review`.
- Task and issue writes are RPC-only for authenticated clients; reads are governed by
  RLS. The app must translate PostgreSQL `42501` authorization errors clearly.

### Evidence storage

- Private bucket: `farm-evidence`.
- Maximum size: 10 MiB.
- Allowed MIME types: JPEG, PNG, WebP.
- Required metadata/RPC path: `{auth_user_uuid}/{farm_id}/{task_id}/{filename}`.
- Users upload/delete within their own top-level folder; authorized viewers read
  registered task-photo paths through RLS.

### Verified backend workflow gap and external resolution

The optional issue-photo flow is not currently satisfiable in one call for a worker:

1. `report_tree_issue` creates the review task internally, so its `task_id` is unknown
   before the RPC returns.
2. The same RPC validates `p_photo_storage_path` against a path containing that new
   task ID.
3. Uploading after a no-photo report and then calling `add_task_photo` is not a general
   worker workaround because the generated review task has no active worker assignment,
   while `add_task_photo` requires `private.can_operate_task`.

The separate, authoritative Supabase repository implements this as
`20260713080541_add_tree_issue_photo_rpc.sql`: an authenticated,
reporter-or-manager-only, idempotent second step after the issue RPC returns its task
ID. Its reported verification is a clean database reset, 13 passing pgTAP assertions,
a matching local migration listing, no advisor findings, and no schema lint errors.
The client reports first without a photo path, uploads to the exact user/farm/task
path, and then registers the uploaded object. An ambiguous registration retry reuses
that same path so the idempotent RPC can safely return the existing UUID. It never
fabricates a task ID or weakens path validation. The copied `supabase/` directory in
this Flutter repository remains read-only reference material; the migration has not
been deployed from here.

## Baseline verification

Commands attempted before Flutter edits:

```text
flutter test
flutter analyze
```

`flutter` was not on shell `PATH`; the installed binary was found at
`/Users/darts/development/flutter/bin/flutter`. Both commands then failed before
loading the project with the same Dart VM crash:

```text
../../runtime/vm/cpuinfo_macos.cc: 42: error: unreachable code
version=3.1.5 (stable) ... on "macos_x64"
```

Therefore the original baseline test and analyzer status is **toolchain crash / not
executed**, not a test failure.

### Flutter 3.13.9 compatibility verification

The local SDK at `/Users/darts/development/flutter` remains Flutter 3.13.9 / Dart 3.1.5
and was not modified, upgraded, or replaced. Earlier official x64 SDK downloads were
isolated under `/private/tmp` and did not alter the local installation.

The originally declared dependency set did not resolve on Dart 3.1.5. In particular,
`flutter_lints ^6.0.0` requires Dart `^3.8.0`; other originally selected package releases
and Flutter APIs also postdated Flutter 3.13.9. With explicit user authorization, the
application packages were pinned to releases supported by Dart 3.1.5, unused Riverpod
was removed, and newer Flutter API calls were expressed using their Flutter 3.13
equivalents. The SDK constraint remains `>=3.1.5 <4.0.0`.

Results using the resulting declared Flutter 3.13-compatible dependency versions:

```text
flutter pub get                          PASS
dart format --set-exit-if-changed .     PASS (84 files, 0 changed)
flutter analyze                         PASS (no issues)
flutter test --reporter compact         PASS (65 passed, 3 live-only skipped)
flutter run -d chrome                    PASS (debug service connected)
flutter build ios --simulator            PASS (Runner.app produced)
iPhone 14 Pro Max simulator launch       PASS (sign-in screen rendered)
Supabase Auth settings endpoint          PASS (HTTP 200 with public key)
map simulator integration flow           PASS (1,567 points; pan interactions)
```

Compatibility changes are limited to Dart/Flutter source and package declarations.
No Flutter SDK, Gradle, Android Gradle Plugin, Java, Xcode, deployment-target, or
platform-version declaration was changed. `connectivity_plus 4.0.2` retains the
project's iOS 11.0 target, and the transitive `SDWebImage` pod is locked to 5.19.7
because later 5.21 releases use Apple SDK APIs unavailable in Xcode 14.2. CocoaPods
installed 27 pods and repaired stale Xcode UUID references during normal integration.

No Android emulator or physical camera was available. Storage RPCs, real QR scanning,
and full authenticated UI integration flows remain unverified. The passing suite
genuinely covers unit, widget, and Flutter 3.13-regenerated golden tests; the iOS
simulator build and configured rendered launch were also verified.

An opt-in live data check was subsequently run with a disposable operational account
through the public client configuration and its authenticated user session. It passed
profile and membership RLS, resolved the `owner` role, and returned 12 active sections,
1,567 active trees, and 122 active irrigation zones. The zone counts by section were
`A:12, B:12, C:10, D:12, E:7, F:12, G:12, L:14, M:12, N:5, O:6, Q:8`. No service-role
credential was used, no credential or token was logged, and no backend row was changed.
The farm operator confirmed the coherent 122-zone distribution as authoritative, so
the earlier 120-zone statement and reference UI metric are treated as stale.

The same owner-scoped live suite reads one active QR label through its existing RLS
policy and verifies that `scan_tree_by_qr` returns the exact linked live tree. The token
is kept only in test memory and is never logged. Camera capture, issue creation, storage
upload, and the new issue-photo RPC are not mutated against the live project.

The map profile integration target is committed and records a timeline when run in
profile mode on hardware. It cannot genuinely run in profile mode on the available iOS
simulator: Flutter 3.13 reports that release/profile builds are supported only for
physical devices. The same test passes in simulator debug mode; no physical iPhone was
available for profile capture.

## Audit decisions

- Preserve the reference JSON as immutable canonical geometry and copy it to a Flutter
  asset; live Supabase rows enrich/reconcile tree state by UUID, then tree code.
- Use feature-first UI folders with explicit domain models, repository interfaces,
  Supabase services, and controller-backed view state. Widgets will not call Supabase
  directly.
- Avoid code generation initially; immutable hand-written models and parsing keep the
  bootstrap auditable.
- Keep weather isolated and visibly mocked until a provider is configured.
- Do not queue non-idempotent RPC mutations offline. Cache reads first; require
  connectivity for unsafe writes.
- Treat the authoritative 122 zones as a backend gate, not an asset assertion, because
  only 56 zone IDs are referenced by planted-tree asset rows. The original reference
  UI's hardcoded 120 is a documented fidelity correction, not the operational truth.
