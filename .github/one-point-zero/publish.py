"""Stage only the exact reviewed DEV artifact, preserving all current LIVE bytes.

This script never builds or deploys. GitHub Pages receives its verified staging
directory only in the separately invoked publisher workflow.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path, PurePosixPath
import shutil
import stat
import subprocess
import time
import urllib.request
import zipfile

from contracts import (ARTIFACT_NAME, BRANCH, DEV_VERSION, HERE, REPOSITORY, REQUIRED_JOBS,
                       WEB_FILES, WORKFLOW, check_files, identity, read_json, require,
                       valid_sha, verify_candidate, write_json)

BASE = read_json(HERE / "baseline.json")
PUBLIC_URL = "https://corpax88.github.io/Ever-Deeper/"


def reviewed():
    data = read_json(HERE / "review.json")
    require(data["schema"] == 1 and data["dev_only"] is True and data["live_publication_authorized"] is False, "Only DEV publication is authorized")
    require(data["dev_version"] == DEV_VERSION, "Wrong reviewed DEV version")
    flags = ("package_checks_passed", "visual_reviewed", "mobile_touch_reviewed", "web_audio_reviewed", "full_progression_reviewed", "critic_reviewed")
    require(all(data.get(flag) is True for flag in flags), "Candidate review is incomplete; nothing will be staged")
    require(data.get("dev_test_ready") is True and data.get("final_one_point_zero_approved") is False, "This publisher stages DEV tests, not final 1.0 acceptance")
    require(isinstance(data["critic_score"], (float, int)) and not isinstance(data["critic_score"], bool) and 1 <= data["critic_score"] <= 10, "Record the provisional critic score honestly")
    require(type(data["critical_bug_count"]) is int and data["critical_bug_count"] == 0, "Critical bugs remain or have not been evaluated")
    require(isinstance(data["physical_iphone_verified"], bool), "Record the physical iPhone test status explicitly")
    require(valid_sha(data["source_commit"], 40), "Reviewed source commit is missing")
    for key in ("candidate_zip_sha256", "candidate_manifest_sha256"):
        require(valid_sha(data[key]), "Reviewed identity is missing: " + key)
    for key in ("qa_run_id", "candidate_artifact_id"):
        require(type(data[key]) is int and data[key] > 0, "Reviewed identifier is missing: " + key)
    require(set(data["files"]) == WEB_FILES, "Reviewed DEV manifest is incomplete")
    require(bool(data["reviewed_at"]), "Review date is missing")
    return data


def api(endpoint):
    return json.loads(subprocess.check_output(["gh", "api", "repos/" + REPOSITORY + "/" + endpoint], text=True))


def check_run(accepted, run, jobs, artifact):
    require(run["id"] == accepted["qa_run_id"] and run["head_sha"] == accepted["source_commit"], "Wrong validation run or source")
    require(run["head_branch"] == BRANCH and run["path"].split("@", 1)[0] == WORKFLOW, "Wrong validation workflow/branch")
    require(run["status"] == "completed" and run["conclusion"] == "success", "Validation run did not succeed")
    require(jobs["total_count"] <= 100, "Unexpected paginated jobs; review the workflow")
    by_name = {job["name"]: job for job in jobs["jobs"]}
    require(REQUIRED_JOBS <= by_name.keys(), "Required validation jobs are missing")
    require(all(by_name[name]["conclusion"] == "success" for name in REQUIRED_JOBS), "Required validation jobs did not pass")
    require(artifact["id"] == accepted["candidate_artifact_id"] and artifact["name"] == ARTIFACT_NAME, "Wrong candidate artifact")
    require(artifact["expired"] is False, "Reviewed artifact expired; rebuilding is not permitted by this publisher")
    require(artifact["workflow_run"]["id"] == run["id"] and artifact["workflow_run"]["head_sha"] == run["head_sha"], "Artifact belongs to a different source/run")


def extract_candidate(archive, destination):
    allowed = {"manifest.json", "validation.json"} | {"dev/" + name for name in WEB_FILES}
    require(not destination.exists(), "Candidate extraction directory already exists")
    with zipfile.ZipFile(archive) as source:
        infos = [info for info in source.infolist() if not info.is_dir()]
        require(len(infos) == len(allowed) and {info.filename for info in infos} == allowed, "Unexpected or duplicate artifact members")
        for info in source.infolist():
            path = PurePosixPath(info.filename)
            require(not path.is_absolute() and ".." not in path.parts and "\\" not in info.filename, "Unsafe artifact member")
            require(not stat.S_ISLNK(info.external_attr >> 16), "Artifact symlinks are forbidden")
            if info.is_dir():
                require(info.filename == "dev/", "Unexpected artifact directory")
        require(sum(info.file_size for info in infos) < 1024 * 1024 * 1024, "Candidate exceeds expected size bound")
        destination.mkdir(parents=True)
        for info in infos:
            target = destination / info.filename
            target.parent.mkdir(parents=True, exist_ok=True)
            with source.open(info) as contents, target.open("wb") as output:
                shutil.copyfileobj(contents, output)


def fetch_public(side, name, target, expected):
    target.parent.mkdir(parents=True, exist_ok=True)
    url = PUBLIC_URL + ("dev/" if side == "dev" else "") + name
    request = urllib.request.Request(url, headers={"Cache-Control": "no-cache"})
    with urllib.request.urlopen(request, timeout=120) as response, target.open("wb") as output:
        received = 0
        while block := response.read(1024 * 1024):
            received += len(block)
            require(received <= expected["size"], "Public baseline size changed: " + side + "/" + name)
            output.write(block)
    require(identity(target) == expected, "Public baseline changed; stop before staging: " + side + "/" + name)


def stage(candidate, site, backup, accepted):
    manifest = verify_candidate(candidate)
    require(manifest["source_commit"] == accepted["source_commit"] and manifest["build_run_id"] == accepted["qa_run_id"], "Candidate source/run mismatch")
    require(identity(candidate / "manifest.json")["sha256"] == accepted["candidate_manifest_sha256"], "Candidate manifest is not the reviewed manifest")
    require(manifest["dev_files"] == accepted["files"], "Candidate differs from reviewed DEV files")
    require(not site.exists() and not backup.exists(), "Staging/rollback destination already exists")
    tasks = [(side, name, backup / side / name, info) for side, files in BASE["files"].items() for name, info in files.items()]
    require(set(BASE["files"]) == {"dev", "live"} and all(set(files) == WEB_FILES for files in BASE["files"].values()), "Pinned publication baseline is incomplete")
    # Every existing DEV and LIVE file must match before a site directory exists.
    with ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(lambda task: fetch_public(*task), tasks))
    for side in ("live", "dev"):
        check_files(backup / side, BASE["files"][side])
    shutil.copytree(backup / "live", site)
    shutil.copytree(candidate / "dev", site / "dev")
    (site / ".nojekyll").write_text("")
    require({item.name for item in site.iterdir()} == WEB_FILES | {"dev", ".nojekyll"}, "Unexpected Pages root")
    for name, info in BASE["files"]["live"].items():
        require(identity(site / name) == info, "LIVE staging bytes changed: " + name)
    check_files(site / "dev", accepted["files"])
    print("ONE_POINT_ZERO_DEV_STAGED live_files_preserved=9 dev_files=9 production_candidate_included=false")


def prepare(workspace):
    accepted = reviewed()  # Fail before network or filesystem mutations.
    require(not workspace.exists(), "Publisher workspace already exists")
    run = api("actions/runs/" + str(accepted["qa_run_id"]))
    jobs = api("actions/runs/" + str(accepted["qa_run_id"]) + "/jobs?per_page=100")
    artifact = api("actions/artifacts/" + str(accepted["candidate_artifact_id"]))
    check_run(accepted, run, jobs, artifact)
    workspace.mkdir(parents=True)
    write_json(workspace / "reviewed.json", accepted)
    write_json(workspace / "run.json", run)
    write_json(workspace / "jobs.json", jobs)
    write_json(workspace / "artifact.json", artifact)
    archive = workspace / "candidate.zip"
    # gh handles authenticated API redirects without forwarding our token to a
    # foreign storage host. Tokens are inherited from GH_TOKEN, never printed.
    with archive.open("wb") as output:
        subprocess.run(["gh", "api", "repos/" + REPOSITORY + "/actions/artifacts/" + str(artifact["id"]) + "/zip"], stdout=output, check=True)
    require(identity(archive)["sha256"] == accepted["candidate_zip_sha256"], "Artifact ZIP is not the reviewed ZIP")
    extract_candidate(archive, workspace / "candidate")
    stage(workspace / "candidate", workspace / "site", workspace / "rollback", accepted)
    write_json(workspace / "staging.json", {"dev_only": True, "reviewed_artifact": artifact["id"], "source_commit": accepted["source_commit"], "files": {"dev": accepted["files"], "live": BASE["files"]["live"]}})


def verify(output):
    accepted = reviewed()
    expected = {"dev": accepted["files"], "live": BASE["files"]["live"]}
    require(not output.exists(), "Verification directory already exists")
    output.mkdir(parents=True)
    pending = [(side, name, output / side / name, info) for side, files in expected.items() for name, info in files.items()]
    def matches(task):
        try:
            fetch_public(*task)
            return True
        except Exception:
            return False
    for attempt in range(10):
        with ThreadPoolExecutor(max_workers=3) as pool:
            passed = list(pool.map(matches, pending))
        pending = [task for task, good in zip(pending, passed) if not good]
        if not pending:
            write_json(output / "publication-receipt.json", {"dev_only": True, "dev_version": DEV_VERSION, "live_version": BASE["live_version"], "artifact_id": accepted["candidate_artifact_id"], "source_commit": accepted["source_commit"], "verified_files": 18, "files": expected})
            print("ONE_POINT_ZERO_PUBLIC_VERIFY_OK dev_files=9 live_files_unchanged=9")
            return
        if attempt < 9:
            time.sleep(10)
    raise RuntimeError("Public files did not match: " + str([(side, name) for side, name, _, _ in pending]))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    prepare_parser = sub.add_parser("prepare")
    prepare_parser.add_argument("workspace", type=Path)
    verify_parser = sub.add_parser("verify")
    verify_parser.add_argument("output", type=Path)
    sub.add_parser("check-review")
    args = parser.parse_args()
    if args.command == "prepare":
        prepare(args.workspace.resolve())
    elif args.command == "verify":
        verify(args.output.resolve())
    else:
        reviewed()
        print("ONE_POINT_ZERO_REVIEW_COMPLETE")
