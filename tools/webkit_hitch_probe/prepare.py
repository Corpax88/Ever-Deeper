#!/usr/bin/env python3
"""Bind the explicitly instrumented DEV11 package; never publish it."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
BASE = '8f5680defb9083bbe1e044d39a10612f2186e7f3'
WORLD = 'scripts/world/endless_descent_world.gd'
STATE = 'scripts/state/run_state.gd'
RECORDER = 'scripts/dev/hitch_phase_recorder.gd'
OBSERVER = '35db05eed667a6b95ec235d2b0673ea2ddf48cf7ccfa84ef193ed04ba0bf4424'
RUNTIME = ['scripts', 'scenes', 'shaders', 'assets', 'data', 'project.godot', 'export_presets.cfg']
FILES = ['index.apple-touch-icon.png', 'index.audio.position.worklet.js', 'index.audio.worklet.js', 'index.html', 'index.icon.png', 'index.js', 'index.pck', 'index.png', 'index.wasm']

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + '\n')

def verify():
    expected = {}
    expected['project.godot'] = git('show', BASE + ':project.godot').decode().replace('RunState="*res://scripts/state/run_state.gd"', 'HitchProbe="*res://scripts/dev/hitch_phase_recorder.gd"\nRunState="*res://scripts/state/run_state.gd"')
    s = git('show', BASE + ':' + WORLD).decode()
    for name, arg, kind in [('_generate_stream_window', 'start_depth', 1), ('_rebase_stream_window', 'next_start', 2)]:
        old = f'func {name}({arg}: int) -> void:\n'
        replacement = old + f'\tvar hitch_span: int = HitchProbe.begin_span({kind}, current_depth, window_start_depth, {arg})\n\t_hitch_original{name}({arg})\n\tHitchProbe.end_span(hitch_span, current_depth, window_start_depth)\n\n\nfunc _hitch_original{name}({arg}: int) -> void:\n'
        assert s.count(old) == 1
        s = s.replace(old, replacement)
    expected[WORLD] = s
    s = git('show', BASE + ':' + STATE).decode()
    old = 'func save_game(path: String = "") -> bool:\n'
    replacement = old + '\tvar hitch_span: int = HitchProbe.begin_span(3, endless_current_depth, int(endless_stream_anchor.get("start_depth", 0)))\n\tvar hitch_result: bool = _hitch_original_save_game(path)\n\tHitchProbe.end_span(hitch_span, endless_current_depth, int(endless_stream_anchor.get("start_depth", 0)), int(hitch_result), int(last_save_error))\n\treturn hitch_result\n\n\nfunc _hitch_original_save_game(path: String = "") -> bool:\n'
    assert s.count(old) == 1
    expected[STATE] = s.replace(old, replacement)
    for path, content in expected.items():
        assert (ROOT/path).read_bytes() == content.encode(), ('Original body or wrapper changed', path)
    changed = set(git('diff', '--name-only', BASE, '--', *RUNTIME).decode().splitlines())
    changed.update(git('ls-files', '--others', '--exclude-standard', '--', *RUNTIME).decode().splitlines())
    allowed = set(expected) | {RECORDER, RECORDER + '.uid'}
    assert changed <= allowed, ('Unauthorized runtime change', changed - allowed)
    assert set(expected) <= changed
    here = ROOT/'tools/webkit_hitch_probe'
    assert sha((here/'observer.js').read_bytes()) == OBSERVER
    run = (here/'run.mjs').read_text()
    for first, last, digest in [
        ('async function scan(label)', 'async function phaseClocks(label)', 'dc7423e58dbd8fbaedc628237ff7632f5b201b3a6702b4bd4865563a87c28892'),
        ('  context=await browser.newContext', "  actions.push({stage:'begin_real_keys'", 'ee0e3db55eaf62bb6b43d85add36cbb5edab6cdc7c8c2103e5d49cd4338c6bcd'),
    ]:
        section = run[run.index(first):run.index(last)]
        assert sha(section.encode()) == digest, ('Original GUI/draw/save route changed', first)
    assert "const raw=await bounded(page.evaluate(()=>window.__webkitMovingStudy.begin()),75000,'60-second engine loop');" in run
    first = "  await page.keyboard.up('Space');await page.keyboard.up('ArrowDown');actions.push({stage:'release_real_keys'"
    start = run.index(first)
    assert sha(run[start:run.index('}catch(e) {', start)].encode()) == '66730720baf1a6f070b7fa341b3a29a894983e55f063e9349aae798b614d078c', 'Original downstream functional gates changed'
    return {'diagnostic_only': True, 'production_base': BASE, 'source': git('rev-parse', 'HEAD').decode().strip(), 'allowed_runtime_changes': sorted(changed), 'original_function_bodies_byte_equal': True, 'original_navigation_byte_equal': True, 'observer_byte_equal': True, 'source_hashes': {p: sha((ROOT/p).read_bytes()) for p in sorted(allowed) if (ROOT/p).exists()}, 'observer_sha256': OBSERVER}

def recorder_check(binary, output):
    with tempfile.TemporaryDirectory(prefix='hitch-recorder-') as folder:
        root = Path(folder)
        (root/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Hitch recorder checks"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
        shutil.copyfile(ROOT/RECORDER, root/'recorder.gd')
        shutil.copyfile(ROOT/'tools/webkit_hitch_probe/recorder_check.gd', root/'check.gd')
        proc = subprocess.run([binary, '--headless', '--path', str(root), '--script', 'res://check.gd'], capture_output=True, text=True, timeout=30)
        log = proc.stdout + proc.stderr
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(log)
        assert proc.returncode == 0 and log.count('HITCH_RECORDER_CHECKS_OK ') == 1 and not re.search(r'SCRIPT ERROR|Parse Error|^ERROR:|Assertion failed', log, re.M), log
        print('HITCH_RECORDER_CHECKS_VERIFIED')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('operation', choices=['verify', 'bind', 'recorder-check'])
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--candidate', type=Path)
    parser.add_argument('--godot')
    args = parser.parse_args()
    if args.operation == 'recorder-check':
        recorder_check(args.godot, args.output)
        return
    receipt = verify()
    write(args.output, receipt)
    if args.operation == 'bind':
        candidate = args.candidate
        assert set(p.name for p in candidate.iterdir() if p.is_file()) == set(FILES)
        request = json.loads((ROOT/'tools/webkit_hitch_probe/REQUEST.json').read_text())
        source = git('rev-parse', 'HEAD').decode().strip()
        assert source == os.environ['GITHUB_SHA'] and git('rev-parse', 'HEAD^').decode().strip() == request['preparation_sha']
        assert request['source'] == BASE and request['sessions'] == 1 and request['diagnostic_only'] is True
        dev_files = {p: {'size': (candidate/p).stat().st_size, 'sha256': sha((candidate/p).read_bytes())} for p in FILES}
        identity = {'schema': 1, 'diagnostic_only': True, 'sourceSha': source, 'productionBase': BASE, 'preparationSha': request['preparation_sha'], 'devFiles': dev_files, 'sourceReceipt': receipt, 'exportPreset': 'Web DEV', 'godot': '4.7.2.stable', 'baselinePckSha256': '5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9'}
        write(candidate/'artifact-identity.json', identity)
        digest = sha((candidate/'artifact-identity.json').read_bytes())
        if os.environ.get('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as output:
                output.write('identity_sha256=' + digest + '\n')
        print('DIAGNOSTIC_PACKAGE_BOUND ' + digest)
    else:
        print('DIAGNOSTIC_SOURCE_PARITY_OK ' + receipt['observer_sha256'])

if __name__ == '__main__':
    main()
