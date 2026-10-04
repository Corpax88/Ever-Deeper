"""Publish accepted DEV15.56 artifact bytes; never export the main checkout."""
import hashlib
import http.client
import io
import json
import os
from pathlib import Path
import re
import shutil
import sys
import time
from concurrent.futures import ThreadPoolExecutor
import urllib.request
import urllib.error
import zipfile

HERE = Path(__file__).resolve().parent
PUBLIC = 'https://corpax88.github.io/Ever-Deeper/'
VERSION = '1.0.0-dev.15.57'
BASE_VERSION = '1.0.0-dev.15.56'
BASE_SOURCE = 'deaa7088d75d473b0c16951bc05f19c4db7800c4'
BASE_PCK = {'size': 327914622, 'sha256': '8de6ebae373816a37159327218f90cb9cb0419eae91eb9d833cba0810e0ac5de'}
BASE_HTML = {'size': 23145, 'sha256': 'd18c1eddb76078ac04c63084f691faa40266903008498a435cfebbb47d855bbf'}
BEFORE_SHA = '53a302c263a8f9afcdaf7dac1fa04e42efa8640b9e939185c95215126e6e3335'
WEB = {'index.html', 'index.js', 'index.wasm', 'index.pck', 'index.png', 'index.icon.png', 'index.apple-touch-icon.png', 'index.audio.worklet.js', 'index.audio.position.worklet.js'}
BROWSER = ('candidate', 'focused', 'ricochet-lifecycle', 'journey', 'ordinary-candidate')
REPORTS = ('native',) + BROWSER
NATIVE_GATES = {
    'core-charging',
    'hunt-boundary',
    'save-retry', 'save-status', 'mod-lifecycle', 'laser-stamina', 'completed-goals',
    'pickup-bonus', 'corebreaker-burst', 'retained-five-mechanics',
    'running-achievements', 'achievement-recovery', 'companion-training',
    'companion-new-run', 'treasury-seams', 'treasury-seam-world',
    'notification-modals', 'treasury-seam-integrity', 'treasury-hunt-rate',
    'completed-collection', 'retained-input', 'retained-premium-core',
    'retained-endgame', 'retained-one-point-zero-world',
    'treasury-sale-reserve', 'treasury-routes',
}


def require(ok, why):
    if not ok:
        raise RuntimeError(why)


def read(path):
    return json.loads(path.read_text())


def sha(data):
    return hashlib.sha256(data).hexdigest()


def ident(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return {'size': path.stat().st_size, 'sha256': h.hexdigest()}


def acceptance():
    accepted = read(HERE / 'accepted.json')
    require(accepted.get('schema') == 1 and accepted.get('accepted') is True
            and accepted.get('images_inspected') is True and accepted.get('reviewer') == 'author',
            'Explicit visual and QA acceptance is missing')
    require(accepted['version'] == VERSION and accepted['destination'] == 'dev', 'Wrong release')
    require(re.fullmatch(r'[0-9a-f]{40}', accepted['source']), 'Invalid accepted source')
    require(type(accepted['run']) is int and accepted['run'] > 0, 'Invalid accepted run')
    require(set(accepted['report_sha256']) == set(REPORTS), 'Bind all six original reports')
    require(set(accepted['receipt_sha256']) == {'baseline', 'candidate', 'production'}, 'Bind all build receipts')
    for digest in [*accepted['report_sha256'].values(), *accepted['receipt_sha256'].values()]:
        require(re.fullmatch(r'[0-9a-f]{64}', digest), 'Invalid evidence hash')
    names, ids = set(), set()
    for artifact in accepted['artifacts']:
        require(re.fullmatch(r'hunt-followup-[a-z0-9-]+', artifact['name']), 'Invalid artifact name')
        require(type(artifact['id']) is int and artifact['id'] > 0, 'Invalid artifact id')
        require(re.fullmatch(r'sha256:[0-9a-f]{64}', artifact['digest']), 'Missing immutable artifact digest')
        require(artifact['name'] not in names and artifact['id'] not in ids, 'Duplicate artifact binding')
        names.add(artifact['name'])
        ids.add(artifact['id'])
    for kind in ('production_manifest', 'qa_manifest'):
        require(set(accepted[kind]) == WEB, 'Wrong distribution files: ' + kind)
        for value in accepted[kind].values():
            require(type(value['size']) is int and value['size'] > 0
                    and re.fullmatch(r'[0-9a-f]{64}', value['sha256']), 'Invalid file identity')
    before_path = HERE / 'public-before.json'
    require(ident(before_path)['sha256'] == BEFORE_SHA, 'Protected LIVE/Worn baseline changed')
    before = read(before_path)
    require(set(before) == WEB | {'dev/' + n for n in WEB} | {'dev/worn/' + n for n in WEB}, 'Wrong public baseline')
    require(before['dev/index.html'] == BASE_HTML and before['dev/index.pck'] == BASE_PCK,
            'Wrong currently published DEV15.55 baseline')
    for name in WEB - {'index.html', 'index.pck'}:
        require(accepted['production_manifest'][name] == before['dev/' + name], 'Unreviewed engine/asset change: ' + name)
        require(accepted['qa_manifest'][name] == before['dev/' + name], 'QA engine/asset mismatch: ' + name)
    require(accepted['qa_manifest']['index.pck'] != accepted['production_manifest']['index.pck'], 'QA overlay cannot be the production pack')
    return accepted, before


def check_actions(accepted):
    def api(path):
        request = urllib.request.Request('https://api.github.com/repos/Corpax88/Ever-Deeper/actions/' + path,
            headers={'Authorization': 'Bearer ' + os.environ['GH_TOKEN'], 'Accept': 'application/vnd.github+json'})
        with urllib.request.urlopen(request, timeout=120) as stream:
            return json.load(stream)
    run = api('runs/' + str(accepted['run']))
    require(run['head_sha'] == accepted['source'] and run['status'] == 'completed'
            and run['conclusion'] == 'success' and run['path'] == '.github/workflows/quality2.yml', 'Unaccepted QA run')
    for bound in accepted['artifacts']:
        actual = api('artifacts/' + str(bound['id']))
        require(not actual['expired'] and actual['name'] == bound['name'] and actual['digest'] == bound['digest']
                and actual['workflow_run']['id'] == accepted['run']
                and actual['workflow_run']['head_sha'] == accepted['source'], 'Artifact binding mismatch: ' + bound['name'])


def split_report(artifacts, group, used):
    prefix = 'hunt-followup-' + group
    used.add(prefix + '-manifest')
    manifest = read(artifacts / (prefix + '-manifest') / 'recovery-manifest.json')
    parts = manifest['parts']
    require(0 < len(parts) <= 14, 'Invalid evidence part count: ' + group)
    archive = io.BytesIO()
    for index, part in enumerate(parts):
        require(part['name'] == 'part-%02d.bin' % index and 0 < part['size'] <= 28 * 1024 * 1024, 'Invalid evidence part')
        name = prefix + '-%02d' % index
        used.add(name)
        path = artifacts / name / part['name']
        require(ident(path) == {'size': part['size'], 'sha256': part['sha256']}, 'Split evidence changed: ' + name)
        archive.write(path.read_bytes())
    require(archive.tell() == manifest['archive_size'] and sha(archive.getvalue()) == manifest['archive_sha256'], 'Evidence archive mismatch: ' + group)
    archive.seek(0)
    with zipfile.ZipFile(archive) as bundle:
        require(bundle.namelist().count('report.json') == 1, 'Missing/duplicate original report: ' + group)
        require(bundle.getinfo('report.json').file_size < 32 * 1024 * 1024, 'Unexpected report size')
        raw = bundle.read('report.json')
        for image in json.loads(raw).get('images', []):
            names = [image] if isinstance(image, str) else [image['file'], image['state']]
            for name in names:
                require(bundle.namelist().count(name) == 1 and bundle.getinfo(name).file_size > 0, 'Missing captured evidence: ' + group + '/' + name)
        return raw


def validate(artifacts):
    accepted, before = acceptance()
    production = artifacts / 'hunt-followup-production-candidate'
    manifest = accepted['production_manifest']
    require(read(production / 'manifest.json') == manifest, 'Production manifest changed')
    for name, value in manifest.items():
        require(ident(production / name) == value, 'Production bytes changed: ' + name)
    used = {'hunt-followup-production-candidate', 'hunt-followup-native', 'hunt-followup-package-receipts'}
    receipts = {}
    for group in ('baseline', 'candidate', 'production'):
        raw = (artifacts / 'hunt-followup-package-receipts' / group / 'qa-build-receipt.json').read_bytes()
        require(sha(raw) == accepted['receipt_sha256'][group], 'Build receipt changed: ' + group)
        receipt = json.loads(raw)
        require(receipt['baseline_pck'] == BASE_PCK and receipt['baseline_source'] == BASE_SOURCE
                and receipt['qa_source'] == accepted['source'] and receipt['retained_payloads_verified'] is True
                and receipt['production'] is (group == 'production'), 'Build provenance mismatch: ' + group)
        require(receipt['version'] == (BASE_VERSION if group == 'baseline' else VERSION), 'Build version mismatch')
        receipts[group] = receipt
    require(receipts['baseline']['overrides'] == [], 'Baseline source drift')
    require(receipts['candidate']['files'] == accepted['qa_manifest'] and receipts['production']['files'] == manifest, 'QA/production receipt mismatch')
    require(receipts['candidate']['overrides'] == receipts['production']['overrides'] and receipts['production']['overrides'], 'Different reviewed production sources')
    require(not any(p.startswith('scripts/qa/') for p in receipts['production']['replaced']), 'QA replacements in production')
    require('scripts/qa/suites/full_quality_base.gd' in receipts['candidate']['replaced'], 'Missing review fixture')
    require(read(production / 'qa-build-receipt.json') == receipts['production'], 'Production artifact receipt mismatch')
    reports = {}
    for group in REPORTS:
        raw = (artifacts / 'hunt-followup-native/report.json').read_bytes() if group == 'native' else split_report(artifacts, group, used)
        require(sha(raw) == accepted['report_sha256'][group], 'Reviewed report changed: ' + group)
        report = json.loads(raw)
        reports[group] = report
        source_key = 'source_commit' if group == 'ordinary-candidate' else 'source'
        require(report[source_key] == accepted['source'], 'Report source mismatch: ' + group)
        if group == 'native':
            require(report['production_pck'] == manifest['index.pck'] and report['qa_pck'] == accepted['qa_manifest']['index.pck'], 'Native pack mismatch')
            require(NATIVE_GATES <= {row['name'] for row in report['checks']}, 'Required native gate missing')
        else:
            require(report['version'] == VERSION and report['files'] == (manifest if group == 'ordinary-candidate' else accepted['qa_manifest']), 'Browser package mismatch: ' + group)
            require(report.get('images'), 'Missing graphical evidence: ' + group)
        if group == 'ordinary-candidate':
            require(report.get('completed_observation') is True and not report.get('failure') and not report.get('crashed')
                    and report.get('normal_startup') is True and report.get('fixture_args') == [], 'Ordinary startup failed')
            require(any('Apple' in str(s.get('renderer', '')) and s.get('lost') is False and s.get('frames', 0) > 0 for s in report['samples']), 'Missing actual Apple GPU startup')
        else:
            require(report.get('passed') is True and report.get('checks') and not report.get('failures')
                    and all(row['passed'] is True for row in report['checks']), 'QA gate failed: ' + group)
            if group != 'native':
                require(report['runtime']['lost'] is False and 'Apple' in report['runtime']['renderer'], 'Missing actual Apple GPU review: ' + group)
    require(used == {a['name'] for a in accepted['artifacts']}, 'Artifact list must bind exactly all production and evidence artifacts')
    print('QUALITY2_ACCEPTED_BYTES_AND_EVIDENCE_VERIFIED', accepted['source'])
    return accepted, before, production


def fetch(name, path, want):
    path.parent.mkdir(parents=True, exist_ok=True)
    partial = path.with_name(path.name + '.download')
    for attempt in range(3):
        request = urllib.request.Request(PUBLIC + name, headers={'Cache-Control': 'no-cache'})
        h, size = hashlib.sha256(), 0
        try:
            print('QUALITY2_FETCH', name, 'attempt', attempt + 1, flush=True)
            with urllib.request.urlopen(request, timeout=45) as src, partial.open('wb') as out:
                while block := src.read(1024 * 1024):
                    size += len(block)
                    require(size <= want['size'], 'Unexpected public size: ' + name)
                    h.update(block)
                    out.write(block)
                out.flush()
                os.fsync(out.fileno())
            require({'size': size, 'sha256': h.hexdigest()} == want, 'Public content changed: ' + name)
            os.replace(partial, path)
            print('QUALITY2_FETCH_VERIFIED', name, flush=True)
            return
        except (urllib.error.URLError, TimeoutError, ConnectionError, http.client.IncompleteRead) as error:
            if isinstance(error, urllib.error.HTTPError) and error.code not in (429, 500, 502, 503, 504):
                raise
            print('QUALITY2_FETCH_RETRY', name, type(error).__name__, flush=True)
            if attempt == 2:
                raise RuntimeError('Public transfer failed after three attempts: ' + name) from error
            time.sleep(2 ** attempt)
        finally:
            partial.unlink(missing_ok=True)


def prepare(work, artifacts):
    require(not work.exists(), 'Use fresh publication staging')
    accepted, before, production = validate(artifacts)
    check_actions(accepted)
    with ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(lambda item: fetch(item[0], work / 'previous' / item[0], item[1]), before.items()))
    shutil.copytree(work / 'previous', work / 'site')
    for name in WEB:
        shutil.copy2(production / name, work / 'site/dev' / name)
    (work / 'site/.nojekyll').write_text('')
    protected = {name: value for name, value in before.items() if not name.startswith('dev/') or name.startswith('dev/worn/')}
    require(len(protected) == 18 and all(ident(work / 'site' / n) == v for n, v in protected.items()), 'LIVE/Worn preservation failed')
    require(sum(p.stat().st_size for p in (work / 'site').rglob('*') if p.is_file()) < 1024 ** 3, 'Pages package exceeds 1GiB')
    rollback = work / 'rollback-dev'
    rollback.mkdir()
    for name in WEB:
        shutil.copy2(work / 'previous/dev' / name, rollback / name)
    (rollback / 'rollback-manifest.json').write_text(json.dumps({n: before['dev/' + n] for n in sorted(WEB)}, indent=2))
    (work / 'staging-receipt.json').write_text(json.dumps({'version': VERSION, 'source': accepted['source'], 'run': accepted['run'], 'accepted_sha256': ident(HERE / 'accepted.json')['sha256'], 'files': accepted['production_manifest'], 'protected_files': protected}, indent=2))
    print('QUALITY2_DEV15_56_STAGED_LIVE_AND_WORN_UNCHANGED')


def verify(work):
    accepted, before = acceptance()
    expected = {**before, **{'dev/' + n: v for n, v in accepted['production_manifest'].items()}}
    pending = list(expected)
    work.mkdir(parents=True, exist_ok=True)
    def check(name):
        try:
            fetch(name, work / name, expected[name])
            return True
        except Exception:
            return False
    for attempt in range(10):
        with ThreadPoolExecutor(max_workers=3) as pool:
            results = list(pool.map(check, pending))
        pending = [name for name, ok in zip(pending, results) if not ok]
        if not pending:
            break
        if attempt < 9:
            time.sleep(10)
    receipt = {'passed': not pending, 'version': VERSION, 'source': accepted['source'], 'run': accepted['run'],
               'accepted_sha256': ident(HERE / 'accepted.json')['sha256'], 'artifacts': accepted['artifacts'],
               'files': expected, 'unverified': pending, 'live_preserved': 9, 'worn_preserved': 9,
               'physical_iphone_verified': False}
    (work / 'publication-receipt.json').write_text(json.dumps(receipt, indent=2))
    require(not pending, 'Public hashes incomplete: ' + ', '.join(pending))
    print('QUALITY2_PUBLIC_VERIFIED_27_FILES')


if __name__ == '__main__':
    if sys.argv[1] == 'inputs':
        accepted, _ = acceptance()
        with open(os.environ['GITHUB_OUTPUT'], 'a') as stream:
            print('run=' + str(accepted['run']), file=stream)
            print('artifacts=' + ','.join(str(a['id']) for a in accepted['artifacts']), file=stream)
    elif sys.argv[1] == 'validate':
        validate(Path(sys.argv[2]))
    elif sys.argv[1] == 'prepare':
        prepare(Path(sys.argv[2]), Path(sys.argv[3]))
    elif sys.argv[1] == 'verify':
        verify(Path(sys.argv[2]))
    else:
        raise SystemExit('Use inputs, validate ARTIFACTS, prepare STAGING ARTIFACTS, or verify OUTPUT')
