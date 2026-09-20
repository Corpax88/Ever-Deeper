"""Stage the bounded native Worn trial without modifying ordinary exports."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess


def stage(repo, candidate, tasks, target):
    if target.exists():
        raise RuntimeError("Use a fresh staging directory")
    target.mkdir(parents=True)
    paths = subprocess.check_output(["git", "ls-files", "-z"], cwd=repo).decode().split("\0")
    for name in paths:
        if not name or not (name.startswith(("assets/", "scripts/", "scenes/", "shaders/", "data/")) or name in ("project.godot", "export_presets.cfg")):
            continue
        src, dst = repo / name, target / name
        if not src.is_file():
            raise RuntimeError("Missing source: " + name)
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
    modules = target / "scripts/dev/native_trial"
    modules.mkdir(parents=True)
    for name in ("capture_motion.gd", "native_rig.gd", "task_motion.gd", "contact_surface.gd", "native_surface.gdshader", "trial_world.gd"):
        shutil.copy2(Path(__file__).parent / name, modules / name)
    assets = target / "assets/native-flow-trial"
    assets.mkdir()
    selected = ("candidate.json", "motion.json", "worn-native-runtime.glb", "albedo.png", "normal.png", "orm.png", "cloth.png", "component-response/response.png", "component-response/report.json", "transfer-albedo/report.json")
    identities = {}
    for name in selected:
        source = candidate / name
        # Preserve raw native bytes instead of Godot's importer-transformed files.
        destination = assets / (name + ".raw" if source.suffix in (".glb", ".png") else name)
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        identities[str(destination.relative_to(target))] = hashlib.sha256(destination.read_bytes()).hexdigest()
    shutil.copy2(tasks, assets / "tasks.json")
    project = (target / "project.godot").read_text()
    project = project.replace('config/name="Ever Deeper"', 'config/name="Ever Deeper — Worn-hakketest"')
    project = project.replace('config/version="1.0.0-rc.1"', 'config/version="1.0.0-dev.13-worn-trial.1"')
    project = project.replace('run/main_scene="res://scenes/main/main.tscn"', 'run/main_scene="res://scripts/dev/native_trial/entry.tscn"')
    project += '\n[native_worn_trial]\n\ninteractive=true\n'
    project = project.replace('Ever Deeper- Godot Production Port', 'Ever Deeper- Native Worn Trial').replace('Ever Deeper- Godot Development Port', 'Ever Deeper- Native Worn Trial')
    (target / "project.godot").write_text(project)
    (modules / "entry.tscn").write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/dev/native_trial/capture_motion.gd" id="1"]\n\n[node name="WornTrial" type="Node"]\nscript = ExtResource("1")\n')
    # Main initializes persistence again in its _ready. Redirect that first
    # load as well, including Web where the custom desktop user-dir is ignored.
    main_path = target / "scripts/main.gd"
    main_source = main_path.read_text()
    old_path = '"user://ever_deeper_dev_run_v3.sav"'
    assert main_source.count(old_path) == 1
    main_path.write_text(main_source.replace(old_path, '"user://native-flow-trial/isolated-save.json"'))
    for relative in ("scripts/progression/achievement_service.gd", "scripts/audio/audio_director.gd", "scripts/state/run_state.gd"):
        isolated = target / relative
        isolated.write_text(isolated.read_text().replace('"user://ever_deeper_', '"user://native_worn_trial_'))
    tutorial = target / "scripts/ui/quick_tutorial.gd"
    tutorial.write_text(tutorial.read_text().replace('"user://quick_tutorial', '"user://native_worn_trial_tutorial'))
    presets = (target / "export_presets.cfg").read_text()
    presets = presets.replace('include_filter="assets/hero/dad/*/manifest.json"', 'include_filter="assets/hero/dad/*/manifest.json,assets/native-flow-trial/*,assets/native-flow-trial/component-response/*,assets/native-flow-trial/transfer-albedo/*"')
    (target / "export_presets.cfg").write_text(presets)
    # Reuse already verified import products; editor revalidates staged sources.
    if (repo / ".godot/imported").exists():
        shutil.copytree(repo / ".godot/imported", target / ".godot/imported")
    (target / "trial-inputs.json").write_text(json.dumps({"raw_files": identities, "private_blender_included": False}, indent=2))
    print(json.dumps({"stage": str(target), "native_files": len(identities)}))


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    for name in ("repo", "candidate", "tasks", "target"):
        p.add_argument("--" + name, type=Path, required=True)
    a = p.parse_args()
    stage(a.repo.resolve(), a.candidate.resolve(), a.tasks.resolve(), a.target.resolve())
