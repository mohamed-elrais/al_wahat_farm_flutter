#!/usr/bin/env python3
"""Regenerate assets/data/al_wahat_map_data.json from the reference KMZ.

Every layer is rebuilt from the KMZ except two per-tree properties that only
exist in the app/live database: the tree's stable UUID id and its health
status, which are carried over from the existing asset by tree code.

Irrigation-zone identity: the live database keys zones by UUID while the KMZ
keys them by ZCV asset id (`irrigation_zones.code`). The committed
reference/zone_uuid_map.json holds that mapping; refresh it from the live
database with a read-only query (select code, id from irrigation_zones)
whenever zones are added.

Isolation-valve topology is the naming convention: Mainline Isolation Valve
NN is the shutoff for Irrigation Submain NN, and every dependent asset
carries the SMNN id (IRR-ZCV-D-SM04-*, IRR-BR-C-SM04-*, IRR-FV-D-SM04-*).

Utilities carry their surveyed type and style colors (water tanks blue,
houses tan, solar arrays indigo, gates dark lines ...) so the app can render
them distinctly. Tank polygons surveyed under "04 Water Source & Supply" are
folded into the utilities layer.

Deterministic output: features sorted by asset id (or folder order for legacy
layers), no timestamps, minified UTF-8 JSON.

Usage:
  python3 tool/generate_map_data.py \
      [--kmz reference/al_wahat_map_reference.kmz] \
      [--asset assets/data/al_wahat_map_data.json] \
      [--zones reference/zone_uuid_map.json]
"""

import argparse
import json
import re
import sys
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


class Kml:
    """The parsed KML document plus resolved style colors."""

    def __init__(self, kmz_path):
        with zipfile.ZipFile(kmz_path) as archive:
            kml_name = next(n for n in archive.namelist() if n.endswith(".kml"))
            with archive.open(kml_name) as handle:
                self.document = ET.parse(handle).getroot().find("k:Document", NS)
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

    def folder(self, name):
        for candidate in self.document.findall("k:Folder", NS):
            if candidate.findtext("k:name", default="", namespaces=NS) == name:
                return candidate
        raise SystemExit(f"KMZ folder not found: {name}")

    def placemarks(self, folder_name):
        return self.folder(folder_name).findall("k:Placemark", NS)

    def style_colors(self, placemark):
        """(fill '#RRGGBB' or None, stroke '#RRGGBB' or None) for a placemark."""
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
    """The KML descriptions hold `key: value<br>` metadata rows."""
    description = placemark.findtext("k:description", default="", namespaces=NS) or ""
    return {
        key: value.strip()
        for key, value in re.findall(r"([a-z_0-9]+):\s*([^<]*)", description)
        if value.strip()
    }


def name_of(placemark):
    return placemark.findtext("k:name", default="", namespaces=NS).strip()


def coordinates(placemark):
    """All coordinates as [lng, lat] pairs (altitude dropped)."""
    node = placemark.find(".//k:coordinates", NS)
    pairs = []
    for token in (node.text or "").split():
        lng, lat = token.split(",")[:2]
        pairs.append([float(lng), float(lat)])
    return pairs


def optional(record, key, value):
    if value:
        record[key] = value


def point_record(placemark, meta):
    lng, lat = coordinates(placemark)[0]
    record = {
        "assetId": meta["asset_id"],
        "name": name_of(placemark),
        "type": meta["asset_type"],
        "lat": lat,
        "lng": lng,
    }
    optional(record, "section", meta.get("section"))
    optional(record, "submain", meta.get("submain"))
    optional(record, "status", meta.get("status"))
    return record


def build_layout(kml):
    return [
        {"name": name_of(placemark), "coordinates": coordinates(placemark)}
        for placemark in kml.placemarks("01 Site Layout")
    ]


def build_utilities(kml):
    """Folder 03 plus the tank polygons surveyed under folder 04, with their
    surveyed type and style colors."""
    shapes = []
    for placemark in kml.placemarks("03 Utilities"):
        meta = fields(placemark)
        fill, stroke = kml.style_colors(placemark)
        record = {
            "name": name_of(placemark),
            "coordinates": coordinates(placemark),
            "type": meta.get("asset_type", "building"),
        }
        optional(record, "fillColor", fill)
        optional(record, "strokeColor", stroke)
        shapes.append(record)
    for placemark in kml.placemarks("04 Water Source & Supply"):
        meta = fields(placemark)
        if (
            meta.get("asset_type") == "water_tank"
            and placemark.find(".//k:Polygon", NS) is not None
        ):
            fill, stroke = kml.style_colors(placemark)
            record = {
                "name": name_of(placemark),
                "coordinates": coordinates(placemark),
                "type": "water_tank",
            }
            optional(record, "fillColor", fill)
            optional(record, "strokeColor", stroke)
            shapes.append(record)
    return shapes


def build_water_lines(kml):
    lines = []
    for placemark in kml.placemarks("04 Water Source & Supply"):
        if fields(placemark).get("asset_type") == "mainline":
            lines.append(
                {"name": name_of(placemark), "coordinates": coordinates(placemark)}
            )
    for placemark in sorted(
        kml.placemarks("05 Submains"),
        key=lambda pm: fields(pm)["asset_id"],
    ):
        lines.append(
            {"name": name_of(placemark), "coordinates": coordinates(placemark)}
        )
    return lines


def build_sections_and_trees(kml, old_asset, zone_uuids):
    old_by_code = {tree["code"]: tree for tree in old_asset["trees"]}
    trees = []
    for placemark in sorted(
        kml.placemarks("10 Trees"), key=lambda pm: fields(pm)["asset_id"]
    ):
        meta = fields(placemark)
        code = meta["asset_id"]
        old = old_by_code.get(code)
        if old is None:
            raise SystemExit(f"Tree {code} has no stable id in the existing asset")
        zone = meta["irrigation_zone_id"]
        if zone not in zone_uuids:
            raise SystemExit(f"Tree {code} zone {zone} missing from the zone map")
        lng, lat = coordinates(placemark)[0]
        trees.append(
            {
                "id": old["id"],
                "code": code,
                "section": meta["section"],
                "zoneId": zone_uuids[zone],
                "row": int(meta["row_number"]),
                "number": int(meta["tree_number_in_row"]),
                "lat": lat,
                "lng": lng,
                "health": old["health"],
                "type": old["type"],
                "color": meta["zone_color_hex"],
            }
        )

    per_section = {}
    for tree in trees:
        per_section[tree["section"]] = per_section.get(tree["section"], 0) + 1
    sections = []
    for placemark in sorted(
        kml.placemarks("02 Farm Sections"),
        key=lambda pm: fields(pm)["section_code"],
    ):
        meta = fields(placemark)
        code = meta["section_code"]
        count = per_section.get(code, 0)
        sections.append(
            {
                "id": code,
                "name": f"Section {code}",
                "area": float(meta["area_m2"]),
                "planted": count > 0,
                "treeCount": count,
                "polygon": coordinates(placemark),
            }
        )
    return sections, trees


def build_branch_lines(kml, zone_uuids):
    lines = []
    for placemark in kml.placemarks("06 Branch Lines"):
        meta = fields(placemark)
        record = {
            "assetId": meta["asset_id"],
            "name": name_of(placemark),
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


def build_valves(kml, zone_uuids):
    # The naming convention is the topology: Mainline Isolation Valve NN is
    # the shutoff for Irrigation Submain NN.
    submain_lines = {}
    for placemark in kml.placemarks("05 Submains"):
        meta = fields(placemark)
        submain_lines[meta["asset_id"].split("-")[-1]] = coordinates(placemark)
    mosque_line = None
    for placemark in kml.placemarks("04 Water Source & Supply"):
        if fields(placemark).get("asset_type") == "mosque_supply_line":
            mosque_line = coordinates(placemark)

    valves = []
    for placemark in kml.placemarks("07 Valves"):
        meta = fields(placemark)
        record = point_record(placemark, meta)
        optional(record, "zoneId", meta.get("irrigation_zone_id"))
        optional(record, "zoneUuid", zone_uuids.get(meta.get("irrigation_zone_id")))
        optional(record, "color", meta.get("zone_color_hex"))
        if "irrigation_zone_tree_count" in meta:
            record["zoneTreeCount"] = int(meta["irrigation_zone_tree_count"])
        if meta["asset_type"] == "isolation_valve":
            number = record["assetId"].split("-")[-1]
            if "-ML-" in record["assetId"] and number in submain_lines:
                record["downstreamSubmains"] = [number]
                record["downstreamLine"] = [
                    [lng, lat] for lng, lat in submain_lines[number]
                ]
            elif mosque_line is not None:
                record["downstreamSubmains"] = []
                record["downstreamLine"] = [[lng, lat] for lng, lat in mosque_line]
        valves.append(record)
    return sorted(valves, key=lambda item: item["assetId"])


def build_points(kml, folder_name):
    return sorted(
        (
            point_record(placemark, fields(placemark))
            for placemark in kml.placemarks(folder_name)
        ),
        key=lambda item: item["assetId"],
    )


def build_water_supply(kml):
    """Folder 04 minus features drawn by other layers (the mainline lives in
    waterLines; tank polygons live in utilities)."""
    points, lines, polygons = [], [], []
    for placemark in kml.placemarks("04 Water Source & Supply"):
        meta = fields(placemark)
        asset_type = meta.get("asset_type")
        if asset_type == "mainline":
            continue
        if asset_type == "water_tank":
            continue
        if placemark.find(".//k:Point", NS) is not None:
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
    parser.add_argument("--zones", default="reference/zone_uuid_map.json")
    parser.add_argument(
        "--generated-from",
        default=None,
        help="Recorded source name (defaults to the existing asset's value)",
    )
    args = parser.parse_args()

    with open(args.asset, encoding="utf-8") as handle:
        old_asset = json.load(handle)
    with open(args.zones, encoding="utf-8") as handle:
        zone_uuids = json.load(handle)

    kml = Kml(args.kmz)
    sections, trees = build_sections_and_trees(kml, old_asset, zone_uuids)

    asset = {
        "generatedFrom": args.generated_from or old_asset["generatedFrom"],
        "bounds": old_asset["bounds"],
        "sections": sections,
        "trees": trees,
        "layout": build_layout(kml),
        "utilities": build_utilities(kml),
        "waterLines": build_water_lines(kml),
        "branchLines": build_branch_lines(kml, zone_uuids),
        "valves": build_valves(kml, zone_uuids),
        "flushValves": build_points(kml, "08 Flush Valves"),
        "risers": build_points(kml, "09 Distribution Risers"),
        "waterSupply": build_water_supply(kml),
    }

    # Reference contract: totals and per-section counts must hold.
    if len(asset["sections"]) != 12 or len(asset["trees"]) != 1567:
        raise SystemExit("Reference contract broken: 12 sections / 1567 trees")
    old_counts = {s["id"]: s["treeCount"] for s in old_asset["sections"]}
    new_counts = {s["id"]: s["treeCount"] for s in asset["sections"]}
    if old_counts != new_counts:
        raise SystemExit(f"Per-section counts changed: {old_counts} -> {new_counts}")
    for point in (p for t in asset["trees"] for p in [(t["lng"], t["lat"])]):
        bounds = asset["bounds"]
        if not (
            bounds["minLng"] <= point[0] <= bounds["maxLng"]
            and bounds["minLat"] <= point[1] <= bounds["maxLat"]
        ):
            raise SystemExit(f"Tree outside recorded bounds: {point}")

    ordered = {key: asset[key] for key in OUTPUT_KEYS}
    with open(args.asset, "w", encoding="utf-8") as handle:
        json.dump(ordered, handle, ensure_ascii=False, separators=(",", ":"))

    old_trees = {tree["code"]: tree for tree in old_asset["trees"]}
    rezoned = sum(
        1
        for tree in asset["trees"]
        if old_trees[tree["code"]]["zoneId"] != tree["zoneId"]
    )
    print(
        json.dumps(
            {
                "trees": len(asset["trees"]),
                "treesRezoned": rezoned,
                "utilities": len(asset["utilities"]),
                "waterLines": len(asset["waterLines"]),
                "branchLines": len(asset["branchLines"]),
                "valves": len(asset["valves"]),
                "flushValves": len(asset["flushValves"]),
                "risers": len(asset["risers"]),
            }
        )
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
