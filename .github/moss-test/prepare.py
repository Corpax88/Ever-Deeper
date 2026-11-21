import hashlib,json,os,re,struct,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.github/five-mods'))
from pack_helpers import unpack,identity
src,out=map(Path,sys.argv[1:3]);out.mkdir(parents=True,exist_ok=True)
qa=False
original=src.read_bytes()
assert len(original)==327930210
base,entries=unpack(original)
def raw(n):
 o,s,*_=entries[n];return original[base+o:base+o+s]
overrides=['scripts/world/surface_world.gd','scripts/player/native_worn/native_surface.gdshader','shaders/moss_trail.gdshader','shaders/moss_trail.tres','scenes/surface/surface_world.tscn','scenes/surface/surface_parallax.tscn']
replacements={n:(ROOT/n).read_bytes() for n in overrides}
for n in overrides:
 if n+'.remap' in entries: replacements[n+'.remap']=('[remap]\npath="res://'+n+'"\n').encode()
for png in (ROOT/'assets/surface/painted').glob('*.png'):
 imp=Path(str(png)+'.import')
 path=re.search(r'^path="res://([^"]+)"',imp.read_text(),re.M)[1]
 for file in [imp,ROOT/path]:
  replacements[file.relative_to(ROOT).as_posix()]=file.read_bytes()
data=bytearray(original[:base]);after={}
for name in sorted(set(entries)|set(replacements)):
 payload=replacements.get(name,raw(name) if name in entries else b'')
 data+=b'\0'*(-len(data)%32);after[name]=(len(data)-base,len(payload),hashlib.md5(payload).digest(),0);data+=payload
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(after))
for name,(o,s,d,f) in after.items():
 key=name.encode();key+=b'\0'*(-len(key)%4);data+=struct.pack('<I',len(key))+key+struct.pack('<QQ16sI',o,s,d,f)
b,e=unpack(data)
for n,(o,s,*_) in e.items(): assert data[b+o:b+o+s]==replacements.get(n,raw(n) if n in entries else b'')
p=out/'index.pck';p.write_bytes(data)
assert identity(p)=={'size':len(data),'sha256':hashlib.sha256(data).hexdigest()}
(out/'receipt.json').write_text(json.dumps({'baseline_sha256':hashlib.sha256(original).hexdigest(),'overrides':overrides,'retained_verified':True,'pck':identity(p)},indent=2))
# Web shell and engine bytes are copied unchanged from the same immutable artifact.
web=['index.html','index.js','index.wasm','index.pck','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js']
import shutil
if (src.parent/'index.html').exists():
 for n in web:
  if n!='index.pck': shutil.copyfile(src.parent/n,out/n)
 html=(out/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html)
 cfg=json.loads(m[1]);assert not cfg['args'];cfg['fileSizes']['index.pck']=len(data)
 (out/'index.html').write_text(html[:m.start(1)]+json.dumps(cfg,separators=(',',':'))+html[m.end(1):])
 manifest={n:identity(out/n) for n in web}
 (out/'manifest.json').write_text(json.dumps(manifest,indent=2))
 (out/'qa-build-receipt.json').write_text(json.dumps({'baseline_pck':identity(src),'baseline_source':'0016ba09ad62c33c6f076c4c4f05200262ee99c2','qa_source':os.environ.get('GITHUB_SHA'),'overrides':overrides,'production':not qa,'version':'1.0.0-dev.15.61','replaced':list(replacements),'retained_payloads_verified':True,'files':manifest},indent=2))
print(identity(p))
