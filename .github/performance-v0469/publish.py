"""Publish only the exact inspected packages; preserve the current release for rollback."""
import concurrent.futures, hashlib, json, shutil, sys, time, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
URL = 'https://corpax88.github.io/Ever-Deeper/'
REVIEW = json.loads((ROOT/'review.json').read_text())
BASELINE = json.loads((ROOT.parent/'light-v0468/bundle.json').read_text())
FILES = REVIEW['files']

def verify(data, expected):
    if len(data) != expected['size'] or hashlib.sha256(data).hexdigest() != expected['sha256']:
        raise RuntimeError('Package identity mismatch; stop and rebase against the current release')

def fetch(side, name):
    request = urllib.request.Request(URL + ('dev/' if side == 'dev' else '') + name)
    return urllib.request.urlopen(request, timeout=120).read()

def prepare(candidate, site, rollback):
    if not REVIEW['visual_reviewed'] or not REVIEW['exact_pack_checks_passed']:
        raise RuntimeError('Final package review is incomplete')
    manifest = json.loads((candidate/'manifest.json').read_text())
    if manifest != FILES: raise RuntimeError('The downloaded artifact is not the reviewed artifact')
    for side, files in FILES.items():
        if set(files) != set(BASELINE[side]['files']): raise RuntimeError('Unexpected web file set')
        for name, expected in files.items(): verify((candidate/side/name).read_bytes(), expected)
    tasks = [(side, name, expected) for side, info in BASELINE.items() for name, expected in info['files'].items()]
    def preserve(task):
        side, name, expected = task
        data = fetch(side, name); verify(data, expected)
        dest = rollback/side/name; dest.parent.mkdir(parents=True, exist_ok=True); dest.write_bytes(data)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool: list(pool.map(preserve, tasks))
    for side, files in FILES.items():
        dest = site/('dev' if side == 'dev' else '')
        dest.mkdir(parents=True, exist_ok=True)
        for name in files: shutil.copyfile(candidate/side/name, dest/name)
    (site/'.nojekyll').write_text('')
    print('Prepared the exact reviewed LIVE and DEV packages; all previous public bytes retained')

def verify_public():
    pending = [(side, name, expected) for side, files in FILES.items() for name, expected in files.items()]
    for attempt in range(10):
        remaining = []
        for side, name, expected in pending:
            try: verify(fetch(side, name), expected)
            except Exception: remaining.append((side, name, expected))
        pending = remaining
        if not pending:
            print('All 18 public files verified against the inspected packages'); return
        if attempt < 9: time.sleep(10)
    raise RuntimeError('Public files did not converge to the reviewed release: '+str([(s,n) for s,n,_ in pending]))

if sys.argv[1] == 'prepare': prepare(*map(Path, sys.argv[2:5]))
elif sys.argv[1] == 'verify': verify_public()
else: raise SystemExit('Expected prepare or verify')
