"""Apply only wardrobe presentation resources to each verified public baseline."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import re
import struct
import sys
import urllib.request

ROOT = Path(__file__).resolve().parent
BASE = json.loads((ROOT / 'baseline.json').read_text())
URL = 'https://corpax88.github.io/Ever-Deeper/'


def identity(data):
    return {'size': len(data), 'sha256': hashlib.sha256(data).hexdigest()}


def download(side, name):
    data = urllib.request.urlopen(URL + ('dev/' if side == 'dev' else '') + name, timeout=120).read()
    assert identity(data) == BASE[side][name], f'Public baseline changed: {side}/{name}'
    return data


def read_pack(data):
    assert data[:4] == b'GDPC' and struct.unpack_from('<I', data, 4)[0] == 4
    assert not (struct.unpack_from('<I', data, 20)[0] & 1), 'Encrypted packs are unsupported'
    base, directory = struct.unpack_from('<QQ', data, 24)
    count = struct.unpack_from('<I', data, directory)[0]
    cursor = directory + 4
    entries = {}
    for _ in range(count):
        length = struct.unpack_from('<I', data, cursor)[0]
        cursor += 4
        name = data[cursor:cursor + length].rstrip(b'\0').decode()
        cursor += length
        offset, size = struct.unpack_from('<QQ', data, cursor)
        digest = data[cursor + 16:cursor + 32]
        flags = struct.unpack_from('<I', data, cursor + 32)[0]
        cursor += 36
        payload = data[base + offset:base + offset + size]
        assert hashlib.md5(payload).digest() == digest, name
        assert name not in entries
        entries[name] = (offset, size, digest, flags, payload)
    return base, entries


def select_wardrobe(entries):
    prefixes = ('scripts/ui/commerce_panel.', 'scripts/ui/wardrobe_portrait.',
                'scripts/ui/wardrobe_portrait_cloth.', 'assets/hero/dad/wardrobe/')
    selected = {name for name in entries if name.removeprefix('res://').startswith(prefixes)}
    # Resolve Godot export remaps and imported texture paths from their own metadata.
    pending = list(selected)
    while pending:
        name = pending.pop()
        if not name.endswith(('.import', '.remap')):
            continue
        for target in re.findall(r'"res://([^"]+)"', entries[name][4].decode()):
            found = target if target in entries else 'res://' + target
            if found in entries and found not in selected:
                selected.add(found)
                pending.append(found)
    assert any('commerce_panel.gdc' in name for name in selected)
    assert any('wardrobe_portrait.gdc' in name for name in selected)
    assert any(name.endswith('.ctex') for name in selected)
    assert len(selected) < 20, sorted(selected)
    return {name: entries[name] for name in selected}


def patch_pack(original, replacement):
    base, entries = read_pack(original)
    result = bytearray(original)
    changed, added = [], []
    for name, item in sorted(replacement.items()):
        if name in entries and entries[name][4] == item[4]:
            continue
        (changed if name in entries else added).append(name)
        result.extend(b'\0' * (-len(result) % 16))
        offset = len(result) - base
        result.extend(item[4])
        entries[name] = (offset, item[1], item[2], item[3], item[4])
    result.extend(b'\0' * (-len(result) % 16))
    directory = len(result)
    result.extend(struct.pack('<I', len(entries)))
    for name, (offset, size, digest, flags, _) in sorted(entries.items()):
        encoded = name.encode() + b'\0'
        encoded += b'\0' * (-len(encoded) % 4)
        result.extend(struct.pack('<I', len(encoded)) + encoded)
        result.extend(struct.pack('<QQ', offset, size) + digest + struct.pack('<I', flags))
    struct.pack_into('<Q', result, 32, directory)
    _, verified = read_pack(result)
    _, previous = read_pack(original)
    assert set(verified) == set(previous) | set(replacement)
    assert all(verified[n][4] == item[4] for n, item in replacement.items())
    assert all(verified[n][4] == item[4] for n, item in previous.items() if n not in replacement)
    return bytes(result), {'changed': changed, 'added': added, 'removed': [],
                           'unchanged_resources': len(previous) - len(changed)}


def fetch_baseline(out, sides=('live', 'dev')):
    tasks = [(side, name) for side in sides for name in BASE[side]]
    def save(task):
        side, name = task
        path = out / side / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(download(side, name))
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(save, tasks))


def build(exported, out):
    _, exported_entries = read_pack(exported.read_bytes())
    replacement = select_wardrobe(exported_entries)
    fetch_baseline(out)
    manifest, audit = {}, {}
    for side in BASE:
        pack = out / side / 'index.pck'
        patched, audit[side] = patch_pack(pack.read_bytes(), replacement)
        pack.write_bytes(patched)
        html = out / side / 'index.html'
        text = html.read_text()
        text, count = re.subn(r'("index\.pck"\s*:\s*)\d+', lambda m: m[1] + str(len(patched)), text)
        assert count == 1, 'Godot loader package size must be updated exactly once'
        html.write_text(text)
        manifest[side] = {n: identity((out / side / n).read_bytes()) for n in BASE[side]}
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (out / 'resource-audit.json').write_text(json.dumps(audit, indent=2) + '\n')
    print(json.dumps(audit, indent=2))


if __name__ == '__main__':
    if sys.argv[1] == 'build':
        build(Path(sys.argv[2]), Path(sys.argv[3]))
    elif sys.argv[1] == 'baseline':
        fetch_baseline(Path(sys.argv[3]), (sys.argv[2],))
    else:
        raise SystemExit('Expected build EXPORTED_PCK OUTPUT or baseline SIDE OUTPUT')
