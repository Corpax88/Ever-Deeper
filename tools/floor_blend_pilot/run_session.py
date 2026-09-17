#!/usr/bin/env python3
"""Original free-running route with the isolated floor blend controller/observer."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def once(source: str, old: str, new: str) -> str:
    if source.count(old) != 1:
        raise RuntimeError(f"Changed route/observer anchor: {old}")
    return source.replace(old, new)


def generate(output: Path) -> Path:
    route_path = ROOT / "tools/review_premium_session.gd"
    observer_path = HERE / "moving_observer.gd"
    route = route_path.read_text()
    observer = observer_path.read_text()
    prefix = 'extends "res://tools/review_premium_session.gd"\n'
    if not observer.startswith(prefix):
        raise RuntimeError("Observer has an unexpected route")
    observer = observer[len(prefix):]
    anchor = '\tworld = main.hub_world if area == "hub" else main.depth_world if area == "ember" else main.endless_world'
    route = once(route, anchor, anchor + '''
\t_floor_controller = load("res://tools/floor_blend_pilot/controller.gd").new()
\troot.add_child(_floor_controller)
\t_floor_controller.configure(world)
\t_floor_controller.candidate_enabled = "--floor-blend-candidate" in OS.get_cmdline_user_args()''')
    route = once(route, 'func _record_window(', 'func _record_window_base(')
    observer = once(observer,
        'super._record_window(frames, cpu, draws, elapsed, distance)',
        '_record_window_base(frames, cpu, draws, elapsed, distance)')
    observer = once(observer, '\t_pending.append(row)', '''\tvar floor_cost: int = _floor_controller.controller_usec
\trow["floor_controller_usec"] = floor_cost - _floor_previous_cost
\t_floor_previous_cost = floor_cost
\trow["floor_active_materials"] = _floor_controller.last_material_count
\trow["floor_active_frame"] = int(_floor_controller.last_material_count > 0)
\trow["floor_fallback_frame"] = int(_floor_controller.candidate_enabled and _floor_controller.last_material_count == 0)
\trow["observer_usec"] = Time.get_ticks_usec() - observer_started
\t_pending.append(row)''')
    observer = once(observer,
        '\trow["terrain_cache"] = _sections.debug_snapshot()',
        '\trow["terrain_cache"] = _sections.debug_snapshot()\n\trow["floor_blend_study"] = _floor_controller.study_snapshot()')
    observer = once(observer, '"observer_usec", "shadow_casters"]:',
        '"observer_usec", "shadow_casters", "floor_controller_usec", "floor_active_materials", "floor_active_frame", "floor_fallback_frame"]:')
    harness = output / "generated-session.gd"
    harness.write_text(route + '\n\nvar _floor_controller: Node\nvar _floor_previous_cost: int = 0\n\n' + observer)
    (output / "harness-generation.json").write_text(json.dumps({
        "route_sha256": sha(route_path.read_bytes()),
        "observer_sha256": sha(observer_path.read_bytes()),
        "controller_sha256": sha((HERE / "controller.gd").read_bytes()),
        "generator_sha256": sha(Path(__file__).read_bytes()),
        "generated_sha256": sha(harness.read_bytes()),
        "limit": "All variants use the unchanged production world and original held-mining route. The same helper is disabled in A/A2, active in B. B's full opacity checks and shader-state changes are included in timing. No freeze, clock/input/animation substitution or production edit.",
    }, indent=2) + "\n")
    return harness


def require_parity(folder: Path) -> None:
    gate = json.loads((folder / "parity-gate.json").read_text())
    report = json.loads((folder / "floor-blend-review.json").read_text())
    log = (folder / "godot.log").read_text()
    if not gate.get("passed") or gate.get("wrapper_exit") != 0:
        raise RuntimeError("Rendered parity process/marker gate has not passed")
    if report.get("failure") or len(report.get("pairs", [])) != 22:
        raise RuntimeError("The complete 22-state parity matrix is required")
    if "FLOOR_BLEND_REVIEW_COMPLETE" not in log or "FLOOR_BLEND_REVIEW_FINISHED" not in log:
        raise RuntimeError("Both parity completion markers are required")
    if report["controller_sha256"] != sha((HERE / "controller.gd").read_bytes()):
        raise RuntimeError("Controller changed since graphical parity")
    for pair in report["pairs"]:
        if pair["candidate_diff"]["changed_pixels"] or pair["restored_diff"]["changed_pixels"]:
            raise RuntimeError("Pixel parity failed")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--variant", choices=["original", "candidate"], required=True)
    parser.add_argument("--source-revision", required=True)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--xvfb", type=Path, required=True)
    parser.add_argument("--parity-evidence", type=Path)
    parser.add_argument("--seconds", type=float, default=60)
    parser.add_argument("--generate-only", action="store_true")
    args = parser.parse_args()
    if not args.generate_only:
        if args.parity_evidence is None:
            parser.error("--parity-evidence is required before any timed run")
        require_parity(args.parity_evidence)
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
    if args.variant == "candidate": command.append("--floor-blend-candidate")
    (output / "launch.json").write_text(json.dumps(command, indent=2) + "\n")
    return subprocess.call(command, cwd=ROOT)


if __name__ == "__main__":
    raise SystemExit(main())
