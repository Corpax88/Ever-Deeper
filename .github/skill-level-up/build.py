from pathlib import Path
import json,sys,struct,hashlib,re,shutil,os
from pack_helpers import unpack,identity
src,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
root=Path(__file__).resolve().parents[2]
manifest=json.loads((src/'manifest.json').read_text())
assert all(identity(src/n)==v for n,v in manifest.items())
assert manifest==json.loads((Path(__file__).parent/'baseline.json').read_text())
assert json.loads((src/'focus-build.json').read_text())['source']=='4811f56ca5b524980cebe4ded68f3bcfe2389488'
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
p='scripts/ui/premium_menu.gd';script(p,(root/'.github/graphics-settings/dev-premium_menu.gd').read_text().replace('1.0.0-dev.15.13','1.0.0-dev.15.15'))
for p,local in [('scripts/state/run_state.gd','run_state.gd'),('scripts/ui/achievement_toast.gd','achievement_toast.gd')]:
 script(p,(Path(__file__).parent/local).read_text())
# Reload the exact unchanged main source so its compiled preload resolves the new toast script.
script('scripts/main.gd',(root/'scripts/main.gd').read_text())
replace['scripts/ui/skill_level_toast.gd']=(Path(__file__).parent/'skill_level_toast.gd').read_bytes()
p='scripts/qa/suites/fps_review.gd';text=(root/p).read_text()
extra=(Path(__file__).parent/'fixture.gd').read_text()
text=text.replace('func _command(data: Dictionary) -> void:', 'func _original_command(data: Dictionary) -> void:')
text=text.replace('func _frame() -> void:\n','func _frame() -> void:\n\t_skill_frame()\n')
script(p,text+'\n'+extra)
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
(out/'focus-build.json').write_text(json.dumps({'baseline':manifest,'replaced':list(replace),'source':os.environ['GITHUB_SHA'],'purpose':'DEV15.15 earned skill level notices; preserve approved DEV15.14 hero'},indent=2))
