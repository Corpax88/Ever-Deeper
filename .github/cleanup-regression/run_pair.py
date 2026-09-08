"""Run the two source versions sequentially on one rendered runner."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

root = Path.cwd()
meta = root / '.github/cleanup-regression'
stage = Path(os.environ['RUNNER_TEMP']) / 'cleanup-regression'
stage.mkdir()
output = stage / 'results'
output.mkdir()
manifest = json.loads((meta / 'source-pair.json').read_text())
area = sys.argv[1]
godot = 'Godot_v4.7.2-stable_linux.x86_64'


def run(command, cwd, log, env=None, marker=None):
    with log.open('w') as stream:
        result = subprocess.run(command, cwd=cwd, env=env, stdout=stream,
                                stderr=subprocess.STDOUT, timeout=480)
    text = log.read_text(errors='replace')
    errors = re.findall(r'^.*(?:SCRIPT ERROR|Parse Error|^ERROR:).*$', text, re.M)
    if result.returncode or errors or (marker and marker not in text):
        print(text[-10000:], flush=True)
        raise RuntimeError(f'{log.name}: exit {result.returncode}; errors {errors[:5]}')


for side in ['before', 'after']:
    project = stage / side
    project.mkdir()
    archive = subprocess.Popen(['git', 'archive', 'HEAD'], cwd=root, stdout=subprocess.PIPE)
    unpack = subprocess.run(['tar', '-x', '-C', str(project)], stdin=archive.stdout)
    archive.stdout.close()
    assert unpack.returncode == 0 and archive.wait() == 0
    if side == 'before':
        subprocess.run(['git', 'apply', str(meta / 'restore-before.patch')], cwd=project, check=True)
    for name, identities in manifest['files'].items():
        assert hashlib.sha256((project / name).read_bytes()).hexdigest() == identities[f'{side}_sha256'], name
    run([godot, '--headless', '--editor', '--path', str(project), '--import'],
        project, output / f'{side}-import.log')
    env = dict(os.environ)
    env['XDG_DATA_HOME'] = str(stage / f'{side}-save')
    env['XDG_CONFIG_HOME'] = str(stage / f'{side}-config')
    env['LIBGL_ALWAYS_SOFTWARE'] = '1'
    run(['xvfb-run', '-a', '-s', '-screen 0 1280x720x24', godot,
         '--path', str(project), '--audio-driver', 'Dummy',
         '--script', str(meta / 'normal_startup_probe.gd'), '--',
         f'--audit-area={area}', f'--audit-output={output / side}'],
        project, output / f'{side}-runtime.log', env, 'CLEANUP_NORMAL_STARTUP_COMPLETE')
    report = json.loads((output / f'{side}.json').read_text())
    assert report['duration_seconds'] >= 90 and len(report['buckets']) >= 17
    assert not report['automated_mode'] and not report['qa_launcher_present']
    assert report['persistence_active'] and report['final']['window'] == [844, 390]
    print(f'{side}: {area} completed 90 seconds through ordinary startup', flush=True)
    shutil.rmtree(project)

print('CLEANUP_SOURCE_PAIR_COMPLETE', flush=True)
