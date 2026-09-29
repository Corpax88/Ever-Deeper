"""Scoped stamina fix against immutable published LIVE or DEV pack."""
from pathlib import Path
import hashlib,json,os,re,shutil,struct,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'diagnostics-v2'))
from pack_helpers import unpack,identity
root=Path(__file__).resolve().parents[2];here=Path(__file__).resolve().parent
src,out=map(Path,sys.argv[1:3]);flavor=sys.argv[3];assert flavor in ['live','dev']
version='1.0.2' if flavor=='live' else '1.0.0-dev.15.22'
expected=json.loads((here/(flavor+'-baseline.json')).read_text())
assert all(identity(src/n)==v for n,v in expected.items()),'Published baseline changed'
out.mkdir(parents=True,exist_ok=False)
for n in expected:shutil.copyfile(src/n,out/n)
original=(src/'index.pck').read_bytes();base,entries=unpack(original)
def raw(n):
 o,s,*_=entries[n];return original[base+o:base+o+s]
def target(n):return re.search(r'path="res://([^\"]+)"',raw(n+'.remap').decode())[1]
replacements={}
for n in ['scripts/progression/miner_training.gd','scripts/qa/suites/skills_browser_review.gd']:
 replacements[n]=(root/n).read_bytes();replacements[n+'.remap']=('[remap]\npath="res://'+n+'"\n').encode()
n=target('scripts/ui/premium_menu.gd');s=raw(n).decode();assert s.count('1.0.0-dev.15.21')==1 and s.count('return "1.0.1"')==1
s=s.replace('1.0.0-dev.15.21','1.0.0-dev.15.22').replace('return "1.0.1"','return "1.0.2"');replacements[n]=s.encode()
if flavor=='live':
 b=raw('project.binary');assert b.count(b'1.0.1')==1;replacements['project.binary']=b.replace(b'1.0.1',b'1.0.2')
data=bytearray(original[:base]);after={}
for name in sorted(set(entries)|set(replacements)):
 payload=replacements[name] if name in replacements else raw(name);data+=b'\0'*(-len(data)%32)
 after[name]=(len(data)-base,len(payload),hashlib.md5(payload).digest(),0);data+=payload
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(after))
for name,(o,s,d,f) in after.items():
 k=name.encode();k+=b'\0'*(-len(k)%4);data+=struct.pack('<I',len(k))+k+struct.pack('<QQ16sI',o,s,d,f)
nb,verified=unpack(data)
for n,(o,s,d,f) in verified.items():
 assert bytes(data[nb+o:nb+o+s])==(replacements[n] if n in replacements else raw(n)),n
(out/'index.pck').write_bytes(data)
html=(src/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);assert not c['args'];c['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):])
manifest={n:identity(out/n) for n in expected};(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'build-receipt.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'version':version,'flavor':flavor,'baseline':expected,'files':manifest,'changed_resources':list(replacements),'unchanged_resources':sum(n not in replacements for n in entries),'all_retained_payloads_verified':True},indent=2))
print('STAMINA_PACKAGE_PARITY_VERIFIED',version)
