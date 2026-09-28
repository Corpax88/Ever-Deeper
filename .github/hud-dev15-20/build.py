"""Patch only approved HUD presentation, QA observer and version into DEV15.19."""
from pathlib import Path
import hashlib,json,os,re,shutil,struct,subprocess,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'diagnostics-v2'))
from pack_helpers import unpack,identity
root=Path(__file__).resolve().parents[2];here=Path(__file__).resolve().parent
src,out=map(Path,sys.argv[1:3]);engine=sys.argv[3];expected=json.loads((here/'baseline.json').read_text())
assert all(identity(src/n)==v for n,v in expected.items()),'Wrong DEV15.19 bytes'
out.mkdir(parents=True,exist_ok=False)
for n in expected:shutil.copyfile(src/n,out/n)
data=bytearray((src/'index.pck').read_bytes());base,entries=unpack(data);before=dict(entries)
def raw(n):
 o,s,*_=entries[n];return bytes(data[base+o:base+o+s])
def target(n):return re.search(r'path="res://([^\"]+)"',raw(n+'.remap').decode())[1]
replacements={}
def replace(n,text):
 active=target(n);replacements[n]=text.encode();replacements[n+'.remap']=('[remap]\npath="res://'+n+'"\n').encode()
 if active.endswith('.gd'):replacements[active]=text.encode()
n='scripts/ui/premium_hud.gd'
if target(n).endswith('.gd'):assert raw(target(n))==(here/'premium-hud-before.gd').read_bytes(),'HUD source drift'
for n in ['scripts/ui/premium_hud.gd','scripts/qa/suites/skills_browser_review.gd']:replace(n,(root/n).read_text())
n='scripts/ui/premium_menu.gd';text=raw(target(n)).decode();assert text.count('1.0.0-dev.15.19')==1
replace(n,text.replace('1.0.0-dev.15.19','1.0.0-dev.15.20'))
# Import only the approved PNG with the exact engine, without rebuilding the game.
asset='assets/ui/skills/icons/skills-knot-blue-steel-v1.png'
import_root=out.parent/'icon-import';import_root.mkdir(exist_ok=False)
(import_root/'project.godot').write_text('config_version=5\n[application]\nconfig/name="HUD icon import"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
(import_root/asset).parent.mkdir(parents=True);shutil.copyfile(root/asset,import_root/asset)
subprocess.run([engine,'--headless','--editor','--path',str(import_root),'--import'],check=True,timeout=120)
meta=(import_root/(asset+'.import')).read_bytes();ctex=re.search(rb'path="res://([^\"]+\.ctex)"',meta)[1].decode()
replacements[asset]= (root/asset).read_bytes();replacements[asset+'.import']=meta;replacements[ctex]=(import_root/ctex).read_bytes()
for name,b in replacements.items():
 data+=b'\0'*(-len(data)%32);entries[name]=(len(data)-base,len(b),hashlib.md5(b).digest(),0);data+=b
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(entries))
for name,(o,s,d,f) in sorted(entries.items()):
 k=name.encode();k+=b'\0'*(-len(k)%4);data+=struct.pack('<I',len(k))+k+struct.pack('<QQ16sI',o,s,d,f)
_,after=unpack(data);assert all(after[n]==v for n,v in before.items() if n not in replacements)
assert 'override.cfg' not in after
(out/'index.pck').write_bytes(data)
html=(src/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);c['fileSizes']['index.pck']=len(data)
html=html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):];(out/'index.html').write_text(html)
manifest={n:identity(out/n) for n in expected};(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'build-receipt.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'baseline':expected,'files':manifest,'changed_resources':list(replacements),'unchanged_resources':sum(n not in replacements for n in before),'all_original_md5_verified':True,'asset':identity(root/asset),'physical_iphone_verified':False},indent=2))
print('HUD_PACKAGE_PARITY_VERIFIED')
