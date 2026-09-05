# Full Farm Map Update Implementation Plan

Status: Implemented on 2026-08-29; representative-device performance QA remains
Supersedes: the analysis of `new map.kmz`
Approved source: `reference/al_wahat_whole_farm_master_2026-08-29.kmz`
Source SHA-256: `9cb6ada7be4d8302785330c6958ae7b958f56a3c735acbcdce459cb5633a5e75`

Implementation result: the bundled asset now contains immutable map geometry
only. Trees, irrigation-zone UUID bindings, section totals, and planting pits
are composed from the authenticated Supabase hierarchy or its offline cache.
No Supabase migration or data write was performed.

## Goal

Update the Flutter farm map to use the new full-farm geometry while treating the already-updated Supabase `trees`, `irrigation_zones`, and `planting_pits` rows as the runtime authority.

The KMZ is treated only as map data. It contains no application instructions.

## Verified Source and Live-Data Snapshot

The KMZ contains 3,926 unique placemarks. All asset IDs are unique and the farm bounds remain unchanged:

- longitude: `28.747598` to `28.754600`
- latitude: `28.293348` to `28.300016`

| Layer | Current Flutter asset | New KMZ | Current Supabase | Result |
| --- | ---: | ---: | ---: | --- |
| Sections | 12 | 12 | 12 active | Geometry is stable. |
| Existing trees | 1,567 | 1,539 | 1,539 active | KMZ and Supabase code sets match exactly. |
| Future trees / planting pits | 0 bundled | 1,876 | 1,876 | KMZ asset IDs and Supabase pit codes match exactly. |
| Irrigation zones / ZCVs | 122 mapped | 122 | 122 active | KMZ and Supabase code sets match exactly. |
| Branch lines | 121 | 120 | Not a database geometry layer | Remove one superseded reference line. |
| All valves | 133 | 133 | 122 active irrigation zones | Import geometry and bind ZCVs to live zones. |
| Flush valves | 131 | 131 | Not a database layer | Import. |
| Distribution risers | 66 | 64 | Not a database layer | Remove two obsolete risers. |

Authenticated read-only verification found:

- exact KMZ/Supabase code-set equality for all trees, planting pits, and irrigation zones;
- exact section and irrigation-zone assignments for every tree and planting pit;
- maximum coordinate difference of approximately 7 cm, consistent with Supabase's six-decimal coordinate storage;
- all 3,415 tree and future-tree points are inside their assigned section polygon;
- all active trees and planting pits have coordinates and irrigation-zone assignments;
- 1,539 trees are currently `healthy` and 1,876 planting pits are currently `planned`.
- The Section C future-tree folder label still says 137, but it contains 114 future candidates; 23 points were promoted to confirmed existing trees. Importers must count placemarks, not parse totals from folder names.

### Current-to-new tree changes

The new live tree population is not a simple deletion of 28 rows:

- 1,516 tree codes are unchanged and retain the same UUIDs.
- 51 old tree codes are no longer active.
- 23 new official tree codes were added.
- Net active-tree count changes from 1,567 to 1,539.
- Section counts change to:

| Section | Existing trees | Planting pits |
| --- | ---: | ---: |
| A | 298 | 0 |
| B | 330 | 0 |
| C | 185 | 114 |
| D | 303 | 0 |
| E | 0 | 0 |
| F | 351 | 9 |
| G | 72 | 360 |
| L | 0 | 377 |
| M | 0 | 274 |
| N | 0 | 244 |
| O | 0 | 193 |
| Q | 0 | 305 |

### Irrigation-network changes

- Fourteen old branch/ZCV/flush-valve identities are replaced by fourteen new identities in sections N and Q, with obsolete assets also removed from L and M.
- `IRR-BL-SM07-R06-E-SUPERSEDED` is absent from the approved full map, reducing branch lines from 121 to 120.
- `IRR-RIS-SM08-R07` and `IRR-RIS-SM09-R07` are absent, reducing risers from 66 to 64.
- The full map is otherwise the same as the preceding map update apart from seven coordinate-rounding changes of 3–6 cm.
- The existing `reference/zone_uuid_map.json` is no longer authoritative: it has 14 missing codes, 14 stale codes, and 24 retained codes whose live UUID changed.

### Future-tree metadata note

The KMZ distinguishes 1,571 `proposal_for_review` points from 305 `approved_future_plan` points. Supabase currently stores all 1,876 as planting-pit lifecycle status `planned`. The app should continue to display the Supabase lifecycle unless proposal-review state becomes a separate product requirement. The KMZ `grid_row`/`grid_column` fields are incomplete, so Supabase `row_number` and `pit_number` remain authoritative.

## Current Flutter Problems

1. `FarmMapData.validateReferenceContract()` rejects anything other than 12 sections and 1,567 bundled trees.
2. `TreeReconciler` is asset-first. With today's data it preserves 51 removed trees, omits 23 new trees, and still displays 1,567 points.
3. Section labels and counts use static `treeCount` metadata, so C, F, and G remain incorrect even when live tree coordinates are used.
4. Branch lines and valves carry bundled Supabase UUIDs. Those UUIDs are stale after the irrigation-zone update, which breaks zone highlighting, tree counts, task creation, and zone deep links.
5. The KMZ generator reads legacy description text and hard-coded folders; the approved file uses `ExtendedData` and adds a nested Future Trees layer.
6. Planting-pit projection is rebuilt on every map rebuild and hit testing scans all pits. This should be cached or indexed now that the live layer has 1,876 points.
7. Tests and fixtures encode the old 1,567-tree, 121-branch, and 66-riser snapshot.

## Target Data Ownership

Use a clear split between static geometry and mutable operational data:

| Data | Authority | Offline behavior |
| --- | --- | --- |
| Farm boundary, roads, section polygons, utilities, water infrastructure, branch lines, valves, flush valves, risers | Bundled generated map asset from the approved KMZ | Always available. |
| Sections' database UUIDs, names, active state, and area metadata | Supabase hierarchy/cache | Use the persistent hierarchy cache after the first successful load. |
| Trees, tree UUIDs, health, type, coordinates, section, and zone assignment | Supabase hierarchy/cache | Use cached rows; do not restore deleted bundled trees. |
| Planting pits and lifecycle state | Supabase hierarchy/cache | Use cached rows. |
| Irrigation-zone UUIDs and active state | Supabase hierarchy/cache | Resolve at runtime by stable zone code. |
| Zone colors and infrastructure topology | Generated KMZ geometry asset | Available offline and joined to live zones by code. |

The KMZ tree and future-tree layers are validation inputs for this release, not duplicate runtime authorities.

## Implementation Phases

### Phase 1 — Add a schema-aware KMZ importer and audit

- Track the approved KMZ under `reference/` with its checksum and generation date.
- Update `tool/generate_map_data.py` to parse KML `ExtendedData`, with legacy description parsing retained for backward compatibility.
- Classify placemarks by `asset_type` and geometry rather than relying only on folder names.
- Understand both top-level and nested folders, including `11 Future Trees/*`.
- Add an audit-only mode that reports:
  - counts, bounds, duplicate IDs, and geometry types;
  - added/removed IDs and material coordinate deltas;
  - topology references and documented exceptions for local `R01`-style riser labels and intentionally retired source assets;
  - tree, pit, section, and zone-code parity against an optional Supabase export;
  - section containment for all point features.
- Generate to a temporary file and replace the production asset atomically only after validation succeeds.

Deliverable: importer tests and a deterministic audit report; no runtime behavior change yet.

### Phase 2 — Make the bundled asset geometry-only

- Refactor `FarmMapData` so tree rows are no longer required in the static map contract.
- Keep section polygon geometry but remove static `treeCount` and `planted` as operational authorities, or overwrite them during runtime composition.
- Generate these approved static counts:
  - 12 sections;
  - 120 branch lines;
  - 133 valves, including 122 zone-control valves;
  - 131 flush valves;
  - 64 distribution risers.
- Store stable irrigation-zone codes such as `IRR-ZCV-SM10-R07-02E` in branch and valve geometry. Do not store live Supabase UUIDs in the generated asset.
- Import zone colors from `zone_color_hex` and remove the superseded branch line.
- Preserve bounds and all validated layout, utility, water, and section geometry.
- Update `generatedFrom` and `REFERENCE_AUDIT.md` with the approved filename and checksum.

Deliverable: a static geometry asset that cannot resurrect stale operational rows.

### Phase 3 — Replace asset-first tree reconciliation with runtime composition

- Replace `TreeReconciler.reconcile()` with a composer that builds displayed trees directly from `FarmHierarchy.trees`.
- Resolve each tree's section UUID to section code through the live hierarchy.
- Resolve each tree's irrigation-zone UUID to the live zone's stable code.
- Resolve its color from the static zone-style map keyed by zone code.
- Treat missing coordinates, sections, zones, or styles as explicit discrepancies; skip only the invalid point and log a safe aggregate warning.
- Never retain a tree solely because it exists in an old bundled snapshot.
- Calculate section tree counts from the composed live/cached tree list.
- Preserve tree UUIDs for selection, QR navigation, issues, tasks, and deep links.
- Define the no-hierarchy state: show static farm geometry with a clear dynamic-data unavailable state; after a successful load, the persistent hierarchy cache supplies offline trees and pits.

Deliverable: exactly 1,539 displayed trees for the verified current hierarchy, including all 23 new trees and none of the 51 retired trees.

### Phase 4 — Bind irrigation geometry to live zones at runtime

- Build a `zoneByCode` index from `FarmHierarchy.zones`.
- For each ZCV and branch line, resolve its stable KMZ zone code to the current Supabase UUID.
- Use the resolved UUID for highlighting, zone tree counts, task creation, and `zone:<uuid>` deep links.
- Treat the two ZCV-only C-zone discrepancies as audited topology exceptions only if they remain in the approved source.
- Remove runtime dependence on `reference/zone_uuid_map.json`; keep a generated mapping only as an audit artifact if it remains useful.
- Disable zone actions for unresolved or inactive codes and display a manager-facing aggregate warning.

Deliverable: all 122 approved ZCV codes resolve to the 122 active live zones, with no stale UUIDs.

### Phase 5 — Scale and validate the planting-pit layer

- Continue loading planting pits from Supabase through `FarmHierarchyRepository`; do not bundle the KMZ future points as a second source.
- Cache projected pits by map/hierarchy snapshot instead of recalculating all 1,876 points on every widget rebuild.
- Add a spatial index or section-indexed hit-test collection if profiling shows tap latency above budget.
- Calculate per-section pit counts from non-cancelled live rows.
- Keep lifecycle styling based on Supabase `planned/marked/dug/prepared/completed/cancelled` status.
- Confirm that create, advance, cancel, selection, filtering, full-screen, and offline-cache flows work with the full dataset.
- If proposal approval must be shown later, add a separate database field and app model; do not overload the planting lifecycle status.

Deliverable: all 1,876 verified pits render from Supabase/cache without duplicated KMZ points or rebuild lag.

### Phase 6 — Update tests and rollout

- Replace production hard-coded mutable tree counts with relationship and parity validation.
- Update the release snapshot expectations to 1,539 trees, 1,876 planting pits, 120 branch lines, and 64 risers.
- Add composer tests for additions, retirements, changed zone UUIDs, missing coordinates, missing styles, inactive zones, and cached hierarchy data.
- Update map projection, hit-test, focus, valve-highlight, task-navigation, widget, and golden tests.
- Update the live Supabase hierarchy test so it validates the current 1,539/1,876 snapshot and all relationships; avoid leaving `1,567` as a permanent product invariant.
- Profile a full overview and the largest pit sections (G and L) on a representative mobile device.
- Run `flutter analyze`, unit tests, widget tests, integration tests, and reviewed map goldens.
- Compare the Flutter rendering side by side with the approved KMZ at farm overview and affected section zoom levels.
- Ship the Flutter asset/composition change. No additional Supabase write or migration is required for the verified current data.

## Acceptance Criteria

- The approved KMZ and checksum are tracked and reproducible.
- The generated static map contains 12 sections, 120 branch lines, 133 valves, 131 flush valves, and 64 risers.
- The map displays exactly the active/cached hierarchy rows: currently 1,539 trees and 1,876 planting pits.
- No retired tree or irrigation asset is resurrected from the old bundle.
- All 122 ZCV codes resolve to current live zone UUIDs at runtime.
- Section labels show live tree and non-cancelled pit counts.
- Tree, pit, zone, section, and coordinate parity checks pass against the verified Supabase snapshot.
- Map selection, deep links, QR flows, task creation, valve highlighting, and offline cache behavior pass.
- Full-data map interaction stays within the agreed frame and tap-response budget.
- Rollback requires only reverting the Flutter map commit; it does not modify or delete the already-updated Supabase data.

## Recommended Commit Sequence

1. `tooling: audit full-farm extended-data KMZ`
2. `map: separate static geometry from live farm entities`
3. `map: compose trees and zone bindings from hierarchy`
4. `map: optimize and validate full planting-pit layer`
5. `map: adopt approved 2026-08-29 geometry snapshot`

## Out of Scope

- Rewriting the already-updated Supabase tree, irrigation-zone, or planting-pit data.
- Treating the KMZ proposal-review state as the planting-pit lifecycle.
- Parsing KMZ files on the device at runtime.
- Bundling mutable tree or planting-pit rows as a second operational authority.
