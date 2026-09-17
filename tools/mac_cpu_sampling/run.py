#!/usr/bin/env python3
"""One bounded, ordinary-user macOS stack sample of the unchanged DEV11 PCK."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import signal
import subprocess
import sys
import time
from datetime import datetime, timezone

SOURCE = "8f5680defb9083bbe1e044d39a10612f2186e7f3"
PCK_SHA = "5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9"
PCK_BYTES = 221013680
IDENTITY_SHA = "027b128fe5fa70d7814c0f0952ee06549f447afc9769426c3b5696c631579a7a"
ROUTE_SHA = "c3a787767ff0dbfc5c13b2d9283ce0ae7b5a1a77d287a1a5c5e49512ef5b9edb"
BRANCH = "refs/heads/codex/dev11-mac-cpu-sampling-20260917"
SECONDS, SAMPLE_AFTER, SAMPLE_SECONDS, INTERVAL_MS = 60, 15, 10, 5
ERRORS = re.compile(r"SCRIPT ERROR|Parse Error|^ERROR:|Assertion failed|CHECK_FAILED", re.M)
MARKER = "PREMIUM_SESSION_COMPLETE area=deep functional=true"


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_json(path: Path, value: object) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, indent=2) + "\n")
    temporary.replace(path)


def stamp() -> dict:
    return {"unix_seconds": time.time(), "monotonic_seconds": time.monotonic(),
            "utc": datetime.now(timezone.utc).isoformat()}


def checked_replace(text: str, old: str, new: str) -> str:
    if text.count(old) != 1:
        raise ValueError("Pinned route injection point is not unique: " + old[:100])
    return text.replace(old, new, 1)


def generate(route: Path) -> str:
    if sha(route) != ROUTE_SHA:
        raise ValueError("Established DEV11 route hash changed")
    text = route.read_text()
    text = checked_replace(text, "var require_fps: bool = false\n",
                           "var require_fps: bool = false\nvar _study_started_usec: int = 0\nvar _study_raw_windows: Array[Dictionary] = []\n")
    text = checked_replace(text, "\tvar started: int = Time.get_ticks_usec()\n",
                           '\t_study_event("route_ready")\n\tvar started: int = Time.get_ticks_usec()\n\t_study_started_usec = started\n')
    text = checked_replace(text, "\tplayer.set_external_movement(Vector2.ZERO)\n",
                           '\t_study_event("route_finished")\n\t_study_json("raw-windows.json", _study_raw_windows)\n\tplayer.set_external_movement(Vector2.ZERO)\n')
    original = '\tprint("PREMIUM_SESSION_COMPLETE area=", area, " functional=", functional, " meets_50_fps=", meets)\n'
    text = checked_replace(text, original, original +
                           '\t_study_event("complete", functional)\n' +
                           '\tprinterr("PREMIUM_SESSION_COMPLETE area=", area, " functional=", functional, " meets_50_fps=", meets, " source=' + SOURCE + ' pck=' + PCK_SHA + '")\n')
    signature = "func _record_window(frames: Array[float], cpu: Array[float], draws: Array[float], elapsed: float, distance: float) -> void:\n"
    text = checked_replace(text, signature, signature +
                           '\t_study_raw_windows.append({"frame_ms": frames.duplicate(), "recorded_tick_usec": Time.get_ticks_usec(), "elapsed_argument": elapsed, "distance": distance, "mined_resources_total": state.total_mined_resources()})\n')
    return text + '''

func _study_json(name: String, value: Variant) -> void:
	var destination: String = output.path_join(name)
	var file: FileAccess = FileAccess.open(destination + ".tmp", FileAccess.WRITE)
	if file == null:
		push_error("Cannot open diagnostic receipt: " + destination)
		return
	file.store_string(JSON.stringify(value, "\\t"))
	file.close()
	if DirAccess.rename_absolute(destination + ".tmp", destination) != OK:
		push_error("Cannot finalize diagnostic receipt: " + destination)

func _study_event(stage: String, functional: bool = false) -> void:
	var ticks: int = Time.get_ticks_usec()
	var pet: Node = world.get_node_or_null("MoleCompanion")
	_study_json("event-" + stage + ".json", {
		"schema": 1, "stage": stage, "source": "''' + SOURCE + '''", "pck_sha256": "''' + PCK_SHA + '''",
		"pid": OS.get_process_id(), "unix_seconds": Time.get_unix_time_from_system(), "tick_usec": ticks,
		"route_start_tick_usec": _study_started_usec,
		"route_elapsed_seconds": float(ticks - _study_started_usec) / 1000000.0 if _study_started_usec > 0 else 0.0,
		"area": area, "requested_seconds": seconds, "seed": state.world_seed, "functional": functional,
		"held_mining": world.external_mine_held, "player": [world.player.position.x, world.player.position.y],
		"mined_resources_total": state.total_mined_resources(),
		"companion": pet.debug_snapshot() if pet != null else {},
		"engine": Engine.get_version_info(), "display": DisplayServer.get_name(), "os": OS.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(), "method": RenderingServer.get_current_rendering_method(),
		"window_pixels": [root.size.x, root.size.y], "user_data_dir": OS.get_user_data_dir(),
		"engine_stdout": Engine.print_to_stdout,
		"disable_stdout": ProjectSettings.get_setting("application/run/disable_stdout", false),
		"disable_stderr": ProjectSettings.get_setting("application/run/disable_stderr", false),
		"thread_model": ProjectSettings.get_setting("rendering/driver/threads/thread_model", -1),
		"harness_sha256": FileAccess.get_sha256(get_script().resource_path)
	})
'''


def command_record(command: list[str], output: Path, timeout: int = 20) -> dict:
    before = stamp()
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                timeout=timeout, check=False)
        output.write_bytes(result.stdout)
        return {"command": command, "start": before, "end": stamp(), "exit": result.returncode,
                "output": output.name}
    except subprocess.TimeoutExpired as error:
        output.write_bytes(error.stdout or b"")
        return {"command": command, "start": before, "end": stamp(), "exit": None,
                "timeout": True, "output": output.name}


def preflight(output: Path) -> None:
    details = {"platform": platform.platform(), "uid": os.getuid(), "sample_confirmed": False,
               "xctrace_used": False, "commands": []}
    try:
        if platform.system() != "Darwin" or os.environ.get("RUNNER_OS") != "macOS":
            raise ValueError("Runtime sampling is restricted to the macOS Actions runner")
        if os.environ.get("GITHUB_REF") != BRANCH or os.getuid() == 0:
            raise ValueError("Require the study branch and an ordinary, non-root user")
        if not os.access("/usr/bin/sample", os.X_OK):
            raise ValueError("The runner does not provide executable /usr/bin/sample")
        usage = command_record(["/usr/bin/sample"], output / "sample-usage.txt")
        details["commands"].append(usage)
        help_text = (output / "sample-usage.txt").read_text(errors="replace")
        if not all(part in help_text.lower() for part in ["duration", "interval", "-file"]):
            raise ValueError("Installed sample CLI did not confirm duration/interval/-file syntax")
        timer = command_record(["/usr/bin/time", "-l", "/usr/bin/true"], output / "time-capability.txt")
        details["commands"].append(timer)
        if timer["exit"] != 0:
            raise ValueError("Ordinary /usr/bin/time -l is unavailable")
        details["commands"].append(command_record(["/usr/bin/sw_vers"], output / "macos-version.txt"))
        details["commands"].append(command_record(["/usr/bin/xcrun", "--find", "xctrace"], output / "xctrace-location.txt"))
        # Availability is recorded only. No Instruments trace, privileges or fallback.
        details["sample_confirmed"] = True
    finally:
        write_json(output / "capabilities.json", details)


def inspect_sample(path: Path, expected_pid: int) -> dict:
    text = path.read_text(errors="replace")
    if not re.search(r"^Process:\s+.*\[" + str(expected_pid) + r"\]\s*$", text, re.M):
        raise ValueError("Raw sample is not bound to the launched Godot PID")
    if "Call graph:" not in text or "Binary Images:" not in text:
        raise ValueError("Raw sample lacks complete call-graph/binary-image sections")
    threads = re.findall(r"^\s*\d+\s+Thread_[^\n]+", text, re.M)
    if not threads:
        raise ValueError("Raw sample has no sampled thread stacks")
    engine_lines = {line.strip() for line in text.splitlines() if "(in Godot)" in line}
    unresolved = {line for line in engine_lines if "???" in line}
    return {"target_pid": expected_pid, "thread_headers": threads,
            "unique_engine_stack_lines": len(engine_lines), "unresolved_engine_stack_lines": len(unresolved),
            "symbolization_note": "Line counts are distinct text entries, not sample weights or CPU percentages. Inspect raw addresses/images and named thread stacks before attribution.",
            "limit": "sample captures stack occupancy, including sleeping/blocked threads; neither exclusive CPU duration nor GPU pass timing follows from these counts."}


def validate_session(output: Path, pid: int, harness_sha: str, sampling: dict) -> dict:
    game = output / "session"
    log = (output / "godot.log").read_text(errors="replace")
    if ERRORS.search(log) or MARKER not in log:
        raise ValueError("Runtime errors or missing functional completion marker")
    ready, stopped, complete = [json.loads((game / f"event-{stage}.json").read_text())
                                 for stage in ["route_ready", "route_finished", "complete"]]
    for receipt in [ready, stopped, complete]:
        if any([receipt["pid"] != pid, receipt["source"] != SOURCE, receipt["pck_sha256"] != PCK_SHA,
                receipt["harness_sha256"] != harness_sha, receipt["area"] != "deep", receipt["seed"] != 4608]):
            raise ValueError("Runtime receipt identity mismatch")
    if not complete["functional"] or not stopped["held_mining"] or complete["held_mining"]:
        raise ValueError("Functional or ordinary input-restoration gate failed")
    if not 60 <= stopped["route_elapsed_seconds"] < 90:
        raise ValueError("Missing a real sixty-second route")
    if not ready["unix_seconds"] < sampling["start"]["unix_seconds"] < sampling["end"]["unix_seconds"] < stopped["unix_seconds"]:
        raise ValueError("Sampler invocation was not fully contained in the moving route")
    if sampling["end"]["monotonic_seconds"] - sampling["start"]["monotonic_seconds"] < SAMPLE_SECONDS:
        raise ValueError("Sampler did not complete its requested sampling duration")
    report = json.loads((game / "session.json").read_text())
    raw = json.loads((game / "raw-windows.json").read_text())
    if not (report["functional"] and report["persistence_enabled"] and report["save_bytes"] > 0
            and report["area"] == "deep" and report["seconds"] == SECONDS and report["workload"] == "held_mining_v1"
            and report["distance"] > 100 and report["mined_resources"] > 0 and report["end_orphans"] == 0):
        raise ValueError("Established route functional/persistence/orphan gates failed")
    if report["os"] != "macOS" or report["display"] == "headless" or re.search("llvmpipe|swiftshader|software", report["renderer"], re.I):
        raise ValueError("Expected the real macOS native renderer")
    if report["window_pixels"] != [1696, 780] or report["framebuffer_size"] != [1696, 780]:
        raise ValueError("The requested exact framebuffer was not rendered")
    if len(raw) != len(report["windows"]) or len(raw) < 2:
        raise ValueError("Raw windows are missing")
    for original, values in zip(report["windows"], raw):
        if original["frames"] != len(values["frame_ms"]) or any(x <= 0 for x in values["frame_ms"]):
            raise ValueError("Raw frame sample count/duration mismatch")
    measured_seconds = sum(sum(w["frame_ms"]) for w in raw) / 1000
    if not 60 <= measured_seconds < 90:
        raise ValueError("Raw frames do not cover sixty actual seconds")
    return {"actual_route_seconds": stopped["route_elapsed_seconds"], "raw_frame_seconds": measured_seconds,
            "frame_count": sum(len(w["frame_ms"]) for w in raw), "distance": report["distance"],
            "mined_resources": report["mined_resources"], "renderer": report["renderer"],
            "functional": True, "performance_acceptance": False}


def run(args: argparse.Namespace) -> int:
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    report = {"schema": 1, "source": SOURCE, "pck_sha256": PCK_SHA, "success": False,
              "start": stamp(), "limits": [
                  "One sampled session, no unsampled control and no profiler-overhead correction.",
                  "Sample/time process usage is retained; impact on gameplay cannot be isolated from one run.",
                  "Named waits do not identify their cause or establish exclusive GPU duration.",
                  "Virtual Mac native PCK; not browser, physical iPhone or stable-50 certification."]}
    godot_process = sampler_process = None
    try:
        route = args.project / "tools/review_premium_session.gd"
        pck = args.candidate / "index.pck"
        identity = args.candidate / "artifact-identity.json"
        if sha(pck) != PCK_SHA or pck.stat().st_size != PCK_BYTES or sha(identity) != IDENTITY_SHA:
            raise ValueError("The already-published immutable DEV11 package identity does not match")
        package = json.loads(identity.read_text())
        if package["sourceSha"] != SOURCE or package["runId"] != "35186932201":
            raise ValueError("Candidate artifact source/run mismatch")
        (output / "artifact-identity.json").write_bytes(identity.read_bytes())
        harness = output / "generated-session.gd"
        harness.write_text(generate(route))
        (output / "original-route.gd").write_bytes(route.read_bytes())
        report["identity"] = {"pck_bytes": pck.stat().st_size, "pck_path": str(pck),
                              "route_sha256": ROUTE_SHA, "harness_sha256": sha(harness),
                              "generator_sha256": sha(Path(__file__)), "godot_sha256": sha(args.godot),
                              "workflow_commit": os.environ.get("GITHUB_SHA"),
                              "workflow_run": os.environ.get("GITHUB_RUN_ID"),
                              "workflow_attempt": os.environ.get("GITHUB_RUN_ATTEMPT")}
        if args.prepare_only:
            report["prepared_only"] = True
            report["success"] = True
            return 0
        preflight(output)
        version = command_record([str(args.godot), "--version"], output / "godot-version.txt")
        if version["exit"] != 0 or not (output / "godot-version.txt").read_text().startswith("4.7.2.stable"):
            raise ValueError("The matching Godot 4.7.2 engine is unavailable")
        launch = output / "empty-project"
        launch.mkdir()
        session = output / "session"
        session.mkdir()
        command = [str(args.godot.resolve()), "--path", str(launch), "--main-pack", str(pck.resolve()),
                   "--resolution", "1696x780", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy",
                   "--script", str(harness), "--", "--output=" + str(session), "--area=deep", "--seconds=60"]
        report["command"] = command
        with (output / "godot.log").open("wb") as log, (output / "sample-tool-and-overhead.log").open("wb") as sampler_log:
            godot_process = subprocess.Popen(command, cwd=launch, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            report["pid"] = godot_process.pid
            report["launched"] = stamp()
            deadline = time.monotonic() + 180
            ready_at = None
            while godot_process.poll() is None:
                now = time.monotonic()
                if now >= deadline:
                    raise TimeoutError("The single diagnostic session exceeded 180 seconds")
                if ERRORS.search((output / "godot.log").read_text(errors="replace")):
                    raise ValueError("Godot reported a runtime error; preserving failure")
                ready_path = session / "event-route_ready.json"
                if ready_at is None and ready_path.exists():
                    receipt = json.loads(ready_path.read_text())
                    if receipt["pid"] != godot_process.pid:
                        raise ValueError("Ready receipt does not name the actual child")
                    ready_at = now
                    report["ready_observed"] = stamp()
                if ready_at is not None and now >= ready_at + SAMPLE_AFTER and sampler_process is None:
                    report["process_before_sample"] = command_record(
                        ["/bin/ps", "-p", str(godot_process.pid), "-o", "pid,ppid,uid,lstart,etime,time,pcpu,comm,args"],
                        output / "process-before.txt")
                    sample_command = ["/usr/bin/time", "-l", "/usr/bin/sample", str(godot_process.pid),
                                      str(SAMPLE_SECONDS), str(INTERVAL_MS), "-file", str(output / "sample.txt")]
                    report["sampling"] = {"command": sample_command, "start": stamp(), "seconds": SAMPLE_SECONDS,
                                          "interval_ms": INTERVAL_MS, "target_pid": godot_process.pid}
                    sampler_process = subprocess.Popen(sample_command, stdout=sampler_log, stderr=subprocess.STDOUT, start_new_session=True)
                if sampler_process is not None and "end" not in report["sampling"]:
                    code = sampler_process.poll()
                    if code is not None:
                        report["sampling"].update({"end": stamp(), "exit": code})
                        report["process_after_sample"] = command_record(
                            ["/bin/ps", "-p", str(godot_process.pid), "-o", "pid,ppid,uid,lstart,etime,time,pcpu,comm,args"],
                            output / "process-after.txt")
                        if code != 0:
                            raise ValueError("Ordinary-user sample attachment/capture failed; no retry or fallback")
                        report["stack_structure"] = inspect_sample(output / "sample.txt", godot_process.pid)
                    elif now - report["sampling"]["start"]["monotonic_seconds"] > 30:
                        raise TimeoutError("The bounded sampler/symbolication exceeded thirty seconds")
                time.sleep(0.1)
            report["godot_exit"] = godot_process.returncode
        if godot_process.returncode != 0:
            raise ValueError("Godot did not exit successfully")
        if sampler_process is None or "end" not in report["sampling"]:
            raise ValueError("Godot exited without a complete sampler invocation")
        report["session"] = validate_session(output, godot_process.pid, sha(harness), report["sampling"])
        if sha(pck) != PCK_SHA:
            raise ValueError("Published PCK changed during diagnosis")
        report["success"] = True
        print("MAC_CPU_SAMPLE_CAPTURE_COMPLETE functional=true attribution=requires_raw_stack_review")
        return 0
    except Exception as error:
        report["failure"] = f"{type(error).__name__}: {error}"
        print(report["failure"], file=sys.stderr)
        return 2
    finally:
        for process in [sampler_process, godot_process]:
            if process is not None and process.poll() is None:
                # Only the process group created for this owned child; include
                # sample beneath /usr/bin/time if a bounded timeout interrupts it.
                try:
                    os.killpg(process.pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    try:
                        os.killpg(process.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    process.wait()
        report["godot_exit"] = godot_process.returncode if godot_process is not None else None
        report["sampler_exit"] = sampler_process.returncode if sampler_process is not None else None
        report["end"] = stamp()
        write_json(output / "diagnostic.json", report)
        write_json(output / "file-manifest.json", [{"path": str(p.relative_to(output)), "bytes": p.stat().st_size,
                                                     "sha256": sha(p)} for p in sorted(output.rglob("*"))
                                                    if p.is_file() and p.name != "file-manifest.json"])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True, type=Path)
    parser.add_argument("--candidate", required=True, type=Path)
    parser.add_argument("--godot", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--prepare-only", action="store_true", help="Only bind identities and generate the unchanged-route diagnostic; never launch Godot/sample.")
    return run(parser.parse_args())


if __name__ == "__main__":
    raise SystemExit(main())
