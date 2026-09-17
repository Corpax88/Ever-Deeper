#!/usr/bin/env python3
"""Plan or run isolated native motion cases serially; never export or publish."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
MISSING_GEARS = ["iron", "runed", "moonglass", "ember", "comet", "crown", "burrower", "pulse"]
RUNTIME_PATHS = [
    "scripts/player/player_controller.gd", "scripts/player/player_visual.gd",
    "scripts/player/hero_gear.gd", "scripts/main.gd", "scripts/state/run_state.gd",
    "scripts/world/endless_descent_world.gd", "scripts/world/endless_deep_layout.gd",
    "scripts/camera/cinematic_camera_2d.gd", "scripts/ui/resource_pickup_burst.gd",
    "scripts/audio/audio_director.gd", "scenes/player/player.tscn", "scenes/main/main.tscn",
    "data/ever_deeper_v0381.json", "data/source_manifest.json",
]


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def git(project: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(project), *args], text=True).strip()


def approved_keys(project: Path) -> tuple[list[str], list[str]]:
    source = (project / "scripts/player/hero_gear.gd").read_text()
    return tuple(json.loads(re.search(rf"const {name}: Array\[String\] = (\[[^\n]+\])", source)[1])
                 for name in ("TOOLS", "DIRECTIONS"))


def validate_report(case: dict, pack_sha: str) -> dict:
    folder = Path(case["output"])
    report = json.loads((folder / "hero-motion-coverage.json").read_text())
    errors = []
    for key in ("gear", "direction", "source_sha"):
        if report.get(key) != case[key]:
            errors.append(f"Incorrect {key}")
    if not report.get("passed") or report.get("failures"):
        errors.append("Mechanical observations failed")
    if not report.get("rendered") or report.get("actual_viewport") != [1696, 780]:
        errors.append("Expected actual 1696x780 native capture")
    if report.get("pack_sha256") != pack_sha or bool(report.get("packed")) != bool(pack_sha):
        errors.append("Package identity mismatch")
    if report.get("manual_process_steps") is not False or report.get("terrain_replaced") is not False:
        errors.append("Fixture did not retain real processing/terrain")
    if not report.get("framing", {}).get("passed"):
        errors.append("Hero/tool/target framing contract failed or was not observed")
    if case.get("all_frames") and not report.get("all_observed_frames_captured"):
        errors.append("Full ordered rendered frames were requested but are incomplete")
    capture_format = case.get("capture_format", "png")
    if report.get("capture_format", "png") != capture_format:
        errors.append("Capture format mismatch")
    required = {"release_before_contact", "move_away_during_anticipation", "first_real_impact", "release_after_delivered_contact"}
    if not required.issubset({event.get("name") for event in report.get("events", [])}):
        errors.append("Missing impact or cancellation observation")
    captures = report.get("captures", [])
    if not captures:
        errors.append("No actual images")
    def validate_png(name: str) -> None:
        if Path(name).name != name:
            errors.append("Invalid PNG name")
            return
        with (folder / name).open("rb") as stream:
            header = stream.read(24)
        if header[:8] != b"\x89PNG\r\n\x1a\n" or len(header) != 24 or struct.unpack(">II", header[16:24]) != (1696, 780):
            errors.append(f"Invalid native PNG: {name}")
    for capture in captures:
        name = capture["file"]
        if Path(name).name != name:
            errors.append("Invalid capture name")
            continue
        if capture_format == "rgba8":
            expected = {"format": "rgba8", "width": 1696, "height": 780, "byte_count": 1696 * 780 * 4,
                        "row_stride_bytes": 1696 * 4, "row_order": "top_to_bottom", "channel_order": "RGBA"}
            if (any(capture.get(key) != value for key, value in expected.items())
                    or not name.endswith(".rgba") or (folder / name).stat().st_size != 1696 * 780 * 4):
                errors.append(f"Invalid sized RGBA8 frame: {name}")
        else:
            validate_png(name)
    if capture_format == "rgba8":
        critical = report.get("critical_pngs", [])
        if not critical:
            errors.append("No critical native PNGs encoded from raw frames")
        for entry in critical:
            validate_png(entry["file"])
            if entry.get("origin") != "godot_png_from_stored_rgba8":
                errors.append("Critical native PNG origin mismatch")
    return {"passed": not errors, "errors": errors, "captures": len(captures),
            "samples": len(report.get("samples", [])), "report_sha256": digest(folder / "hero-motion-coverage.json")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, default=ROOT)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--gear", nargs="+", help="Default: the eight gears missing browser motion coverage; 'all' selects all eleven")
    parser.add_argument("--direction", nargs="+", help="Default: all four approved directions")
    parser.add_argument("--godot", type=Path)
    parser.add_argument("--xvfb", type=Path)
    parser.add_argument("--pack", type=Path, help="Exact exported candidate; external fixture runs against its resources")
    parser.add_argument("--source-sha", help="Source corresponding to the package; defaults to this checkout's HEAD")
    parser.add_argument("--plan-only", action="store_true", help="Write receipts and commands without starting Godot/Xvfb")
    parser.add_argument("--all-frames", action="store_true", help="Save every observed rendered frame for a complete lossless motion archive")
    parser.add_argument("--archive-lossless", action="store_true", help="Implies --all-frames; encode and verify each case before starting the next")
    parser.add_argument("--capture-format", choices=["png", "rgba8"], default="png",
                        help="Optional fast raw RGBA8 captures plus critical native PNGs; raw implies --all-frames")
    args = parser.parse_args()
    args.all_frames = args.all_frames or args.archive_lossless or args.capture_format == "rgba8"
    project = args.project.resolve()
    output = args.output.resolve()
    gears, directions = approved_keys(project)
    selected_gears = gears if args.gear == ["all"] else (args.gear or MISSING_GEARS)
    selected_directions = args.direction or directions
    if (not set(selected_gears).issubset(gears) or not set(selected_directions).issubset(directions)
            or len(set(selected_gears)) != len(selected_gears) or len(set(selected_directions)) != len(selected_directions)):
        parser.error("Choose distinct approved gear/direction keys")
    if not args.plan_only and (not args.godot or not args.xvfb):
        parser.error("Native execution requires --godot and --xvfb; use --plan-only to prepare without a renderer")
    source_sha = git(project, "rev-parse", f"{args.source_sha or 'HEAD'}^{{commit}}")
    # CI, documentation and study-tool edits do not change the runtime identity.
    dirty = git(project, "diff", "--name-only", source_sha, "--", "scripts", "scenes", "data", "assets", "shaders", "project.godot")
    if dirty:
        parser.error("Runtime files differ from the declared source revision: " + dirty.replace("\n", ", "))
    runtime_paths = RUNTIME_PATHS + [
        f"assets/hero/dad/{gear}/{name}"
        for gear in gears
        for name in ["manifest.json"] + [f"{direction}{suffix}.png" for direction in directions for suffix in ("", "-cloth")]
    ]
    runtime_hashes = {name: digest(project / name) for name in runtime_paths}
    pack = args.pack.resolve() if args.pack else None
    pack_sha = digest(pack) if pack else ""
    fixture = Path(__file__).resolve().with_name("capture.gd")
    archiver = Path(__file__).resolve().with_name("archive.py")
    cases = []
    for gear in selected_gears:
        for direction in selected_directions:
            folder = output / f"{gear}-{direction}"
            command = [sys.executable, str(project / "tools/run_rendered_isolated.py"),
                       "--godot", str(args.godot.resolve()) if args.godot else "GODOT_BIN",
                       "--xvfb", str(args.xvfb.resolve()) if args.xvfb else "XVFB_BIN",
                       "--project", str(output / "empty-project") if pack else str(project),
                       "--output", str(folder), "--resolution", "1696x780", "--timeout", "180",
                       "--completion-marker", "HERO_COVERAGE_COMPLETE failures=0", "--"]
            if pack:
                command += ["--main-pack", str(pack)]
            command += ["--fixed-fps", "60", "--script", str(fixture), "--",
                        f"--output={folder}", f"--source-sha={source_sha}", f"--gear={gear}", f"--direction={direction}"]
            if pack:
                command += [f"--pack-source={pack}"]
            if args.all_frames:
                command += ["--all-frames"]
            if args.capture_format != "png":
                command += [f"--capture-format={args.capture_format}"]
            case = {"gear": gear, "direction": direction, "source_sha": source_sha,
                    "output": str(folder), "command": command, "all_frames": args.all_frames,
                    "capture_format": args.capture_format}
            if args.archive_lossless:
                case["archive_command"] = [sys.executable, str(archiver), "--input", str(folder),
                                           "--output", str(folder / "lossless"), "--require-complete", "--threads", "2"]
            cases.append(case)
    output.mkdir(parents=True, exist_ok=True)
    if any(Path(case["output"]).exists() for case in cases):
        parser.error("Use a new output directory; existing captures are never overwritten")
    receipt = {"schema": 1, "source_sha": source_sha, "pack_sha256": pack_sha,
               "approved_gears": gears, "approved_directions": directions,
               "fixture_sha256": digest(fixture), "runner_sha256": digest(Path(__file__)),
               "capture_format": args.capture_format,
               "archive_lossless_per_case": args.archive_lossless,
               "archiver_sha256": digest(archiver) if args.archive_lossless else None,
               "runtime_sha256": runtime_hashes, "cases": cases,
               "execution": "pending", "visual_acceptance": False, "physical_iphone": False, "fps_claim": False}
    receipt_path = output / "coverage-plan.json"
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    print(f"Prepared {len(cases)} cases for {source_sha}: {receipt_path}", flush=True)
    if args.plan_only:
        return 0
    if pack:
        (output / "empty-project").mkdir(exist_ok=True)
    results = []
    for case in cases:
        print(f"CAPTURE {case['gear']} {case['direction']}", flush=True)
        result = subprocess.run(case["command"], cwd=project)
        try:
            row = validate_report(case, pack_sha)
        except (OSError, ValueError, KeyError, TypeError) as error:
            row = {"passed": False, "errors": [str(error)]}
        row.update(gear=case["gear"], direction=case["direction"], exit_code=result.returncode)
        row["passed"] = row["passed"] and result.returncode == 0
        if args.archive_lossless and row.get("captures", 0) > 0:
            print(f"ARCHIVE AND VERIFY {case['gear']} {case['direction']}", flush=True)
            archived = subprocess.run(case["archive_command"], cwd=project)
            try:
                archive_folder = Path(case["output"]) / "lossless"
                proof = json.loads((archive_folder / "archive.json").read_text())
                verified = (archived.returncode == 0 and proof.get("verified_rgb") is True
                            and proof.get("all_observed_frames_present") is True
                            and proof.get("source_captures_retained", proof.get("original_pngs_retained")) is True
                            and proof.get("capture_format", "png") == args.capture_format
                            and proof.get("opaque_alpha_verified") is True
                            and proof.get("critical_source_pngs_retained") is True
                            and proof.get("source_report_sha256") == row["report_sha256"])
                row["archive"] = {"verified": verified, "receipt": str(archive_folder / "archive.json"),
                                  "video_sha256": proof.get("video_sha256"), "video_bytes": proof.get("video_bytes"),
                                  "critical_png_bytes": proof.get("critical_png_bytes"), "exit_code": archived.returncode}
                row["passed"] = row["passed"] and verified
            except (OSError, ValueError, KeyError, TypeError) as error:
                row["archive"] = {"verified": False, "error": str(error), "exit_code": archived.returncode}
                row["passed"] = False
        results.append(row)
        (output / "coverage-results.json").write_text(json.dumps({
            "source_sha": source_sha, "pack_sha256": pack_sha, "planned_cases": len(cases),
            "passed": len(results) == len(cases) and all(item["passed"] for item in results),
            "results": results, "visual_acceptance": False,
        }, indent=2) + "\n")
        if not row["passed"]:
            print("Stopped at first failed case; evidence retained.", flush=True)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
