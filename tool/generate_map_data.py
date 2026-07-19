#!/usr/bin/env python3
"""Augment assets/data/al_wahat_map_data.json with the irrigation-network
layers from the reference KMZ.

The legacy keys (generatedFrom, bounds, sections, trees, layout, utilities,
waterLines) are preserved byte-for-byte from the existing asset — this tool
only (re)generates the additive network keys:

  branchLines   121 lines, each tied to its irrigation zone (ZCV asset id)
  valves        122 zone control valves + 11 mainline isolation valves
  flushValves   131 mainline / branch / submain-terminal flush points
  risers         66 distribution risers
  waterSupply   well, pumps, tank transfer lines, bends/takeoffs (points,
                lines, polygons) — excluding features already present in the
                legacy layers (the mainline lives in waterLines; water-tank
                polygons live in utilities)

Deterministic output: features sorted by asset id, no timestamps, minified
UTF-8 JSON matching the existing asset's formatting.

Usage:
  python3 tool/generate_map_data.py \
      [--kmz reference/al_wahat_map_reference.kmz] \
      [--asset assets/data/al_wahat_map_data.json]
"""

import argparse
import copy
import json
import re
import sys
import xml.etree.ElementTree as ET
import zipfile

NS = {"k": "http://www.opengis.net/kml/2.2"}

LEGACY_KEYS = (
    "generatedFrom",
    "bounds",
    "sections",
    "trees",
    "layout",
    "utilities",
    "waterLines",
)

NETWORK_KEYS = ("branchLines", "valves", "flushValves", "risers", "waterSupply")


def parse_kml(kmz_path):
    with zipfile.ZipFile(kmz_path) as archive:
        kml_name = next(n for n in archive.namelist() if n.endswith(".kml"))
        with archive.open(kml_name) as handle:
            return ET.parse(handle).getroot().find("k:Document", NS)


def fields(placemark):
    """The KML descriptions hold `key: value<br>` metadata rows."""
    description = placemark.findtext("k:description", default="", namespaces=NS) or ""
    return {
        key: value.strip()
        for key, value in re.findall(r"([a-z_0-9]+):\s*([^<]*)", description)
        if value.strip()
    }


def coordinates(placemark):
    """All coordinates as [lng, lat] pairs (altitude dropped)."""
    node = placemark.find(".//k:coordinates", NS)
    pairs = []
    for token in (node.text or "").split():
        lng, lat = token.split(",")[:2]
        pairs.append([float(lng), float(lat)])
    return pairs


def folder(document, name):
    for candidate in document.findall("k:Folder", NS):
        if candidate.findtext("k:name", default="", namespaces=NS) == name:
            return candidate
    raise SystemExit(f"KMZ folder not found: {name}")


def optional(record, key, value):
    if value:
        record[key] = value


def point_record(placemark, meta):
    lng, lat = coordinates(placemark)[0]
    record = {
        "assetId": meta["asset_id"],
        "name": placemark.findtext("k:name", default="", namespaces=NS).strip(),
        "type": meta["asset_type"],
        "lat": lat,
        "lng": lng,
    }
    optional(record, "section", meta.get("section"))
    optional(record, "submain", meta.get("submain"))
    optional(record, "status", meta.get("status"))
    return record


def zone_uuid_mapping(document, asset):
    """ZCV asset id -> irrigation-zone UUID, derived from the trees.

    The live database (and the asset's trees) identify zones by UUID while the
    KMZ identifies them by ZCV asset id; `irrigation_zones.code` in the live
    database equals the ZCV asset id. Trees appear in both datasets keyed by
    tree code, which yields the mapping without any network access.
    """
    kmz_zone_by_code = {}
    for placemark in folder(document, "10 Trees").findall("k:Placemark", NS):
        meta = fields(placemark)
        if "asset_id" in meta and "irrigation_zone_id" in meta:
            kmz_zone_by_code[meta["asset_id"]] = meta["irrigation_zone_id"]
    mapping = {}
    for tree in asset["trees"]:
        zcv = kmz_zone_by_code.get(tree["code"])
        if zcv is None:
            continue
        existing = mapping.setdefault(zcv, tree["zoneId"])
        if existing != tree["zoneId"]:
            raise SystemExit(f"Inconsistent zone mapping for {zcv}")
    return mapping


def build_branch_lines(document, zone_uuids):
    lines = []
    for placemark in folder(document, "06 Branch Lines").findall("k:Placemark", NS):
        meta = fields(placemark)
        record = {
            "assetId": meta["asset_id"],
            "name": placemark.findtext("k:name", default="", namespaces=NS).strip(),
            "section": meta["section"],
            "submain": meta["submain"],
            "coordinates": coordinates(placemark),
        }
        optional(record, "zoneId", meta.get("irrigation_zone_id"))
        optional(record, "zoneUuid", zone_uuids.get(meta.get("irrigation_zone_id")))
        optional(record, "color", meta.get("zone_color_hex"))
        optional(record, "status", meta.get("status"))
        lines.append(record)
    return sorted(lines, key=lambda item: item["assetId"])


def build_valves(document, zone_uuids):
    valves = []
    for placemark in folder(document, "07 Valves").findall("k:Placemark", NS):
        meta = fields(placemark)
        record = point_record(placemark, meta)
        optional(record, "zoneId", meta.get("irrigation_zone_id"))
        optional(record, "zoneUuid", zone_uuids.get(meta.get("irrigation_zone_id")))
        optional(record, "color", meta.get("zone_color_hex"))
        if "irrigation_zone_tree_count" in meta:
            record["zoneTreeCount"] = int(meta["irrigation_zone_tree_count"])
        valves.append(record)
    return sorted(valves, key=lambda item: item["assetId"])


def build_flush_valves(document):
    return sorted(
        (
            point_record(placemark, fields(placemark))
            for placemark in folder(document, "08 Flush Valves").findall(
                "k:Placemark", NS
            )
        ),
        key=lambda item: item["assetId"],
    )


def build_risers(document):
    return sorted(
        (
            point_record(placemark, fields(placemark))
            for placemark in folder(document, "09 Distribution Risers").findall(
                "k:Placemark", NS
            )
        ),
        key=lambda item: item["assetId"],
    )


def build_water_supply(document, legacy):
    """Folder 04 minus features already drawn by legacy layers."""
    already_drawn = {shape["name"] for shape in legacy["utilities"]}
    already_drawn.update(shape["name"] for shape in legacy["waterLines"])
    points, lines, polygons = [], [], []
    for placemark in folder(document, "04 Water Source & Supply").findall(
        "k:Placemark", NS
    ):
        name = placemark.findtext("k:name", default="", namespaces=NS).strip()
        if name in already_drawn:
            continue  # mainline is in waterLines; tanks are in utilities
        meta = fields(placemark)
        if placemark.find(".//k:Point", NS) is not None:
            points.append(point_record(placemark, meta))
            continue
        record = {
            "assetId": meta["asset_id"],
            "name": name,
            "type": meta["asset_type"],
            "coordinates": coordinates(placemark),
        }
        optional(record, "status", meta.get("status"))
        if "diameter_in" in meta:
            record["diameterIn"] = float(meta["diameter_in"])
        if placemark.find(".//k:Polygon", NS) is not None:
            polygons.append(record)
        else:
            lines.append(record)
    key = lambda item: item["assetId"]
    return {
        "points": sorted(points, key=key),
        "lines": sorted(lines, key=key),
        "polygons": sorted(polygons, key=key),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kmz", default="reference/al_wahat_map_reference.kmz")
    parser.add_argument("--asset", default="assets/data/al_wahat_map_data.json")
    args = parser.parse_args()

    with open(args.asset, encoding="utf-8") as handle:
        asset = json.load(handle)
    legacy_before = {key: copy.deepcopy(asset[key]) for key in LEGACY_KEYS}

    document = parse_kml(args.kmz)
    zone_uuids = zone_uuid_mapping(document, asset)
    asset["branchLines"] = build_branch_lines(document, zone_uuids)
    asset["valves"] = build_valves(document, zone_uuids)
    asset["flushValves"] = build_flush_valves(document)
    asset["risers"] = build_risers(document)
    asset["waterSupply"] = build_water_supply(document, asset)

    # Guarantee the change is additive: legacy layers must be untouched.
    for key in LEGACY_KEYS:
        if asset[key] != legacy_before[key]:
            raise SystemExit(f"Refusing to write: legacy key changed: {key}")

    ordered = {key: asset[key] for key in LEGACY_KEYS + NETWORK_KEYS}
    with open(args.asset, "w", encoding="utf-8") as handle:
        json.dump(ordered, handle, ensure_ascii=False, separators=(",", ":"))

    counts = {key: len(ordered[key]) for key in NETWORK_KEYS if key != "waterSupply"}
    supply = ordered["waterSupply"]
    counts["waterSupply"] = {kind: len(supply[kind]) for kind in supply}
    zone_uuids = {
        valve["zoneUuid"] for valve in ordered["valves"] if "zoneUuid" in valve
    }
    tree_zones = {tree["zoneId"] for tree in ordered["trees"]}
    print("network layers written:", json.dumps(counts))
    print(f"zone uuids on valves: {len(zone_uuids)}; "
          f"tree zones covered: {tree_zones <= zone_uuids}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
