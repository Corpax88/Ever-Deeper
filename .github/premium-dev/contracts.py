"""Contracts for one immutable premium DEV playtest; no publication operations."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import stat
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
REPOSITORY = "Corpax88/Ever-Deeper"
SOURCE = "e76a2b90a8a6da4d2673689ce2eeb646e5c2303b"
BRANCH = "codex/premium-polish-recovery-20260915"
WORKFLOW = ".github/workflows/premium-web-review.yml"
RUN = 35099632983
ATTEMPT = 1
WEB_FILES = frozenset((
    "index.html", "index.js", "index.pck", "index.wasm", "index.png",
    "index.icon.png", "index.apple-touch-icon.png",
    "index.audio.position.worklet.js", "index.audio.worklet.js",
))
SECTIONS = ("pause", "wardrobe", "light", "lists", "starforge", "workshops")
BROWSER_SUITES = ("visual-forge", "visual-workshops", "gameplay", *("touch-" + s for s in SECTIONS))
UNITS = {"build", "commerce-residency", *BROWSER_SUITES}
JOBS = {"build", "commerce-residency", "Complete premium review", *("browser (" + s + ")" for s in BROWSER_SUITES)}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def read_json(path):
    return json.loads(Path(path).read_text())


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n")


def identity(path):
    path = Path(path)
    require(path.is_file() and not path.is_symlink(), "Expected a regular file: " + str(path))
    with path.open("rb") as source:
        digest = hashlib.file_digest(source, "sha256").hexdigest()
    return {"size": path.stat().st_size, "sha256": digest}


def valid_files(files, names):
    require(isinstance(files, dict) and set(files) == set(names), "Unexpected file manifest")
    for name, info in files.items():
        require(name == Path(name).name, "Unsafe manifest filename")
        require(type(info.get("size")) is int and info["size"] > 0, "Invalid file size: " + name)
        require(isinstance(info.get("sha256"), str) and re.fullmatch(r"[a-f0-9]{64}", info["sha256"]), "Invalid file hash: " + name)


def pinned():
    data = read_json(HERE / "package.json")
    require(data["schema"] == 1 and data["source_commit"] == SOURCE and data["qa_run_id"] == RUN and data["qa_run_attempt"] == ATTEMPT, "Unexpected reviewed source/run")
    require(data["candidate"]["id"] == 10448000795 and data["candidate"]["zip"]["sha256"] == "9e70a36076a6f856a2bca94c284f0edac3b579d18197f033cd5091d2ebfe22a3", "Candidate artifact pin changed")
    require(data["complete"]["id"] == 10448008790 and data["complete"]["zip"]["sha256"] == "4acbc9dcedb5ac2a64fdd8f914f00f404df92b52eb92c854894d21a83625c81c", "Complete artifact pin changed")
    require(data["candidate"]["name"] == "premium-web-candidate-" + SOURCE and data["complete"]["name"] == "premium-web-review-complete-" + SOURCE, "Artifact names changed")
    valid_files(data["candidate"]["members"], WEB_FILES | {"manifest.json", "artifact-identity.json"})
    valid_files(data["complete"]["members"], {"complete-review.json"})
    return data


def baseline():
    pin = read_json(HERE / "baseline.json")
    require(pin["source_receipt"] == ".github/premium-dev/baseline-c8906f1-receipt.json", "Wrong baseline receipt")
    require(pin["source_receipt_sha256"] == "e66a038406fa7b01ba1aaa4cf63741ef8f259978c86a64e7d980369f35cf3301", "Baseline pin changed")
    path = ROOT / pin["source_receipt"]
    require(identity(path)["sha256"] == pin["source_receipt_sha256"], "Baseline receipt bytes changed")
    data = read_json(path)
    require(data["dev_only"] is True and data["verified_files"] == 18 and data["candidate_artifact_id"] == 10442929350 and data["passed"] is True, "Invalid DEV8 baseline receipt")
    require(data["displayed_dev_version"] == "1.0.0-dev.8" and data["live_version"] == "0.46.9", "Unexpected public baseline version")
    require(set(data["files"]) == {"dev", "live"}, "Incomplete rollback baseline")
    for files in data["files"].values():
        valid_files(files, WEB_FILES)
    return data


def reviewed(pin):
    data = read_json(HERE / "review.json")
    require(data["schema"] == 1 and data["dev_only"] is True, "Only this DEV playtest can be published")
    require(data["live_publication_authorized"] is False and data["final_one_point_zero_approved"] is False and data["physical_iphone_verified"] is False, "This record cannot approve LIVE, final 1.0, or a physical iPhone")
    require(data["source_commit"] == pin["source_commit"] and data["qa_run_id"] == pin["qa_run_id"], "Review belongs to a different source/run")
    require(data["candidate_artifact_id"] == pin["candidate"]["id"] and data["complete_artifact_id"] == pin["complete"]["id"], "Review belongs to different artifacts")
    require(data.get("dev_publication_authorized") is True, "Record the current DEV publication authorization before staging")
    authorization = data.get("authorization_record", {})
    require(isinstance(authorization, dict) and all(isinstance(authorization.get(k), str) and authorization[k].strip() for k in ("requested_by", "request", "recorded_at")), "DEV authorization record is incomplete")
    visual = data.get("visual_readiness", {})
    require(visual.get("status") == "approved_for_dev_playtest", "Actual visual readiness is unapproved; nothing will be staged")
    require(all(isinstance(visual.get(k), str) and visual[k].strip() for k in ("reviewer", "reviewed_at", "scope", "findings")), "Visual readiness record is incomplete")
    require(isinstance(visual.get("evidence"), list) and visual["evidence"] and all(isinstance(x, str) and x.strip() for x in visual["evidence"]), "Actual visual evidence references are missing")
    require(visual.get("blocking_defects") == [], "Visual blockers remain or have not been evaluated")
    require(isinstance(data.get("limitations"), list) and data["limitations"], "Record the bounded DEV limitations")
    return data


def check_run(pin, run, jobs, artifacts):
    require(run["id"] == RUN and run["head_sha"] == SOURCE and run["run_attempt"] == ATTEMPT, "Wrong QA source/run/attempt")
    require(run["head_branch"] == BRANCH and run["path"].split("@", 1)[0] == WORKFLOW, "Wrong QA workflow/branch")
    require(run["repository"]["full_name"] == REPOSITORY, "Wrong QA repository")
    require(run["status"] == "completed" and run["conclusion"] == "success", "QA run did not complete successfully")
    rows = jobs["jobs"]
    require(jobs["total_count"] == len(rows) == len(JOBS) and {row["name"] for row in rows} == JOBS, "Expected all 12 exact QA jobs without duplicates")
    require(all(row["status"] == "completed" and row["conclusion"] == "success" and row["run_id"] == RUN and row["head_sha"] == SOURCE for row in rows), "A required QA job failed, was cancelled, or belongs to another source/run")
    require(set(artifacts) == {"candidate", "complete"}, "Required artifact metadata missing")
    for kind, artifact in artifacts.items():
        expected = pin[kind]
        require(artifact["id"] == expected["id"] and artifact["name"] == expected["name"] and artifact["expired"] is False, "Wrong or expired " + kind + " artifact")
        require(artifact["workflow_run"]["id"] == RUN and artifact["workflow_run"]["head_sha"] == SOURCE, "Artifact source/run mismatch: " + kind)


def check_files(directory, expected):
    require(directory.is_dir() and not directory.is_symlink(), "Missing regular directory: " + str(directory))
    require({path.name for path in directory.iterdir()} == set(expected), "Unexpected directory contents: " + str(directory))
    for name, info in expected.items():
        require(identity(directory / name) == info, "File identity mismatch: " + str(directory / name))


def extract_exact(archive, destination, artifact):
    require(identity(archive) == artifact["zip"], "Downloaded artifact ZIP identity mismatch")
    require(not destination.exists(), "Extraction directory already exists")
    expected = artifact["members"]
    with zipfile.ZipFile(archive) as source:
        infos = source.infolist()
        require(len(infos) == len(expected) and {info.filename for info in infos} == set(expected), "Unexpected, duplicate or missing ZIP members")
        require(sum(info.file_size for info in infos) < 1024 * 1024 * 1024, "Artifact exceeds size bound")
        for info in infos:
            require(not info.is_dir() and info.filename == Path(info.filename).name and "\\" not in info.filename, "Unsafe ZIP member")
            mode = stat.S_IFMT(info.external_attr >> 16)
            require(mode in (0, stat.S_IFREG), "ZIP member is not a regular file")
            require(not info.flag_bits & 1, "Encrypted ZIP member")
            require(info.file_size == expected[info.filename]["size"], "ZIP member size mismatch")
        destination.mkdir(parents=True)
        for info in infos:
            with source.open(info) as contents, (destination / info.filename).open("wb") as output:
                while block := contents.read(1024 * 1024):
                    output.write(block)
    check_files(destination, expected)


def verify_bundle(candidate, complete, pin):
    check_files(candidate, pin["candidate"]["members"])
    check_files(complete, pin["complete"]["members"])
    files = {name: pin["candidate"]["members"][name] for name in WEB_FILES}
    require(read_json(candidate / "manifest.json") == files, "Candidate manifest mismatch")
    data = read_json(candidate / "artifact-identity.json")
    require(data["schema"] == 1 and data["sourceSha"] == SOURCE and data["runId"] == str(RUN) and data["runAttempt"] == str(ATTEMPT), "Candidate source/run/attempt identity mismatch")
    require(data["physicalIphone"] is False and data["devFiles"] == files, "Candidate evidence scope or DEV manifest mismatch")
    valid_files(data["productionFiles"], WEB_FILES)
    require(all(data.get(key) == value for key, value in pin["source_hashes"].items()), "Candidate review source hashes mismatch")
    report = read_json(complete / "complete-review.json")
    require(report["schema"] == 1 and report["sourceSha"] == SOURCE and report["reviewOnly"] is True and report["physicalIphone"] is False, "Complete report identity or scope mismatch")
    require(report["passed"] is True and report["complete"] is True and report["errors"] == [], "Complete review did not pass")
    require(report["pckSha256"] == files["index.pck"]["sha256"] and report["htmlSha256"] == files["index.html"]["sha256"], "Complete review belongs to different package bytes")
    units = report["units"]
    require(set(units) == UNITS and all(row["passed"] is True for row in units.values()), "Incomplete or failed review units")
    require(units["build"] == {"passed": True, "coreCases": 15, "devFlavorCases": 1, "productionFlavorCases": 1}, "Core/flavor review differs")
    for name, limits, count in (("visual-forge", [1, 14], 14), ("visual-workshops", [15, 19], 5)):
        require(units[name]["visualCases"] == limits and units[name]["pngCount"] == count, "Incomplete visual coverage: " + name)
    for name in ("gameplay", "commerce-residency", *("touch-" + section for section in SECTIONS)):
        require(type(units[name]["checks"]) is int and units[name]["checks"] > 0 and type(units[name]["pngCount"]) is int and units[name]["pngCount"] > 0, "Missing actual checks/captures: " + name)
    require(units["gameplay"]["touchSection"] is None, "Ordinary gameplay was replaced by a touch section")
    for section in SECTIONS:
        require(units["touch-" + section]["touchSection"] == section, "Wrong touch section")
    return files
