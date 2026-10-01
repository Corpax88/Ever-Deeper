from pathlib import Path
import hashlib,json,os,re,shutil,struct,sys
from pack_helpers import unpack,identity
root=Path(__file__).resolve().parents[2];here=Path(__file__).resolve().parent
src,out=map(Path,sys.argv[1:3]);expected=json.loads((here/'baseline.json').read_text())
assert all(identity(src/n)==v for n,v in expected.items()),'Baseline mismatch'
out.mkdir(parents=True,exist_ok=False)
for n in expected:shutil.copyfile(src/n,out/n)
original=(src/'index.pck').read_bytes();base,entries=unpack(original)
def raw(n):
 o,s,*_=entries[n];return original[base+o:base+o+s]
def target(n):return re.search(r'path="res://([^\"]+)"',raw(n+'.remap').decode())[1]
changed=['scripts/state/treasury_goals.gd','scripts/ui/treasury_goal_panel.gd','scripts/ui/mod_preview_catalog.gd','scripts/world/drill_modes.gd','scripts/world/endless_descent_world.gd','scripts/player/player_controller.gd','scripts/main.gd','scripts/dev/developer_menu.gd','scripts/qa/suites/skills_browser_review.gd']
replacements={}
for n in changed:
 replacements[n]=(root/n).read_bytes();replacements[n+'.remap']=('[remap]\npath="res://'+n+'"\n').encode()
for n in ['assets/ui/mods/bore-rush-pappa-v1.png','assets/ui/mods/laser-pappa-v1.png','assets/ui/mods/laser-emitter-v1.png']:
 replacements[n]=(root/n).read_bytes()
n=target('scripts/ui/premium_menu.gd');s=raw(n).decode();assert s.count('1.0.0-dev.15.43')==1
replacements[n]=s.replace('1.0.0-dev.15.43','1.0.0-dev.15.44').encode()
data=bytearray(original[:base]);after={}
for name in sorted(set(entries)|set(replacements)):
 payload=replacements.get(name) if name in replacements else raw(name);data+=b'\0'*(-len(data)%32)
 after[name]=(len(data)-base,len(payload),hashlib.md5(payload).digest(),0);data+=payload
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(after))
for name,(o,s,d,f) in after.items():
 k=name.encode();k+=b'\0'*(-len(k)%4);data+=struct.pack('<I',len(k))+k+struct.pack('<QQ16sI',o,s,d,f)
nb,verified=unpack(data)
for n,(o,s,d,f) in verified.items():assert bytes(data[nb+o:nb+o+s])==(replacements[n] if n in replacements else raw(n)),n
(out/'index.pck').write_bytes(data)
html=(src/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);assert not c['args'];c['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):])
manifest={n:identity(out/n) for n in expected};(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'build-receipt.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'version':'1.0.0-dev.15.44','baseline':expected,'files':manifest,'changed_resources':list(replacements),'unchanged_resources':sum(n not in replacements for n in entries),'all_retained_payloads_verified':True},indent=2))
print('MOLE_PACKAGE_PARITY_VERIFIED')
