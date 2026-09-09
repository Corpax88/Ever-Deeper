"""Publish the exact inspected wardrobe packages, retaining both rollback builds."""
import concurrent.futures
import json
from pathlib import Path
import shutil
import sys
import time
import urllib.request

from prepare import BASE, ROOT, URL, fetch_baseline, identity


def review():
    data = json.loads((ROOT / 'review.json').read_text())
    assert data['visual_reviewed'] and data['package_checks_passed'], 'Review incomplete'
    return data


def prepare(candidate, site, rollback):
    accepted = review()
    manifest = json.loads((candidate / 'manifest.json').read_text())
    assert manifest == accepted['files'], 'Wrong candidate artifact'
    audit = json.loads((candidate / 'resource-audit.json').read_text())
    assert audit == accepted['resource_audit'], 'Wrong resource audit'
    for side in BASE:
        assert set(manifest[side]) == set(BASE[side]), 'Unexpected web files'
        assert not audit[side]['removed'], 'Resources were removed'
        for name, expected in manifest[side].items():
            assert identity((candidate / side / name).read_bytes()) == expected, f'Changed candidate: {side}/{name}'
    # A concurrent game publication aborts this job before staging or deployment.
    fetch_baseline(rollback)
    site.mkdir(parents=True, exist_ok=True)
    for side in BASE:
        destination = site / 'dev' if side == 'dev' else site
        destination.mkdir(parents=True, exist_ok=True)
        for name in manifest[side]:
            shutil.copyfile(candidate / side / name, destination / name)
    (site / '.nojekyll').write_text('')
    print('Reviewed wardrobe packages staged; both previous builds preserved')


def verify():
    accepted = review()
    pending = [(side, name, info) for side, files in accepted['files'].items() for name, info in files.items()]
    def matches(item):
        side, name, info = item
        try:
            data = urllib.request.urlopen(URL + ('dev/' if side == 'dev' else '') + name, timeout=120).read()
            return identity(data) == info
        except Exception:
            return False
    for attempt in range(10):
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
            results = list(pool.map(matches, pending))
        pending = [item for item, passed in zip(pending, results) if not passed]
        if not pending:
            print('All 18 public DEV/LIVE files match the inspected wardrobe packages')
            return
        time.sleep(10)
    raise RuntimeError('Public files did not match: ' + str([(s, n) for s, n, _ in pending]))


if __name__ == '__main__':
    if sys.argv[1] == 'prepare':
        prepare(*map(Path, sys.argv[2:5]))
    elif sys.argv[1] == 'verify':
        verify()
    else:
        raise SystemExit('Expected prepare CANDIDATE SITE ROLLBACK or verify')
