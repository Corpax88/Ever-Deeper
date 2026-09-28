"""Build diagnostic-only CPU candidates against byte-bound DEV15.16."""
from pathlib import Path
import hashlib, json, os, re, shutil, struct, sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'surface-light-probe'))
from pack_helpers import unpack, identity
import hero_patches, world_candidate

src,out=map(Path,sys.argv[1:]);here=Path(__file__).resolve().parent
manifest=json.loads((here/'baseline.json').read_text())
assert all(identity(src/n)==v for n,v in manifest.items())
out.mkdir(parents=True,exist_ok=False)
for n in manifest: shutil.copyfile(src/n,out/n)
data=bytearray((src/'index.pck').read_bytes());base,entries=unpack(data);before=dict(entries);replacements={}
assert 'override.cfg' not in entries, 'Parked depth-prepass must stay absent'
def raw(name):
 off,size,*_=entries[name];return bytes(data[base+off:base+off+size])
def script(name,source):
 remap=name+'.remap';assert remap in entries
 target=re.search(r'path="res://([^\"]+)"',raw(remap).decode())[1]
 replacements[name]=source.encode()
 replacements[remap]=('[remap]\npath="res://'+name+'"\n').encode()
 if target.endswith('.gd'): replacements[target]=source.encode()
script(hero_patches.EXPECTED['rig'][0],hero_patches.transform((here/'rig-original.gd').read_text(),'rig'))
script(hero_patches.EXPECTED['contact'][0],hero_patches.transform((here/'contact-original.gd').read_text(),'contact'))
assert hashlib.sha256(raw(world_candidate.ORIGINAL_REMAP_PATH)).hexdigest()==world_candidate.ORIGINAL_REMAP_SHA256
assert hashlib.sha256(raw(world_candidate.ORIGINAL_ACTIVE_PATH)).hexdigest()==world_candidate.ORIGINAL_ACTIVE_SHA256
script(world_candidate.SOURCE_PATH,world_candidate.transform((here/'world-original.gd').read_text()))
script('scripts/qa/suites/fps_review.gd',(here/'fixture.gd').read_text()+'\n'+(here/'hero_helpers.gd').read_text())
replacements['scripts/qa/suites/round2_native_base.gd']=(here/'fixture-base.gd').read_bytes()
replacements['scripts/qa/suites/round2_world_fixture.gd']=(here/'world_fixture.gd').read_bytes()
for n,b in replacements.items():
 data+=b'\0'*(-len(data)%32);entries[n]=(len(data)-base,len(b),hashlib.md5(b).digest(),0);data+=b
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(entries))
for n,(off,size,digest,flags) in sorted(entries.items()):
 key=n.encode();key+=b'\0'*(-len(key)%4);data+=struct.pack('<I',len(key))+key+struct.pack('<QQ16sI',off,size,digest,flags)
_,after=unpack(data);assert all(after[n]==v for n,v in before.items() if n not in replacements)
(out/'index.pck').write_bytes(data)
html=(out/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);c['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):])
(out/'manifest.json').write_text(json.dumps({n:identity(out/n) for n in manifest},indent=2))
(out/'audit-build.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'baseline':manifest,'replaced':list(replacements),'unchanged_resources':sum(n not in replacements for n in before),'scope':'QA-only same-source baseline/candidate comparisons; no production or physical-phone acceptance','parked_depth_prepass_unchanged':True},indent=2))
print('Round2 diagnostic package verified')
