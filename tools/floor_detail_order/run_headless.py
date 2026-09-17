#!/usr/bin/env python3
"""Bind unchanged DEV11 resources and run only the headless opportunity screen."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time

SOURCE = "8f5680defb9083bbe1e044d39a10612f2186e7f3"
PCK_SHA = "5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9"
ROOT = Path(__file__).resolve().parents[2]
PINS = {
    "scripts/world/endless_descent_world.gd": "5115995cf0b1b531d51a65af832a9a818f2e14136abee3bc922b2f47fb3667ac",
    "scripts/lighting/lit_draw_sections.gd": "260dc901a518ee71f18451bd9e1025889d1bb5fbce46f678aaf13a47a1f64eac",
    "shaders/lit_visible_pixels.gdshader": "6ba2feb3a212b238ade4d285f688e00e2106797f0fc05ecf1a4670977136ee7d",
}


def sha(path):
    with Path(path).open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--pack", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    out = args.output.resolve()
    if out.exists():
        raise ValueError("Use a fresh evidence directory; previous failures stay intact")
    out.mkdir(parents=True)
    if args.pack.stat().st_size != 221013680 or sha(args.pack) != PCK_SHA:
        raise ValueError("Not the unchanged published DEV11 PCK")
    if subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip() != SOURCE:
        raise ValueError("Unexpected study base")
    subprocess.run(["git", "diff", "--quiet", "HEAD", "--", "scripts", "shaders", "scenes", "assets", "project.godot"], cwd=ROOT, check=True)
    for name, digest in PINS.items():
        if sha(ROOT / name) != digest:
            raise ValueError("Production source pin failed: " + name)
    tool_files = sorted(Path(__file__).parent.glob("*.gd")) + [Path(__file__).resolve()]
    identity = {"source": SOURCE, "pck_sha256": PCK_SHA, "production_pins": PINS,
                "tools": [{"name": p.name, "sha256": sha(p)} for p in tool_files],
                "rendered": False, "timed": False}
    (out / "source-identity.json").write_text(json.dumps(identity, indent=2) + "\n")
    empty = out / "empty-project"
    empty.mkdir()
    environment = dict(os.environ, XDG_DATA_HOME=str(out / "userdata"))
    command = [str(args.godot.resolve()), "--headless", "--path", str(empty),
               "--main-pack", str(args.pack.resolve()), "--audio-driver", "Dummy",
               "--script", str(Path(__file__).with_name("check.gd").resolve()), "--",
               "--output=" + str(out), "--bound-pck=" + PCK_SHA]
    start = time.monotonic()
    with (out / "godot.log").open("wb") as log:
        process = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT,
                                 cwd=empty, env=environment, timeout=90)
    receipt = {"command": command, "exit": process.returncode,
               "elapsed_seconds": time.monotonic() - start, "rendered": False}
    (out / "execution-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    text = (out / "godot.log").read_text(errors="replace")
    if process.returncode or re.search(r"(^|\n)(SCRIPT ERROR|ERROR:|Parse Error)", text) or "FLOOR_DETAIL_AUDIT_COMPLETE guards=true" not in text:
        raise RuntimeError("Headless guard gate failed; retain godot.log")
    report = json.loads((out / "headless-audit.json").read_text())
    if not report["headless_guards_passed"] or len(report["inventory"]) != 9 or len(report["guards"]) != 10:
        raise RuntimeError("Incomplete guard/inventory report")
    for name, field in [("candidate.gd", "candidate_sha256"), ("audit.gd", "audit_sha256"), ("check.gd", "harness_sha256")]:
        if report[field] != sha(Path(__file__).with_name(name)):
            raise RuntimeError("Executed tool hash mismatch")
    print(json.dumps({"headless_guards_passed": True,
                      "median_modeled_reduction": report["median_modeled_reduction"],
                      "worthwhile_for_pixel_and_draw_gate": report["worthwhile_for_pixel_and_draw_gate"],
                      "output": str(out)}))


if __name__ == "__main__":
    main()
