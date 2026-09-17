#!/usr/bin/env python3
"""Capture one new immutable DEV13 PCK with the approved input choreography."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import threading
import time

HERE = Path(__file__).resolve().parent
SOURCE = "5ca6f0f77a1f87eaead777613062208159325068"
OWNER_SHA = "5c485b1e41ad40fe6c71368c7824b92932bc9a1f0114e732ed1300b9e6d7be73"
HELPER_SHA = "6cd2d6f3baa1f302cd0c1ba4596185b7281af174e52f302dc4e48566fe885358"
PINNED = {
    "original-capture.gd": "0fb2feb3d1b7fbf812564fc56edc20642ba4e5a0483f27376e4e8b131a2b1e31",
    "original-run.py": "1eda6982e08d0624fdda0291a866bc039a53f86850f01bdec5cccc3c1d207429",
    "original-archive.py": "84826496337eb36459c5c77c5e03a1297af52ee4eaeaced867f63789b5d75b27",
    "hero_capture_base.gd": "3360084e68765a68fcb8b6a37aaf7253115d256fe562d16343eef1e77b15acb9",
}
START_FREE = 3424134400
RESERVE = 1500000000


def digest(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def write(path, obj):
    tmp = path.with_suffix(path.suffix + ".partial")
    tmp.write_text(json.dumps(obj, indent=2) + "\n")
    os.replace(tmp, path)


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    obj = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(obj)
    return obj


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--project", type=Path, required=True)
    p.add_argument("--package", type=Path, required=True)
    p.add_argument("--reference", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--godot", type=Path, required=True)
    p.add_argument("--xvfb", type=Path, required=True)
    p.add_argument("--direction", choices=["right", "up"], required=True)
    p.add_argument("--prepare-only", action="store_true")
    args = p.parse_args()
    root, package, reference, output = (getattr(args, n).resolve() for n in ["project", "package", "reference", "output"])
    if output.exists(): p.error("Use a fresh output folder; evidence is never overwritten")
    for name, value in PINNED.items():
        assert digest(HERE / name) == value, name
    identity = json.loads((package / "artifact-identity.json").read_text())
    assert identity["sourceSha"] == SOURCE
    pack = package / "index.pck"
    pack_sha = identity["devFiles"]["index.pck"]["sha256"]
    assert digest(pack) == pack_sha
    prior = json.loads((reference / "companion-plan.json").read_text())
    prior_result = json.loads((reference / "companion-results.json").read_text())
    old = json.loads((reference / ("worn-" + args.direction + "-candidate") / "hero-motion-coverage.json").read_text())
    assert prior_result["passed"] and old["passed"] and old["direction"] == args.direction
    assert prior["study_source_sha"] == "01409145ec6cc889878c0ac5de5fe83e1ded21b6"
    assert subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip() == SOURCE
    assert not subprocess.check_output(["git", "-C", str(root), "diff", "HEAD", "--name-only", "--", "scripts", "assets", "shaders", "scenes", "data", "project.godot"], text=True).strip()
    preserved = {}
    for name, expected in prior["runtime_sha256"].items():
        if name == "scripts/companion/mole_companion.gd": expected = OWNER_SHA
        assert digest(root / name) == expected, name
        preserved[name] = expected
    assert digest(root / "scripts/companion/follow_separation.gd") == HELPER_SHA
    profile = prior["achievement_starting_profile"]
    assert digest(profile["profile_file"]) == profile["profile_sha256"]
    assert digest(profile["provenance_file"]) == profile["provenance_sha256"]
    for name, expected in profile["unchanged_compatibility_owners"].items(): assert digest(root / name) == expected
    if not args.prepare_only:
        assert shutil.disk_usage(output.parent).free >= START_FREE, "Capture start disk reserve"
        for proc in Path("/proc").glob("[0-9]*/cmdline"):
            try:
                argv = proc.read_bytes().split(b"\0")
                name = Path(argv[0].decode()).name
            except (OSError, UnicodeError, IndexError): continue
            assert not (name == "Xvfb" or name.lower().startswith("blender") or (name.startswith("Godot") and b"--headless" not in argv)), "Another heavy renderer is active"
    output.mkdir(parents=True)
    stage = output / "fixture-source"
    shutil.copytree(HERE, stage, ignore=shutil.ignore_patterns("__pycache__"))
    fixture_hashes = {x.name: digest(x) for x in stage.iterdir() if x.is_file()}
    empty = output / "empty-project"
    empty.mkdir()
    case_dir = output / ("worn-" + args.direction + "-production")
    case = {"gear": "worn", "direction": args.direction, "source_sha": SOURCE, "output": str(case_dir),
            "all_frames": True, "capture_format": "png", "achievement_profile": profile}
    if args.direction == "up": case["natural_wall"] = [13, 15]
    userdata = case_dir / "userdata" / profile["userdata_relative_path"]
    userdata.parent.mkdir(parents=True)
    shutil.copyfile(profile["profile_file"], userdata)
    command = [sys.executable, str(stage / "run_rendered_isolated.py"), "--godot", str(args.godot.resolve()),
        "--xvfb", str(args.xvfb.resolve()), "--project", str(empty), "--output", str(case_dir),
        "--resolution", "1696x780", "--timeout", "360", "--completion-marker", "HERO_COVERAGE_COMPLETE failures=0",
        "--", "--main-pack", str(pack), "--fixed-fps", "60", "--script", str(stage / "capture_release.gd"), "--",
        "--output=" + str(case_dir), "--source-sha=" + SOURCE, "--pack-source=" + str(pack),
        "--gear=worn", "--direction=" + args.direction, "--all-frames", "--capture-format=png",
        "--achievement-profile-records=" + profile["profile_file"], "--achievement-profile-sha256=" + profile["profile_sha256"],
        "--achievement-provenance-sha256=" + profile["provenance_sha256"], "--expected-pack-sha256=" + pack_sha]
    if args.direction == "up": command.append("--natural-wall=13,15")
    plan = {"source_sha": SOURCE, "pack_sha256": pack_sha, "identity_sha256": digest(package / "artifact-identity.json"),
        "fixture_sha256": fixture_hashes, "runtime_sha256": preserved, "helper_sha256": HELPER_SHA,
        "case": case, "reference": str(reference), "reference_report_sha256": digest(reference / ("worn-" + args.direction + "-candidate") / "hero-motion-coverage.json"),
        "command": command, "capture_format_reason": "All 195 original PNGs avoid a duplicate raw-frame cache; input and fixed simulation steps are unchanged.",
        "start_free_bytes": shutil.disk_usage(output).free, "start_guard_bytes": START_FREE, "reserve_bytes": RESERVE,
        "runtime_replacements": [], "execution": "prepared", "visual_acceptance": False}
    write(output / "release-plan.json", plan)
    if args.prepare_only:
        print("RELEASE_CAPTURE_PREPARED", output)
        return 0
    start = time.monotonic()
    done = threading.Event()
    disk_stop = []
    process = subprocess.Popen(command, cwd=root, start_new_session=True)
    def guard():
        while not done.wait(0.1):
            free = shutil.disk_usage(output).free
            if free < RESERVE + 760000000:
                disk_stop.append(free)
                os.killpg(process.pid, signal.SIGTERM)
                return
    thread = threading.Thread(target=guard, daemon=True)
    thread.start()
    code = process.wait()
    done.set()
    thread.join(timeout=1)
    plan.update(exit_code=code, elapsed_seconds=time.monotonic()-start, disk_stop=disk_stop, execution="closed")
    plan["fixture_preserved"] = all(digest(stage / n) == h for n,h in fixture_hashes.items())
    plan["runtime_preserved"] = all(digest(root / n) == h for n,h in preserved.items()) and digest(root / "scripts/companion/follow_separation.gd") == HELPER_SHA and digest(pack) == pack_sha
    write(output / "release-plan.json", plan)
    print("COMPANION_RENDERER_RELEASED", flush=True)
    result = module("hero", stage / "original-run.py").validate_report(case, pack_sha)
    capture = json.loads((case_dir / "hero-motion-coverage.json").read_text())
    comparator = module("companion", stage / "run_companion.py")
    changes = comparator.differences([comparator.mechanical_row(x) for x in old["samples"]], [comparator.mechanical_row(x) for x in capture["samples"]])
    comparator.differences([{**comparator.mechanical_row(x), "name": x["name"], "after_sample": x["after_sample"]} for x in old["events"]], [{**comparator.mechanical_row(x), "name": x["name"], "after_sample": x["after_sample"]} for x in capture["events"]], "/events", changes)
    result.update(exit_code=code, source_sha=SOURCE, pack_sha256=pack_sha, compared_samples=len(capture["samples"]), compared_events=len(capture["events"]), mechanical_differences=changes,
        all_png_sha256={x["file"]: digest(case_dir / x["file"]) for x in capture["captures"]}, visual_acceptance=False)
    result["passed"] = bool(result["passed"] and code == 0 and not disk_stop and not changes and plan["fixture_preserved"] and plan["runtime_preserved"] and len(capture["samples"]) == 195 and len(capture["events"]) == 6)
    write(output / "release-results.json", result)
    print(json.dumps({k:v for k,v in result.items() if k not in ["all_png_sha256", "mechanical_differences"]}), flush=True)
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
