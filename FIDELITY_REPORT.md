# Al Wahat Farm Fidelity Report

Report date: 2026-07-13
Phase: 8 — fidelity certification
Reference: `reference_web_app/` (React/Next prototype) and `REFERENCE_AUDIT.md`
Toolchain: Flutter 3.13.9 / Dart 3.1.5 (local), unchanged.

This report compares the Flutter build against the reference contract captured in
`REFERENCE_AUDIT.md` and `FIDELITY_CHECKLIST.md`. It records what was inspected, the
intentional mobile adaptations, every known mismatch, and every item that remains
unverified. Per the phase gate, completion is not claimed for any unverified item.

## Method and scope

- **Rendered screenshots** were generated as committed golden PNGs under `test/goldens/`
  by `test/golden/phase8_certification_golden_test.dart` and
  `test/golden/phase1_golden_test.dart`, with the bundled Inter / Libre Baskerville /
  Material Icons fonts loaded so type renders authentically.
- **Design-system, geometry, and workflow facts** were compared against the values
  audited in `REFERENCE_AUDIT.md` (tokens, projection contract, counts, render order,
  radii) and the enum/RPC contracts in `supabase/migrations/`.
- **Behavioral states** were compared against the interaction/state matrix in the audit
  and are backed by the 122-test default suite.

What this report does **not** claim: a live side-by-side pixel diff against the running
React reference, or capture on physical Android/iOS hardware. Those remain listed under
"Remaining unverified".

## Screenshots generated and inspected

| File | Size | Screen | Result |
|---|---|---|---|
| `login_390x844.png` | 390×844 | Login | Matches warm-paper/serif system |
| `login_430x932.png` | 430×932 | Login | Matches; scales cleanly |
| `login_android_360x800.png` | 360×800 | Login (common Android) | Matches; no clipping |
| `login_tablet_1024x1366.png` | 1024×1366 | Login (tablet) | Card stays centered/constrained, not stretched |
| `shell_390x844.png` | 390×844 | Phone shell (top bar + nav) | Matches |
| `shell_430x932.png` | 430×932 | Phone shell | Matches |
| `top_bar_390x120.png` | 390×120 | Branded top bar | Matches |
| `tasks_worker_390x844.png` | 390×844 | Worker task list | Matches; see chip note below |
| `review_queue_390x844.png` | 390×844 | Manager review queue | Matches |

All nine goldens pass on re-run (`flutter test test/golden`).

## Design-language comparison

### Color tokens — MATCH
All ten required tokens are defined once in `AppColors` with the exact reference ARGB
values (`paper #F8F4E9`, `card #FFFDF7`, `ink #173D28`, `green #285C36`,
`orange #CC6637`, `muted #6E7168`, `line #E5DCC8`, `softGreen #E8EFDE`, `sand #E8D6AE`,
`road #B9A47D`, `issue #B65535`). The paper background renders the subtle ~28px grid
texture (visible in every capture).

### Typography — MATCH
- Body/labels/controls/numbers use bundled **Inter** (variable, weights 400–900).
- Major headings and prominent values use bundled **Libre Baskerville** (the audited
  Georgia-like serif) with `Georgia`/`serif` fallback — see "Welcome to Al Wahat.",
  "Farm tasks", "Review queue" in the captures.
- Compact uppercase tracked eyebrows ("FARM OPERATIONS", "FIELD OPERATIONS",
  "ENGINEER REVIEW") match the reference.
- No runtime font download.

### Shape, spacing, elevation — MATCH
- Cards: off-white fill, warm 1 dp `line` borders, 16–22 dp radii, soft low-opacity
  shadows (login/task/review cards).
- Bottom navigation: dark `ink` rounded (~19 dp) bar, inset from edges, with the raised
  orange circular Scan action centered (`shell_*` captures).
- Selected pills/chips use green fill (the "Today" filter, per the audited "selected green
  fill" rule); orange is reserved for the Scan action and issue/alert emphasis
  ("Needs review" badge, login error text).

### Navigation — MATCH
Five fixed destinations (Home, Map, raised Scan, Tasks, More) with semantic labels and
selected state; proportions match the reference dark rounded bar.

### Farm geometry, layer order, radii — MATCH (by contract + unit tests)
The painter renders exactly one layer stack in reference order (background/grid →
boundary → roads/shared → 12 sections → water main/submains → utilities → labels →
trees → selection), with tree radii 2.7 / 4.4 / 6.8 logical units and the 820×880 / 24-pad
/ cosine-corrected projection. Counts (12 sections, 6 planted, 1,567 trees) and per-section
tallies are asserted by the map unit tests. A device screenshot of the full map is listed
under "Remaining unverified".

### Selected-tree sheet and forms — MATCH (by widget tests)
The draggable tree sheet, create-task form, report-issue form, and review decision sheet
expose the audited fields and exact RPC parameter names; they are covered by widget and
contract tests (`tree_detail_sheet_test`, `task_create_screen_test`,
`issue_report_screen_test`, review tests). Dedicated form goldens were not captured this
pass (scrolling sheets); this is noted under "Remaining".

### Async / loading / empty / error / offline / success — MATCH (by tests)
Each async surface has intentional loading, empty, retryable error, authorization,
offline/cached, and success feedback, backed by the suite. Offline state is globally
visible via the shell banner and the More sync tile.

## Known mismatches and corrections

1. **Filter chip contrast — FIXED this pass.** Inspection of `tasks_worker_390x844.png`
   showed the unselected "All (N)" `ChoiceChip` rendering with a near-invisible label (no
   `ChipThemeData`, so the Material-3 default color applied) and the selected "Today" chip
   filled orange. A `ChipThemeData` was added: unselected chips use `card` fill, a `line`
   border, and an `ink` label; selected chips use the audited **green fill** with a white
   label and checkmark. The regenerated golden now shows both chips as deliberate pill
   treatments, and the selected state matches the reference's green-fill rule (orange stays
   reserved for Scan/alerts).
2. **Irrigation-zone count 120 → 122.** The reference UI hardcodes a stale `120`; the
   authoritative live count is `122` (operator-confirmed). The app shows `122`. Documented
   correction, not a regression.
3. **Weather is an intentional isolated mock.** The reference weather card is simulated;
   the app keeps weather visibly mocked/omitted rather than mixing it with persisted
   operational data, per the audit decision. (No weather surface is shipped in the MVP
   screens captured.)
4. **Role preview switch is intentionally absent in production.** The reference exposes a
   local role switch; production role derives from `farm_memberships` only.

## Intentional mobile adaptations

- The single-screen React dashboard becomes routed mobile screens (Splash, Login, Home,
  Map, Scanner, Tree Detail, Create Task, Report Issue, Tasks, Task Detail, Review Queue,
  Review Detail, More) with a fixed five-tab shell.
- Forms are large rounded modal sheets; the selected-tree inspector is a draggable sheet
  above navigation.
- On tablet the login card stays centered and width-constrained rather than stretching
  (see `login_tablet_1024x1366.png`); the map-dominant three-region composition is a
  layout target for the wide breakpoint.

## Verification (2026-07-13)

```text
dart format --set-exit-if-changed .   PASS (clean)
flutter analyze                       PASS (no issues)
flutter test                          PASS (122 passed, 6 opt-in live tests skipped)
flutter test test/golden              PASS (9 goldens)
```

The opt-in live Supabase suites (hierarchy/counts/QR, task lifecycle, review lifecycle)
are skipped by default and require credentials plus explicit mutation flags.

## Remaining unverified (explicitly not claimed complete)

- **Physical-device capture**: 390×844 and 430×932 are rendered as host goldens; capture
  on real iOS/Android hardware and a device profile-mode map performance timeline are not
  done here (Flutter 3.13 supports iOS profile builds on physical devices only; no device
  available).
- **Live side-by-side pixel diff** against the running React reference app.
- **Form/map screen goldens**: create-task, report-issue, complete-task sheets and the
  full 1,567-point map were validated by widget/unit tests but not captured as goldens
  this pass.
- **Live backend mutations**: real camera capture, storage upload, and remote deployment
  of the `add_tree_issue_photo` RPC remain controlled in the separate Supabase repository.

Given these, Phase 8 is reported as evidenced-with-remaining: the design system, geometry
contract, navigation, workflows, and multi-size login/shell/list/review screenshots are
certified against the reference, while device-hardware capture and a live reference pixel
diff are listed as outstanding rather than claimed.
