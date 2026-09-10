#!/usr/bin/env python3
"""Run the current Godot checks; fail on errors, timeouts or missing completion markers."""
from __future__ import annotations
import argparse, json, os, re, shutil, subprocess, tempfile, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
ROOT = Path(__file__).resolve().parents[1]
CASES = {
    'mole-autonomy': (['--qa-mole-autonomy'], 'EVER_DEEPER_MOLE_AUTONOMY_OK'),
    'input': (['--qa-input-release'], 'EVER_DEEPER_INPUT_RELEASE_OK'),
    'overhaul': (['--visual-capture-suite','--overhaul-gameplay','--visual-capture-auto-ack'], 'EVER_DEEPER_OVERHAUL_GAMEPLAY_OK'),
    'touch': (['--visual-capture-suite','--menu-touch-only','--visual-capture-auto-ack'], 'EVER_DEEPER_OVERHAUL_GAMEPLAY_OK'),
    'commerce': (['--qa-commerce'], 'EVER_DEEPER_COMMERCE_OK'),
    'endgame': (['--qa-endgame'], 'EVER_DEEPER_ENDGAME_OK'),
    'endless': (['--qa-endless'], 'EVER_DEEPER_ENDLESS_OK'),
    'build-flavor': (['--qa-build-flavor'], 'EVER_DEEPER_BUILD_FLAVOR_QA_OK'),
    'onboarding': (['--qa-onboarding'], 'EVER_DEEPER_ONBOARDING_OK'),
    'layout': (['--qa-iphone-layout'], 'EVER_DEEPER_IPHONE_LAYOUT_OK'),
    'landscape': (['--qa-landscape'], 'EVER_DEEPER_LANDSCAPE_OK'),
    'portrait': (['--qa-portrait'], 'EVER_DEEPER_PORTRAIT_GUARD_OK'),
    'smoke': (['--smoke-test'], 'EVER_DEEPER_MOSS_ROOTWOUND_LOOP_OK'),
    'dev-tools': (['--qa-dev-tools'], 'EVER_DEEPER_DEV_TOOLS_QA_OK'),
    'workshops': (['--qa-workshop-panel'], 'EVER_DEEPER_WORKSHOP_PANEL_OK'),
    'crusher': (['--qa-crusher-impact'], 'EVER_DEEPER_CRUSHER_IMPACT_OK'),
    'one-point-zero-state': (['--qa-one-point-zero-state'], 'EVER_DEEPER_ONE_POINT_ZERO_STATE_OK'),
    'one-point-zero-world': (['--qa-one-point-zero-world'], 'EVER_DEEPER_ONE_POINT_ZERO_WORLD_OK'),
    'one-point-zero-migration': (['--qa-one-point-zero-migration'], 'EVER_DEEPER_ONE_POINT_ZERO_MIGRATION_OK'),
    'one-point-zero-ui': (['--qa-one-point-zero-ui'], 'EVER_DEEPER_ONE_POINT_ZERO_UI_OK'),
}
CORE = ['input','overhaul','touch','endgame','onboarding','layout','portrait','dev-tools','crusher',
        'one-point-zero-state','one-point-zero-world','one-point-zero-migration','one-point-zero-ui','mole-autonomy']
# Preserve historical assertions explicitly. Endless describes the retired
# floor/elevator design; 1.0 world/migration replace its applicable protections.
# See docs/one-point-zero/qa-round-1.md for every intentional contract change.
LEGACY = ['commerce','landscape','smoke','workshops','endless']
ERROR = re.compile(r'SCRIPT ERROR|Parse Error|(^|\n)ERROR:|Assertion failed|CHECK_FAILED', re.M)
def run_case(name, args):
    flags, marker = CASES[name]
    log_path = args.output / (name + '.log')
    start = time.monotonic()
    with tempfile.TemporaryDirectory(prefix='ever-deeper-qa-') as data_dir, log_path.open('w+') as log:
        env = dict(os.environ, XDG_DATA_HOME=data_dir)
        command = [args.godot, '--headless', '--path', str(args.project), '--', *flags]
        if args.pack: command = [args.godot, '--headless', '--path', data_dir, '--main-pack', str(args.pack.resolve()), '--', *flags]
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, env=env)
        reason = ''
        while process.poll() is None:
            log.flush(); text = log_path.read_text(errors='replace')
            if ERROR.search(text): reason = 'runtime error'; break
            if time.monotonic() - start > args.timeout: reason = 'timeout'; break
            time.sleep(.1)
        if reason:
            process.terminate()
            try: process.wait(timeout=5)
            except subprocess.TimeoutExpired: process.kill(); process.wait()
        text = log_path.read_text(errors='replace')
        passed = not reason and process.returncode == 0 and marker in text and not ERROR.search(text)
        row = {'case': name, 'passed': passed, 'exit_code': process.returncode,
               'reason': reason or ('' if passed else 'exit status or completion marker'),
               'seconds': round(time.monotonic() - start, 2), 'marker': marker,
               'completion': [line for line in text.splitlines() if '_OK' in line], 'log': str(log_path)}
        print(('PASS' if passed else 'FAIL') + ' ' + name + (' — ' + row['reason'] if not passed else ''), flush=True)
        return row

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    parser.add_argument('--project', type=Path, default=ROOT)
    parser.add_argument('--cases', nargs='+', choices=list(CASES), default=CORE)
    parser.add_argument('--all', action='store_true', help='Include legacy failing checks and export-only flavor validation; see docs/verification.md.')
    parser.add_argument('--pack', type=Path, help='Run a packed export; required for the build-flavor gate.')
    parser.add_argument('--output', type=Path, default=ROOT/'qa-results')
    parser.add_argument('--timeout', type=float, default=120)
    parser.add_argument('--jobs', type=int, default=2)
    args = parser.parse_args()
    binary = shutil.which(args.godot)
    if not binary: parser.error('Godot not found. Pass --godot /path/to/Godot or set GODOT_BIN.')
    args.godot = str(Path(binary).resolve()); args.project = args.project.resolve(); args.output = args.output.resolve()
    args.output.mkdir(parents=True, exist_ok=True)
    if args.all: args.cases = list(CASES)
    if 'build-flavor' in args.cases and not args.pack: parser.error('build-flavor checks exported resource exclusion; pass --pack build/index.pck.')
    with ThreadPoolExecutor(max_workers=args.jobs) as pool: rows = list(pool.map(lambda name: run_case(name,args),args.cases))
    (args.output/'results.json').write_text(json.dumps({'passed': all(row['passed'] for row in rows), 'cases': rows},indent=2)+'\n')
    return 0 if all(row['passed'] for row in rows) else 1
if __name__ == '__main__': raise SystemExit(main())
