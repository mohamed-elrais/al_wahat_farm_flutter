#!/usr/bin/env python3
"""Generate a deterministic, non-production farm hierarchy test fixture."""

import argparse
import json
from pathlib import Path

from generate_map_data import Kml, coordinates, name_of


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--kmz",
        default="reference/al_wahat_whole_farm_master_2026-08-29.kmz",
    )
    parser.add_argument(
        "--map-asset",
        default="assets/data/al_wahat_map_data.json",
    )
    parser.add_argument(
        "--output",
        default="test/fixtures/full_farm_hierarchy.json",
    )
    args = parser.parse_args()

    with open(args.map_asset, encoding="utf-8") as handle:
        map_asset = json.load(handle)
    area_by_section = {
        section["id"]: section["area"] for section in map_asset["sections"]
    }
    kml = Kml(args.kmz)

    sections = []
    for placemark in kml.of_type("farm_section"):
        meta = kml.metadata[id(placemark)]
        code = meta.get("section_code") or meta["asset_id"].removeprefix("SEC-")
        sections.append(
            {
                "code": code,
                "name": name_of(placemark),
                "area": area_by_section[code],
            }
        )

    zones = []
    for placemark in kml.of_type("zone_control_valve"):
        meta = kml.metadata[id(placemark)]
        code = meta["asset_id"]
        zones.append(
            {
                "id": code,
                "code": code,
                "section": meta["section"],
                "name": name_of(placemark),
            }
        )

    trees = []
    for placemark in kml.of_type("tree"):
        meta = kml.metadata[id(placemark)]
        longitude, latitude = coordinates(placemark)[0]
        code = meta["asset_id"]
        trees.append(
            {
                "id": code,
                "code": code,
                "section": meta["section"],
                "zone": meta["irrigation_zone_id"],
                "row": int(meta["row_number"]),
                "number": int(meta["tree_number_in_row"]),
                "lat": latitude,
                "lng": longitude,
            }
        )

    pits = []
    pit_number_by_section = {}
    for placemark in kml.of_type("future_tree_candidate"):
        meta = kml.metadata[id(placemark)]
        longitude, latitude = coordinates(placemark)[0]
        section = meta["section"]
        number = pit_number_by_section.get(section, 0) + 1
        pit_number_by_section[section] = number
        pits.append(
            {
                "id": meta["asset_id"],
                "code": meta["asset_id"],
                "section": section,
                "zone": meta["irrigation_zone_id"],
                "row": 1,
                "number": number,
                "lat": latitude,
                "lng": longitude,
            }
        )

    payload = {
        "sections": sorted(sections, key=lambda item: item["code"]),
        "zones": sorted(zones, key=lambda item: item["code"]),
        "trees": sorted(trees, key=lambda item: item["code"]),
        "plantingPits": sorted(pits, key=lambda item: item["code"]),
    }
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, separators=(",", ":"))
    print(
        json.dumps(
            {
                "sections": len(sections),
                "zones": len(zones),
                "trees": len(trees),
                "plantingPits": len(pits),
            },
            sort_keys=True,
        )
    )


if __name__ == "__main__":
    main()
