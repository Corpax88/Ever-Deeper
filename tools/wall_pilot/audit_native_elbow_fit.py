#!/usr/bin/env python3
"""Measure the existing upright elbow against V3's physical corner anchors.

This is a source-space feasibility audit. It writes JSON, never artwork, and is
not a renderer, a gameplay test, or visual acceptance of any wall candidate.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE = "assets/caves/ancient-bedrock-corner-v1.png"
BASE = "90ac772232b8506f7146a495e8ae613cd178f663"
REFERENCES = (
    SOURCE,
    "assets/caves/ancient-bedrock-edge-loop-v1.png",
    "assets/voidstar/cave-corner-v1.png",
    "assets/voidstar/cave-edge-loop-v1.png",
    "tools/wall_pilot/native_wall_mapper.gd",
    "tools/wall_pilot/native_wall_contours.json",
    "tools/wall_pilot/native_wall_v3_proof.json",
    "scripts/world/cave_edge_asset_drawer.gd",
    "scripts/world/endless_descent_world.gd",
)


def main() -> None:
    reference_hashes = {}
    for reference in REFERENCES:
        original = subprocess.check_output(["git", "show", BASE + ":" + reference], cwd=ROOT)
        current = (ROOT / reference).read_bytes()
        if current != original:
            raise RuntimeError("Reference differs from preserved V3: " + reference)
        reference_hashes[reference] = hashlib.sha256(current).hexdigest()
    path = ROOT / SOURCE
    alpha = np.array(Image.open(path).convert("RGBA"))[:, :, 3]
    opaque = alpha >= 250
    scale = 55.0 / 243.0
    bias = 55.0 / 2.0 - 8.0

    # Use the horizontal arm just before the authored bend. The vertical
    # center/width remain the exact measured V3 production-source profile.
    columns = np.arange(256, 341)
    top = opaque[:, columns].argmax(axis=0)
    bottom = alpha.shape[0] - 1 - opaque[::-1, columns].argmax(axis=0)
    native_horizontal_center = float(np.median((top + bottom) * 0.5))
    native_vertical_center = 511.5
    vertex = np.array([
        native_vertical_center + bias / scale,
        native_horizontal_center - bias / scale,
    ])

    ys, xs = np.nonzero(opaque)
    opaque_points = np.column_stack((xs, ys))
    squared = ((opaque_points - vertex) ** 2).sum(axis=1)
    nearest = opaque_points[int(np.argmin(squared))]
    translation = (vertex - nearest) * scale

    samples = []
    for offset in ((0, 0), (-8, 0), (0, 8), (-8, 8), (-16, 16), (-24, 24)):
        source = vertex + np.array(offset) / scale
        x, y = np.rint(source).astype(int)
        samples.append({
            "world_offset_from_physical_ne_vertex": list(offset),
            "native_sample_xy": [int(x), int(y)],
            "native_alpha": int(alpha[y, x]),
        })

    result = {
        "base_commit": BASE,
        "source_only": True,
        "rendered": False,
        "visual_acceptance": False,
        "source_artwork_modified": False,
        "proposed_correction": "Use the actual upright bedrock elbow instead of intersecting two straight native bands at a NE turn.",
        "source": SOURCE,
        "source_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "preserved_reference_sha256": reference_hashes,
        "all_references_byte_identical_to_base": True,
        "alpha_threshold": 250,
        "v3_tile_size": 64,
        "v3_visible_leg_thickness": 55,
        "v3_floor_overlap": 8,
        "uniform_scale": scale,
        "native_horizontal_measurement_columns_inclusive": [256, 340],
        "native_horizontal_center": native_horizontal_center,
        "native_horizontal_median_opaque_height": float(np.median(bottom - top + 1)),
        "native_vertical_center": native_vertical_center,
        "physical_ne_vertex_in_source": vertex.tolist(),
        "nearest_opaque_native_pixel": nearest.tolist(),
        "nearest_opaque_distance_world_px": float(np.sqrt(squared.min()) * scale),
        "translation_to_put_that_pixel_on_physical_corner": translation.tolist(),
        "samples": samples,
        "fit_status": "rejected_before_runtime_integration",
        "reason": "At the existing two arm anchors the physical corner and 8px-inside samples are transparent. Moving the native elbow to cover them changes both arm alignment and floor intrusion. Stamping, clipping, or fading does not supply the missing correctly placed grain.",
        "limits": [
            "This audits one measured upright NE placement, not all conceivable placements or orientations.",
            "No claim is made that source alpha alone proves the final game's appearance.",
            "No mass, collision, lighting, gameplay, or shared drawer changes are included.",
            "Voidstar repetition and the other seven bedrock turn cases remain unresolved.",
        ],
    }
    destination = Path(__file__).with_name("native_elbow_fit_audit.json")
    destination.write_text(json.dumps(result, indent=2) + "\n")
    print(f"NATIVE_ELBOW_FIT_REJECTED: physical corner alpha=0; nearest opaque point {result['nearest_opaque_distance_world_px']:.2f} world px away. No runtime integration.")


if __name__ == "__main__":
    main()
