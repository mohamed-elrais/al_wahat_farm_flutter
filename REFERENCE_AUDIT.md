# Al Wahat Full-Farm Map Reference Audit

Audit date: 2026-08-29
Source: `reference/al_wahat_whole_farm_master_2026-08-29.kmz`
Source SHA-256: `9cb6ada7be4d8302785330c6958ae7b958f56a3c735acbcdce459cb5633a5e75`
KML document: `Al-Wahat Farm — Whole-Farm Master — Latest Approved Future Trees`

## Authority Model

The Flutter map deliberately combines two authorities:

- The tracked KMZ and generated JSON own immutable geometry: farm layout,
  sections, utilities, water infrastructure, branches, valves, flush valves,
  and risers.
- The authenticated Supabase hierarchy, or its private offline cache, owns
  mutable trees, planting pits, active section counts, and irrigation-zone
  UUIDs.

Stable irrigation-zone codes join the sources. Supabase UUIDs and operational
tree/pit rows are not embedded in the generated production map asset.

## Source Inventory

| Layer | Count |
| --- | ---: |
| Total placemarks | 3,926 |
| Site layout | 7 |
| Farm sections | 12 |
| Utilities | 14 rendered shapes |
| Mainline and submains | 11 |
| Branch lines | 120 |
| Valves | 133 |
| Zone-control valves | 122 |
| Flush valves | 131 |
| Distribution risers | 64 |
| Existing tree points | 1,539 |
| Future-tree candidates | 1,876 |

All 3,926 placemarks have a unique `asset_id`.

### Bounds

| Coordinate | Value |
| --- | ---: |
| Minimum longitude | 28.747598 |
| Maximum longitude | 28.754600 |
| Minimum latitude | 28.293348 |
| Maximum latitude | 28.300016 |

The bounds are unchanged from the previous Flutter map.

## Live Supabase Parity

An authenticated read-only verification through the public client and existing
RLS policies confirmed:

- 12 active sections;
- 122 active irrigation zones;
- 1,539 active trees;
- 1,876 planting pits;
- exact code-set equality between KMZ trees and Supabase `trees.tree_code`;
- exact code-set equality between KMZ future candidates and
  `planting_pits.pit_code`;
- exact code-set equality between KMZ ZCV IDs and
  `irrigation_zones.code`;
- exact section and irrigation-zone assignments for every tree and pit;
- maximum KMZ/database coordinate difference below 8 cm, consistent with
  six-decimal database coordinates;
- no missing coordinates or irrigation-zone assignments among active trees or
  planting pits.

No Supabase write was needed for the Flutter update.

## Section Counts

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
| **Total** | **1,539** | **1,876** |

Section C's future-tree folder label says 137 but contains 114 future
placemarks. The other 23 points were promoted to confirmed existing trees.
Import and audit tooling counts placemarks and never trusts totals embedded in
folder labels.

## Changes From the Previous Flutter Snapshot

### Trees

- 1,516 tree codes and UUIDs remain unchanged.
- 51 old tree codes are no longer active.
- 23 official tree codes were added.
- Net tree count changes from 1,567 to 1,539.

The runtime composer uses the live/cache list as the complete authority, so
removed trees cannot be resurrected by an old asset and new trees do not need a
matching bundled fixture.

### Irrigation Network

- Fourteen old branch/ZCV/flush identities were replaced by fourteen current
  identities.
- `IRR-BL-SM07-R06-E-SUPERSEDED` was removed.
- `IRR-RIS-SM08-R07` and `IRR-RIS-SM09-R07` were removed.
- Branch count changes from 121 to 120.
- Riser count changes from 66 to 64.
- The old static zone UUID map was removed. Runtime binding now resolves every
  stable ZCV code against the current hierarchy.

Two approved C-section ZCVs do not have matching branch-line features:
`IRR-ZCV-C-SM04-01` and `IRR-ZCV-C-SM04-02`. They also lack a KMZ zone color.
They are retained as surveyed valve points; no current tree uses either style.

## Future-Tree Semantics

The KMZ includes:

- 1,571 points marked `proposal_for_review`;
- 305 points marked `approved_future_plan`;
- 1,876 points with planting status `proposed`.

Supabase currently represents all 1,876 rows with planting-pit lifecycle status
`planned`. Proposal review and field lifecycle are different concepts. Flutter
continues to render the authoritative Supabase lifecycle and does not overload
it with KMZ proposal-review metadata.

The KMZ grid fields are incomplete. Supabase `row_number` and `pit_number`
remain authoritative for operational display and validation.

## Generated Asset Contract

`assets/data/al_wahat_map_data.json` contains:

- the unchanged bounds and 12 section polygons;
- 7 layout shapes;
- 14 utility shapes;
- 11 water/main/submain lines;
- 120 branches;
- 133 valves;
- 131 flush valves;
- 64 risers;
- 7 water-supply points and 12 water-supply lines;
- zero bundled operational trees;
- stable zone codes and colors, but zero Supabase UUIDs.

The generator supports both legacy description metadata and modern
`ExtendedData`, validates unique IDs and immutable counts, supports audit-only
execution, and replaces its output atomically.

## Reproduction

```sh
shasum -a 256 reference/al_wahat_whole_farm_master_2026-08-29.kmz
python3 tool/generate_map_data.py --audit-only
python3 tool/generate_map_data.py
python3 tool/generate_map_test_fixture.py
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test test/integration/live_supabase_hierarchy_test.dart \
  --dart-define-from-file=config.json
```

The generated test fixture is non-production data with stable code-based IDs.
It provides deterministic full-density map tests without making CI depend on a
live Supabase project.
