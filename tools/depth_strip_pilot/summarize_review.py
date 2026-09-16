#!/usr/bin/env python3
"""Recompute three completed native study runs; keep every parity discrepancy."""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image


def comparison(first, second):
    a = np.asarray(Image.open(first).convert("RGBA"), dtype=np.int16)
    b = np.asarray(Image.open(second).convert("RGBA"), dtype=np.int16)
    if a.shape != b.shape:
        return {"equal": False, "shape_mismatch": [list(a.shape), list(b.shape)]}
    delta = np.abs(a - b)
    mask = np.any(delta != 0, axis=2)
    ys, xs = np.nonzero(mask)
    return {
        "equal": not bool(mask.any()),
        "changed_pixels": int(mask.sum()),
        "max_channel_delta": int(delta.max()),
        "bbox": [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1] if xs.size else None,
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", required=True, type=Path)
    parser.add_argument("--candidate", required=True, type=Path)
    parser.add_argument("--restored", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    roots = {"A": args.reference, "B": args.candidate, "A2": args.restored}
    data = {key: json.loads((path / "depth-strip-review.json").read_text()) for key, path in roots.items()}
    result = {"scope": "Frozen Depth 2 strip redraw study, not sustained gameplay or physical iPhone", "runs": {}, "pairs": []}
    for key, report in data.items():
        timing = report["timing"]
        intervals = np.asarray(timing["intervals_ms"])
        cpu = {name: timing["after"][name] - timing["before"][name] for name in ["setup_usec", "draw_callback_usec", "draw_callbacks", "redraws", "reuses"]}
        result["runs"][key] = {
            "complete": report["complete"], "passed": report["passed"], "failures": report["failures"],
            "frames": len(intervals), "seconds": float(intervals.sum() / 1000),
            "fps": float(1000 * len(intervals) / intervals.sum()),
            "p95_ms": float(np.sort(intervals)[int(len(intervals) * .95)]),
            "mutations": timing["mutations"], "counter_deltas": cpu,
        }
    result["same_source_hashes"] = data["A"]["source_sha256"] == data["B"]["source_sha256"] == data["A2"]["source_sha256"]
    result["same_timing_lights"] = data["A"]["timing"]["lights"] == data["B"]["timing"]["lights"] == data["A2"]["timing"]["lights"]
    result["same_starting_terrain"] = len({data[key]["timing"]["terrain_hash_at_start"] for key in roots}) == 1
    for row in data["B"]["pairs"]:
        case = row["id"]
        item = {"id": case, "within_run": {key: comparison(path / f"{case}-cached.png", path / f"{case}-fresh.png") for key, path in roots.items()}}
        item["candidate_vs_reference_fresh"] = comparison(args.candidate / f"{case}-fresh.png", args.reference / f"{case}-fresh.png")
        item["restored_vs_reference_fresh"] = comparison(args.restored / f"{case}-fresh.png", args.reference / f"{case}-fresh.png")
        result["pairs"].append(item)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({key: value for key, value in result.items() if key != "pairs"}, indent=2))
    print("cross_run_fresh_mismatches", [row["id"] for row in result["pairs"] if not row["candidate_vs_reference_fresh"]["equal"] or not row["restored_vs_reference_fresh"]["equal"]])


if __name__ == "__main__":
    main()
