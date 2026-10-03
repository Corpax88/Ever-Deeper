"""Build the treasury atmosphere candidate over the immutable DEV15.50 package."""
from pathlib import Path
import hashlib,json,re,shutil,struct,sys
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'.github/five-mods'))
from pack_helpers import unpack,identity
src,out=map(Path,sys.argv[1:3])
assert identity(src/'index.pck')=={'size':316990798,'sha256':'5dbd8b6428b9ea82fa30895d65d6809928a1595a33aaad6e9af9fd3ad302c82f'}
out.mkdir(parents=True,exist_ok=True)
for p in src.iterdir():
 if p.is_file() and p.name not in ('manifest.json','build-receipt.json'):shutil.copyfile(p,out/p.name)
original=(src/'index.pck').read_bytes();base,entries=unpack(original)
def raw(n):
 o,s,*_=entries[n];return original[base+o:base+o+s]
changed=['scripts/world/treasury_room.gd','scripts/qa/suites/skills_browser_review.gd'] + ['assets/treasury/'+n for n in ['vault-exit-v1.png','slate-floor-v1.png','lantern-pillar-v1.png','low-wall-v1.png']]
replacements={n:(root/n).read_bytes() for n in changed}
for n in changed:
 if n.endswith('.gd'):replacements[n+'.remap']=('[remap]\npath="res://'+n+'"\n').encode()
menu_remap=raw('scripts/ui/premium_menu.gd.remap').decode()
menu_path=re.search(r'path="res://([^\"]+)"',menu_remap)[1]
menu=raw(menu_path).decode();assert menu.count('1.0.0-dev.15.50')==1
replacements[menu_path]=menu.replace('1.0.0-dev.15.50','1.0.0-dev.15.51').encode()
data=bytearray(original[:base]);after={}
for name in sorted(set(entries)|set(replacements)):
 payload=replacements[name] if name in replacements else raw(name);data+=b'\0'*(-len(data)%32)
 after[name]=(len(data)-base,len(payload),hashlib.md5(payload).digest(),0);data+=payload
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(after))
for name,(o,s,d,f) in after.items():
 k=name.encode();k+=b'\0'*(-len(k)%4);data+=struct.pack('<I',len(k))+k+struct.pack('<QQ16sI',o,s,d,f)
nb,verified=unpack(data)
for n,(o,s,d,f) in verified.items():assert bytes(data[nb+o:nb+o+s])==(replacements[n] if n in replacements else raw(n)),n
(out/'index.pck').write_bytes(data)
html=(src/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);config=json.loads(m[1]);assert not config['args'];config['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(config,separators=(',',':'))+html[m.end(1):])
manifest={p.name:identity(p) for p in out.iterdir() if p.is_file() and p.name not in ('manifest.json','build-receipt.json')}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'build-receipt.json').write_text(json.dumps({'base_source':'6ceef595e33e8caf82bd3d6991bbbc69c4d515ca','baseline_pck_sha256':hashlib.sha256(original).hexdigest(),'kind':'treasury-atmosphere','changed_resources':list(replacements),'unchanged_resources':sum(n not in replacements for n in entries),'all_retained_payloads_verified':True,'files':manifest},indent=2))
print('TREASURY_PACKAGE_PARITY_VERIFIED',manifest['index.pck'])
