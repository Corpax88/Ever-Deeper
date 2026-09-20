"""Recover an exact unreviewed candidate for QA only; never deploy."""
import argparse
import json
import shutil
import subprocess
from pathlib import Path
from publish import HERE, FILES, fetch, identity, require

def assemble(output):
    require(not output.exists(), "Use a fresh QA directory")
    bundle = json.loads((HERE / "bundle.json").read_text())
    base = json.loads((HERE / "baseline.json").read_text())
    require(bundle["destination"] == "dev/worn", "Wrong scope")
    require(set(bundle["files"]) == FILES, "Incomplete candidate")
    require(bundle["base_pck"] == base["files"]["dev"]["index.pck"], "Wrong delta base")
    output.mkdir(parents=True)
    base_pck = output / "base.pck"
    fetch("dev/index.pck", base_pck, bundle["base_pck"])
    delta = output / "candidate.xdelta"
    require(0 < len(bundle["parts"]) < 200, "Invalid delta parts")
    with delta.open("wb") as target:
        for index, part in enumerate(bundle["parts"]):
            require(part["name"] == f"payload-{index:03d}.bin", "Invalid part order")
            source = HERE / "payload" / part["name"]
            require(identity(source) == {k:part[k] for k in ("size","sha256")}, "Part mismatch")
            target.write(source.read_bytes())
    require(identity(delta) == bundle["delta"], "Delta mismatch")
    web = output / "web"
    web.mkdir()
    subprocess.run(["xdelta3", "-d", "-s", str(base_pck), str(delta), str(web / "index.pck")], check=True)
    shutil.copy2(HERE / "index.html", web / "index.html")
    for name in sorted(FILES - {"index.html", "index.pck"}):
        require(bundle["files"][name] == base["files"]["dev"][name], "Runtime differs")
        fetch("dev/" + name, web / name, bundle["files"][name])
    require(all(identity(web / name) == data for name,data in bundle["files"].items()), "Candidate mismatch")
    print("QA_CANDIDATE_VERIFIED files=9")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    assemble(parser.parse_args().output.resolve())
