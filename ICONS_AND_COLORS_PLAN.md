# Icons and colours for options — plan

**Goal:** every option a user picks or reads (task type, issue type, severity, status, inventory category …) has **one fixed icon and one fixed colour**, the same on every screen. A worker who can't read the word can still recognise *"blue drop = irrigation"*, *"red bug = pests"*, *"3 bars = high"*.

This is step 1 of supporting users who can't read or write. Voice, picture pickers and simpler login come later.

Status: **V0–V4 done and deployed (2026-10-14).** V5 automated checks done; the phone-in-daylight check and the worker test need people (see V5 in Progress).

---

## 1. What exists today (2026-10-14)

There's no central place for icons or colours. Each screen picks its own, and many options have none.

| Option set | Values | Icon today | Colour today | Where it's shown |
|---|---|---|---|---|
| `TaskType` | 9 | `_taskIcon` in tasks_screen only | none | tasks list, task detail, create (dropdown), home |
| `OperationPlanType` | 5 (subset of task types) | `planTypeIcon` in schedules_screen (copy of the above) | none | schedules list, schedule form (dropdown) |
| `TaskStatus` | 8 | none | `_statusColor` in task_widgets | status pill: tasks, detail, review queue/detail |
| `TaskPriority` | 4 | none | none | task create, inspection create (dropdowns), tasks |
| `TreeIssueType` | 7 | **none** | none | issue report (dropdown), issues list + filter, issue detail, inspection sheet (chips), map filter, tree sheet |
| `IssueSeverity` | 4 | none | **two different ramps** | issues list (`_severityColor`), map painter (`_IssueMark.color`), report/detail (dropdowns), inspection sheet, map filter |
| `TreeIssueStatus` | 4 | none | none | issues list, issue detail, tree sheet, map |
| `TreeIssueEventType` | 9 | `_eventIcon` (all drawn green) | green only | issue timeline |
| `EngineerReviewDecision` | 3 | `_decisionIcon` | none | review detail |
| `OperationPlanStatus` | 5 | none | in schedules_screen | schedules |
| Inventory category (seeded codes) | 9 + custom | `_categoryIcon` in inventory_screen | none | inventory list |
| `InventoryTransactionType` | 4 | none | none | inventory item history |
| `ApplicationMethod` | 4 | none | none | schedule form (managers only) |

**Inconsistencies found:**
- **Severity "low"** is yellow `#D19A2A` on the map but green on the Issues list. The other three levels also differ between the two screens.
- **"Needs review"** status is red (`AppColors.issue`), the same red as "Returned", so a waiting task looks like a failed one.
- **Issue types have no icon anywhere**, and they're the options workers pick most often.
- **Two identical icon tables**: `_taskIcon` and `planTypeIcon`.

---

## 2. Design rules

1. **Defined in one file.** `lib/app/theme/app_visuals.dart` holds every icon and colour, next to `app_tokens.dart`. Screens never pick their own.
2. **Each value has a unique icon and a unique colour within its set**, so no two task types look alike.
3. **The same idea looks the same in every set (D1).** Pest-control task, insecticide (inventory) and the "pest or disease" issue are all **red with the bug icon**. Irrigation is always blue with a drop. Learning one teaches the others.
4. **Never colour alone.** Colour always comes with an icon, and the shape still tells values apart for colour-blind users (red/green).
5. **Severity and priority use bar count plus colour:** 1–4 bars, drawn by the app, so they're readable with no words and no colour. Severity and priority share one look, because they already share their labels.
6. **Statuses** use the round pill with an icon and the word. "Good" is always green with ✓, "problem" always red, "waiting for engineer" always indigo, "stopped or cancelled" always grey.
7. **Filled icons in a coloured circle with a white glyph.** Filled shapes read better than outlines at small sizes and in sunlight.
   - Sizes: 32 dp in chips, 40 in lists, 56–64 in pickers.
8. **Contrast:** every colour is ≥ 3:1 against white and against the card (WCAG 1.4.11 for icons). A unit test enforces this.
9. **Text stays dark.** Labels are drawn in `AppColors.ink`, never in the option's colour, because some colours are only 3.5–4.5:1, which is too weak for text.
10. **The word stays next to the icon.** Icon-only appears only where space forces it (the map), and there the icon gets a Semantics label.
11. **No new dependencies.** The icons are Material icons already bundled with Flutter 3.13, so nothing extra to download and they work offline. Custom drawn pictograms can replace individual icons later without touching the screens.

---

## 3. Proposed palette (reviewed on the phone in V0)

Contrast is shown as white-on-colour / against the card (#FFFDF7), from a scratch script.

### Task types (also used for `OperationPlanType`)
| Value | Icon | Colour | Contrast |
|---|---|---|---|
| Irrigation | `water_drop` | blue `#2F6E99` (= map water main) | 5.5 |
| Fertilization | `compost` | brown `#8A5A32` | 5.9 |
| Harmful weed control | `grass` | olive `#5E7A1F` | 4.9 |
| Pest control | `pest_control` (bug) | red `#B03A2E` | 6.0 |
| Disease control | `coronavirus` | purple `#7B4B94` | 6.4 |
| Dripper maintenance | `plumbing` | teal `#1F7A74` | 5.1 |
| Tree inspection | `park` (tree) | farm green `#285C36` | 7.9 |
| Engineer review | `engineering` | indigo `#3F51A3` | 7.2 |
| General field work | `assignment` | grey `#6E7168` | 5.0 |

### Tree issue types
| Value | Icon | Colour | Same family as |
|---|---|---|---|
| Insufficient irrigation | `format_color_reset` (drop with slash) | blue `#2F6E99` | Irrigation |
| Too much water (added 2026-10-14) | `flood` | cyan-blue `#1A7FA6` | Irrigation |
| Dripper problem (clogged + leak merged 2026-10-14) | `plumbing` | teal `#1F7A74` | Dripper maintenance |
| Harmful weed | `grass` | olive `#5E7A1F` | Weed control |
| Pest or disease | `pest_control` | red `#B03A2E` | Pest control |
| Tree damage | `park` + a red corner badge | plum `#A23B72` | — |
| Other | `help` | grey `#6E7168` | General |

### Severity / priority (one ramp, replaces both current ramps)
| Value | Bars | Colour | Contrast |
|---|---|---|---|
| Low | ▮▯▯▯ | olive `#5E7A1F` | 4.9 |
| Medium | ▮▮▯▯ | amber `#B07D12` | 3.6 |
| High | ▮▮▮▯ | orange `#D0612A` | 3.9 |
| Urgent | ▮▮▮▮ | dark red `#A3262A` | 7.3 |

### Task status
| Value | Icon | Colour |
|---|---|---|
| Draft | `edit_note` | slate `#7A7F87` |
| Assigned | `assignment_ind` | blue `#2F6E99` |
| In progress | `timelapse` | orange `#C25E2E` |
| Completed | `check_circle` | green `#285C36` |
| Needs review | `rate_review` | **indigo `#3F51A3`** (was red) |
| Approved | `verified` | deep green `#1E6B4A` |
| Returned | `undo` | red `#B03A2E` |
| Cancelled | `cancel` | light grey `#8C8880` |

Issue status, plan status and review decision reuse these by meaning:
- **Issue status:** open = red `report`, in review = indigo, resolved = green ✓, dismissed = grey.
- **Plan status:** active = green ▶, paused = amber ⏸, completed = blue ✓, draft and archived = grey.
- **Review decision:** approved = deep green, returned = red, follow-up = orange `flag`.

### Inventory categories
| Code | Icon | Colour |
|---|---|---|
| pipe / pipe_joint | `horizontal_rule` / `call_split` | blue `#2F6E99` / `#4F7FA0` |
| dripper | `water_drop` | teal `#1F7A74` |
| fertilizer | `compost` | brown `#8A5A32` |
| insecticide | `pest_control` | red `#B03A2E` |
| herbicide | `grass` | olive `#5E7A1F` |
| fungicide | `coronavirus` | purple `#7B4B94` |
| tool | `handyman` | dark slate `#4A5560` |
| other / custom | `inventory_2` | grey `#6E7168` |

---

## 4. Building blocks (V0)

`lib/app/theme/app_visuals.dart`:
- `class OptionVisual { final IconData icon; final Color color; }`
- Extensions that mirror `lib/core/l10n/domain_labels.dart`: `extension TaskTypeVisual on TaskType { OptionVisual get visual => switch … }`, and the same for every set in section 3.
- Inventory categories key on `code`, with a fallback for custom ones.
- An exhaustive `switch`, so adding an enum value without a visual fails to compile.

`lib/core/widgets/option_visuals.dart` (shared widgets):
- `OptionBadge(visual, {size})`: coloured circle with a white filled icon.
- `OptionLabel(visual, label)`: badge plus ink text, the default way to show an option.
- `SeverityBars(severity)`: draws 1–4 bars with a CustomPainter, with no icon font involved.
- `StatusPill`: replaces the one in `task_widgets.dart`. It gets an icon and keeps its current look otherwise.
- `optionDropdownItem(...)`: `DropdownMenuItem` child with the badge plus label, so every existing dropdown gains icons with a one-line change.
- `OptionChip`: Filter/Choice chip whose avatar is the badge. When selected it fills with the option's colour (white label), replacing today's uniform dark-green fill.

**Icons guide page** (Profile → "Icons guide"):
- Shows every set with its icons, colours and labels, in English and Arabic.
- The engineers can train workers with it, and you can review the palette on a real phone before anything else changes.

---

## 5. Phases

Each phase ends with: tests and analyze green, a commit, then a staging and production deploy.

### V0 — Visual system and guide page (review gate)
- V0.1 `app_visuals.dart` with all sets from section 3.
- V0.2 Shared widgets from section 4.
- V0.3 Icons guide page plus l10n keys (en/ar).
- V0.4 Tests:
  - every value has a visual;
  - icons are unique within each set, and colours are unique within each set (except where D1 says families repeat across sets);
  - every colour is ≥ 3:1 against white and against `AppColors.card`;
  - golden of the guide page in English and Arabic.
- **Gate:** you open the guide page on your phone and approve or change colours and icons. Only then V1+.

### V1 — Tasks
- Task cards (tasks list, home): `OptionBadge` for the type. Delete `_taskIcon`.
- Task detail header: type badge, status pill with icon, priority bars.
- Task create: type and priority dropdown items with badges.
- Review queue/detail: status pills; decision icons from the shared set (delete `_decisionIcon`).
- Schedules: plan type badge (delete `planTypeIcon`), plan status pill.

### V2 — Issues, inspections and map
- Issue report: type and severity dropdown items with badges and bars.
- Issues list:
  - card shows the type badge and severity bars, replacing the coloured dot;
  - filters show badges;
  - delete `_severityColor`.
- Issue detail: header badges; timeline icons coloured by meaning, not all green.
- Inspection issue sheet: type chips with badges, coloured when selected; severity buttons with bars.
- Map:
  - severity markers use the new ramp (delete the map's own ramp);
  - the filter chips get badges;
  - tree sheet issue rows get badges.
- Update map goldens.

### V3 — Inventory and schedules details
- Inventory categories (delete `_categoryIcon`) and transaction types (add = green +, use = orange −, adjust = blue ±, reversal = grey ↶).
- Application methods in the schedule form (managers only, low priority).

### V4 — Picture pickers for workers (optional, D4)
- On worker-facing screens, replace the issue type and severity dropdowns with a **grid of large tiles** (64 dp badge plus word): issue report and the inspection sheet.
- The same for task completion choices if there are any.
- This is the bridge to the later voice and picture work.

### V5 — Check
- Full suite and goldens.
- Arabic RTL screenshots of every changed screen.
- Check on the iPhone in daylight.
- Show the guide page to 2–3 workers and note which icons they didn't understand, then swap those icons. That only touches `app_visuals.dart`.

---

## 6. Risks
- **Material icons are generic.** "Clogged dripper" and "leak" are the weakest. Fix: after V5 feedback, draw custom pictograms for the 2–3 that fail; that only changes `app_visuals.dart`.
- **Red is used a lot:** pests, returned, urgent. Shape keeps them apart (bug vs ↶ vs 4 bars). Watch for this in the V5 worker test.
- **Status colour change:** "Needs review" turning from red to indigo changes what managers are used to (D2).
- **Goldens:** map and task goldens will change in V1/V2. That's expected; update them deliberately.

---

## 7. Decisions needed

| # | Question | Recommendation |
|---|---|---|
| D1 | Should related options in **different** sets share a colour and icon (pest task = insecticide = pest issue)? | **Yes.** One idea, one look. |
| D2 | Change "Needs review" from red to indigo, keeping red only for problems? | **Yes.** |
| D3 | One severity ramp everywhere (low olive → urgent dark red, with bars)? | **Yes.** It fixes the map/list mismatch. |
| D4 | Include V4 (big picture tiles instead of dropdowns on worker screens) in this round? | **Yes, after V2.** It's the biggest win for non-readers. |
| D5 | Add the "Icons guide" page to Profile for training? | **Yes.** It's also the review step for V0. |

## Decision log
| Date | Item | Decision |
|---|---|---|
| 2026-10-14 | D1–D5 | All accepted as recommended. |
| 2026-10-14 | Issue types | User: merge "Clogged dripper" and "Leak or dripper damage" into one type, and add "Too much water". Done in the database (Al-Wahat-Farm-supabase migrations `20261014160145`, `20261014160148`) and the app: `dripperProblem` keeps wire value `clogged_dripper`; the retired `leak_or_dripper_damage` stays in the Postgres enum and reads as it; new `excess_irrigation` creates irrigation follow-up tasks. One tree had both types active: the leak copy was dismissed with a merge note. |
| 2026-10-14 | V0 build notes | Inventory "dripper" uses the dripper family (teal plumbing), not the irrigation drop, per D1. Severity bars always rise left to right, in Arabic too (like phone signal bars). The "Returned" ↶ icon mirrors in Arabic (Flutter's RTL icon). |

## Progress
| Phase | State | Notes |
|---|---|---|
| V0 | Done | `lib/app/theme/app_visuals.dart`, `lib/core/widgets/option_visuals.dart`, Profile → Icons guide (`/more/icons`). Tests: `test/unit/theme/app_visuals_test.dart`, `test/widget/icons_guide_test.dart`, goldens `test/goldens/icons_guide_{en,ar}_390.png`. **Gate:** palette review on a phone. |
| V1 | Done | Task cards and Home preview (type badge; Home used a water drop for every task), status pills with icons, priority bars, type/priority pickers, task and review activity icons, review decisions, schedules list/detail/form. Palette gate waived: user asked to continue through the plan while away (2026-10-14). |
| V2 | Done | Issues list (type badge replaces the severity stripe, severity and status pills), filters, issue detail (badges, timeline icons by meaning, linked task badges), task issue card, tree sheet rows, map filters and markers on the shared severity ramp. |
| V3 | Done | Inventory list, filter chips, item header, category picker; stock movements (added green +, used orange −, correction blue ±, undone grey ↺); application methods in the schedule form. Unit tests cover both new sets and the history-row pictures. |
| V4 | Done (with V2) | Picture tiles (`OptionTile`, `OptionTileGrid`) for issue type and severity on Report issue and in the inspection issue sheet and its severity dialog. Built together with V2 so those pickers were rebuilt once. Golden: `issue_report_tiles_{en,ar}_390.png`. |
| V5 | Partly done | Done: full suite (all pass), goldens in English and Arabic (icons guide, report issue tiles), live staging check in headless Chrome at phone size in English and Arabic (icons guide, tasks, issues list with real data; icons render in the web build). **Needs people:** check on the iPhone in daylight; show the Icons guide to 2–3 workers and note pictures they misread, then change those in `app_visuals.dart` only. |
