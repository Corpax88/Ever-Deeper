"""Scoped node hotfix on immutable LIVE1.0.3; retain every other payload."""
from pathlib import Path
import hashlib,json,os,re,shutil,struct,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'diagnostics-v2'))
from pack_helpers import unpack,identity
here=Path(__file__).resolve().parent;root=here.parents[1]
src,out=map(Path,sys.argv[1:3]);expected=json.loads((here/'baseline.json').read_text())
assert all(identity(src/n)==v for n,v in expected.items()),'Wrong LIVE1.0.3 bytes'
out.mkdir(parents=True,exist_ok=False)
for n in expected:shutil.copyfile(src/n,out/n)
original=(src/'index.pck').read_bytes();base,entries=unpack(original)
def raw(n):
 o,s,*_=entries[n];return original[base+o:base+o+s]
def target(n):return re.search(r'path="res://([^\"]+)"',raw(n+'.remap').decode())[1]
replacements={n:(root/n).read_bytes() for n in ['scripts/world/endless_descent_world.gd','scripts/world/resonance_drill.gd','scripts/qa/suites/skills_browser_review.gd','scripts/qa/suites/premium_core.gd']}
b=raw('project.binary');assert b[:4]==b'ECFG';count,=struct.unpack_from('<I',b,4);pos=8;records=[];changed=[]
for _ in range(count):
 start=pos;n,=struct.unpack_from('<I',b,pos);pos+=4;k=b[pos:pos+n].decode();pos+=n;n,=struct.unpack_from('<I',b,pos);pos+=4;v=b[pos:pos+n];pos+=n
 assert k!='_custom_features','Unexpected DEV feature'
 record=b[start:pos]
 if k=='application/config/version':
  assert v==struct.pack('<II',4,5)+b'1.0.3\0\0\0';record=record[:-len(v)]+v.replace(b'1.0.3',b'1.0.4');changed.append(k)
 records.append(record)
assert pos==len(b) and changed==['application/config/version']
replacements['project.binary']=b'ECFG'+struct.pack('<I',len(records))+b''.join(records)
n=target('scripts/ui/premium_menu.gd');s=raw(n).decode();assert s.count('return "1.0.3"')==1
replacements[n]=s.replace('return "1.0.3"','return "1.0.4"').encode()
data=bytearray(original[:base]);after={}
for n in sorted(entries):
 payload=replacements[n] if n in replacements else raw(n);data+=b'\0'*(-len(data)%32)
 after[n]=(len(data)-base,len(payload),hashlib.md5(payload).digest(),0);data+=payload
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(after))
for n,(o,s,d,f) in after.items():
 k=n.encode();k+=b'\0'*(-len(k)%4);data+=struct.pack('<I',len(k))+k+struct.pack('<QQ16sI',o,s,d,f)
nb,verified=unpack(data)
for n,(o,s,d,f) in verified.items():assert bytes(data[nb+o:nb+o+s])==(replacements[n] if n in replacements else raw(n)),n
assert not any(n.startswith(('scripts/dev/developer_menu.','scripts/dev/render_probe.')) for n in verified)
(out/'index.pck').write_bytes(data)
html=(src/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);assert not c['args'];c['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):])
manifest={n:identity(out/n) for n in expected};(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'build-receipt.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'baseline':expected,'files':manifest,'changed_resources':list(replacements),'unchanged_resources':len(verified)-len(replacements),'all_retained_payloads_verified':True,'physical_iphone_verified':False},indent=2))
print('LIVE_NODE_HOTFIX_PARITY_VERIFIED')
