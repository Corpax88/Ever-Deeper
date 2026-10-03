"""Build the treasury atmosphere candidate over the immutable DEV15.50 package."""
from pathlib import Path
import hashlib,json,re,shutil,struct,sys
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'.github/five-mods'))
from pack_helpers import unpack,identity
src,out=map(Path,sys.argv[1:3])
assert identity(src/'index.pck')=={'size':325826654,'sha256':'1a38e1cba12cc2d2adc6a7a879fab82a93003b98044e5a9f94741f848000469a'}
out.mkdir(parents=True,exist_ok=True)
for p in src.iterdir():
 if p.is_file() and p.name not in ('manifest.json','build-receipt.json'):shutil.copyfile(p,out/p.name)
original=(src/'index.pck').read_bytes();base,entries=unpack(original)
def raw(n):
 o,s,*_=entries[n];return original[base+o:base+o+s]
changed=['scripts/world/five_drill_mods.gd','scripts/ui/mod_preview_catalog.gd']
replacements={n:(root/n).read_bytes() for n in changed}
for n in changed:
 if n.endswith('.gd'):replacements[n+'.remap']=('[remap]\npath="res://'+n+'"\n').encode()
menu_remap=raw('scripts/ui/premium_menu.gd.remap').decode()
menu_path=re.search(r'path="res://([^\"]+)"',menu_remap)[1]
menu=raw(menu_path).decode();assert menu.count('1.0.0-dev.15.51')==1
replacements[menu_path]=menu.replace('1.0.0-dev.15.51','1.0.0-dev.15.52').encode()
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
(out/'build-receipt.json').write_text(json.dumps({'base_source':'3bf373333fe9ac8fa5e1a58667f358b077df9c5d','baseline_pck_sha256':hashlib.sha256(original).hexdigest(),'kind':'chainbreaker-rock','changed_resources':list(replacements),'unchanged_resources':sum(n not in replacements for n in entries),'all_retained_payloads_verified':True,'files':manifest},indent=2))
print('CHAINBREAKER_PACKAGE_PARITY_VERIFIED',manifest['index.pck'])
