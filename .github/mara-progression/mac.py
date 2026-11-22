"""Render the packaged game through its normal world and screen owners."""
import json
import os
import re
import subprocess
import sys
from pathlib import Path


engine, pack, evidence = (Path(arg).resolve() for arg in sys.argv[1:])
root = Path(__file__).resolve().parents[2]
manifest = json.loads((pack.parent / "manifest.json").read_text())
receipt = json.loads((pack.parent / "qa-build-receipt.json").read_text())
assert receipt["files"] == manifest and receipt["retained_payloads_verified"]

for width, height in [(667, 375), (844, 390), (932, 430)]:
    output = evidence / str(width)
    output.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, PAINTED_OUT=str(output), XDG_DATA_HOME=str(output / "isolated-data"))
    command = [
        str(engine), "--path", str(root), "--main-pack", str(pack),
        "--resolution", f"{width}x{height}", "--script", str(root / ".github/mara-progression/review.gd"),
    ]
    process = subprocess.run(command, env=env, capture_output=True, text=True, timeout=210)
    log = process.stdout + process.stderr
    (output / "godot.log").write_text(log)
    assert process.returncode == 0 and not re.search(r"SCRIPT ERROR|^ERROR:", log, re.M), log[-2200:]
    report_path = output / "report.json"
    report = json.loads(report_path.read_text())
    assert report["passed"] and report["viewport"] == [width, height]
    assert all(report["checks"].values()) and len(report["frames"]) == 6
    report.update(source=receipt["source"], production_pck=manifest["index.pck"])
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"{width}x{height}: {len(report['frames'])} captures, {len(report['checks'])} checks", flush=True)
