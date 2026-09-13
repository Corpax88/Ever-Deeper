"""Shared identities for the DEV-only 1.0 candidate; no deployment operations."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
REPOSITORY = "Corpax88/Ever-Deeper"
BRANCH = "codex-ever-deeper-1-0"
DEV_VERSION = "1.0.0-dev.8"
PRODUCTION_VERSION = "1.0.0-rc.1"
ARTIFACT_NAME = "ever-deeper-one-point-zero-dev-candidate"
WORKFLOW = ".github/workflows/one-point-zero.yml"
WEB_FILES = frozenset((
    "index.html", "index.js", "index.pck", "index.wasm",
    "index.audio.position.worklet.js", "index.audio.worklet.js",
    "index.png", "index.icon.png", "index.apple-touch-icon.png",
))
CASES = [
    "input", "overhaul", "touch", "endgame", "onboarding", "layout", "portrait",
    "dev-tools", "crusher", "one-point-zero-state", "one-point-zero-world",
    "one-point-zero-migration", "one-point-zero-ui", "mole-autonomy",
]
REQUIRED_JOBS = {"build", "mobile", "hero-motion", "native-visual", "web-audio (webkit)", "web-audio (chromium)"}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def read_json(path):
    return json.loads(Path(path).read_text())


def write_json(path, value):
    Path(path).write_text(json.dumps(value, indent=2) + "\n")


def identity(path):
    path = Path(path)
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return {"sha256": digest.hexdigest(), "size": path.stat().st_size}


def valid_sha(value, length=64):
    return isinstance(value, str) and re.fullmatch(r"[a-f0-9]{%d}" % length, value) is not None


def check_files(directory, expected):
    require(set(expected) == WEB_FILES, "Unexpected web-file manifest")
    require({p.name for p in directory.iterdir()} == WEB_FILES, "Unexpected web directory contents")
    for name, info in expected.items():
        path = directory / name
        require(path.is_file() and not path.is_symlink(), "Unsafe web file: " + name)
        require(identity(path) == info, "Changed web file: " + name)


def verify_candidate(candidate):
    candidate = Path(candidate)
    require({p.name for p in candidate.iterdir()} == {"dev", "manifest.json", "validation.json"}, "Unexpected candidate payload")
    manifest = read_json(candidate / "manifest.json")
    require(manifest["schema"] == 1, "Unknown manifest schema")
    require(manifest["repository"] == REPOSITORY and manifest["source_branch"] == BRANCH, "Wrong source repository/branch")
    require(valid_sha(manifest["source_commit"], 40), "Invalid source commit")
    require(manifest["dev_version"] == DEV_VERSION and manifest["production_version"] == PRODUCTION_VERSION, "Wrong candidate versions")
    require(manifest["engine"].startswith("4.7.2.stable."), "Wrong Godot version")
    require(manifest["qa_cases"] == CASES, "Required gameplay gates differ")
    check_files(candidate / "dev", manifest["dev_files"])
    require(identity(candidate / "validation.json") == manifest["validation"], "Changed validation report")
    validation = read_json(candidate / "validation.json")
    require(validation["passed"] is True, "Build validation did not pass")
    require(set(validation["checks"]) == {"source", "dev", "dev-flavor", "production-flavor", "hero-audio", "hero-transitions"}, "Incomplete build validation")
    for name, report in validation["checks"].items():
        require(report["passed"] is True, "Failed validation: " + name)
    for name in ("source", "dev"):
        rows = validation["checks"][name]["cases"]
        require([row["case"] for row in rows] == CASES and all(row["passed"] is True for row in rows), "Incomplete gameplay cases: " + name)
    require(set(manifest["production_flavor_files"]) == WEB_FILES, "Production flavor evidence missing")
    for name, version, files in (("dev-flavor", DEV_VERSION, manifest["dev_files"]), ("production-flavor", PRODUCTION_VERSION, manifest["production_flavor_files"])):
        report = validation["checks"][name]
        require(report["version"] == version and report["pack"] == files["index.pck"], "Flavor check belongs to different package/version: " + name)
    return manifest
