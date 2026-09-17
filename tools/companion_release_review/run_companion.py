#!/usr/bin/env python3
"""Stage or capture one exact DEV12 companion A/B case; never approve visuals."""
from __future__ import annotations

import argparse
import difflib
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import threading
import time

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[1]
SOURCE = "580a2e02eca1e000f5d5f58bb61ac09fd4b2a194"
PACK_SHA = "9dfcf913c867e36e6a16f4f5123fd5cce7654cfb435a753f9eb7bca12f574bd9"
BASE_COMMIT = "72f11bcd33ff129f8f0f694106bef509b68fd0f3"
ORIGIN_SOURCE = "8f5680defb9083bbe1e044d39a10612f2186e7f3"
ORIGIN_PACK = "5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9"
BASE_HASHES = {
    "capture.gd": "0fb2feb3d1b7fbf812564fc56edc20642ba4e5a0483f27376e4e8b131a2b1e31",
    "run.py": "1eda6982e08d0624fdda0291a866bc039a53f86850f01bdec5cccc3c1d207429",
    "archive.py": "84826496337eb36459c5c77c5e03a1297af52ee4eaeaced867f63789b5d75b27",
}
TOOLS = ("follow_separation.gd", "pilot_mole.gd", "pilot_main.gd", "pack_overlay.gd",
         "trace_mole.gd", "check_geometry.gd", "check_integration.gd",
         "check_lifecycle.gd", "RESULTS.md",
         "capture_companion.gd", "run_companion.py", "README.md")
COMPATIBLE_OWNERS = (
    "scripts/progression/achievement_service.gd", "scripts/state/run_state.gd",
    "scripts/state/save_epoch.gd", "scripts/autoload/game_data.gd",
    "scripts/ui/achievement_toast.gd", "data/ever_deeper_v0381.json",
)
EXTRA_RUNTIME = ("scripts/companion/mole_companion.gd", "scripts/companion/mole_skills.gd",
                 "scripts/companion/companion_interface.gd", "assets/companion/walk.png",
                 "assets/companion/pickup.png", "assets/companion/shake.png", "project.godot",
                 "tools/run_rendered_isolated.py")
START_FREE = 3424134400
RESERVE = 1500000000
CPU_FORECAST = 760000000


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def git_bytes(project: Path, revision: str, path: str) -> bytes:
    return subprocess.check_output(["git", "-C", str(project), "show", revision + ":" + path])


def runtime_digest(project: Path, path: str) -> str:
    if (project / path).is_file():
        return digest(project / path)
    # Root may sparsely omit clean tracked asset duplicates to retain disk
    # reserve. The exact PCK is the running authority; never rematerialize them.
    flag = subprocess.check_output(["git", "-C", str(project), "ls-files", "-v", "--", path], text=True)
    if not path.startswith("assets/") or flag.strip() != "S " + path:
        raise ValueError("Missing runtime file without a declared clean sparse asset: " + path)
    return hashlib.sha256(git_bytes(project, SOURCE, path)).hexdigest()


def write_json(path: Path, data: dict) -> None:
    temporary = path.with_suffix(path.suffix + ".partial")
    temporary.write_text(json.dumps(data, indent=2) + "\n")
    os.replace(temporary, path)


def derive_base(source: str) -> tuple[str, str]:
    edits = (
        ('\tmain = load("res://scenes/main/main.tscn").instantiate()\n',
         '\tmain = load("res://scenes/main/main.tscn").instantiate()\n\tcall("_companion_prepare_main", main)\n'),
        ('\tvar file: FileAccess = FileAccess.open(output.path_join("hero-motion-coverage.json"), FileAccess.WRITE)\n',
         '\treport["companion_comparison"] = call("_companion_report")\n\tvar file: FileAccess = FileAccess.open(output.path_join("hero-motion-coverage.json"), FileAccess.WRITE)\n'),
    )
    derived = source
    for before, after in edits:
        if derived.count(before) != 1:
            raise ValueError("Pinned base hook has changed")
        derived = derived.replace(before, after)
    # Prove that removing just these declared statements restores every byte.
    reverse = derived
    for before, after in reversed(edits): reverse = reverse.replace(after, before)
    if reverse != source:
        raise ValueError("Derived fixture changed more than its declared hooks")
    diff = "".join(difflib.unified_diff(source.splitlines(True), derived.splitlines(True),
                                    fromfile="72f11bc/capture.gd", tofile="derived/hero_capture_base.gd"))
    return derived, diff


def differences(left, right, path="", output=None):
    """Exact structure/integers; 1e-5 absolute tolerance for serialized floats."""
    if output is None: output = []
    if isinstance(left, bool) or isinstance(right, bool):
        same = type(left) is type(right) and left == right
    elif isinstance(left, (int, float)) and isinstance(right, (int, float)):
        same = left == right if isinstance(left, int) and isinstance(right, int) else math.isclose(left, right, rel_tol=0, abs_tol=1e-5)
    elif isinstance(left, dict) and isinstance(right, dict):
        for key in sorted(set(left) | set(right)):
            if key not in left or key not in right: output.append({"path": path + "/" + key, "reason": "missing key"})
            else: differences(left[key], right[key], path + "/" + key, output)
        return output
    elif isinstance(left, list) and isinstance(right, list):
        if len(left) != len(right): output.append({"path": path, "reason": "different lengths", "baseline": len(left), "candidate": len(right)})
        for index, (a, b) in enumerate(zip(left, right)): differences(a, b, path + "/" + str(index), output)
        return output
    else:
        same = type(left) is type(right) and left == right
    if not same: output.append({"path": path, "baseline": left, "candidate": right})
    return output


def mechanical_row(row: dict) -> dict:
    keys = ("stage", "simulated_seconds", "position", "moving", "mining", "mine_held",
            "movement_input", "progress", "impact_serial", "target_id", "target",
            "recover_phase", "recover_direction", "hero_health", "actual_input", "world_damage")
    selected = {key: row[key] for key in keys}
    selected["pose"] = {key: row["pose"][key] for key in ("state", "direction", "gear", "hit_phase")}
    # Idle clock starts during ordinary startup; it is not a gameplay result.
    # Walking/mining native phases must agree after the same actual input.
    if row["pose"]["state"] != "idle":
        selected["pose"].update({key: row["pose"][key] for key in ("local_frame", "native_phase")})
    return selected


def compare_baseline(baseline_dir: Path, candidate: dict, plan: dict) -> dict:
    baseline_path = baseline_dir / "hero-motion-coverage.json"
    baseline = json.loads(baseline_path.read_text())
    prior = json.loads((baseline_dir.parent / "companion-plan.json").read_text())
    prior_result = json.loads((baseline_dir.parent / "companion-results.json").read_text())
    issues = []
    required_identity = ("source_sha", "pack_sha256", "study_sha256", "runtime_sha256",
                         "base_fixture_sha256", "derived_base_sha256", "render_helper_sha256", "achievement_starting_profile")
    for key in required_identity: differences(prior[key], plan[key], "/identity/" + key, issues)
    if not baseline.get("passed") or baseline["companion_comparison"]["variant"] != "baseline":
        issues.append({"path": "/baseline", "reason": "not a passed actual baseline capture"})
    if not prior_result.get("passed") or not prior.get("runtime_preserved") or not prior.get("study_preserved"):
        issues.append({"path": "/baseline", "reason": "baseline closure or source preservation failed"})
    if candidate["companion_comparison"]["variant"] != "candidate":
        issues.append({"path": "/candidate", "reason": "wrong owner"})
    for key in ("gear", "direction", "source_sha", "pack_sha256", "actual_viewport", "fixture"):
        differences(baseline[key], candidate[key], "/" + key, issues)
    differences([mechanical_row(row) for row in baseline["samples"]],
                [mechanical_row(row) for row in candidate["samples"]], "/samples", issues)
    for report in (baseline, candidate):
        if len(report["samples"]) != 195: issues.append({"path": "/samples", "reason": "expected 195 actual rendered samples"})
    differences([{**mechanical_row(row), "name": row["name"], "after_sample": row["after_sample"]} for row in baseline["events"]],
                [{**mechanical_row(row), "name": row["name"], "after_sample": row["after_sample"]} for row in candidate["events"]], "/events", issues)
    return {"passed": not issues, "baseline_report": str(baseline_path), "baseline_report_sha256": digest(baseline_path),
            "samples_compared": len(candidate["samples"]), "events_compared": len(candidate["events"]),
            "float_absolute_tolerance": 1e-5, "differences": issues, "visual_acceptance": False,
            "exclusions": ["Companion state is the declared changed variable.", "Absolute engine/wall clocks and idle atlas clock are recorded, but not gameplay parity fields.", "No cross-run rendered-pixel identity is assumed."]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=PROJECT)
    parser.add_argument("--hero-fixture", type=Path, required=True, help="Folder containing exact 72f11bc capture.gd/run.py/archive.py")
    parser.add_argument("--pack", type=Path, required=True)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--xvfb", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--direction", choices=("right", "up"), required=True)
    parser.add_argument("--variant", choices=("baseline", "candidate"), required=True)
    parser.add_argument("--achievement-profile", type=Path, required=True)
    parser.add_argument("--study-source-sha", help="Root's verified remote checkpoint, required for actual capture")
    parser.add_argument("--baseline-case", type=Path, help="Actual same-direction baseline case, required for candidate capture")
    parser.add_argument("--prepare-only", action="store_true", help="Stage sources and commands; no Godot/Xvfb/encoder")
    args = parser.parse_args()
    project, hero_dir, pack, output = (getattr(args, key).resolve() for key in ("project", "hero_fixture", "pack", "output"))
    if output.exists(): parser.error("Use a fresh output directory; evidence is never overwritten")
    if not args.prepare_only and (not args.xvfb or not args.study_source_sha): parser.error("Capture requires Xvfb and a verified study checkpoint")
    if args.variant == "candidate" and not args.prepare_only and not args.baseline_case: parser.error("Candidate capture requires actual baseline evidence")
    if args.variant == "baseline" and args.baseline_case: parser.error("Baseline does not accept a reference case")
    if digest(pack) != PACK_SHA: parser.error("Expected exact published DEV12 package")
    if any(digest(hero_dir / name) != value for name, value in BASE_HASHES.items()): parser.error("Hero fixture differs from 72f11bc")
    dirty = subprocess.check_output(["git", "-C", str(project), "diff", "--name-only", SOURCE, "--", "scripts", "scenes", "assets", "data", "shaders", "project.godot"], text=True).strip()
    if dirty: parser.error("Runtime source differs from DEV12: " + dirty.replace("\n", ", "))
    render_helper_sha = digest(project / "tools/run_rendered_isolated.py")
    if render_helper_sha != hashlib.sha256(git_bytes(project, SOURCE, "tools/run_rendered_isolated.py")).hexdigest():
        parser.error("Rendered isolation helper differs from exact DEV12 source")
    if "window/stretch/scale=1.1\n" not in (project / "project.godot").read_text():
        parser.error("Expected the exact DEV12 logical-to-native scale")
    study_hashes = {name: digest(HERE / name) for name in TOOLS}
    if args.study_source_sha:
        for name, value in study_hashes.items():
            content = git_bytes(project, args.study_source_sha, "tools/companion_spacing_study/" + name)
            if hashlib.sha256(content).hexdigest() != value: parser.error("Study differs from checkpoint: " + name)
    spec = importlib.util.spec_from_file_location("pinned_hero_runner", hero_dir / "run.py")
    hero = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(hero)
    profile = hero.read_achievement_profile(args.achievement_profile, ORIGIN_SOURCE, ORIGIN_PACK)
    compatibility = {}
    for path in COMPATIBLE_OWNERS:
        origin = hashlib.sha256(git_bytes(project, ORIGIN_SOURCE, path)).hexdigest()
        current = digest(project / path)
        if origin != current: parser.error("Achievement compatibility owner changed: " + path)
        compatibility[path] = current
    profile["origin_source_sha"] = ORIGIN_SOURCE
    profile["origin_pack_sha256"] = ORIGIN_PACK
    profile["target_source_sha"] = SOURCE
    profile["target_pack_sha256"] = PACK_SHA
    profile["unchanged_compatibility_owners"] = compatibility
    gears, directions = hero.approved_keys(project)
    runtime_paths = hero.RUNTIME_PATHS + [f"assets/hero/dad/{gear}/{name}" for gear in gears
        for name in ["manifest.json"] + [f"{direction}{suffix}.png" for direction in directions for suffix in ("", "-cloth")]]
    runtime_hashes = {path: runtime_digest(project, path) for path in runtime_paths + list(EXTRA_RUNTIME)}
    disk_parent = output.parent
    while not disk_parent.exists(): disk_parent = disk_parent.parent
    if not args.prepare_only and shutil.disk_usage(disk_parent).free < START_FREE: parser.error("Disk guard requires 3,424,134,400 free bytes before one case")
    if not args.prepare_only:
        for path in Path("/proc").glob("[0-9]*/cmdline"):
            try: argv = path.read_bytes().split(b"\0"); name = Path(argv[0].decode()).name
            except (OSError, UnicodeError, IndexError): continue
            if name == "Xvfb" or name.lower().startswith("blender") or (name.startswith("Godot") and b"--headless" not in argv):
                parser.error("Another heavy renderer is active: " + path.parent.name)
    output.mkdir(parents=True)
    earned = output / "earned-profile"; earned.mkdir()
    provenance_path = args.achievement_profile.resolve()
    provenance = json.loads(provenance_path.read_text())
    profile_names = [provenance_path.name] + [provenance[key] for key in ("profile_file", "origin_report_file", "origin_startup_file")]
    for name in profile_names:
        shutil.copyfile(provenance_path.parent / name, earned / name)
        if digest(earned / name) != digest(provenance_path.parent / name): raise ValueError("Profile provenance snapshot differs")
    staged = output / "fixture-source"
    staged.mkdir()
    for name in TOOLS: shutil.copyfile(HERE / name, staged / name)
    for name in BASE_HASHES: shutil.copyfile(hero_dir / name, staged / ("original-" + name))
    shutil.copyfile(project / "tools/run_rendered_isolated.py", staged / "run_rendered_isolated.py")
    if digest(staged / "run_rendered_isolated.py") != render_helper_sha: raise ValueError("Staged renderer helper changed")
    derived, diff = derive_base((hero_dir / "capture.gd").read_text())
    (staged / "hero_capture_base.gd").write_text(derived)
    (staged / "hero-base-hooks.diff").write_text(diff)
    empty = output / "empty-project"; empty.mkdir()
    case_dir = output / ("worn-" + args.direction + "-" + args.variant)
    case = {"gear": "worn", "direction": args.direction, "source_sha": SOURCE,
            "output": str(case_dir), "capture_format": "rgba8", "all_frames": True, "achievement_profile": profile}
    if args.direction == "up": case["natural_wall"] = [13, 15]
    overlay = output / "companion-overlay.pck"
    overlay_command = [str(args.godot.resolve()), "--headless", "--path", str(empty), "--script", str(staged / "pack_overlay.gd"),
                       "--", "--source=" + str(staged), "--output=" + str(overlay)]
    command = [sys.executable, str(staged / "run_rendered_isolated.py"), "--godot", str(args.godot.resolve()),
               "--xvfb", str(args.xvfb.resolve()) if args.xvfb else "XVFB_BIN", "--project", str(empty),
               "--output", str(case_dir), "--resolution", "1696x780", "--timeout", "360",
               "--completion-marker", "HERO_COVERAGE_COMPLETE failures=0", "--", "--main-pack", str(pack),
               "--fixed-fps", "60", "--script", str(staged / "capture_companion.gd"), "--",
               "--output=" + str(case_dir), "--source-sha=" + SOURCE, "--pack-source=" + str(pack),
               "--gear=worn", "--direction=" + args.direction, "--all-frames", "--capture-format=rgba8",
               "--achievement-profile-records=" + str(earned / provenance["profile_file"]), "--achievement-profile-sha256=" + profile["profile_sha256"],
               "--achievement-provenance-sha256=" + profile["provenance_sha256"], "--companion-variant=" + args.variant]
    if args.direction == "up": command.append("--natural-wall=13,15")
    plan = {"schema": 1, "source_sha": SOURCE, "pack_sha256": PACK_SHA, "study_source_sha": args.study_source_sha,
            "study_sha256": study_hashes, "runtime_sha256": runtime_hashes, "base_runtime_hero_file_count": 113,
            "sparsely_omitted_clean_assets_hashed_from_source_git": [path for path in runtime_hashes if not (project / path).is_file()],
            "base_fixture_commit": BASE_COMMIT, "base_fixture_sha256": BASE_HASHES,
            "render_helper_sha256": render_helper_sha, "render_helper_source_commit": SOURCE,
            "derived_base_sha256": digest(staged / "hero_capture_base.gd"), "exact_base_diff": diff,
            "achievement_starting_profile": profile, "case": case, "variant": args.variant,
            "earned_profile_snapshot_sha256": {name: digest(earned / name) for name in profile_names},
            "logical_to_native_pixels": {"scale": [1.1, 1.1], "offset": [0, 0]},
            "baseline_case": str(args.baseline_case.resolve()) if args.baseline_case else None,
            "overlay_command": overlay_command, "capture_command": command,
            "archive_command": [sys.executable, str(staged / "original-archive.py"), "--input", str(case_dir),
                                "--output", str(case_dir / "lossless"), "--require-complete", "--threads", "2"],
            "disk_start_guard_bytes": START_FREE, "disk_reserve_bytes": RESERVE,
            "visual_acceptance": False, "execution": "prepared"}
    write_json(output / "companion-plan.json", plan)
    if args.prepare_only:
        print("COMPANION_PREPARED " + str(output / "companion-plan.json")); return 0
    if args.variant == "candidate":
        baseline = json.loads((args.baseline_case / "hero-motion-coverage.json").read_text())
        prior = json.loads((args.baseline_case.parent / "companion-plan.json").read_text())
        prior_result = json.loads((args.baseline_case.parent / "companion-results.json").read_text())
        if not baseline["passed"] or baseline["companion_comparison"]["variant"] != "baseline" or baseline["direction"] != args.direction:
            parser.error("Reference is not an actual successful same-direction baseline")
        for key in ("source_sha", "pack_sha256", "study_sha256", "runtime_sha256", "base_fixture_sha256", "derived_base_sha256", "render_helper_sha256", "achievement_starting_profile"):
            if prior[key] != plan[key]: parser.error("Baseline identity differs before capture: " + key)
        if not prior_result.get("passed") or not prior.get("runtime_preserved") or not prior.get("study_preserved"):
            parser.error("Baseline closure/source preservation failed")
        with (output / "overlay-build.log").open("w") as log:
            subprocess.run(overlay_command, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=30)
        plan["overlay_sha256"] = digest(overlay)
        command += ["--companion-overlay=" + str(overlay), "--companion-overlay-sha256=" + plan["overlay_sha256"]]
    staged_profile = case_dir / "userdata" / profile["userdata_relative_path"]
    staged_profile.parent.mkdir(parents=True)
    shutil.copyfile(profile["profile_file"], staged_profile)
    if digest(staged_profile) != profile["profile_sha256"]: raise ValueError("Earned profile copy differs")
    plan["execution"] = "capturing"; write_json(output / "companion-plan.json", plan)
    start = time.monotonic(); done = threading.Event(); disk_stop = []
    proc = subprocess.Popen(command, cwd=project, start_new_session=True)
    def guard():
        while not done.wait(0.1):
            free = shutil.disk_usage(output).free
            if free < RESERVE + CPU_FORECAST:
                disk_stop.append({"free_bytes": free, "elapsed_seconds": time.monotonic() - start})
                os.killpg(proc.pid, signal.SIGTERM); return
    thread = threading.Thread(target=guard, daemon=True); thread.start()
    exit_code = proc.wait(); done.set(); thread.join(timeout=1)
    plan["capture_elapsed_seconds"] = time.monotonic() - start
    plan["disk_stop_events"] = disk_stop
    plan["runtime_preserved"] = all(runtime_digest(project, path) == value for path, value in runtime_hashes.items())
    plan["render_helper_preserved"] = digest(staged / "run_rendered_isolated.py") == render_helper_sha
    plan["study_preserved"] = all(digest(HERE / name) == value for name, value in study_hashes.items())
    plan["execution"] = "capture_closed"; write_json(output / "companion-plan.json", plan)
    print("COMPANION_RENDERER_RELEASED", flush=True)
    try:
        result = hero.validate_report(case, PACK_SHA)
        report = json.loads((case_dir / "hero-motion-coverage.json").read_text())
        if args.variant == "candidate":
            parity = compare_baseline(args.baseline_case.resolve(), report, plan)
            write_json(output / "mechanics-comparison.json", parity)
            result["mechanical_parity"] = parity["passed"]
            result["passed"] = result["passed"] and parity["passed"]
    except (OSError, ValueError, KeyError, TypeError) as error:
        result = {"passed": False, "errors": [str(error)]}
    result["passed"] = bool(result["passed"] and exit_code == 0 and not disk_stop and plan["runtime_preserved"] and plan["study_preserved"] and plan["render_helper_preserved"])
    result.update(exit_code=exit_code, visual_acceptance=False, capture_elapsed_seconds=plan["capture_elapsed_seconds"])
    write_json(output / "companion-results.json", result)
    print(json.dumps(result), flush=True)
    # Encoding is explicitly separate, allowing immediate renderer handoff.
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
