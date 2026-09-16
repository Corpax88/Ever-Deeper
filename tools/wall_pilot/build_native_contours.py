#!/usr/bin/env python3
"""Measure opaque native join contours; never writes or recolors source artwork."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DEST = Path(__file__).resolve().parent
PROFILES = [
    ("rootwound", (431, 720, 165, 304)),
    ("moonglass", (486, 720, 148, 304)),
    ("emberdeep", (475, 720, 154, 304)),
    ("voidstar", (454, 720, 135, 304)),
    ("mossvein", (420, 720, 377, 304)),
    ("bedrock", (372, 720, 280, 304)),
]
OPAQUE = 250


def main() -> None:
    measured = []
    checks = []
    for name, (x, y, width, height) in PROFILES:
        version = 2 if name == "mossvein" else 1
        prefix = f"assets/{name}/cave" if name != "bedrock" else "assets/caves/ancient-bedrock"
        edge_path = f"{prefix}-edge-loop-v{version}.png"
        corner_path = f"{prefix}-corner-v{version}.png"
        edge = np.array(Image.open(ROOT / edge_path).convert("RGBA"))
        corner = np.array(Image.open(ROOT / corner_path).convert("RGBA"))
        edge_core = edge[:, :, 3] >= OPAQUE
        leg_core = corner[y:y + height, x:x + width, 3] >= OPAQUE
        assert edge_core.any(axis=0).all(), (name, "empty edge core column")
        assert leg_core.any(axis=1).all(), (name, "empty leg core row")
        top = edge_core.argmax(axis=0)
        bottom = edge.shape[0] - 1 - edge_core[::-1].argmax(axis=0)
        left = x + leg_core.argmax(axis=1)
        right = x + width - 1 - leg_core[:, ::-1].argmax(axis=1)
        # Each contour value must identify an actual opaque pixel in the source,
        # not a box fitted to the source or a generated rounded-corner mask.
        xs = np.arange(edge.shape[1])
        ys = np.arange(y, y + height)
        assert (edge[top, xs, 3] >= OPAQUE).all()
        assert (edge[bottom, xs, 3] >= OPAQUE).all()
        assert (corner[ys, left, 3] >= OPAQUE).all()
        assert (corner[ys, right, 3] >= OPAQUE).all()
        measured.append({
            "name": name,
            "edge_top": top.tolist(), "edge_bottom": bottom.tolist(),
            "leg_left": left.tolist(), "leg_right": right.tolist(),
            "edge_source": edge_path, "corner_source": corner_path,
            "edge_sha256": hashlib.sha256((ROOT / edge_path).read_bytes()).hexdigest(),
            "corner_sha256": hashlib.sha256((ROOT / corner_path).read_bytes()).hexdigest(),
        })
        checks.append({
            "name": name, "all_contour_samples_are_native_opaque_pixels": True,
            "sample_count": 2 * (len(top) + len(left)),
            "minimum_edge_core_span": int((bottom - top + 1).min()),
            "minimum_leg_core_span": int((right - left + 1).min()),
            "vertical_band_wrap_is_authored_seamless": False,
        })
    (DEST / "native_wall_contours.json").write_text(json.dumps({
        "alpha_threshold": OPAQUE, "profiles": measured,
    }, separators=(",", ":")) + "\n")
    (DEST / "native_wall_source_validation.json").write_text(json.dumps({
        "source_only": True, "visual_acceptance": False,
        "source_artwork_modified": False, "checks": checks,
        "limitations": [
            "Opaque contours validate source coverage, not rendered join appearance.",
            "The vertical source band still has an unauthored wrap seam requiring rendered review.",
            "No performance or gameplay checks are represented by this file.",
        ],
    }, indent=2) + "\n")
    print(f"Measured {sum(row['sample_count'] for row in checks)} native opaque contour samples across {len(checks)} materials.")


if __name__ == "__main__":
    main()
