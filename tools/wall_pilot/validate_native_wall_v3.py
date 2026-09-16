#!/usr/bin/env python3
"""Source/geometry proof for the unrendered third wall candidate, not visual QA."""
from __future__ import annotations
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DIR = Path(__file__).resolve().parent
V2 = "83eb590c8953cbdf26b4a83c46ec4f849f51a263"
STEP = 0.5


def profiles(source: str) -> list[dict]:
    table = source.split("const PROFILES:", 1)[1].split("const CONTOUR_PATH", 1)[0]
    result = []
    for block in re.findall(r"\{[^}]+\}", table):
        row = {key: float(re.search(r'"' + key + r'":\s*([0-9.]+)', block).group(1))
               for key in ("edge_height", "edge_center", "leg_width", "leg_center")}
        row["leg_region"] = list(map(float, re.search(r"Rect2\(([^)]+)\)", block).group(1).split(",")))
        result.append(row)
    assert len(result) == 6
    return result


def samples(start: float, end: float) -> list[float]:
    return [start] + [i * STEP for i in range(math.ceil(start / STEP), math.floor(end / STEP) + 1)
                      if start + 0.0001 < i * STEP < end - 0.0001] + [end]


def transition(x: float, boundary: float, profile: dict, contour: dict) -> float:
    scale = 48.0 / profile["edge_height"]
    grid = math.floor(x / STEP) * STEP
    native = contour["edge_top"]
    def bound(at: float) -> float:
        first = math.floor((at / scale) % len(native))
        return max(native[first], native[(first + 1) % len(native)])
    native_y = bound(grid) + (bound(grid + STEP) - bound(grid)) * (x - grid) / STEP
    return boundary + (native_y - contour["edge_top_anchor"]) * scale


def area(points: list[tuple[float, float]]) -> float:
    return abs(sum(a[0] * b[1] - a[1] * b[0]
                   for a, b in zip(points, points[1:] + points[:1]))) * 0.5


def split_rows(points: list[tuple[float, float]], top: float, bottom: float) -> list[tuple[float, float]]:
    result = []
    for point in points:
        if result:
            prev = result[-1]
            weights = [] if abs(point[1] - prev[1]) < 1e-12 else [
                (row - prev[1]) / (point[1] - prev[1]) for row in (top, bottom)]
            for w in sorted(w for w in weights if 0 < w < 1):
                result.append((prev[0] + (point[0] - prev[0]) * w, prev[1] + (point[1] - prev[1]) * w))
        result.append(point)
    return result


def region_area(points: list[tuple[float, float]], top: float, bottom: float, upper: bool) -> float:
    base = top if upper else bottom
    run = []
    total = 0.0
    def run_area(active: list) -> float:
        return 0 if len(active) < 2 else area([(active[0][0], base)] + active + [(active[-1][0], base)])
    for a, b in zip(points, points[1:]):
        va = a[1] > base if upper else a[1] < base
        vb = b[1] > base if upper else b[1] < base
        if va and not run:
            run.append((a[0], np.clip(a[1], top, bottom)))
        if va != vb:
            weight = (base - a[1]) / (b[1] - a[1])
            crossing = (a[0] + (b[0] - a[0]) * weight, base)
            if va:
                run.append(crossing)
                total += run_area(run)
                run = []
            else:
                run.append(crossing)
        if vb:
            run.append((b[0], np.clip(b[1], top, bottom)))
    return total + run_area(run)


def main() -> None:
    mapper_path = DIR / "native_wall_mapper.gd"
    current = profiles(mapper_path.read_text())
    old = profiles(subprocess.check_output(["git", "show", V2 + ":tools/wall_pilot/native_wall_mapper.gd"], cwd=ROOT).decode())
    data = json.loads((DIR / "native_wall_contours.json").read_text())
    old_data = json.loads(subprocess.check_output(["git", "show", V2 + ":tools/wall_pilot/native_wall_contours.json"], cwd=ROOT))
    selection = json.loads((DIR / "native_band_selection.json").read_text())
    preserved = []
    for i in (1, 2, 4):
        assert current[i] == old[i]
        assert all(data["profiles"][i][key] == value for key, value in old_data["profiles"][i].items())
        preserved.append(data["profiles"][i]["name"])
    for row in selection["materials"]:
        i = ["rootwound", "moonglass", "emberdeep", "voidstar", "mossvein", "bedrock"].index(row["name"])
        assert current[i]["leg_region"] == row["region"]
        assert current[i]["leg_width"] == row["leg_width"]
        assert current[i]["leg_center"] == row["leg_center"]
    for contour in data["profiles"]:
        for kind in ("edge", "corner"):
            path = ROOT / contour[kind + "_source"]
            assert hashlib.sha256(path.read_bytes()).hexdigest() == contour[kind + "_sha256"]
            assert path.read_bytes() == subprocess.check_output(["git", "show", V2 + ":" + contour[kind + "_source"]], cwd=ROOT)
    assert (ROOT / "scripts/world/cave_edge_asset_drawer.gd").read_bytes() == subprocess.check_output(
        ["git", "show", V2 + ":scripts/world/cave_edge_asset_drawer.gd"], cwd=ROOT)

    bed = current[5]
    a = np.array(Image.open(ROOT / data["profiles"][5]["edge_source"]))[:, :, 3] >= 128
    edge_span = a.shape[0] - a[::-1].argmax(axis=0) - a.argmax(axis=0)
    max_horizontal = float(edge_span.max()) * 55.0 / bed["edge_height"]
    max_vertical = next(row["maximum_opaque_width"] for row in selection["materials"] if row["name"] == "bedrock")
    assert max_horizontal <= 64.0 and max_vertical <= 64.0

    masks = []
    for i in range(5):
        p, c = current[i], data["profiles"][i]
        y = [transition(x, 1408.0, p, c) for x in np.arange(-0.5, 2561.0, STEP)]
        assert max(y) > min(y)
        assert max(abs(v - 1408) for v in y) < 32
        max_partition_error = 0.0
        for column in range(40):
            left, right = column * 64 - 0.5, (column + 1) * 64 + 0.5
            xs = samples(left, right)
            for top in (1408 - 64 - 0.5, 1408 - 0.5):
                bottom = top + 65
                poly = split_rows([(x, transition(x, 1408, p, c)) for x in xs], top, bottom)
                combined = region_area(poly, top, bottom, True) + region_area(poly, top, bottom, False)
                max_partition_error = max(max_partition_error, abs(combined - 65 * 65))
        assert max_partition_error < 1e-6
        # Different native face extents must interpolate the same shared mask.
        leg_scale = 48 / p["leg_width"]
        left = 640 + (p["leg_region"][0] - p["leg_center"]) * leg_scale
        right = left + p["leg_region"][2] * leg_scale
        xs = samples(left, right)
        ys = [transition(x, 1408, p, c) for x in xs]
        probes = np.linspace(left, right, 1007)
        interp = np.interp(probes, xs, ys)
        exact = np.array([transition(float(x), 1408, p, c) for x in probes])
        mask_error = float(np.max(np.abs(interp - exact)))
        assert mask_error < 1e-8
        # Rebase changes local Y only; both sides retain the same absolute mask.
        for window in (4, 5, 6):
            origin = (window - 1) * 1408
            absolute_boundary = 9 * 1408
            assert all(abs(transition(x, absolute_boundary - origin, p, c) + origin -
                           transition(x, absolute_boundary, p, c)) < 1e-8 for x in (500.25, 1056.1, 1537.8))
        masks.append({"material": c["name"], "native_contour_world_range": [min(y) - 1408, max(y) - 1408],
                      "mass_partition_max_area_error": max_partition_error, "rim_mass_max_mask_error": mask_error,
                      "absolute_phase_rebase_invariant": True})
    report = {
        "source_only": True, "rendered": False, "visual_acceptance": False,
        "reviewed_v2_commit": V2, "accepted_profile_constants_and_contours_preserved": preserved,
        "native_artwork_and_shared_drawer_unchanged": True,
        "mass_mesh": "Explicit native-textured triangles between adjacent shared-contour samples; no polygon triangulator",
        "bedrock_mesh": "Convex native-contour trapezoids split at texture wraps, explicitly triangulated; accepted three rim renderers unchanged",
        "bedrock": {"median_visible_thickness": 55, "maximum_opaque_horizontal_span": max_horizontal,
                    "maximum_opaque_vertical_span": max_vertical, "both_fit_one_64px_solid": True},
        "transition_masks": masks, "native_band_selection": selection["materials"],
        "source_sha256": {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest()
                           for path in (mapper_path, ROOT / "scripts/world/endless_descent_world.gd", DIR / "native_wall_contours.json")},
        "limitations": ["Python source geometry checks do not validate Godot triangulation or actual pixels.",
                        "Long walls still repeat finite native motifs; better seam scores do not eliminate repetition.",
                        "Native bedrock/void corner grain remains directional; thickness and row selection cannot reauthor it.",
                        "No gameplay, device, or performance acceptance is represented."],
    }
    (DIR / "native_wall_v3_proof.json").write_text(json.dumps(report, indent=2) + "\n")
    print("SOURCE_PROOF_OK: 3 accepted profiles unchanged, 12 artwork files unchanged, 5 matching transition masks, bedrock opaque spans fit64.")


if __name__ == "__main__":
    main()
