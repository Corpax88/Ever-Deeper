"""Publish exact reviewed trial bytes at dev/worn; preserve DEV13 and LIVE."""
from concurrent.futures import ThreadPoolExecutor
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import time
import urllib.request

HERE = Path(__file__).resolve().parent
PUBLIC = "https://corpax88.github.io/Ever-Deeper/"
FILES = {"index.html", "index.pck", "index.js", "index.wasm", "index.png", "index.icon.png", "index.apple-touch-icon.png", "index.audio.worklet.js", "index.audio.position.worklet.js"}


def require(value, message):
    if not value:
        raise RuntimeError(message)


def read(name):
    return json.loads((HERE / name).read_text())


def identity(path):
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return {"size": path.stat().st_size, "sha256": digest.hexdigest()}


def reviewed():
    base, bundle, review = read("baseline.json"), read("bundle.json"), read("review.json")
    require(base["passed"] is True and base["source_commit"] == "5ca6f0f77a1f87eaead777613062208159325068", "Wrong DEV13 baseline")
    require(set(base["files"]) == {"dev", "live"}, "Both existing games must be retained")
    require(all(set(rows) == FILES for rows in base["files"].values()), "Incomplete baseline")
    require(bundle["destination"] == "dev/worn" and set(bundle["files"]) == FILES, "Wrong trial scope")
    require(review["dev_trial_only"] is True and review["ordinary_game_adopted"] is False and review["live_authorized"] is False, "Only additive trial publication is authorized")
    require(all(review.get(key) is True for key in ["independent_visual_accepted", "exported_controls_passed", "publisher_reviewed"]), "Trial review is incomplete")
    require(review["bundle_sha256"] == identity(HERE / "bundle.json")["sha256"], "Unreviewed bundle")
    require(review["baseline_sha256"] == identity(HERE / "baseline.json")["sha256"], "Baseline binding changed")
    require(review["source_commit"] == bundle["source_commit"], "Wrong reviewed source")
    proof = read("evidence/browser-report.json")
    require(review["browser_report_sha256"] == identity(HERE / "evidence/browser-report.json")["sha256"], "Browser evidence changed")
    require(proof["passed"] is True and proof["physical_device"] is False, "Invalid browser evidence")
    require(proof["pck_sha256"] == bundle["files"]["index.pck"]["sha256"], "Browser tested another package")
    require(proof["files"] == bundle["files"], "Browser did not test these exact nine served files")
    require({row["name"] for row in proof["checks"]} >= {"01-ready", "02-held-mining", "03-walk-exit", "04-reset", "05-touch-mining", "06-touch-walk"}, "Missing interaction evidence")
    require(all(row["state"]["failed"] is False for row in proof["checks"]), "Motion failure in reviewed evidence")
    require(bundle["base_pck"] == base["files"]["dev"]["index.pck"], "Delta has a different base")
    for name in FILES - {"index.html", "index.pck"}:
        require(bundle["files"][name] == base["files"]["dev"][name], "Unexpected runtime file change: " + name)
    return base, bundle, review


def fetch(relative, target, expected):
    target.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(PUBLIC + relative, headers={"Cache-Control": "no-cache", "Pragma": "no-cache"})
    digest = hashlib.sha256()
    total = 0
    with urllib.request.urlopen(request, timeout=120) as response, target.open("wb") as output:
        while block := response.read(1024 * 1024):
            total += len(block)
            require(total <= expected["size"], "Public bytes exceed pinned size: " + relative)
            digest.update(block)
            output.write(block)
    require({"size": total, "sha256": digest.hexdigest()} == expected, "Public bytes changed: " + relative)


def prepare(workspace):
    base, bundle, review = reviewed()
    require(not workspace.exists(), "Use a fresh publication workspace")
    workspace.mkdir(parents=True)
    backup, site = workspace / "rollback", workspace / "site"
    tasks = [(('dev/' if side == 'dev' else '') + name, backup / side / name, info)
             for side, rows in base["files"].items() for name, info in rows.items()]
    with ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(lambda args: fetch(*args), tasks))
    # Create no staging tree until every existing file has been verified.
    delta = workspace / "trial.xdelta"
    require(bundle["parts"] and len(bundle["parts"]) < 200, "Invalid delta parts")
    with delta.open("wb") as output:
        for index, part in enumerate(bundle["parts"]):
            require(part["name"] == f"payload-{index:03d}.bin", "Noncanonical or unordered delta part")
            source = HERE / "payload" / part["name"]
            require(identity(source) == {key: part[key] for key in ("size", "sha256")}, "Delta part changed")
            output.write(source.read_bytes())
    require(identity(delta) == bundle["delta"], "Reassembled delta differs")
    candidate = workspace / "candidate"
    candidate.mkdir()
    subprocess.run(["xdelta3", "-d", "-s", str(backup / "dev/index.pck"), str(delta), str(candidate / "index.pck")], check=True)
    shutil.copy2(HERE / "index.html", candidate / "index.html")
    for name in FILES - {"index.html", "index.pck"}:
        shutil.copy2(backup / "dev" / name, candidate / name)
    require(all(identity(candidate / name) == info for name, info in bundle["files"].items()), "Candidate differs from exact reviewed package")
    shutil.copytree(backup / "live", site)
    shutil.copytree(backup / "dev", site / "dev")
    shutil.copytree(candidate, site / "dev/worn")
    (site / ".nojekyll").write_text("")
    actual = {str(p.relative_to(site)) for p in site.rglob("*") if p.is_file()}
    expected = FILES | {"dev/" + p for p in FILES} | {"dev/worn/" + p for p in FILES} | {".nojekyll"}
    require(actual == expected, "Unexpected public file set")
    for side, rows in base["files"].items():
        for name, info in rows.items():
            require(identity(site / ("dev" if side == "dev" else "") / name) == info, "Existing game changed during staging")
    shutil.copy2(HERE / "baseline.json", backup / "baseline-receipt.json")
    (workspace / "staging.json").write_text(json.dumps({"preserved_files":18,"trial_files":9,"source_commit":bundle["source_commit"],"bundle_sha256":review["bundle_sha256"],"site_bytes":sum(p.stat().st_size for p in site.rglob("*") if p.is_file())},indent=2))
    print("WORN_TRIAL_STAGED existing_files_unchanged=18 trial_files=9")


def verify(output):
    base, bundle, review = reviewed()
    require(not output.exists(), "Use a fresh verification directory")
    output.mkdir(parents=True)
    expected = {**base["files"]["live"], **{"dev/" + k: v for k, v in base["files"]["dev"].items()}, **{"dev/worn/" + k: v for k, v in bundle["files"].items()}}
    pending = list(expected)
    def check(name):
        try:
            fetch(name, output / name, expected[name])
            return True
        except Exception:
            return False
    for attempt in range(10):
        with ThreadPoolExecutor(max_workers=3) as pool:
            passed = list(pool.map(check, pending))
        pending = [name for name, ok in zip(pending, passed) if not ok]
        if not pending:
            (output / "publication-receipt.json").write_text(json.dumps({"passed":True,"dev_trial_only":True,"existing_files_unchanged":18,"trial_files":9,"source_commit":bundle["source_commit"],"bundle_sha256":review["bundle_sha256"],"files":expected,"physical_iphone_verified":False},indent=2))
            print("WORN_TRIAL_PUBLIC_VERIFY_OK preserved=18 trial=9")
            return
        if attempt < 9:
            time.sleep(10)
    raise RuntimeError("Published bytes differ: " + str(pending))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["prepare", "verify", "check-review"])
    parser.add_argument("output", type=Path, nargs="?")
    args = parser.parse_args()
    if args.command == "check-review":
        reviewed()
    else:
        require(args.output is not None, "Output directory required")
        (prepare if args.command == "prepare" else verify)(args.output.resolve())
