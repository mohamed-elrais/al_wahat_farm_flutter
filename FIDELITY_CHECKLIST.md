# Al Wahat Farm Fidelity Checklist

This checklist turns the reference contract into measurable acceptance criteria. A
checked item requires test evidence or an inspected screenshot; compilation alone is
not evidence.

## Design system

- [x] One immutable token class owns all ten required colors with exact ARGB values.
- [x] Inter is bundled and used for body, controls, labels, and numeric UI.
- [x] Libre Baskerville (or documented bundled Georgia-like equivalent) is used for
  major headings and prominent values.
- [x] No runtime font download is needed.
- [x] Paper background includes the subtle 28-unit grid texture.
- [x] Cards use off-white fill, warm 1 dp borders, 16–22 dp radii, and soft shadows.
- [ ] Controls use 9–13 dp radii; section and role controls are pill/chip treatments.
- [ ] Orange is reserved for Scan, issue/alert emphasis, and primary field moments.
- [ ] Dark green is used for selection, actions, and phone navigation.
- [ ] Stock Material components are visually wrapped by the project design system.

## App shell and responsive layout

- [ ] Splash restores the Supabase session and shows an intentional loading state.
- [x] Login matches the warm-paper, serif-heading visual system.
- [x] Phone top bar has palm mark, Al Wahat, notification control, and avatar.
- [ ] Production role is membership-derived; role impersonation is unavailable.
- [x] Phone bottom navigation has Home, Map, raised orange Scan, Tasks, More.
- [ ] Selected-tree details appear above navigation as a draggable sheet.
- [ ] Forms use full-height or large rounded sheets on phones.
- [x] Section filters scroll horizontally without clipping.
- [ ] Tablet preserves a three-region composition with the map dominant.
- [ ] Text scaling does not clip core actions at 200%.
- [ ] Reduced-motion setting suppresses nonessential transitions.

## Farm geometry and painter

- [x] Flutter asset is byte-for-byte copied from the reference map JSON.
- [x] Parser asserts 12 sections, 6 planted sections, and 1,567 trees.
- [x] Per-section counts are A 298, B 330, C 168, D 303, E 0, F 360, G 108,
  L 0, M 0, N 0, O 0, Q 0.
- [x] Bounds are 28.747598–28.754600 longitude and 28.293348–28.300016 latitude.
- [x] Projection uses an 820 × 880 canvas, 24-unit padding, midpoint cosine
  correction, and a single fit scale.
- [x] One painter renders tree points; there are no 1,567 marker widgets.
- [x] Render order exactly follows background, boundary, roads/shared area, sections,
  water network, utilities, labels, trees, selection/overlays.
- [x] All seven layout shapes, twelve utilities, and eleven water lines are rendered.
- [x] Overview/section/selected tree radii are 2.7/4.4/6.8 logical units.
- [x] Selected tree has a strong white outline and remains visibly distinct.
- [x] Nearest-point hit testing honors an approximately 44 dp minimum touch target.
- [x] Spatial lookup is deterministic and never chooses an arbitrary overlapping tree.
- [x] One known tree in each planted section is selected in automated tests.
- [ ] Filtering fits the selected polygon with padding and hides/dims unrelated data.
- [ ] Reset restores complete farm bounds.
- [x] Trees, Irrigation network, and Buildings/utilities toggle independently.
- [x] Painter is isolated in a `RepaintBoundary`; projected geometry is precomputed.
- [x] Manager sees a nonblocking structured discrepancy warning when live data differs.

## Tree, task, issue, and review workflows

- [ ] Tree detail shows code, section, row/tree, health, type, zone/color, and
  coordinates to seven decimals when available.
- [x] Owner/engineer can attach a persisted farm/section/zone/tree task.
- [x] Task form exposes every required field and sends exact final RPC parameters.
- [x] Assignees are active operational farm members only.
- [x] New tasks appear after repository refresh and survive restart.
- [x] Worker task queries expose only active assignments.
- [x] Worker/manager can start eligible tasks and see activity history.
- [x] Completion handles before/after/evidence upload and final status refresh.
- [ ] Scanner calls `scan_tree_by_qr`; no simulation exists in production.
- [ ] Issue types exactly match the final `tree_issue_type` enum.
- [ ] Issue reports surface both returned IDs and refresh the review queue.
- [ ] Optional issue photo follows a verified backend-supported two-step contract.
- [ ] Review supports approve, return for correction, and follow-up required.
- [ ] Worker review attempts fail in capability tests and at the backend boundary.
- [ ] Authorization and RLS errors are understandable and actionable.

## Async, offline, privacy, and accessibility

- [ ] Every async route has intentional loading, empty, retryable error, authorization,
  offline/cached, and success feedback.
- [ ] Farm/section/zone/tree and task/detail reads are cached.
- [ ] Immutable map geometry renders without network access.
- [ ] Online/offline/sync state is visible in More and relevant workflows.
- [ ] Non-idempotent RPCs are not blindly queued.
- [ ] Evidence upload shows progress, preserves image orientation, compresses images,
  and cleans failed temporary state.
- [ ] Logout clears all private local cache while preserving immutable app assets.
- [ ] Interactive controls expose semantic labels and at least 44 dp hit targets.
- [ ] Error reporting hooks do not include tokens, photo paths, coordinates tied to a
  person, or other PII/secrets.

## Test and certification evidence

- [x] Projection math unit tests pass.
- [x] JSON parsing and all count validations pass.
- [x] Nearest-tree hit-testing tests pass.
- [x] Role capability tests pass.
- [x] RPC payload contract tests pass.
- [x] Login/session routing widget tests pass.
- [x] Section filtering and role-aware tree-sheet widget tests pass.
- [ ] Task form validation/submission tests pass.
- [x] Issue form and photo-failure tests pass.
- [ ] Task transition tests pass.
- [ ] Core-screen goldens pass. Phase 1 login/shell/top-bar goldens pass; remaining
  core screens are not yet covered.
- [ ] Fake-backed login → map → tree → create-task integration flow passes.
- [x] Fake-backed worker scan → report-issue flow passes. Authentication/bootstrap is
  covered separately by the login and farm-gate suites.
- [x] Opt-in live Supabase integration suite is documented. The authenticated check
  verifies RLS, the authoritative 12-section/122-zone/1,567-tree counts, and a real
  active QR token without logging it.
- [x] `dart format --set-exit-if-changed .` passes.
- [x] `flutter analyze` passes with no suppressed product diagnostics.
- [x] `flutter test` passes (65 tests; 3 explicitly configured live tests skip by
  default).
- [ ] Screenshots inspected at 390×844, 430×932, a common Android size, and 1024×1366.
- [ ] `FIDELITY_REPORT.md` records comparisons, adaptations, and remaining mismatches.
