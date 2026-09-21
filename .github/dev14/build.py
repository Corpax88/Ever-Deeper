"""Reuse approved native bytes and export the ordinary DEV14 game."""
import argparse, hashlib, json, os, re, subprocess, urllib.request
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

def build(godot, work):
    work.mkdir(parents=True)
    bundle = json.loads((ROOT/'.github/native-flow-trial/bundle.json').read_text())
    pck = work/'approved-worn.pck'
    with urllib.request.urlopen('https://corpax88.github.io/Ever-Deeper/dev/worn/index.pck',timeout=120) as source, pck.open('wb') as out:
        while block := source.read(1024*1024): out.write(block)
    assert identity(pck) == bundle['files']['index.pck'], 'Approved native source changed'
    assets = ROOT/'assets/native-worn'
    run([godot,'--headless','--path',str(ROOT),'--script',str(ROOT/'.github/dev14/extract-native.gd'),'--',str(pck),str(assets)],work/'extract.log')
    run([godot,'--headless','--path',str(ROOT),'--script',str(ROOT/'.github/dev14/prepare-native.gd')],work/'prepare-native.log')
    preparation = json.loads((assets/'runtime-scene.json').read_text())
    assert preparation['geometry_and_bindings_identical'] and preparation['source_fingerprint'] == preparation['prepared_fingerprint']
    (work/'native-preparation.json').write_text(json.dumps(preparation,indent=2)+'\n')
    # This generated extraction copy is build input only. The prepared resource
    # replaces the 93 MB raw GLTF in the web package; approved source stays pinned.
    (assets/'worn-native-runtime.glb.raw').unlink()
    run([godot,'--headless','--editor','--path',str(ROOT),'--import'],work/'import.log')
    candidate = work/'candidate'; candidate.mkdir()
    run([godot,'--headless','--path',str(ROOT),'--export-release','Web DEV',str(candidate/'index.html')],work/'export.log')
    subprocess.run(['python3','tools/install-render-probe-shell.py',str(candidate/'index.html')],cwd=ROOT,check=True)
    files = {name:identity(candidate/name) for name in NAMES}
    (candidate/'manifest.json').write_text(json.dumps(files,indent=2)+'\n')
    (work/'build.json').write_text(json.dumps({'version':'1.0.0-dev.14.1','source_commit':os.environ.get('GITHUB_SHA'),'main_scene':'res://scenes/main/main.tscn','save_path':'user://ever_deeper_dev_run_v3.sav','native_input_pck':bundle['files']['index.pck'],'files':files,'physical_iphone_verified':False},indent=2)+'\n')
    print('DEV14_ORDINARY_EXPORT_COMPLETE')

if __name__ == '__main__':
    p=argparse.ArgumentParser();p.add_argument('godot');p.add_argument('work',type=Path);a=p.parse_args();build(a.godot,a.work.resolve())
