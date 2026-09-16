#!/usr/bin/env python3
"""Generate the exact baseline outside production, then run one isolated gate."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
BASE = "c8906f1d46309227344f101a6b0ae7c1a9b1e69b"
OWNER = "scripts/world/cave_edge_asset_drawer.gd"


def generate(output):
    original = subprocess.check_output(["git", "show", f"{BASE}:{OWNER}"], cwd=ROOT)
    # Avoid registering another global class; all original functions are intact.
    source = original.decode().replace("class_name CaveEdgeAssetDrawer\n", "", 1)
    assert source.encode() != original
    output.mkdir(parents=True, exist_ok=True)
    reference = output / "reference_drawer.gd"
    reference.write_text(source)
    (output / "reference-receipt.json").write_text(json.dumps({
        "base": BASE, "owner": OWNER,
        "original_sha256": hashlib.sha256(original).hexdigest(),
        "generated_sha256": hashlib.sha256(source.encode()).hexdigest(),
        "transformation": "Remove only class_name CaveEdgeAssetDrawer declaration; original methods and constants unchanged",
    }, indent=2) + "\n")
    return reference


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--generate-only", action="store_true")
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists() and any(output.iterdir()):
        parser.error("Use a new empty output directory; preserve every prior attempt")
    reference = generate(output)
    if args.generate_only:
        print(reference)
        return 0
    command = [sys.executable, str(ROOT / "tools/run_rendered_isolated.py"),
        "--godot", "/tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64",
        "--xvfb", "/workspace/scratch/4e99473f21fc/runtime/xvfb/usr/bin/Xvfb",
        "--project", str(ROOT), "--output", str(output), "--resolution", "1696x780",
        "--timeout", "240", "--completion-marker", "CORNER_MATRIX_FINISHED",
        "--", "--verbose", "--render-thread", "safe", "--script", "res://tools/corner_quad_pilot/review_matrix.gd",
        "--", f"--output={output}", f"--reference-script={reference}"]
    (output / "launch.json").write_text(json.dumps(command, indent=2) + "\n")
    started = time.monotonic()
    code = subprocess.call(command, cwd=ROOT)
    (output / "process-result.json").write_text(json.dumps({
        "returncode": code, "process_wall_seconds": time.monotonic() - started,
        "limit": "Total wrapper/runtime wall duration; not a measured gameplay or frame interval",
    }, indent=2) + "\n")
    return code


if __name__ == "__main__":
    raise SystemExit(main())
