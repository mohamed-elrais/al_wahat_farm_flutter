#!/usr/bin/env python3
"""Generate the Flutter static farm-map asset from an approved KMZ.

The generated JSON contains immutable geometry only. Trees, planting pits,
active section counts, and Supabase irrigation-zone UUIDs are deliberately
resolved at runtime from the authenticated farm hierarchy (or its private
offline cache).

Both legacy ``description`` metadata and modern KML ``ExtendedData`` are
accepted. ExtendedData wins when a field exists in both representations.

Usage:
  python3 tool/generate_map_data.py
  python3 tool/generate_map_data.py --audit-only
  python3 tool/generate_map_data.py --kmz reference/source.kmz --asset /tmp/map.json
"""

import argparse
import json
import os
from pathlib import Path
import re
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile

NS = {"k": "http://www.opengis.net/kml/2.2"}

OUTPUT_KEYS = (
    "generatedFrom",
    "bounds",
    "sections",
    "trees",
    "layout",
    "utilities",
    "waterLines",
    "branchLines",
    "valves",
    "flushValves",
    "risers",
    "waterSupply",
)

LAYOUT_TYPES = {"farm_boundary", "road", "shared_services_area"}
UTILITY_TYPES = {
    "water_tank",
    "building",
    "worker_house",
    "pump_electrical_control_room",
    "warehouse",
    "owner_rest_house",
    "solar_array",
    "gate",
}
FLUSH_TYPES = {
    "branch_flush_valve",
    "flush_valve",
    "submain_terminal_flush_valve",
}
VALVE_TYPES = {"zone_control_valve", "isolation_valve"}


class Kml:
    """Parsed KML document, placemark metadata, and resolved style colors."""

    def __init__(self, kmz_path):
        with zipfile.ZipFile(kmz_path) as archive:
            kml_name = next(n for n in archive.namelist() if n.endswith(".kml"))
            with archive.open(kml_name) as handle:
                self.document = ET.parse(handle).getroot().find("k:Document", NS)
        if self.document is None:
            raise SystemExit("KMZ does not contain a KML Document")

        self._styles = {}
        for style in self.document.findall("k:Style", NS):
            entry = {}
            for tag in ("PolyStyle", "LineStyle", "IconStyle"):
                color = style.find(f"k:{tag}/k:color", NS)
                if color is not None and color.text:
                    entry[tag] = color.text.strip()
            self._styles[style.get("id")] = entry

        self._style_maps = {}
        for style_map in self.document.findall("k:StyleMap", NS):
            for pair in style_map.findall("k:Pair", NS):
                if pair.findtext("k:key", default="", namespaces=NS) == "normal":
                    self._style_maps[style_map.get("id")] = (
                        pair.findtext("k:styleUrl", default="", namespaces=NS)
                        .strip()
                        .lstrip("#")
                    )

        self.placemarks = self.document.findall(".//k:Placemark", NS)
        self.metadata = {id(pm): fields(pm) for pm in self.placemarks}

    def of_type(self, *asset_types):
        wanted = set(asset_types)
        return [
            pm
            for pm in self.placemarks
            if self.metadata[id(pm)].get("asset_type") in wanted
        ]

    def geometry_type(self, placemark):
        for name in ("Point", "LineString", "Polygon"):
            if placemark.find(f".//k:{name}", NS) is not None:
                return name
        return None

    def style_colors(self, placemark):
        """Return (fill, stroke) as #RRGGBB values when present."""
        style_id = (
            placemark.findtext("k:styleUrl", default="", namespaces=NS)
            .strip()
            .lstrip("#")
        )
        entry = self._styles.get(self._style_maps.get(style_id, style_id), {})

        def to_hex(kml_color):
            if not kml_color or len(kml_color) != 8:
                return None
            # KML colors are aabbggrr.
            return f"#{kml_color[6:8]}{kml_color[4:6]}{kml_color[2:4]}".upper()

        return to_hex(entry.get("PolyStyle")), to_hex(entry.get("LineStyle"))


def fields(placemark):
    """Read legacy description rows and modern ExtendedData values."""
    description = placemark.findtext("k:description", default="", namespaces=NS) or ""
    result = {
        key: value.strip()
        for key, value in re.findall(r"([a-z_0-9]+):\s*([^<]*)", description)
        if value.strip()
    }
    for data in placemark.findall(".//k:ExtendedData/k:Data", NS):
        key = data.get("name")
        value = data.findtext("k:value", default="", namespaces=NS).strip()
        if key and value:
            result[key] = value
    for data in placemark.findall(".//k:ExtendedData/k:SchemaData/k:SimpleData", NS):
        key = data.get("name")
        value = (data.text or "").strip()
        if key and value:
            result[key] = value
    return result


def name_of(placemark):
    return placemark.findtext("k:name", default="", namespaces=NS).strip()


def coordinates(placemark):
    """Return all coordinates as [longitude, latitude] pairs."""
    pairs = []
    for node in placemark.findall(".//k:coordinates", NS):
        for token in (node.text or "").split():
            longitude, latitude = token.split(",")[:2]
            pairs.append([float(longitude), float(latitude)])
    if not pairs:
        raise SystemExit(f"Placemark has no coordinates: {name_of(placemark)}")
    return pairs


def optional(record, key, value):
    if value not in (None, ""):
        record[key] = value


def point_record(placemark, meta):
    longitude, latitude = coordinates(placemark)[0]
    record = {
        "assetId": meta["asset_id"],
        "name": name_of(placemark),
        "type": meta["asset_type"],
        "lat": latitude,
        "lng": longitude,
    }
    optional(record, "section", meta.get("section"))
    optional(record, "submain", meta.get("submain"))
    optional(record, "status", meta.get("status"))
    return record


def build_layout(kml):
    return [
        {"name": name_of(pm), "coordinates": coordinates(pm)}
        for pm in kml.placemarks
        if kml.metadata[id(pm)].get("asset_type") in LAYOUT_TYPES
    ]


def build_utilities(kml):
    shapes = []
    for placemark in kml.placemarks:
        meta = kml.metadata[id(placemark)]
        if meta.get("asset_type") not in UTILITY_TYPES:
            continue
        fill, stroke = kml.style_colors(placemark)
        record = {
            "name": name_of(placemark),
            "coordinates": coordinates(placemark),
            "type": meta["asset_type"],
        }
        optional(record, "fillColor", fill)
        optional(record, "strokeColor", stroke)
        shapes.append(record)
    return shapes


def build_water_lines(kml):
    mainlines = kml.of_type("mainline")
    submains = sorted(
        kml.of_type("submain"),
        key=lambda pm: kml.metadata[id(pm)]["asset_id"],
    )
    return [
        {"name": name_of(pm), "coordinates": coordinates(pm)}
        for pm in [*mainlines, *submains]
    ]


def build_sections(kml, old_asset):
    old_by_code = {section["id"]: section for section in old_asset["sections"]}
    sections = []
    for placemark in kml.of_type("farm_section"):
        meta = kml.metadata[id(placemark)]
        code = meta.get("section_code") or meta["asset_id"].removeprefix("SEC-")
        old = old_by_code.get(code)
        if old is None and "area_m2" not in meta:
            raise SystemExit(f"Section {code} has no approved area metadata")
        sections.append(
            {
                "id": code,
                "name": name_of(placemark) or f"Section {code}",
                "area": float(meta.get("area_m2") or old["area"]),
                # Runtime composition replaces these from Supabase/cache.
                "planted": False,
                "treeCount": 0,
                "polygon": coordinates(placemark),
            }
        )
    return sorted(sections, key=lambda item: item["id"])


def build_branch_lines(kml):
    lines = []
    for placemark in kml.of_type("branch_line"):
        meta = kml.metadata[id(placemark)]
        record = {
            "assetId": meta["asset_id"],
            "name": name_of(placemark),
            "section": meta["section"],
            "submain": meta["submain"],
            "coordinates": coordinates(placemark),
        }
        optional(record, "zoneId", meta.get("irrigation_zone_id"))
        optional(record, "color", meta.get("zone_color_hex"))
        optional(record, "status", meta.get("status"))
        lines.append(record)
    return sorted(lines, key=lambda item: item["assetId"])


def build_valves(kml):
    # Mainline Isolation Valve NN shuts off Irrigation Submain NN.
    submain_lines = {}
    for placemark in kml.of_type("submain"):
        meta = kml.metadata[id(placemark)]
        submain_lines[meta["asset_id"].split("-")[-1]] = coordinates(placemark)
    mosque_lines = kml.of_type("mosque_supply_line")
    mosque_line = coordinates(mosque_lines[0]) if mosque_lines else None

    valves = []
    for placemark in kml.placemarks:
        meta = kml.metadata[id(placemark)]
        if meta.get("asset_type") not in VALVE_TYPES:
            continue
        record = point_record(placemark, meta)
        optional(record, "zoneId", meta.get("irrigation_zone_id"))
        optional(record, "color", meta.get("zone_color_hex"))
        if "irrigation_zone_tree_count" in meta:
            record["zoneTreeCount"] = int(meta["irrigation_zone_tree_count"])
        if meta["asset_type"] == "isolation_valve":
            number = record["assetId"].split("-")[-1]
            if "-ML-" in record["assetId"] and number in submain_lines:
                record["downstreamSubmains"] = [number]
                record["downstreamLine"] = submain_lines[number]
            elif mosque_line is not None:
                record["downstreamSubmains"] = []
                record["downstreamLine"] = mosque_line
        valves.append(record)
    return sorted(valves, key=lambda item: item["assetId"])


def build_points(kml, asset_types):
    return sorted(
        (
            point_record(placemark, kml.metadata[id(placemark)])
            for placemark in kml.placemarks
            if kml.metadata[id(placemark)].get("asset_type") in asset_types
        ),
        key=lambda item: item["assetId"],
    )


def build_water_supply(kml):
    points, lines, polygons = [], [], []
    excluded = LAYOUT_TYPES | UTILITY_TYPES | {
        "farm_section",
        "mainline",
        "submain",
        "branch_line",
        "zone_control_valve",
        "isolation_valve",
        *FLUSH_TYPES,
        "distribution_riser",
        "tree",
        "future_tree_candidate",
    }
    for placemark in kml.placemarks:
        meta = kml.metadata[id(placemark)]
        asset_type = meta.get("asset_type")
        if not asset_type or asset_type in excluded:
            continue
        geometry = kml.geometry_type(placemark)
        if geometry == "Point":
            points.append(point_record(placemark, meta))
            continue
        record = {
            "assetId": meta["asset_id"],
            "name": name_of(placemark),
            "type": asset_type,
            "coordinates": coordinates(placemark),
        }
        optional(record, "status", meta.get("status"))
        if "diameter_in" in meta:
            record["diameterIn"] = float(meta["diameter_in"])
        (polygons if geometry == "Polygon" else lines).append(record)
    key = lambda item: item["assetId"]
    return {
        "points": sorted(points, key=key),
        "lines": sorted(lines, key=key),
        "polygons": sorted(polygons, key=key),
    }


def compute_bounds(kml):
    points = [point for pm in kml.placemarks for point in coordinates(pm)]
    return {
        "minLng": min(point[0] for point in points),
        "maxLng": max(point[0] for point in points),
        "minLat": min(point[1] for point in points),
        "maxLat": max(point[1] for point in points),
    }


def validate_source(kml):
    ids = [meta.get("asset_id") for meta in kml.metadata.values()]
    if any(not asset_id for asset_id in ids):
        raise SystemExit("Every placemark must have an asset_id")
    if len(ids) != len(set(ids)):
        raise SystemExit("KMZ contains duplicate asset_id values")


def validate_asset(asset):
    expected = {
        "sections": 12,
        "layout": 7,
        "utilities": 14,
        "waterLines": 11,
        "branchLines": 120,
        "valves": 133,
        "flushValves": 131,
        "risers": 64,
    }
    actual = {key: len(asset[key]) for key in expected}
    if actual != expected:
        raise SystemExit(f"Static map contract broken: {actual} != {expected}")
    if asset["trees"]:
        raise SystemExit("Static map asset must not contain operational trees")
    if len({item["assetId"] for item in asset["branchLines"]}) != 120:
        raise SystemExit("Branch-line asset IDs must be unique")
    zone_valves = [v for v in asset["valves"] if v["type"] == "zone_control_valve"]
    if len(zone_valves) != 122:
        raise SystemExit(f"Expected 122 zone-control valves, got {len(zone_valves)}")
    for collection in (asset["branchLines"], zone_valves):
        for feature in collection:
            if not feature.get("zoneId"):
                raise SystemExit(f"Missing stable zone code: {feature['assetId']}")


def build_asset(kml, old_asset, generated_from):
    return {
        "generatedFrom": generated_from,
        "bounds": compute_bounds(kml),
        "sections": build_sections(kml, old_asset),
        "trees": [],
        "layout": build_layout(kml),
        "utilities": build_utilities(kml),
        "waterLines": build_water_lines(kml),
        "branchLines": build_branch_lines(kml),
        "valves": build_valves(kml),
        "flushValves": build_points(kml, FLUSH_TYPES),
        "risers": build_points(kml, {"distribution_riser"}),
        "waterSupply": build_water_supply(kml),
    }


def audit(kml, asset):
    types = {}
    for meta in kml.metadata.values():
        asset_type = meta["asset_type"]
        types[asset_type] = types.get(asset_type, 0) + 1
    return {
        "placemarks": len(kml.placemarks),
        "sourceTrees": types.get("tree", 0),
        "sourceFutureTrees": types.get("future_tree_candidate", 0),
        "sections": len(asset["sections"]),
        "layout": len(asset["layout"]),
        "utilities": len(asset["utilities"]),
        "waterLines": len(asset["waterLines"]),
        "branchLines": len(asset["branchLines"]),
        "valves": len(asset["valves"]),
        "flushValves": len(asset["flushValves"]),
        "risers": len(asset["risers"]),
        "waterSupplyPoints": len(asset["waterSupply"]["points"]),
        "waterSupplyLines": len(asset["waterSupply"]["lines"]),
        "bounds": asset["bounds"],
    }


def write_atomic(path, payload):
    destination = Path(path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(
        prefix=f".{destination.name}.", dir=destination.parent
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(payload, handle, ensure_ascii=False, separators=(",", ":"))
        os.replace(temporary, destination)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--kmz",
        default="reference/al_wahat_whole_farm_master_2026-08-29.kmz",
    )
    parser.add_argument("--asset", default="assets/data/al_wahat_map_data.json")
    parser.add_argument("--generated-from", default=None)
    parser.add_argument("--audit-only", action="store_true")
    args = parser.parse_args()

    with open(args.asset, encoding="utf-8") as handle:
        old_asset = json.load(handle)

    kml = Kml(args.kmz)
    validate_source(kml)
    asset = build_asset(
        kml,
        old_asset,
        args.generated_from or Path(args.kmz).name,
    )
    validate_asset(asset)
    report = audit(kml, asset)
    print(json.dumps(report, ensure_ascii=False, sort_keys=True))

    if not args.audit_only:
        ordered = {key: asset[key] for key in OUTPUT_KEYS}
        write_atomic(args.asset, ordered)
    return 0


if __name__ == "__main__":
    sys.exit(main())
