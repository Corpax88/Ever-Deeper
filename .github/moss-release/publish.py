import importlib.util
import json
import subprocess
import sys
from pathlib import Path

here = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("pages", here.parent / "visual-guidance/publish.py")
pages = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pages)
pages.HERE = here
pages.VERSION = "DEV15.68 Mara Dialogue"
accepted = json.loads((here / "accepted.json").read_text())
before = accepted["before"]
pages.acceptance = lambda: (accepted, before)

def check_actions(record):
    run = json.loads(subprocess.check_output(["gh", "api", f"repos/Corpax88/Ever-Deeper/actions/runs/{record['run']}"]))
    assert run["conclusion"] == "success" and run["head_sha"] == record["source"]
    assert run["path"] == ".github/workflows/mara-dialogue.yml"
    for evidence in record["artifacts"]:
        artifact = json.loads(subprocess.check_output([
            "gh", "api", f"repos/Corpax88/Ever-Deeper/actions/artifacts/{evidence['id']}"
        ]))
        assert artifact["digest"] == evidence["digest"] and not artifact["expired"]
        assert artifact["workflow_run"]["id"] == record["run"]

def validate(candidate):
    assert len(before) == 26 and len(accepted["production_manifest"]) == 9
    for name, expected in accepted["production_manifest"].items():
        assert pages.ident(candidate / name) == expected, name
        if name not in ("index.html", "index.pck"):
            assert expected == before["dev/" + name]
    return accepted, before, candidate

pages.check_actions = check_actions
pages.validate = validate
if sys.argv[1] == "prepare":
    pages.prepare(Path(sys.argv[2]), Path(sys.argv[3]))
else:
    pages.verify(Path(sys.argv[2]))
