#!/usr/bin/env python3
"""Compose the original real-time route with a V2-only option and draw signals."""
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


def replace_once(source: str, old: str, new: str) -> str:
    if source.count(old) != 1:
        raise RuntimeError(f"Changed source anchor: {old}")
    return source.replace(old, new)


def generate(output: Path) -> Path:
    route_path = ROOT / "tools/review_premium_session.gd"
    observer_path = ROOT / "tools/moving_draw_diagnosis.gd"
    candidate_path = ROOT / "tools/camera_bounds_pilot/candidate_dynamic.gd"
    route = route_path.read_text()
    observer = observer_path.read_text()
    prefix = 'extends "res://tools/review_premium_session.gd"\n'
    if not observer.startswith(prefix):
        raise RuntimeError("Observer no longer extends the expected route")
    observer = observer[len(prefix):]
    route = replace_once(route,
        'main = load("res://scenes/main/main.tscn").instantiate()',
        'main = load("res://scenes/main/main.tscn").instantiate()\n\tif "--camera-bounds-candidate" in OS.get_cmdline_user_args():\n\t\tmain.get_node("EndlessDescentWorld").set_script(load("res://tools/camera_bounds_pilot/candidate_dynamic.gd"))')
    route = replace_once(route, 'func _record_window(', 'func _record_window_base(')
    observer = replace_once(observer,
        'super._record_window(frames, cpu, draws, elapsed, distance)',
        '_record_window_base(frames, cpu, draws, elapsed, distance)')
    observer = replace_once(observer, '\t\t_sections.profile_draws = true',
        '\t\t_sections.profile_draws = true\n\t\t_sections.child_entered_tree.connect(_study_section_entered)\n\t\tfor section in _sections._pool: _study_section_entered(section)\n\t\t_study_prior_stats = _study_stats()')
    observer = replace_once(observer, '\t_pending.append(row)', '''\trow["dynamic_callbacks_actual"] = _study_dynamic_pending.size()
\trow["dynamic_callback_poses"] = _study_dynamic_pending.duplicate(true)
\t_study_dynamic_pending.clear()
\tvar study_now: Dictionary = _study_stats()
\tfor key in study_now:
\t\trow["study_" + key] = int(study_now[key]) - int(_study_prior_stats.get(key, 0))
\t_study_prior_stats = study_now
\t# Include the added signal/pose observer work in its own overhead timer.
\trow["observer_usec"] = Time.get_ticks_usec() - observer_started
\t_pending.append(row)''')
    observer = replace_once(observer,
        '\trow["terrain_cache"] = _sections.debug_snapshot()',
        '\trow["terrain_cache"] = _sections.debug_snapshot()\n\trow["camera_bounds_study"] = world.study_snapshot() if world.has_method("study_snapshot") else {"candidate": false}')
    observer = replace_once(observer, '"observer_usec", "shadow_casters"]:',
        '"observer_usec", "shadow_casters", "dynamic_callbacks_actual", "study_key_usec", "study_skipped_setups", "study_dynamic_requeues", "study_original_requests"]:')
    observer += '''

var _study_dynamic_pending: Array[Dictionary] = []
var _study_prior_stats: Dictionary = {}

func _study_stats() -> Dictionary:
\tif not world.has_method("study_snapshot"): return {}
\treturn {"key_usec":world.study_key_usec,"skipped_setups":world.study_skipped_setups,
\t\t"dynamic_requeues":world.study_dynamic_requeues,"original_requests":world.study_original_requests}

func _study_section_entered(section: Node) -> void:
\t# add() puts new dynamic sections in _pool before add_child(). Attach before
\t# their first actual draw, without replacing the production paint callable.
\tif not _sections._pool.has(section): return
\tvar callback: Callable = _study_dynamic_draw.bind(section)
\tif not section.is_connected(&"draw", callback): section.connect(&"draw", callback)

func _study_dynamic_draw(section: Node) -> void:
\tvar arguments: Array = section.paint.get_bound_arguments()
\tvar pose: Dictionary = {"time_usec":Time.get_ticks_usec(),"drawn_frame":Engine.get_frames_drawn(),
\t\t"sample":_sample_index,"paint_method":str(section.paint.get_method()),"visible":section.visible}
\tif arguments.size() == 1 and arguments[0] is Dictionary:
\t\tvar impact: Dictionary = arguments[0]
\t\tpose["age"] = impact.get("age", -1.0)
\t\tpose["life"] = impact.get("life", -1.0)
\t\tpose["position"] = [impact.position.x, impact.position.y]
\t_study_dynamic_pending.append(pose)
'''
    harness = output / "generated-session.gd"
    harness.write_text(route + "\n\n" + observer)
    (output / "harness-generation.json").write_text(json.dumps({
        "route_sha256": sha(route_path.read_bytes()),
        "observer_sha256": sha(observer_path.read_bytes()),
        "candidate_sha256": sha(candidate_path.read_bytes()),
        "generator_sha256": sha(Path(__file__).read_bytes()),
        "generated_sha256": sha(harness.read_bytes()),
        "limit": "Both controls use the original world. Only B substitutes V2 before scene-tree entry. All runs observe actual dynamic CanvasItem draw signals without replacing paint callables. Route, input, mining, animation, persistence and clocks are unchanged; signal/pose collection adds diagnostic overhead equally. No production source changes.",
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
