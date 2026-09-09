"""Build and validate one exact source commit. Never publish from this script."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile

from contracts import (ARTIFACT_NAME, BRANCH, CASES, DEV_VERSION, HERE, PRODUCTION_VERSION,
                       REPOSITORY, ROOT, WEB_FILES, identity, read_json, require,
                       verify_candidate, write_json)

ERROR = re.compile(r"SCRIPT ERROR|Parse Error|(^|\n)ERROR:|Assertion failed|CHECK_FAILED", re.M)


def checked(command, log_path, marker=None, timeout=900, env=None, cwd=ROOT):
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("w") as log:
        result = subprocess.run(command, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
    text = log_path.read_text(errors="replace")
    require(result.returncode == 0 and not ERROR.search(text), "Check failed; see " + str(log_path))
    require(marker is None or marker in text, "Completion marker missing: " + str(log_path))
    print("PASS " + log_path.stem, flush=True)


def build(args):
    candidate, review = args.candidate.resolve(), args.review_output.resolve()
    require(not candidate.exists(), "Candidate destination already exists; do not overwrite reviewed bytes")
    require(not review.exists(), "Review output already exists")
    require(not candidate.is_relative_to(ROOT) and not review.is_relative_to(ROOT), "Build outputs must be outside the source checkout")
    status = subprocess.check_output(["git", "status", "--porcelain"], cwd=ROOT, text=True).strip()
    require(not status, "Build requires a clean committed source checkout")
    source_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
    branch = os.environ.get("GITHUB_REF_NAME") or subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip()
    require(branch == BRANCH, "Validation is restricted to the 1.0 DEV branch")
    require(not os.environ.get("GITHUB_SHA") or os.environ["GITHUB_SHA"] == source_commit, "Checkout differs from triggering commit")
    project = (ROOT / "project.godot").read_text()
    menu = (ROOT / "scripts/ui/premium_menu.gd").read_text()
    require(re.search(r'^config/version="' + re.escape(PRODUCTION_VERSION) + '"$', project, re.M), "Commit the intended production-candidate version before building")
    require(re.search(r'^const DEV_RELEASE_VERSION: = "' + re.escape(DEV_VERSION) + '"$', menu, re.M), "Commit the intended DEV version before building")
    engine = subprocess.check_output([args.godot, "--version"], text=True).strip()
    require(engine.startswith("4.7.2.stable."), "Matching Godot 4.7.2 is required")
    review.mkdir(parents=True)
    (candidate / "dev").mkdir(parents=True)
    checks = {}
    checked([args.godot, "--headless", "--editor", "--path", str(ROOT), "--import"], review / "import.log", timeout=1800)
    checked(["python3", "tools/check_invariants.py"], review / "invariants.log", "INVARIANTS_OK")
    qa = ["python3", str(ROOT / "tools/qa.py"), "--godot", args.godot, "--jobs", "2", "--timeout", "240"]
    checked(qa + ["--cases", *CASES, "--output", str(review / "source")], review / "source-qa.log", timeout=1800)
    checks["source"] = read_json(review / "source/results.json")
    with tempfile.TemporaryDirectory(prefix="ever-deeper-1-0-production-") as temporary:
        production = Path(temporary)
        for flavor, preset, directory in (("dev", "Web DEV", candidate / "dev"), ("production", "Web Production", production)):
            checked([args.godot, "--headless", "--path", str(ROOT), "--export-release", preset, str(directory / "index.html")], review / ("export-" + flavor + ".log"), timeout=900)
        # Keep the existing DEV diagnostics functional before binding final bytes.
        checked(["python3", "tools/install-render-probe-shell.py", str(candidate / "dev/index.html")], review / "dev-shell.log")
        # The export shell may include auxiliary import records; they are not web files.
        for directory in (candidate / "dev", production):
            for item in directory.iterdir():
                if item.name not in WEB_FILES:
                    require(item.is_file() and not item.is_symlink(), "Unexpected export directory")
                    item.unlink()
        checked(qa + ["--pack", str(candidate / "dev/index.pck"), "--cases", *CASES, "--output", str(review / "dev")], review / "dev-qa.log", timeout=1800)
        checks["dev"] = read_json(review / "dev/results.json")
        for flavor, version, directory in (("dev", DEV_VERSION, candidate / "dev"), ("production", PRODUCTION_VERSION, production)):
            with tempfile.TemporaryDirectory(prefix="ever-deeper-flavor-") as isolated:
                env = dict(os.environ, XDG_DATA_HOME=isolated)
                log = review / (flavor + "-flavor.log")
                checked([args.godot, "--headless", "--path", isolated, "--main-pack", str(directory / "index.pck"), "--", "--qa-build-flavor", "--expected-version=" + version], log, "EVER_DEEPER_BUILD_FLAVOR_QA_OK", env=env, timeout=240)
                require("EVER_DEEPER_VERSION_OK version=" + version in log.read_text(), "Wrong exported version")
                checks[flavor + "-flavor"] = {"passed": True, "version": version, "pack": identity(directory / "index.pck")}
        production_files = {name: identity(production / name) for name in sorted(WEB_FILES)}
    for fixture, marker in (("hero-audio", "HERO_AUDIO_QA "), ("hero-transitions", "HERO_TRANSITIONS_QA passed=true")):
        with tempfile.TemporaryDirectory(prefix="ever-deeper-hero-") as isolated:
            env = dict(os.environ, XDG_DATA_HOME=isolated)
            result_dir = review / fixture
            checked([args.godot, "--headless", "--audio-driver", "Dummy", "--path", isolated, "--main-pack", str(candidate / "dev/index.pck"), "--script", str(ROOT / ("tools/qa-" + fixture + ".gd")), "--", "--output=" + str(result_dir)], review / (fixture + ".log"), marker, timeout=240, env=env)
            checks[fixture] = read_json(result_dir / (fixture + ".json"))
    write_json(candidate / "validation.json", {"passed": all(value["passed"] is True for value in checks.values()), "checks": checks})
    manifest = {
        "schema": 1, "repository": REPOSITORY, "source_branch": BRANCH, "source_commit": source_commit,
        "source_tree": subprocess.check_output(["git", "rev-parse", "HEAD^{tree}"], cwd=ROOT, text=True).strip(),
        "build_run_id": int(os.environ.get("GITHUB_RUN_ID", "0")), "artifact_name": ARTIFACT_NAME,
        "engine": engine, "dev_version": DEV_VERSION, "production_version": PRODUCTION_VERSION,
        "qa_cases": CASES, "dev_files": {name: identity(candidate / "dev" / name) for name in sorted(WEB_FILES)},
        "production_flavor_files": production_files, "validation": identity(candidate / "validation.json"),
    }
    write_json(candidate / "manifest.json", manifest)
    verify_candidate(candidate)
    write_json(review / "candidate-identity.json", {"manifest": identity(candidate / "manifest.json"), "manifest_contents": manifest})
    print("ONE_POINT_ZERO_CANDIDATE_READY source=" + source_commit + " dev=" + DEV_VERSION + " live_unpublished=true")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    builder = sub.add_parser("build")
    builder.add_argument("--godot", required=True)
    builder.add_argument("--candidate", type=Path, required=True)
    builder.add_argument("--review-output", type=Path, required=True)
    verifier = sub.add_parser("verify-candidate")
    verifier.add_argument("candidate", type=Path)
    args = parser.parse_args()
    if args.command == "build":
        build(args)
    else:
        verify_candidate(args.candidate)
        print("ONE_POINT_ZERO_CANDIDATE_IDENTITY_OK")
