#!/usr/bin/env python3
"""Summarize paired receiver renders without substituting for visual acceptance."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image


def difference(reference: Path, candidate: Path) -> dict:
    left = np.asarray(Image.open(reference).convert("RGBA"), dtype=np.int16)
    right = np.asarray(Image.open(candidate).convert("RGBA"), dtype=np.int16)
    if left.shape != right.shape:
        raise ValueError(f"Framebuffer sizes differ: {reference.name}, {candidate.name}")
    delta = np.abs(left - right)
    changed = np.any(delta > 0, axis=2)
    rows, columns = np.nonzero(changed)
    return {
        "reference": reference.name,
        "candidate": candidate.name,
        "size": [left.shape[1], left.shape[0]],
        "max_channel_delta": int(delta.max()),
        "mean_channel_delta": float(delta.mean()),
        "changed_pixels": int(changed.sum()),
        "changed_percent": float(changed.mean() * 100),
        "changed_bounds": (
            [int(columns.min()), int(rows.min()), int(columns.max() + 1), int(rows.max() + 1)]
            if rows.size else None
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    pairs = []
    references = sorted(args.output.glob("*-broad.png"))
    if not references:
        parser.error("No broad/narrow/restored captures found")
    for reference in references:
        stem = reference.name.removesuffix("-broad.png")
        pairs.append({
            "fixture": stem,
            "candidate": difference(reference, reference.with_name(stem + "-narrow.png")),
            "control": difference(reference, reference.with_name(stem + "-restored.png")),
        })
    report = {
        "physical_iphone": False,
        "visual_acceptance": "Requires inspection of actual renders",
        "reference_controls_exact": all(pair["control"]["changed_pixels"] == 0 for pair in pairs),
        "candidate_exact": all(pair["candidate"]["changed_pixels"] == 0 for pair in pairs),
        "pairs": pairs,
    }
    (args.output / "hub-receiver-image-differences.json").write_text(
        json.dumps(report, indent=2) + "\n"
    )
    print(json.dumps(report, indent=2))
    return 0 if report["reference_controls_exact"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
