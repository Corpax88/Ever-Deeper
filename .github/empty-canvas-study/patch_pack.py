"""QA-only: append two source scripts to an immutable, verified DEV15.9 PCK.

Preserves all original resource bytes. Only the FPS fixture remap is replaced.
Format follows Godot 4.7.2 core/io/{file_access_pack,pck_packer}.cpp.
Rejects encryption, sparse packs, unknown versions and unexpected file flags.
"""
import hashlib, json, os, re, shutil, struct, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
def identity(p):
    return {'size':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}

def unpack(data):
    magic, version, major, minor, patch, flags, base, directory = struct.unpack_from('<6I2Q', data)
    assert magic == 0x43504447 and version in (3,4), (magic, version)
    assert flags == 2, ('Unexpected pack flags', flags)
    assert (major,minor,patch) == (4,7,2), (major,minor,patch)
    count, = struct.unpack_from('<I',data,directory)
    assert 0 < count < 100000
    pos = directory + 4
    entries = {}
    for _ in range(count):
        length, = struct.unpack_from('<I',data,pos); pos += 4
        assert 0 < length < 4096
        name = data[pos:pos+length].rstrip(b'\0').decode('utf8'); pos += length
        offset, size, digest, file_flags = struct.unpack_from('<QQ16sI',data,pos); pos += 36
        assert file_flags == 0 and name not in entries, (name,file_flags)
        assert base <= base+offset <= base+offset+size <= len(data), name
        raw = data[base+offset:base+offset+size]
        assert hashlib.md5(raw).digest() == digest, ('Resource hash mismatch',name)
        entries[name] = (offset,size,digest,file_flags)
    return base, entries

def main(source, work):
    expected = json.loads((ROOT/'.github/empty-canvas-study/baseline.json').read_text())
    assert all(identity(source/n) == want for n,want in expected.items()), 'Original artifact differs from exact public DEV15.9'
    work.mkdir(parents=True,exist_ok=False)
    candidate = work/'candidate'; candidate.mkdir()
    for name in expected: shutil.copyfile(source/name,candidate/name)
    pck = candidate/'index.pck'
    data = bytearray(pck.read_bytes())
    base, entries = unpack(data)
    before = dict(entries)
    remap = 'scripts/qa/suites/fps_review.gd.remap'
    assert remap in entries, 'Expected exported FPS fixture remap is missing'
    offset,size,_,_ = entries[remap]
    old_remap = bytes(data[base+offset:base+offset+size]).decode()
    assert '[remap]' in old_remap and '.gdc' in old_remap, old_remap
    fixture = 'scripts/qa/suites/fps_review_occupancy.gd'
    helper = 'scripts/qa/light_cost_probe.gd'
    assert fixture not in entries and helper not in entries
    replacements = {
        remap: ('[remap]\npath="res://'+fixture+'"\n').encode(),
        fixture: (ROOT/'scripts/qa/suites/fps_review.gd').read_bytes(),
        helper: (ROOT/helper).read_bytes(),
    }
    revised_scripts = ['scripts/lighting/cave_light_occluders.gd', 'scripts/world/mossvein_mine.gd', 'scripts/qa/overhaul_qa.gd', 'scripts/dev/visual_capture_driver.gd', 'scripts/qa/suites/smoke.gd', 'scripts/qa/suites/crusher.gd', 'scripts/qa/suites/mole_autonomy.gd', 'scripts/qa/suites/world_fixtures.gd']
    replaced_remaps = [remap]
    added_scripts = [fixture,helper]
    for script in revised_scripts:
        old_mapping = script+".remap"
        assert old_mapping in entries, old_mapping
        new_script = script[:-3]+"_revision_qa.gd"
        assert new_script not in entries
        replacements[old_mapping] = ('[remap]\npath="res://'+new_script+'"\n').encode()
        replacements[new_script] = (ROOT/script).read_bytes()
        replaced_remaps.append(old_mapping)
        added_scripts.append(new_script)
    for name,raw in replacements.items():
        data += b'\0' * (-len(data)%32)
        entries[name] = (len(data)-base,len(raw),hashlib.md5(raw).digest(),0)
        data += raw
    data += b'\0' * (-len(data)%32)
    struct.pack_into('<Q',data,32,len(data))
    data += struct.pack('<I',len(entries))
    for name,(offset,size,digest,flags) in sorted(entries.items()):
        path = name.encode(); path += b'\0' * (-len(path)%4)
        data += struct.pack('<I',len(path))+path+struct.pack('<QQ16sI',offset,size,digest,flags)
    newbase, after = unpack(data)
    assert newbase == base
    assert all(after[n] == v for n,v in before.items() if n not in replacements)
    pck.write_bytes(data)
    html = (candidate/'index.html').read_text()
    match = re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html); assert match
    config = json.loads(match[1]); config['fileSizes']['index.pck'] = len(data)
    html = html[:match.start(1)]+json.dumps(config,separators=(',',':'))+html[match.end(1):]
    (candidate/'index.html').write_text(html)
    files = {n:identity(candidate/n) for n in expected}
    (candidate/'manifest.json').write_text(json.dumps(files,indent=2)+'\n')
    (work/'build.json').write_text(json.dumps({
        'source_commit':os.environ.get('GITHUB_SHA'),'method':'QA-only append to immutable original PCK',
        'original_run':36043919958,'original_files':expected,'files':files,
        'original_resource_count':len(before),'unchanged_resource_count':len(before)-len(replaced_remaps),
        'replaced_remaps':replaced_remaps,'original_remap':old_remap,'added_source_scripts':added_scripts,
        'all_original_resource_md5_verified':True,'physical_iphone_verified':False,
    },indent=2)+'\n')
    print('QA_PCK_PATCH_VERIFIED',len(before)-len(replaced_remaps),'unchanged resources')

if __name__ == '__main__': main(Path(sys.argv[1]),Path(sys.argv[2]))
