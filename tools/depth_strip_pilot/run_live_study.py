#!/usr/bin/env python3
"""Build an external, exact-source session observer and run one isolated variant."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def generate(output):
    source_path = ROOT / "tools/review_premium_session.gd"
    addon_path = Path(__file__).with_name("live_workload.gd.inc")
    original = source_path.read_text()
    addon = addon_path.read_text()
    source = original
    substitutions = [
        ('main = load("res://scenes/main/main.tscn").instantiate()', 'main = load("res://scenes/main/main.tscn").instantiate()\n\tif "--cache-reference" in OS.get_cmdline_user_args():\n\t\tmain.get_node("RootwoundWorld").set_script(load("res://tools/depth_strip_pilot/global_reference.gd"))'),
        ('var mined_before: int = state.total_mined_resources()', 'var mined_before: int = state.total_mined_resources()\n\tstudy_previous_mined = mined_before\n\tstudy_previous_removed = _study_removed_cells()\n\tworld.lit_draw_sections.profile_draws = true'),
        ('await create_timer(4.0).timeout\n\tvar started:', 'await create_timer(4.0).timeout\n\tawait RenderingServer.frame_post_draw\n\troot.get_texture().get_image().save_png(output.path_join("initial.png"))\n\tvar started:'),
        ('\t\t\tworld.set_mine_held(true)\n\t\t\tvar direction: Vector2 = Vector2.DOWN if area == "deep" else [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP][int(elapsed / 25.0) % 4]\n\t\t\tworld.player.set_external_movement(direction)', '\t\t\t_study_drive(elapsed)'),
        ('now - window_start >= 30000000', 'now - window_start >= 10000000'),
        ('var functional: bool = distance > 100.0 and (area == "hub" or mined > 0)', 'var functional: bool = distance > 100.0 and mined > 0 and not study_route_failed\n\tfor window in windows: functional = functional and bool(window.valid_workload)'),
        ('"held_mining_v1"', '"depth_nearest_wall_v1"'),
        ('"seed": state.world_seed, "area": area,', '"cache_variant":"reference" if "--cache-reference" in OS.get_cmdline_user_args() else "local", "harness_sha256":FileAccess.get_sha256(get_script().resource_path), "runtime_sha256":FileAccess.get_sha256("res://scripts/world/depth/rootwound_world.gd"), "actual_seconds":study_actual_elapsed, "route_targets":study_targets, "seed": state.world_seed, "area": area,'),
        ('func _record_window(frames: Array[float], cpu: Array[float], draws: Array[float], elapsed: float, distance: float) -> void:\n', 'func _record_window(frames: Array[float], cpu: Array[float], draws: Array[float], elapsed: float, distance: float) -> void:\n\tvar raw_intervals: Array[float] = frames.duplicate()\n'),
        ('\twindows.append(row)', '\t_study_window(row, raw_intervals)\n\twindows.append(row)'),
    ]
    for old, new in substitutions:
        if source.count(old) != 1:
            raise RuntimeError(f"Expected exactly one source anchor: {old[:90]}")
        source = source.replace(old, new)
    source += "\n\n" + addon
    output.mkdir(parents=True, exist_ok=True)
    harness = output / "generated-live-session.gd"
    harness.write_text(source)
    (output / "harness-generation.json").write_text(json.dumps({
        "source": str(source_path), "source_sha256": sha(original.encode()),
        "addon": str(addon_path), "addon_sha256": sha(addon.encode()),
        "harness_sha256": sha(source.encode()), "substitutions": len(substitutions),
        "limit": "Read-only route planner; existing Main joystick/mine inputs, ordinary physics; every observed frame and planner cost included.",
    }, indent=2) + "\n")
    return harness


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--variant", choices=["reference", "local"], required=True)
    parser.add_argument("--seconds", type=float, default=60)
    parser.add_argument("--generate-only", action="store_true")
    args = parser.parse_args()
    output = args.output.resolve()
    if output.exists() and any(output.iterdir()):
        parser.error("Use a new empty output directory; prior attempts must be preserved")
    harness = generate(output)
    if args.generate_only:
        print(harness)
        return 0
    command = [sys.executable, str(ROOT / "tools/run_rendered_isolated.py"),
        "--godot", "/tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64",
        "--xvfb", "/workspace/scratch/4e99473f21fc/runtime/xvfb/usr/bin/Xvfb",
        "--project", str(ROOT), "--output", str(output), "--resolution", "1696x780",
        "--timeout", str(int(args.seconds) + 120), "--completion-marker", "PREMIUM_SESSION_COMPLETE",
        "--", "--verbose", "--render-thread", "safe", "--script", str(harness),
        "--", f"--output={output}", "--area=ember", f"--seconds={args.seconds}"]
    if args.variant == "reference": command.append("--cache-reference")
    (output / "launch.json").write_text(json.dumps(command, indent=2) + "\n")
    return subprocess.call(command, cwd=ROOT)


if __name__ == "__main__":
    raise SystemExit(main())
