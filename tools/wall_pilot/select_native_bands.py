#!/usr/bin/env python3
"""Select native, upright leg rows by repeat-seam difference; never edit pixels."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent / "native_band_selection.json"
# Lower bounds exclude each authored bend. Minimum lengths favor a longer
# repeat without claiming that a short native corner becomes nonrepeating.
SEARCHES = [("rootwound", 605, 352, 48.0), ("voidstar", 605, 320, 48.0), ("bedrock", 682, 305, 55.0)]


def analyze(name: str, first_row: int, minimum_span: int, thickness: float) -> dict:
    path = f"assets/{name}/cave-corner-v1.png" if name != "bedrock" else "assets/caves/ancient-bedrock-corner-v1.png"
    rgba = np.array(Image.open(ROOT / path).convert("RGBA"), dtype=float)
    alpha = rgba[:, :, 3] / 255.0
    features = np.concatenate((rgba[:, :, :3] * alpha[:, :, None], rgba[:, :, 3:4]), axis=2)

    def score(start: int, end: int) -> tuple[float, float, float]:
        first = features[start:start + 3].mean(axis=0)
        last = features[end - 3:end].mean(axis=0)
        occupied = (first[:, 3] > 16) | (last[:, 3] > 16)
        rgb = float(np.abs(first[occupied, :3] - last[occupied, :3]).mean())
        silhouette = float(np.abs(first[occupied, 3] - last[occupied, 3]).mean())
        return rgb + 0.6 * silhouette, rgb, silhouette

    baseline = score(720, 1024)
    candidates = [(*score(start, end), start, end)
                  for start in range(first_row, 1024 - minimum_span + 1)
                  for end in range(start + minimum_span, 1025)]
    total, rgb, silhouette, start, end = min(candidates)
    core = rgba[start:end, :, 3] >= 128
    left = core.argmax(axis=1)
    right = 1023 - core[:, ::-1].argmax(axis=1)
    spans = right - left + 1
    width = float(np.median(spans))
    center = float(np.median((left + right) / 2))
    _, xs = np.where(rgba[start:end, :, 3] > 2)
    region = [int(xs.min()) - 4, start, int(xs.max() - xs.min()) + 9, end - start]
    return {
        "name": name, "source": path,
        "source_sha256": hashlib.sha256((ROOT / path).read_bytes()).hexdigest(),
        "search_first_row": first_row, "minimum_source_span": minimum_span,
        "candidates_examined": len(candidates), "region": region,
        "leg_width": width, "leg_center": center, "target_median_thickness": thickness,
        "uniform_scale": thickness / width,
        "world_repeat_length": (end - start) * thickness / width,
        "maximum_opaque_width": float(spans.max()) * thickness / width,
        "baseline_score": baseline[0], "selected_score": total,
        "relative_score_reduction": 1 - total / baseline[0],
        "selected_rgb_mae": rgb, "selected_alpha_mae": silhouette,
        "authored_seamless": False, "repeating_motifs_eliminated": False,
    }


def main() -> None:
    rows = [analyze(*settings) for settings in SEARCHES]
    result = {
        "source_only": True, "visual_acceptance": False, "pixels_modified": False,
        "metric": "3-row premultiplied RGB MAE + 0.6 * alpha MAE on occupied native columns; smaller is better",
        "selection": "Lowest seam score among native bands satisfying the stated minimum span; no flips, fades, or recoloring",
        "materials": rows,
        "limitation": "These finite corner PNGs cannot establish nonrepeating long walls. Endpoint scores do not establish visual acceptance or coherent crystal/bedrock direction at turns.",
    }
    OUT.write_text(json.dumps(result, indent=2) + "\n")
    for row in rows:
        print(row["name"], row["region"], f"score {row['baseline_score']:.3f} -> {row['selected_score']:.3f}",
              f"repeat {row['world_repeat_length']:.3f} world pixels")


if __name__ == "__main__":
    main()
