"""Verify an immutable, already built candidate before a validation-only rerun."""
import hashlib
import json
import os
import subprocess
import sys
import urllib.request
from pathlib import Path

SOURCE = '1632526b0cb675e5efd5709b0e55a6ab7ef970d9'
RUN = 35704702742
ARTIFACTS = {
    'candidate': (10683499608, 'dev14-candidate', 'sha256:9962b231c3c63b8bb553daa9e207aee7e92f6589f2ea49153b979294f9a713ca'),
    'build': (10684320280, 'dev14-build-review', 'sha256:47de7516cc07dff31df2335b2797bf0628ccce66e1318326443627aaa57b2798'),
}

def read(path):
    return json.loads(path.read_text())

def identity(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return {'size': path.stat().st_size, 'sha256': h.hexdigest()}

def api(path):
    request = urllib.request.Request(
        'https://api.github.com/repos/Corpax88/Ever-Deeper/actions/' + path,
        headers={'Authorization': 'Bearer ' + os.environ['GH_TOKEN'], 'Accept': 'application/vnd.github+json'},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)

candidate, evidence = map(Path, sys.argv[1:])
run = api('runs/' + str(RUN))
assert run['head_sha'] == SOURCE and run['status'] == 'completed'
jobs = api('runs/' + str(RUN) + '/jobs?filter=latest')['jobs']
assert any(j['name'] == 'build' and j['conclusion'] == 'success' for j in jobs)
for artifact_id, name, digest in ARTIFACTS.values():
    item = api('artifacts/' + str(artifact_id))
    assert item['name'] == name and item['workflow_run']['id'] == RUN and item['digest'] == digest and not item['expired']

allowed = {'.github/dev14/review.mjs', '.github/dev14/reuse-export.py', '.github/workflows/dev14-rereview.yml'}
changed = set(subprocess.check_output(['git', 'diff', '--name-only', SOURCE, 'HEAD'], text=True).splitlines())
assert changed <= allowed, 'Validation commit changed game source: ' + str(changed - allowed)
build = read(evidence / 'build.json')
manifest = read(candidate / 'manifest.json')
assert build['source_commit'] == SOURCE and build['version'] == '1.0.0-dev.14.3' and build['files'] == manifest
assert manifest['index.pck'] == {'size': 251484324, 'sha256': '69a3b032e324a865b4ba064756ab23e3f71beb3336df7705430436e37e74df5e'}
assert all(identity(candidate / name) == expected for name, expected in manifest.items())
core = read(evidence / 'core/results.json')
assert core['passed'] and all(c['passed'] for c in core['cases'])
assert {c['case'] for c in core['cases']} == {'input', 'overhaul', 'touch', 'build-flavor'}
fast = read(evidence / 'fast-tool-transitions.json')
assert fast['passed'] and fast['cases'] == 1856 and fast['source_commit'] == SOURCE and fast['pck'] == manifest['index.pck']
assert fast['runtime_adapter_sha256'] == identity(Path('scripts/player/native_worn/runtime_motion.gd'))['sha256']

(evidence / 'reused-export.json').write_text(json.dumps({
    'passed': True, 'source_commit': SOURCE, 'validation_commit': os.environ['GITHUB_SHA'],
    'export_run_id': RUN, 'original_artifacts': ARTIFACTS, 'files': manifest,
    'validation_only_changed_paths': sorted(changed),
    'export_build_job_passed': True, 'game_rebuilt': False,
    'previous_browser_scope': 'All eight tools and direction/contact checks passed. Recorded Worn cadence was 44.58 FPS and failed; fresh unrecorded cadence and WebKit checks remain required.',
}, indent=2) + '\n')
print('DEV143_IMMUTABLE_EXPORT_VERIFIED source=' + SOURCE + ' files=' + str(len(manifest)))
