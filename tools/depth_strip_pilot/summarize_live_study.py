#!/usr/bin/env python3
"""Recompute elapsed time and per-window progress from the moving A/B/A study."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import re


def percentile(values, fraction):
    return sorted(values)[min(len(values) - 1, math.floor(len(values) * fraction))]


def same_number(first, second):
    return math.isclose(first, second, rel_tol=1e-10, abs_tol=1e-8)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--restored", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    roots = {"A": args.reference, "B": args.candidate, "A2": args.restored}
    data = {key: json.loads((path / "session.json").read_text()) for key, path in roots.items()}
    generations = {key: json.loads((path / "harness-generation.json").read_text()) for key, path in roots.items()}
    result = {"scope": "60-second real-time Ember excavation with ordinary input and physics, serialized reference/local/reference on Linux llvmpipe", "runs": {}}
    for key, report in data.items():
        root = roots[key]
        log = (root / "godot.log").read_text()
        intervals = [value for row in report["windows"] for value in row["intervals_ms"]]
        elapsed = sum(intervals) / 1000
        checks = []
        for row in report["windows"]:
            frames = row["intervals_ms"]
            actual = sum(frames) / 1000
            checks.append({
                "actual_seconds": actual, "frames": len(frames),
                "fps": len(frames) / actual, "p95_ms": percentile(frames, .95),
                "distance_delta": row["distance_delta"], "mined_delta": row["mined_delta"], "removed_delta": row["removed_delta"],
                "valid_progress": row["distance_delta"] > 48 and row["mined_delta"] > 0 and row["removed_delta"] > 0,
                "reported_values_match": len(frames) == row["frames"] and same_number(actual, row["actual_seconds"]) and same_number(len(frames) / actual, row["average_fps"]) and percentile(frames, .95) == row["p95_ms"],
            })
        # Profiling starts before warmup, so the first snapshot is not zero.
        # Subtract two measured snapshots for an honest final-five-window cost.
        first, last = report["windows"][0], report["windows"][-1]
        counters = {name: last["terrain_cache"][name] - first["terrain_cache"][name] for name in ["redraws", "reuses", "draw_callbacks", "setup_usec", "draw_callback_usec"]}
        counter_seconds = sum(row["actual_seconds"] for row in report["windows"][1:])
        counters["combined_setup_draw_usec"] = counters["setup_usec"] + counters["draw_callback_usec"]
        result["runs"][key] = {
            "variant": report["cache_variant"], "reported_functional": report["functional"],
            "completion_marker": "PREMIUM_SESSION_COMPLETE area=ember functional=true" in log,
            "runtime_errors": len(re.findall(r"^(?:SCRIPT ERROR|ERROR):", log, flags=re.MULTILINE)),
            "dummy_audio_warnings": log.count("driver doesn't support sample playback"),
            "seconds": elapsed, "requested_seconds": report["seconds"], "reported_seconds_match": same_number(elapsed, report["actual_seconds"]),
            "frames": len(intervals), "fps": len(intervals) / elapsed, "p95_ms": percentile(intervals, .95), "p99_ms": percentile(intervals, .99),
            "distance": report["distance"], "mined_resources": report["mined_resources"], "removed_cells": sum(row["removed_delta"] for row in report["windows"]),
            "mined_window_sum_matches_total": sum(row["mined_delta"] for row in report["windows"]) == report["mined_resources"],
            "first_target_mined_before": report["route_targets"][0]["mined_before"],
            "windows": checks, "all_windows_progressed": all(row["valid_progress"] and row["reported_values_match"] for row in checks),
            "counter_window_seconds": counter_seconds, "counter_deltas": counters,
            "combined_setup_draw_ms_per_second": counters["combined_setup_draw_usec"] / 1000 / counter_seconds,
            "route_targets": len(report["route_targets"]), "planner_usec": last["planner_usec"], "planner_max_usec": last["planner_max_usec"],
            "generated_harness_matches_receipt": hashlib.sha256((root / "generated-live-session.gd").read_bytes()).hexdigest() == report["harness_sha256"] == generations[key]["harness_sha256"],
            "renderer": report["renderer"], "framebuffer_size": report["framebuffer_size"], "physical_iphone": report["physical_iphone"],
        }
    result["same_runtime_sha256"] = len({row["runtime_sha256"] for row in data.values()}) == 1
    result["same_generated_harness_sha256"] = len({row["harness_sha256"] for row in data.values()}) == 1
    result["same_original_harness_sha256"] = len({row["source_sha256"] for row in generations.values()}) == 1
    result["same_addon_sha256"] = len({row["addon_sha256"] for row in generations.values()}) == 1
    result["same_seed_renderer_viewport"] = len({(row["seed"], row["renderer"], tuple(row["framebuffer_size"])) for row in data.values()}) == 1
    result["target_sequences_equal"] = data["A"]["route_targets"] == data["B"]["route_targets"] == data["A2"]["route_targets"]
    result["limits"] = [
        "Real input and physics permit small route/state divergence; these are not identical fixed-step workloads.",
        "Counter deltas cover the last five windows (~50 s); full cumulative counters also contain four-second warmup and are not presented as a 60 s delta.",
        "Planner, per-window report writes and sample-audio warning logging are inside observed frame intervals. TIME_PROCESS is not exclusive script CPU and is not used to attribute cost.",
        "One A/B/A triplet on software rendering does not establish physical-device FPS, battery or thermal behavior.",
        "Live images show different ordinary game trajectories; exact pixel parity is provided by the separate 27-state frozen cache review.",
    ]
    result["valid_measurement"] = all(
        row["completion_marker"] and row["runtime_errors"] == 0
        and row["all_windows_progressed"] and row["generated_harness_matches_receipt"]
        and row["reported_seconds_match"] and row["mined_window_sum_matches_total"]
        and row["requested_seconds"] <= row["seconds"] < row["requested_seconds"] + 2
        and row["variant"] == ("local" if key == "B" else "reference")
        for key, row in result["runs"].items()
    ) and all(result[key] for key in ["same_runtime_sha256", "same_generated_harness_sha256", "same_original_harness_sha256", "same_addon_sha256", "same_seed_renderer_viewport"])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({key: {name: value for name, value in row.items() if name != "windows"} for key, row in result["runs"].items()}, indent=2))
    if result["valid_measurement"]:
        print("DEPTH_STRIP_LIVE_COMPARISON_COMPLETE valid=true")
    else:
        raise SystemExit(4)


if __name__ == "__main__":
    main()
