"""Inspect the exact publication/rollback archives; verify PCK entry bytes as well as names."""
import argparse
import hashlib
import json
import mmap
from pathlib import Path
import shutil
import struct
import tarfile
import zipfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('before_zip', type=Path, help='v0.46.8 rollback artifact ZIP')
parser.add_argument('after_zip', type=Path, help='v0.46.9 Pages artifact ZIP')
parser.add_argument('output', type=Path, help='Directory for extracted files and comparison.json')
args = parser.parse_args()
out = args.output
out.mkdir(parents=True, exist_ok=True)
names = ['index.html', 'index.js', 'index.wasm', 'index.pck',
         'index.audio.position.worklet.js', 'index.audio.worklet.js',
         'index.icon.png', 'index.png', 'index.apple-touch-icon.png']

with zipfile.ZipFile(args.before_zip) as archive:
    for side in ['live', 'dev']:
        for name in names:
            p = out / 'before' / side / name
            p.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(f'{side}/{name}') as source, p.open('wb') as dest:
                shutil.copyfileobj(source, dest)

with zipfile.ZipFile(args.after_zip) as archive:
    tar_name = next(n for n in archive.namelist() if n.endswith('.tar'))
    with archive.open(tar_name) as stream, tarfile.open(fileobj=stream, mode='r|') as tar:
        for member in tar:
            relative = member.name.removeprefix('./')
            side = 'dev' if relative.startswith('dev/') else 'live'
            name = relative.removeprefix('dev/')
            if not member.isfile() or name not in names:
                continue
            p = out / 'after' / side / name
            p.parent.mkdir(parents=True, exist_ok=True)
            with tar.extractfile(member) as source, p.open('wb') as dest:
                shutil.copyfileobj(source, dest)


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def inventory(path):
    # Same PCK v4 directory parser used by .github/pet-reactions-v0460/pack_delta.py.
    entries = {}
    with path.open('rb') as stream, mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ) as data:
        assert data[:4] == b'GDPC' and struct.unpack_from('<I', data, 4)[0] == 4
        base, directory = struct.unpack_from('<QQ', data, 24)
        count = struct.unpack_from('<I', data, directory)[0]
        position = directory + 4
        for _ in range(count):
            size = struct.unpack_from('<I', data, position)[0]
            position += 4
            name = data[position:position + size].rstrip(b'\0').decode()
            position += size
            offset, length = struct.unpack_from('<QQ', data, position)
            position += 16
            expected_md5 = data[position:position + 16]
            flags = struct.unpack_from('<I', data, position + 16)[0]
            position += 20
            payload = data[base + offset:base + offset + length]
            assert len(payload) == length and hashlib.md5(payload).digest() == expected_md5, name
            assert name not in entries
            entries[name] = {'size': length, 'sha256': hashlib.sha256(payload).hexdigest(), 'flags': flags}
        engine = list(struct.unpack_from('<III', data, 8))
    return {'engine': engine, 'entries': entries}


assert sha(out / 'before/live/index.pck') == 'd95621dcda43a2245aa0d21be60c1a309383a19a0f1f4b92d2ee34e86cbcf3a2'
report = {'before_version': '0.46.8', 'after_version': '0.46.9',
          'scope': 'Actual releases: after includes the separate v0.46.9 performance changes, not only cleanup.',
          'artifacts': {'before': 10030946553, 'after': 10030951631}, 'flavors': {}}
for side in ['live', 'dev']:
    a = inventory(out / 'before' / side / 'index.pck')
    b = inventory(out / 'after' / side / 'index.pck')
    ae, be = a['entries'], b['entries']
    common = ae.keys() & be.keys()
    changed = {n: {'before': ae[n], 'after': be[n]} for n in sorted(common) if ae[n] != be[n]}
    textures = {n for n in ae.keys() | be.keys() if n.endswith(('.ctex', '.stex', '.png', '.jpg', '.webp'))}
    texture_changes = sorted(n for n in textures if ae.get(n) != be.get(n))
    result = {'before_engine': a['engine'], 'after_engine': b['engine'],
              'before_count': len(ae), 'after_count': len(be),
              'identical_entries': len(common) - len(changed),
              'changed': changed, 'added': sorted(be.keys() - ae.keys()), 'removed': sorted(ae.keys() - be.keys()),
              'texture_count': len(textures), 'texture_changes': texture_changes,
              'before_files': {n: sha(out / 'before' / side / n) for n in names},
              'after_files': {n: sha(out / 'after' / side / n) for n in names}}
    report['flavors'][side] = result
    print(side, json.dumps({k: v for k, v in result.items() if k not in ['changed', 'before_files', 'after_files']}))
    print('changed entries:', list(changed))
(out / 'comparison.json').write_text(json.dumps(report, indent=2) + '\n')
