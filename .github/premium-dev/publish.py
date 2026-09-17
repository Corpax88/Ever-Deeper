"""Stage the exact reviewed premium DEV artifact; preserve and verify all LIVE bytes."""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import os
from pathlib import Path
import subprocess
import time
import urllib.request

import contracts as c

PUBLIC_URL = "https://corpax88.github.io/Ever-Deeper/"


def api(endpoint):
    import json
    return json.loads(subprocess.check_output(["gh", "api", "repos/" + c.REPOSITORY + "/" + endpoint], text=True))


def download_artifact(artifact, target):
    # gh handles authenticated redirects without forwarding our token ourselves.
    with target.open("wb") as output:
        subprocess.run(["gh", "api", "repos/" + c.REPOSITORY + "/actions/artifacts/" + str(artifact["id"]) + "/zip"], stdout=output, check=True)
    c.require(c.identity(target) == artifact["zip"], "Downloaded artifact differs from the reviewed ZIP")


def fetch_public(side, name, target, expected):
    c.require(side in ("live", "dev") and name in c.WEB_FILES, "Invalid public file request")
    target.parent.mkdir(parents=True, exist_ok=True)
    url = PUBLIC_URL + ("dev/" if side == "dev" else "") + name
    request = urllib.request.Request(url, headers={"Cache-Control": "no-cache", "Pragma": "no-cache"})
    with urllib.request.urlopen(request, timeout=120) as response, target.open("wb") as output:
        received = 0
        while block := response.read(1024 * 1024):
            received += len(block)
            c.require(received <= expected["size"], "Public file exceeds pinned size: " + side + "/" + name)
            output.write(block)
    c.require(c.identity(target) == expected, "Public file differs from pinned bytes: " + side + "/" + name)


def stage(candidate, complete, site, backup, pin, base):
    files = c.verify_bundle(candidate, complete, pin)
    c.require(not site.exists() and not backup.exists(), "Staging/rollback directory already exists")
    tasks = [(side, name, backup / side / name, info) for side, rows in base["files"].items() for name, info in rows.items()]
    c.require(set(base["files"]) == {"live", "dev"}, "Both rollback sides are required")
    for rows in base["files"].values():
        c.valid_files(rows, c.WEB_FILES)
    # All 18 old files must be verified before even creating the site directory.
    with ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(lambda task: fetch_public(*task), tasks))
    for side in ("live", "dev"):
        c.check_files(backup / side, base["files"][side])
    c.write_json(backup / "baseline-receipt.json", base)
    site.mkdir(parents=True)
    (site / "dev").mkdir()
    for name in c.WEB_FILES:
        (site / name).write_bytes((backup / "live" / name).read_bytes())
        (site / "dev" / name).write_bytes((candidate / name).read_bytes())
    (site / ".nojekyll").write_text("")
    c.require({path.name for path in site.iterdir()} == c.WEB_FILES | {"dev", ".nojekyll"}, "Unexpected Pages root")
    for name, info in base["files"]["live"].items():
        c.require(c.identity(site / name) == info, "LIVE staging bytes changed: " + name)
    c.check_files(site / "dev", files)
    print("PREMIUM_DEV_STAGED live_files_preserved=9 dev_files=9 rollback_files=18")
    return files


def prepare(workspace):
    pin = c.pinned()
    accepted = c.reviewed(pin)  # Fail before network or staging when review is pending.
    base = c.baseline()
    c.require(not workspace.exists(), "Publisher workspace already exists")
    run = api("actions/runs/" + str(c.RUN))
    jobs = api("actions/runs/" + str(c.RUN) + "/attempts/" + str(c.ATTEMPT) + "/jobs?per_page=100")
    artifacts = {kind: api("actions/artifacts/" + str(pin[kind]["id"])) for kind in ("candidate", "complete")}
    c.check_run(pin, run, jobs, artifacts)
    workspace.mkdir(parents=True)
    for name, value in (("reviewed", accepted), ("package-pin", pin), ("baseline", base), ("run", run), ("jobs", jobs), ("artifacts", artifacts)):
        c.write_json(workspace / (name + ".json"), value)
    for kind in ("candidate", "complete"):
        archive = workspace / (kind + ".zip")
        download_artifact(pin[kind], archive)
        c.extract_exact(archive, workspace / kind, pin[kind])
    files = stage(workspace / "candidate", workspace / "complete", workspace / "site", workspace / "rollback", pin, base)
    c.write_json(workspace / "staging.json", {
        "schema": 1, "dev_only": True, "source_commit": c.SOURCE, "qa_run_id": c.RUN,
        "candidate_artifact_id": pin["candidate"]["id"], "complete_artifact_id": pin["complete"]["id"],
        "review_sha256": c.identity(c.HERE / "review.json")["sha256"],
        "files": {"dev": files, "live": base["files"]["live"]},
        "rollback_files": base["files"], "rollback_verified": True,
        "final_one_point_zero_approved": False, "physical_iphone_verified": False,
    })


def verify(output):
    pin = c.pinned()
    accepted = c.reviewed(pin)
    base = c.baseline()
    expected = {"dev": {name: pin["candidate"]["members"][name] for name in c.WEB_FILES}, "live": base["files"]["live"]}
    c.require(not output.exists(), "Verification directory already exists")
    output.mkdir(parents=True)
    report = {
        "schema": 1, "dev_only": True, "passed": False, "verified_files": 0,
        "source_commit": c.SOURCE, "qa_run_id": c.RUN,
        "candidate_artifact_id": pin["candidate"]["id"], "complete_artifact_id": pin["complete"]["id"],
        "candidate_zip_sha256": pin["candidate"]["zip"]["sha256"],
        "complete_zip_sha256": pin["complete"]["zip"]["sha256"],
        "review_sha256": c.identity(c.HERE / "review.json")["sha256"],
        "baseline_receipt_sha256": c.read_json(c.HERE / "baseline.json")["source_receipt_sha256"],
        "publication_source_commit": os.environ.get("GITHUB_SHA"),
        "publication_run_id": os.environ.get("GITHUB_RUN_ID"),
        "rollback_artifact_id": os.environ.get("ROLLBACK_ARTIFACT_ID"),
        "displayed_dev_version": "1.0.0-dev.11", "live_version": "0.46.9",
        "final_one_point_zero_approved": False, "physical_iphone_verified": False,
        "limits": accepted["limitations"], "files": expected, "errors": [],
    }
    receipt = output / "publication-receipt.json"
    c.write_json(receipt, report)  # A failed/interrupted verification never leaves a green receipt.
    pending = [(side, name, output / side / name, info) for side, rows in expected.items() for name, info in rows.items()]

    def matches(task):
        try:
            fetch_public(*task)
            return None
        except Exception as error:
            return task[0] + "/" + task[1] + ": " + str(error)

    for attempt in range(10):
        with ThreadPoolExecutor(max_workers=3) as pool:
            errors = list(pool.map(matches, pending))
        pending = [task for task, error in zip(pending, errors) if error is not None]
        report["errors"] = [error for error in errors if error is not None]
        report["verified_files"] = 18 - len(pending)
        report["verification_attempts"] = attempt + 1
        c.write_json(receipt, report)
        if not pending:
            for side in ("live", "dev"):
                c.check_files(output / side, expected[side])
            report.update(passed=True, live_files_unchanged=9, dev_files=9)
            c.write_json(receipt, report)
            print("PREMIUM_DEV_PUBLIC_VERIFY_OK dev_files=9 live_files_unchanged=9")
            return
        if attempt < 9:
            time.sleep(10)
    raise RuntimeError("Public bytes did not match; see failed publication-receipt.json")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("check-review")
    commands.add_parser("prepare").add_argument("workspace", type=Path)
    commands.add_parser("verify").add_argument("output", type=Path)
    args = parser.parse_args()
    if args.command == "prepare":
        prepare(args.workspace.resolve())
    elif args.command == "verify":
        verify(args.output.resolve())
    else:
        c.reviewed(c.pinned())
        c.baseline()
        print("PREMIUM_DEV_REVIEW_READY")
