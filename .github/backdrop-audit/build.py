"""Test reversible zero-alpha backdrop geometry in immutable DEV15.16."""
from pathlib import Path
import hashlib,json,os,re,shutil,struct,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'surface-light-probe'))
from pack_helpers import unpack,identity
src,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
here=Path(__file__).resolve().parent
manifest=json.loads((src/'manifest.json').read_text())
assert manifest==json.loads((here/'baseline.json').read_text())
assert all(identity(src/n)==v for n,v in manifest.items())
assert json.loads((src/'focus-build.json').read_text())['source']=='0225855d5b243fadf75c5267898ac2cd6edb3d0b'
for n in manifest:shutil.copyfile(src/n,out/n)
data=bytearray((src/'index.pck').read_bytes());base,entries=unpack(data);before=dict(entries)
p='scripts/qa/suites/fps_review.gd';remap=p+'.remap';off,size,*_=entries[remap]
target=re.search(r'path="res://([^\"]+)"',bytes(data[base+off:base+off+size]).decode())[1]
raw=(here/'fixture.gd').read_bytes()
replace={p:raw,remap:('[remap]\npath="res://'+p+'"\n').encode()}
if target.endswith('.gd'):replace[target]=raw
replace['scripts/qa/backdrop_crop_probe.gd']=(here/'backdrop_crop_probe.gd').read_bytes()
for n,raw in replace.items():
 data+=b'\0'*(-len(data)%32);entries[n]=(len(data)-base,len(raw),hashlib.md5(raw).digest(),0);data+=raw
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(entries))
for n,(off,size,md5,flags) in sorted(entries.items()):
 key=n.encode();key+=b'\0'*(-len(key)%4);data+=struct.pack('<I',len(key))+key+struct.pack('<QQ16sI',off,size,md5,flags)
_,after=unpack(data);assert all(after[n]==v for n,v in before.items() if n not in replace)
(out/'index.pck').write_bytes(data)
html=(out/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);c['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):])
(out/'manifest.json').write_text(json.dumps({n:identity(out/n) for n in manifest},indent=2))
(out/'audit-build.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'baseline':manifest,'replaced':list(replace),'unchanged_resources':len(before)-len(replace),'runtime_change':'None; QA reversibly crops only zero-alpha backdrop geometry'},indent=2))
