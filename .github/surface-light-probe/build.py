from pathlib import Path
import json,sys,struct,hashlib,re,shutil,os
from pack_helpers import unpack,identity
src,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
root=Path(__file__).resolve().parents[2]
manifest=json.loads((src/'manifest.json').read_text())
assert all(identity(src/n)==v for n,v in manifest.items())
assert manifest==json.loads((Path(__file__).parent/'baseline.json').read_text())
assert json.loads((src/'focus-build.json').read_text())['source']=='08af3b8526b88ba2764fa36860d52d7e0eba5bbe'
assert 'this._audioBuffer.duration>10' in (src/'index.js').read_text()
for n in manifest: shutil.copyfile(src/n,out/n)
data=bytearray((src/'index.pck').read_bytes());base,entries=unpack(data);before=dict(entries);replace={}
def script(path,text):
    replace[path]=text.encode();remap=path+'.remap'
    assert remap in entries
    off,size,*_=entries[remap];old=bytes(data[base+off:base+off+size]).decode()
    target=re.search(r'path="res://([^\"]+)"',old)[1]
    replace[remap]=('[remap]\npath="res://'+path+'"\n').encode()
    if target.endswith('.gd'): replace[target]=text.encode()
p='scripts/ui/premium_menu.gd';script(p,(root/'.github/graphics-settings/dev-premium_menu.gd').read_text().replace('1.0.0-dev.15.13','1.0.0-dev.15.16'))
for p,local in [('scripts/dev/render_probe.gd','render_probe.gd'),('scripts/dev/developer_menu.gd','developer_menu.gd')]:
 script(p,(Path(__file__).parent/local).read_text())
p='scripts/qa/suites/fps_review.gd';script(p,(Path(__file__).parent/'fixture.gd').read_text())
for name,raw in replace.items():
    data+=b'\0'*(-len(data)%32);entries[name]=(len(data)-base,len(raw),hashlib.md5(raw).digest(),0);data+=raw
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(entries))
for name,(off,size,md5,flags) in sorted(entries.items()):
    key=name.encode();key+=b'\0'*(-len(key)%4);data+=struct.pack('<I',len(key))+key+struct.pack('<QQ16sI',off,size,md5,flags)
_,after=unpack(data);assert all(after[n]==v for n,v in before.items() if n not in replace)
(out/'index.pck').write_bytes(data)
html=(out/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);c['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):])
(out/'manifest.json').write_text(json.dumps({n:identity(out/n) for n in manifest}))
(out/'focus-build.json').write_text(json.dumps({'baseline':manifest,'replaced':list(replace),'source':os.environ['GITHUB_SHA'],'purpose':'DEV15.16 enables existing opt-in light diagnostic on surface; no FPS-fix claim'},indent=2))
