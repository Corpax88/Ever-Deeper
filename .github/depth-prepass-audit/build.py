"""Two byte-bound DEV15.16 packages; candidate only disables web depth prepass."""
from pathlib import Path
import hashlib, json, os, re, shutil, struct, sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'surface-light-probe'))
from pack_helpers import unpack, identity

src, out = map(Path, sys.argv[1:])
here = Path(__file__).resolve().parent
manifest = json.loads((src/'manifest.json').read_text())
assert manifest == json.loads((here.parent/'native-gpu-audit/baseline.json').read_text())
assert all(identity(src/n) == v for n, v in manifest.items())
assert json.loads((src/'focus-build.json').read_text())['source'] == '0225855d5b243fadf75c5267898ac2cd6edb3d0b'
original = (src/'index.pck').read_bytes()
base, original_entries = unpack(original)
assert 'override.cfg' not in original_entries
p = 'scripts/qa/suites/fps_review.gd'
remap = p+'.remap'
off, size, *_ = original_entries[remap]
target = re.search(r'path="res://([^\"]+)"', original[base+off:base+off+size].decode())[1]
fixture = (here/'fixture.gd').read_bytes()
common = {p: fixture, remap: ('[remap]\npath="res://'+p+'"\n').encode(),
          'scripts/qa/suites/native_audit_base.gd': (here.parent/'native-gpu-audit/fixture.gd').read_bytes()}
assert 'scripts/qa/suites/native_audit_base.gd' not in original_entries
if target.endswith('.gd'): common[target] = fixture
receipts = {}
for label in ['baseline', 'candidate']:
    dest = out/label
    dest.mkdir(parents=True, exist_ok=False)
    for n in manifest: shutil.copyfile(src/n, dest/n)
    data = bytearray(original)
    entries = dict(original_entries)
    replace = dict(common)
    if label == 'candidate':
        replace['override.cfg'] = b'config_version=5\n[rendering]\ndriver/depth_prepass/enable.web=false\n'
    for n, raw in replace.items():
        data += b'\0'*(-len(data)%32)
        entries[n] = (len(data)-base, len(raw), hashlib.md5(raw).digest(), 0)
        data += raw
    struct.pack_into('<Q', data, 32, len(data))
    data += struct.pack('<I', len(entries))
    for n, (offset, length, digest, flags) in sorted(entries.items()):
        key = n.encode(); key += b'\0'*(-len(key)%4)
        data += struct.pack('<I', len(key))+key+struct.pack('<QQ16sI', offset, length, digest, flags)
    _, after = unpack(data)
    assert all(after[n] == v for n, v in original_entries.items() if n not in replace)
    (dest/'index.pck').write_bytes(data)
    html = (dest/'index.html').read_text()
    m = re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});', html)
    config = json.loads(m[1]); config['fileSizes']['index.pck'] = len(data)
    (dest/'index.html').write_text(html[:m.start(1)]+json.dumps(config,separators=(',',':'))+html[m.end(1):])
    files = {n: identity(dest/n) for n in manifest}
    (dest/'manifest.json').write_text(json.dumps(files,indent=2))
    receipts[label] = {'files': files, 'replaced': list(replace),
                       'unchanged_original_resources': sum(n not in replace for n in original_entries),
                       'all_original_resource_hashes_verified': True}
(out/'audit-build.json').write_text(json.dumps({'source': os.environ.get('GITHUB_SHA'),
    'baseline_source': '0225855d5b243fadf75c5267898ac2cd6edb3d0b',
    'baseline': manifest, 'variants': receipts,
    'only_candidate_runtime_change': 'override.cfg: rendering/driver/depth_prepass/enable.web=false'},indent=2))
