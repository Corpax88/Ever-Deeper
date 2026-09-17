"""Bind the immutable exports and original ordinary-save fixture, without running them."""
import argparse
import hashlib
import json
import struct
from pathlib import Path

root = Path(__file__).resolve().parent
sha = lambda b: hashlib.sha256(b).hexdigest()
p = argparse.ArgumentParser()
p.add_argument('--baseline', type=Path, required=True)
p.add_argument('--candidate', type=Path, required=True)
p.add_argument('--fixture', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
pins = json.loads((root / 'pins.json').read_text())
report = {'packages': {}, 'fixture': pins['fixture'], 'helpers': {}, 'scope': 'binding/parse preparation only; no browser launch'}
for kind in ['baseline', 'candidate']:
    directory, pin = getattr(a, kind), pins[kind]
    b = (directory / 'artifact-identity.json').read_bytes()
    assert sha(b) == pin['identity_sha256'], kind
    identity = json.loads(b)
    assert identity['sourceSha'] == pin['source'] and identity['runId'] == pin['run_id'] and identity['runAttempt'] == '1'
    assert identity['devFiles'] == pin['files'] and len(pin['files']) == 9
    for name, expected in pin['files'].items():
        data = (directory / name).read_bytes()
        assert len(data) == expected['size'] and sha(data) == expected['sha256'], (kind, name)
    html = (directory / 'index.html').read_text()
    assert '"args":[]' in html and '"focusCanvas":true' in html
    js = (directory / 'index.js').read_text()
    assert 'DB_VERSION:21,DB_STORE_NAME:"FILE_DATA"' in js
    assert 'fileStore.createIndex("timestamp","timestamp",{unique:false})' in js
    report['packages'][kind] = pin
fixture = a.fixture.read_bytes()
assert len(fixture) == pins['fixture']['size'] and sha(fixture) == pins['fixture']['sha256']
assert struct.unpack_from('<III', fixture) == (0x52445645, 3, len(fixture)-44)
assert hashlib.sha256(fixture[44:]).digest() == fixture[12:44]
for name, expected in pins['helpers'].items():
    actual = sha((root / name).read_bytes())
    assert actual == expected
    report['helpers'][name] = actual
report['source_files'] = {f.name: {'bytes': f.stat().st_size, 'sha256': sha(f.read_bytes())} for f in sorted(root.iterdir()) if f.is_file()}
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(report, indent=2)+'\n')
print('Immutable exports, fixture, IDBFS shape and original helpers verified')
