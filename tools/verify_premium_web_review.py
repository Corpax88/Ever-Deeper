#!/usr/bin/env python3
"""Verify the complete immutable premium review. This never approves or publishes."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import sys

from qa import CASES as QA_CASES

ROOT = Path(__file__).resolve().parents[1]
SECTIONS = ("pause", "wardrobe", "light", "lists", "starforge", "workshops")
BROWSER_SUITES = ("visual-forge", "visual-workshops", "gameplay", *("touch-" + s for s in SECTIONS))
RESIDENCY = "commerce-residency"
CORE = (
    "premium-core", "input", "overhaul", "touch", "endgame", "onboarding", "layout",
    "portrait", "dev-tools", "crusher", "one-point-zero-state", "one-point-zero-world",
    "one-point-zero-migration", "one-point-zero-ui", "mole-autonomy",
)
VISUAL_STATES = (
    "shop_forge_ordinary_ready", "shop_forge_ordinary_missing_gold",
    "shop_forge_final_missing_resource", "shop_forge_final_missing_both",
    "shop_forge_final_mixed_cost_ready", "shop_forge_final_world_locked_funded",
    "shop_forge_mastery_rank_five_ready", "shop_forge_mastery_insufficient",
    "shop_forge_complete_mastered", "shop_forge_icon_fallback", "shop_wayfarer_baseline",
    "shop_workshop_tool_forge_baseline", "shop_starforge_owned_active",
    "shop_starforge_world_locked", "shop_workshop_light_lab_baseline",
    "shop_workshop_wardrobe_baseline", "shop_workshop_treasure_chamber_baseline",
    "shop_workshop_lift_workshop_baseline", "shop_workshop_tool_forge_locked_loadout",
)
CSS = {"width": 848, "height": 390}
PIXELS = {"width": 1696, "height": 780}
ERROR = re.compile(r"SCRIPT ERROR|Parse Error|(?:^|\n)ERROR:|Assertion failed|CHECK_FAILED|INVALID_OPERATION|INVALID_FRAMEBUFFER_OPERATION|ED_GL_BIND_CONFLICT", re.M)
GAMEPLAY_RESULT = re.compile(r"EVER_DEEPER_OVERHAUL_GAMEPLAY_OK checks=([1-9][0-9]*) failures=\[\]")
META_FILES = {"manifest.json", "artifact-identity.json"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_json(path):
    return json.loads(Path(path).read_text())


def write_json(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")


def sha256(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def valid_hash(value):
    return isinstance(value, str) and re.fullmatch(r"[0-9a-f]{64}", value) is not None


def positive_int(value):
    return type(value) is int and value > 0


def safe_file(directory, filename):
    require(isinstance(filename, str) and filename == Path(filename).name and filename not in ("", ".", ".."), "Invalid evidence filename")
    path = directory / filename
    require(path.is_file() and not path.is_symlink(), "Missing regular file: " + str(path))
    return path


def png_info(path):
    with path.open("rb") as stream:
        header = stream.read(24)
    require(len(header) == 24 and header[:8] == b"\x89PNG\r\n\x1a\n" and header[8:16] == b"\x00\x00\x00\rIHDR", "Invalid PNG header: " + str(path))
    width, height = struct.unpack(">II", header[16:24])
    require(width > 0 and height > 0, "Empty PNG: " + str(path))
    return {"sha256": sha256(path), "width": width, "height": height}


def file_manifest(directory):
    rows = {}
    for path in sorted(directory.iterdir()):
        if path.name in META_FILES:
            continue
        require(path.is_file() and not path.is_symlink(), "Unexpected package entry: " + str(path))
        rows[path.name] = {"size": path.stat().st_size, "sha256": sha256(path)}
    require({"index.pck", "index.html", "index.js", "index.wasm"} <= rows.keys(), "Incomplete Web export")
    require(all(row["size"] > 0 for row in rows.values()), "Empty Web export file")
    return rows


def source_hashes():
    return {
        "harnessSha256": sha256(ROOT / "tools/review_commerce_residency.gd"),
        "runnerSha256": sha256(ROOT / "tools/capture-web.mjs"),
        "verifierSha256": sha256(Path(__file__)),
    }


def identity_contract(identity, source):
    require(identity.get("schema") == 1 and identity.get("sourceSha") == source, "Source identity mismatch")
    require(re.fullmatch(r"[0-9a-f]{40}", source) is not None, "Expected a full immutable source SHA")
    require(identity.get("physicalIphone") is False, "Identity must not claim physical iPhone evidence")
    require(identity.get("runId") == os.environ.get("GITHUB_RUN_ID", "local"), "Artifact belongs to another workflow run")
    for key, digest in source_hashes().items():
        require(identity.get(key) == digest, "Review source hash mismatch: " + key)
    for group in ("devFiles", "productionFiles"):
        files = identity.get(group)
        require(isinstance(files, dict) and {"index.pck", "index.html", "index.js", "index.wasm"} <= files.keys(), "Missing package manifest: " + group)
        for name, row in files.items():
            require(name == Path(name).name and name not in META_FILES, "Invalid package manifest name")
            require(positive_int(row.get("size")) and valid_hash(row.get("sha256")), "Invalid package file identity: " + name)


def bind(args):
    dev = file_manifest(args.candidate)
    production = file_manifest(args.production)
    identity = {
        "schema": 1, "sourceSha": args.source, "runId": os.environ.get("GITHUB_RUN_ID", "local"),
        "runAttempt": os.environ.get("GITHUB_RUN_ATTEMPT", "local"), "physicalIphone": False,
        "devFiles": dev, "productionFiles": production, **source_hashes(),
    }
    identity_contract(identity, args.source)
    write_json(args.candidate / "manifest.json", dev)
    write_json(args.production / "manifest.json", production)
    write_json(args.candidate / "artifact-identity.json", identity)
    write_json(args.review / "artifact-identity.json", identity)
    write_json(args.review / "candidate-manifest.json", dev)
    write_json(args.review / "production-manifest.json", production)
    outputs = {
        "source_sha": args.source,
        "pck_sha256": dev["index.pck"]["sha256"], "html_sha256": dev["index.html"]["sha256"],
        "production_pck_sha256": production["index.pck"]["sha256"],
        "production_html_sha256": production["index.html"]["sha256"],
        "identity_sha256": sha256(args.review / "artifact-identity.json"),
    }
    with args.github_output.open("a") as stream:
        for key, value in outputs.items():
            stream.write(f"{key}={value}\n")


def candidate(args):
    identity = read_json(args.candidate / "artifact-identity.json")
    identity_contract(identity, args.source)
    require(sha256(args.candidate / "artifact-identity.json") == args.identity_sha256, "Build identity hash mismatch")
    require(identity["devFiles"]["index.pck"]["sha256"] == args.pck_sha256, "DEV PCK differs from build output")
    require(identity["devFiles"]["index.html"]["sha256"] == args.html_sha256, "DEV HTML differs from build output")
    require(read_json(args.candidate / "manifest.json") == identity["devFiles"], "Candidate manifest differs from bound identity")
    require(file_manifest(args.candidate) == identity["devFiles"], "Downloaded package bytes changed")
    write_json(args.review / "artifact-identity.json", identity)


def record(args):
    # Keep failed/partial outputs useful without turning them into a passed review.
    args.review.mkdir(parents=True, exist_ok=True)
    pngs, errors = {}, []
    for path in sorted(args.review.glob("*.png")):
        try:
            pngs[path.name] = png_info(path)
        except (OSError, ValueError) as error:
            errors.append(str(error))
    (args.review / "source-sha.txt").write_text(args.source + "\n")
    write_json(args.review / "suite-result.json", {
        "schema": 1, "suite": args.suite, "sourceSha": args.source,
        "runId": os.environ.get("GITHUB_RUN_ID", "local"),
        "runAttempt": os.environ.get("GITHUB_RUN_ATTEMPT", "local"),
        "identityOutcome": args.identity_outcome, "captureOutcome": args.capture_outcome,
        "physicalIphone": False, "pngFiles": pngs, "pngErrors": errors,
    })


def checked_log(path):
    text = path.read_text(errors="replace")
    require(text.strip(), "Empty log: " + str(path))
    require(ERROR.search(text) is None, "Runtime/browser error in " + str(path))
    return text


def qa_report(directory, expected):
    report = read_json(directory / "results.json")
    require(report.get("passed") is True, "Failed QA: " + str(directory))
    rows = report.get("cases", [])
    require(len(rows) == len(expected) and {row.get("case") for row in rows} == set(expected), "Incomplete or duplicate QA case coverage: " + str(directory))
    for row in rows:
        require(row.get("passed") is True and row.get("exit_code") == 0 and row.get("reason") == "", "Failed QA case: " + str(row.get("case")))
        marker = row.get("marker")
        require(marker == QA_CASES[row["case"]][1] and marker in checked_log(directory / (row["case"] + ".log")), "Missing or wrong QA completion marker")
    return len(rows)


def build_review(directory, identity, outputs):
    require((directory / "source-sha.txt").read_text().strip() == identity["sourceSha"], "Build source receipt mismatch")
    require(sha256(directory / "artifact-identity.json") == outputs.get("identity_sha256"), "Build identity bytes differ from job output")
    for group, filename in (("devFiles", "candidate-manifest.json"), ("productionFiles", "production-manifest.json")):
        require(read_json(directory / filename) == identity[group], "Build file manifest mismatch")
    require(outputs.get("source_sha") == identity["sourceSha"], "Build source output mismatch")
    for output, group, filename in (
        ("pck_sha256", "devFiles", "index.pck"), ("html_sha256", "devFiles", "index.html"),
        ("production_pck_sha256", "productionFiles", "index.pck"),
        ("production_html_sha256", "productionFiles", "index.html"),
    ):
        require(outputs.get(output) == identity[group][filename]["sha256"], "Build hash output mismatch: " + output)
    for name in ("import.log", "export-dev.log", "export-production.log"):
        checked_log(directory / name)
    return {
        "coreCases": qa_report(directory / "core", CORE),
        "devFlavorCases": qa_report(directory / "dev-flavor", ("build-flavor",)),
        "productionFlavorCases": qa_report(directory / "production-flavor", ("build-flavor",)),
    }


def suite_receipt(directory, suite, identity):
    require(read_json(directory / "artifact-identity.json") == identity, "Suite consumed another build identity: " + suite)
    require((directory / "source-sha.txt").read_text().strip() == identity["sourceSha"], "Suite source mismatch: " + suite)
    receipt = read_json(directory / "suite-result.json")
    require(receipt.get("suite") == suite and receipt.get("sourceSha") == identity["sourceSha"], "Wrong suite/source receipt")
    require(receipt.get("runId") == identity["runId"], "Suite receipt from another workflow run")
    require(receipt.get("identityOutcome") == "success" and receipt.get("captureOutcome") == "success", "Suite did not finish successfully: " + suite)
    require(receipt.get("physicalIphone") is False and receipt.get("pngErrors") == [], "Invalid image/device receipt")
    pngs = receipt.get("pngFiles")
    require(isinstance(pngs, dict) and pngs, "No PNG evidence: " + suite)
    require(set(pngs) == {p.name for p in directory.glob("*.png")}, "PNG inventory changed: " + suite)
    for name, info in pngs.items():
        require(png_info(safe_file(directory, name)) == info, "PNG bytes or dimensions changed: " + name)
    return pngs


def browser_identity(report, identity):
    require(report.get("pckSha256") == identity["devFiles"]["index.pck"]["sha256"], "Browser PCK identity mismatch")
    require(report.get("htmlSha256") == identity["devFiles"]["index.html"]["sha256"], "Browser HTML identity mismatch")
    require(report.get("viewport") == CSS and report.get("physicalViewport") == PIXELS and report.get("dpr") == 2, "Wrong declared browser geometry")
    require(report.get("physicalIphone") is False, "Browser result cannot claim a physical iPhone")
    webgl = report.get("webgl", {})
    require(all(isinstance(webgl.get(key), str) and webgl[key] for key in ("renderer", "vendor", "version")), "Missing actual WebGL adapter")
    require("WebGL 2" in webgl["version"], "WebGL 2 was not verified")


def actual_surfaces(surfaces):
    require(isinstance(surfaces, list) and surfaces, "No actual browser surfaces")
    for row in surfaces:
        require(row.get("css") == CSS and row.get("canvas") == PIXELS and row.get("buffer") == PIXELS and row.get("dpr") == 2, "Wrong actual canvas/GL/CSS/DPR surface")
        require(isinstance(row.get("label"), str) and row["label"], "Unlabelled actual surface")


def browser_review(directory, suite, identity):
    pngs = suite_receipt(directory, suite, identity)
    require(all((row["width"], row["height"]) == (1696, 780) for row in pngs.values()), "Wrong browser PNG dimensions")
    log = checked_log(directory / "runner.log")
    console = read_json(directory / "browser-console.json")
    require(isinstance(console, list) and console, "Missing browser console evidence")
    require(all(ERROR.search(str(row.get("text", ""))) is None for row in console), "Browser console contains errors")
    started = read_json(directory / "browser-run.json")
    browser_identity(started, identity)
    require(started.get("status") == "started", "Missing browser start receipt")
    visual = suite.startswith("visual-")
    touch = suite.startswith("touch-")
    section = suite.removeprefix("touch-") if touch else None
    require(started.get("gameplay") is (not visual) and started.get("menuTouch") is touch and started.get("touchSection") == section, "Wrong browser mode or requested touch section")
    surfaces = read_json(directory / "browser-surfaces.json")
    actual_surfaces(surfaces)
    if visual:
        first, last = (1, 14) if suite == "visual-forge" else (15, 19)
        report = read_json(directory / "manifest.json")
        browser_identity(report, identity)
        require(started.get("range") == [first, last] and report.get("range") == [first, last], "Wrong visual range")
        require(report.get("surfaces") == surfaces, "Visual surface journal mismatch")
        expected = [(i, VISUAL_STATES[i - 1]) for i in range(first, last + 1)]
        captures = report.get("captures", [])
        require(report.get("captureCount") == len(expected) and len(captures) == len(expected), "Incomplete visual captures")
        require([(row.get("index"), row.get("state")) for row in captures] == expected, "Wrong visual state coverage or order")
        require([row["label"] for row in surfaces] == [state for _, state in expected], "Missing visual surface measurements")
        expected_files = set()
        for row in captures:
            filename = f'{row["index"]:03d}_{row["state"]}.png'
            require(row.get("file") == filename and filename in pngs, "Missing or renamed visual PNG")
            require(row.get("sha256") == pngs[filename]["sha256"], "Visual PNG hash mismatch")
            expected_files.add(filename)
        require(set(pngs) == expected_files, "Unexpected visual PNG coverage")
        ready = re.findall(r"^EVER_DEEPER_VISUAL_CAPTURE_READY state=([a-z0-9_-]+) index=(\d+) total=(\d+)$", log, re.M)
        require(ready == [(state, str(i + 1), str(len(expected))) for i, (_, state) in enumerate(expected)], "Incomplete visual READY markers")
        require(re.findall(r"^EVER_DEEPER_VISUAL_CAPTURE_COMPLETE count=(\d+)$", log, re.M) == [str(len(expected))], "Missing visual completion marker")
        return {"visualCases": [first, last], "pngCount": len(pngs)}
    report = read_json(directory / "gameplay.json")
    browser_identity(report, identity)
    require(report.get("surfaces") == surfaces, "Gameplay surface journal mismatch")
    result = report.get("result", "")
    matched = GAMEPLAY_RESULT.fullmatch(result)
    require(matched is not None and result in log, "Missing successful nonempty gameplay result")
    checks = int(matched.group(1))
    require(report.get("menuTouch") is touch and report.get("touchSection") == section, "Wrong completed touch section")
    events, results = report.get("touchSectionEvents"), report.get("touchSectionResults")
    if touch:
        require(isinstance(events, list) and len(events) == 2 and [(row.get("phase"), row.get("section")) for row in events] == [("BEGIN", section), ("COMPLETE", section)], "Touch section did not complete exactly once")
        require(isinstance(results, list) and len(results) == 1, "Missing or extra touch section results")
        row = results[0]
        require(row.get("section") == section and positive_int(row.get("checks")) and row.get("failures") == [], "Failed or empty touch section")
        require(row["checks"] == checks and events[1] == {"phase": "COMPLETE", **row}, "Touch section count does not match final total")
    else:
        require(events == [] and results == [], "Ordinary gameplay contains touch section results")
    gestures = read_json(directory / "gesture-inputs.json")
    require(isinstance(gestures, list) and gestures, "No actual browser input receipts")
    return {"checks": checks, "touchSection": section, "pngCount": len(pngs)}


def residency_review(directory, identity):
    pngs = suite_receipt(directory, RESIDENCY, identity)
    report_path = directory / "commerce-residency.json"
    report = read_json(report_path)
    require(report.get("kind") == "rendered_commerce_resource_lifetime" and report.get("passed") is True, "Residency review failed or missing")
    require(report.get("require_release") is True and report.get("physical_iphone") is False and report.get("frame_time_benchmark") is False, "Residency release/device contract missing")
    require(report.get("package_sha256") == identity["devFiles"]["index.pck"]["sha256"] and report.get("harness_sha256") == identity["harnessSha256"], "Native package/harness identity mismatch")
    require(str(report.get("renderer", "")).lower() == "x11" and re.search(r"llvmpipe|softpipe|software", str(report.get("adapter", "")), re.I), "Residency did not use the real X11 software renderer")
    checks = report.get("checks", [])
    require(checks and all(row.get("passed") is True for row in checks) and report.get("failures") == [], "Failed or empty residency checks")
    require(report.get("fixture", {}).get("framebuffer") == [2532, 1170], "Wrong native framebuffer")
    expected = {f"{shop}-{cycle}.png": (2532, 1170) for shop in ("wardrobe", "light_lab") for cycle in ("opened", "reopened")}
    expected.update({f"light_lab-{cycle}-beam.png": (1100, 900) for cycle in ("opened", "reopened")})
    captures = report.get("captures", [])
    require(len(captures) == len(expected) and {row.get("file") for row in captures} == set(expected) and set(pngs) == set(expected), "Incomplete native residency captures")
    for row in captures:
        filename = row["file"]
        require((row.get("width"), row.get("height")) == expected[filename] and row.get("sha256") == pngs[filename]["sha256"], "Native capture receipt mismatch")
        require((pngs[filename]["width"], pngs[filename]["height"]) == expected[filename], "Native PNG dimensions mismatch")
    expected_stages = ["cold"]
    for shop in ("wardrobe", "light_lab"):
        expected_stages.extend([shop + "-before", shop + "-opened", shop + "-opened-closed", shop + "-reopened", shop + "-reopened-closed"])
    require([row.get("id") for row in report.get("stages", [])] == expected_stages, "Incomplete native resource lifetime cycle")
    for stage in report["stages"]:
        if stage["id"].endswith("-closed"):
            require(stage.get("previous_preview_nodes_freed") is True and stage.get("shop_viewports") == 0 and stage.get("gpu_released_bytes", 0) > 0, "Native preview resources remain after close")
    markers = re.findall(r"^COMMERCE_RESIDENCY_RESULT checks=(\d+) failed=0 captures=(\d+) sha256=([0-9a-f]{64})$", checked_log(directory / "native.log"), re.M)
    require(markers == [(str(len(checks)), str(len(captures)), sha256(report_path))], "Native completion marker/report hash mismatch")
    return {"checks": len(checks), "pngCount": len(pngs)}


def suite(args):
    identity = read_json(args.review / "artifact-identity.json")
    identity_contract(identity, args.source)
    result = residency_review(args.review, identity) if args.suite == RESIDENCY else browser_review(args.review, args.suite, identity)
    print(json.dumps({"suite": args.suite, "passed": True, **result}))


def aggregate(args):
    report = {
        "schema": 1, "sourceSha": args.source, "reviewOnly": True, "physicalIphone": False,
        "passed": False, "complete": False, "errors": [], "units": {},
        "limits": ["CI evidence requires independent visual review.", "No physical iPhone, sustained-device performance or publication approval."],
    }
    # A cancelled or interrupted verifier must never leave a green-looking receipt.
    write_json(args.output, report)

    def attempt(name, operation):
        try:
            report["units"][name] = {"passed": True, **operation()}
        except (OSError, ValueError, TypeError, KeyError, AttributeError) as error:
            report["units"][name] = {"passed": False, "error": str(error)}
            report["errors"].append(name + ": " + str(error))

    needs = {}
    try:
        needs = json.loads(args.needs_json)
        require(set(needs) == {"build", "browser", RESIDENCY}, "Missing required job conclusions")
        for job in ("build", "browser", RESIDENCY):
            require(needs[job].get("result") == "success", "Required job is not successful: " + job + "=" + str(needs[job].get("result")))
    except (ValueError, TypeError, KeyError, AttributeError) as error:
        report["errors"].append("job conclusions: " + str(error))
        if not isinstance(needs, dict):
            needs = {}
    build_dir = args.artifacts / ("premium-web-review-build-" + args.source)
    identity = None
    try:
        identity = read_json(build_dir / "artifact-identity.json")
        identity_contract(identity, args.source)
        report["pckSha256"] = identity["devFiles"]["index.pck"]["sha256"]
        report["htmlSha256"] = identity["devFiles"]["index.html"]["sha256"]
    except (OSError, ValueError, TypeError, KeyError, AttributeError) as error:
        report["errors"].append("build identity: " + str(error))
        identity = None
    if identity is not None:
        outputs = needs.get("build", {}).get("outputs", {})
        attempt("build", lambda: build_review(build_dir, identity, outputs))
        for name in (*BROWSER_SUITES, RESIDENCY):
            directory = args.artifacts / ("premium-web-review-" + name + "-" + args.source)
            operation = (lambda directory=directory: residency_review(directory, identity)) if name == RESIDENCY else (lambda directory=directory, name=name: browser_review(directory, name, identity))
            attempt(name, operation)
    report["complete"] = set(report["units"]) == {"build", *BROWSER_SUITES, RESIDENCY} and all(row["passed"] for row in report["units"].values()) and not report["errors"]
    report["passed"] = report["complete"]
    write_json(args.output, report)
    print(json.dumps(report, indent=2))
    return 0 if report["passed"] else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    bind_parser = commands.add_parser("bind")
    for field in ("candidate", "production", "review", "github-output"):
        bind_parser.add_argument("--" + field, type=Path, required=True)
    candidate_parser = commands.add_parser("candidate")
    for field in ("candidate", "review"):
        candidate_parser.add_argument("--" + field, type=Path, required=True)
    for field in ("pck-sha256", "html-sha256", "identity-sha256"):
        candidate_parser.add_argument("--" + field, required=True)
    record_parser = commands.add_parser("record")
    record_parser.add_argument("--review", type=Path, required=True)
    record_parser.add_argument("--suite", choices=(*BROWSER_SUITES, RESIDENCY), required=True)
    record_parser.add_argument("--identity-outcome", required=True)
    record_parser.add_argument("--capture-outcome", required=True)
    suite_parser = commands.add_parser("suite")
    suite_parser.add_argument("--review", type=Path, required=True)
    suite_parser.add_argument("--suite", choices=(*BROWSER_SUITES, RESIDENCY), required=True)
    aggregate_parser = commands.add_parser("aggregate")
    aggregate_parser.add_argument("--artifacts", type=Path, required=True)
    aggregate_parser.add_argument("--needs-json", required=True)
    aggregate_parser.add_argument("--output", type=Path, required=True)
    for subparser in (bind_parser, candidate_parser, record_parser, suite_parser, aggregate_parser):
        subparser.add_argument("--source", required=True)
    args = parser.parse_args()
    if args.command == "aggregate":
        return aggregate(args)
    globals()[args.command](args)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, TypeError, KeyError, AttributeError) as error:
        print("PREMIUM_WEB_REVIEW_FAILED: " + str(error), file=sys.stderr)
        sys.exit(1)
