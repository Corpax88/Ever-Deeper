"""Reuse approved native bytes and export the ordinary DEV14 game."""
import argparse, hashlib, json, os, re, subprocess, urllib.request, shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NAMES = ['index.html','index.js','index.pck','index.wasm','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js']

def identity(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024*1024), b''): h.update(block)
    return {'size':path.stat().st_size,'sha256':h.hexdigest()}

def run(args, log):
    with log.open('w') as out:
        result = subprocess.run(args, cwd=ROOT, stdout=out, stderr=subprocess.STDOUT)
    text = log.read_text(errors='replace')
    if result.returncode or re.search(r'SCRIPT ERROR|Parse Error|^ERROR:', text, re.M):
        print(text[-16000:])
        raise RuntimeError('Build step failed: '+log.name)

def build(godot, work, blender):
    work.mkdir(parents=True)
    bundle = json.loads((ROOT/'.github/native-flow-trial/bundle.json').read_text())
    pck = work/'approved-worn.pck'
    with urllib.request.urlopen('https://corpax88.github.io/Ever-Deeper/dev/worn/index.pck',timeout=120) as source, pck.open('wb') as out:
        while block := source.read(1024*1024): out.write(block)
    assert identity(pck) == bundle['files']['index.pck'], 'Approved native source changed'
    assets = ROOT/'assets/native-worn'
    run([godot,'--headless','--path',str(ROOT),'--script',str(ROOT/'.github/dev14/extract-native.gd'),'--',str(pck),str(assets)],work/'extract.log')
    preparation_project = work/'prepare-project'; preparation_project.mkdir()
    (preparation_project/'project.godot').write_text('config_version=5\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    (preparation_project/'assets').symlink_to(ROOT/'assets',target_is_directory=True)
    run([godot,'--headless','--path',str(preparation_project),'--script',str(ROOT/'.github/dev14/prepare-native.gd')],work/'prepare-native.log')
    preparation = json.loads((assets/'runtime-scene.json').read_text())
    assert preparation['geometry_and_bindings_identical'] and preparation['source_fingerprint'] == preparation['prepared_fingerprint']
    (work/'native-preparation.json').write_text(json.dumps(preparation,indent=2)+'\n')
    run([godot,'--headless','--path',str(preparation_project),'--script',str(ROOT/'.github/dev14/optimize-native.gd')],work/'optimize-native.log')
    optimized = json.loads((assets/'runtime-scene.json').read_text())
    assert optimized['animation_and_bindings_preserved'] and optimized['optimization']['vertex_attributes_preserved']
    assert optimized['optimization']['lod'] == 2 and optimized['optimization']['triangles'] < 100000
    (work/'native-optimization.json').write_text(json.dumps(optimized,indent=2)+'\n')
    tools_dir = work/'original-pickaxes'
    run([blender,'--background','--threads','2','--python-exit-code','1','--python',str(ROOT/'tools/hero_v28/original_pickaxes/bake_tools.py'),'--','--output',str(tools_dir)],work/'bake-pickaxes.log')
    source = json.loads((tools_dir/'source-manifest.json').read_text())
    assert len(source['tools']) == 8 and 'ORIGINAL_PICKAXES_COMPLETE 8' in (work/'bake-pickaxes.log').read_text()
    equipment = ROOT/'assets/native-pickaxes'; equipment.mkdir(exist_ok=True)
    for file in list(tools_dir.glob('*.glb.raw')) + [tools_dir/'source-manifest.json']:
        shutil.copy2(file,equipment/file.name)
    run([godot,'--headless','--path',str(preparation_project),'--script',str(ROOT/'.github/dev14/prepare-pickaxes.gd')],work/'prepare-pickaxes.log')
    receipt = json.loads((equipment/'runtime-manifest.json').read_text())
    assert len(receipt['tools']) == 7 and receipt['body']['vertex_attributes_unchanged']
    (work/'equipment-preparation.json').write_text(json.dumps(receipt,indent=2)+'\n')
    (work/'equipment-source.json').write_text(json.dumps(source,indent=2)+'\n')
    # This generated extraction copy is build input only. The prepared resource
    # replaces the 93 MB raw GLTF in the web package; approved source stays pinned.
    (assets/'worn-native-runtime.glb.raw').unlink()
    run([godot,'--headless','--editor','--path',str(ROOT),'--import'],work/'import.log')
    candidate = work/'candidate'; candidate.mkdir()
    run([godot,'--headless','--path',str(ROOT),'--export-release','Web DEV',str(candidate/'index.html')],work/'export.log')
    subprocess.run(['python3','tools/install-render-probe-shell.py',str(candidate/'index.html')],cwd=ROOT,check=True)
    package_check = work/'package-check'; package_check.mkdir()
    # Resource paths can fall back to the source checkout if the test runs there.
    # An empty resource root ensures every observation comes from the PCK alone.
    run([godot,'--headless','--path',str(package_check),'--main-pack',str(candidate/'index.pck'),'--script',str(ROOT/'.github/dev14/check-equipment-package.gd')],work/'equipment-package.log')
    assert 'PICKAXE_PACKAGE_COMPLETE' in (work/'equipment-package.log').read_text()
    files = {name:identity(candidate/name) for name in NAMES}
    (candidate/'manifest.json').write_text(json.dumps(files,indent=2)+'\n')
    (work/'build.json').write_text(json.dumps({'version':'1.0.0-dev.14.3','source_commit':os.environ.get('GITHUB_SHA'),'main_scene':'res://scenes/main/main.tscn','save_path':'user://ever_deeper_dev_run_v3.sav','native_input_pck':bundle['files']['index.pck'],'files':files,'physical_iphone_verified':False},indent=2)+'\n')
    print('DEV14_ORDINARY_EXPORT_COMPLETE')

if __name__ == '__main__':
    p=argparse.ArgumentParser();p.add_argument('godot');p.add_argument('work',type=Path);p.add_argument('blender');a=p.parse_args();build(a.godot,a.work.resolve(),a.blender)
