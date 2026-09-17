#!/usr/bin/env python3
"""Generate the unchanged route plus existing observer; opt in one world subclass."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def generate(output: Path) -> Path:
    route_path = ROOT / "tools/review_premium_session.gd"
    observer_path = ROOT / "tools/moving_draw_diagnosis.gd"
    candidate_path = ROOT / "tools/camera_bounds_pilot/candidate.gd"
    route = route_path.read_text()
    observer = observer_path.read_text()
    expected = 'extends "res://tools/review_premium_session.gd"\n'
    if not observer.startswith(expected):
        raise RuntimeError("Observer no longer extends the expected unmodified route")
    observer = observer[len(expected):]
    anchors = [
        ('main = load("res://scenes/main/main.tscn").instantiate()',
         'main = load("res://scenes/main/main.tscn").instantiate()\n\tif "--camera-bounds-candidate" in OS.get_cmdline_user_args():\n\t\tmain.get_node("EndlessDescentWorld").set_script(load("res://tools/camera_bounds_pilot/candidate.gd"))'),
        ('func _record_window(', 'func _record_window_base('),
    ]
    generated_route = route
    for old, new in anchors:
        if generated_route.count(old) != 1:
            raise RuntimeError(f"Changed route anchor: {old}")
        generated_route = generated_route.replace(old, new)
    old = 'super._record_window(frames, cpu, draws, elapsed, distance)'
    if observer.count(old) != 1:
        raise RuntimeError("Changed observer delegation")
    observer = observer.replace(old, '_record_window_base(frames, cpu, draws, elapsed, distance)')
    old = '\trow["terrain_cache"] = _sections.debug_snapshot()'
    if observer.count(old) != 1:
        raise RuntimeError("Changed observer result anchor")
    observer = observer.replace(old, old + '\n\trow["camera_bounds_study"] = world.study_snapshot() if world.has_method("study_snapshot") else {"candidate": false}')
    harness = output / "generated-session.gd"
    harness.write_text(generated_route + "\n\n" + observer)
    (output / "harness-generation.json").write_text(json.dumps({
        "route_sha256": sha(route.encode()), "observer_sha256": sha(observer_path.read_bytes()),
        "candidate_sha256": sha(candidate_path.read_bytes()),
        "generated_sha256": sha(harness.read_bytes()),
        "limit": "Both controls use the original world script. Candidate alone substitutes the camera guard before scene-tree entry. Route, movement, mining, animation, persistence, frame clock and observer are identical; no production file is edited.",
    }, indent=2) + "\n")
    return harness


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--variant", choices=["original", "candidate"], required=True)
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--xvfb", type=Path, required=True)
    parser.add_argument("--seconds", type=float, default=60)
    parser.add_argument("--generate-only", action="store_true")
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists() and any(output.iterdir()):
        parser.error("Use a fresh output directory; preserve earlier attempts")
    output.mkdir(parents=True, exist_ok=True)
    harness = generate(output)
    if args.generate_only:
        print(harness)
        return 0
    command = [sys.executable, str(ROOT / "tools/run_rendered_isolated.py"),
               "--godot", str(args.godot), "--xvfb", str(args.xvfb), "--project", str(ROOT),
               "--output", str(output), "--resolution", "1696x780", "--timeout", str(int(args.seconds) + 120),
               "--completion-marker", "PREMIUM_SESSION_COMPLETE", "--", "--script", str(harness),
               "--", f"--output={output}", "--area=deep", f"--seconds={args.seconds}",
               f"--source-revision={args.source_revision}"]
    if args.variant == "candidate": command.append("--camera-bounds-candidate")
    (output / "launch.json").write_text(json.dumps(command, indent=2) + "\n")
    return subprocess.call(command, cwd=ROOT)


if __name__ == "__main__":
    raise SystemExit(main())
