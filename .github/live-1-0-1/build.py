"""Promote immutable approved DEV15.21 resources to production, without re-export."""
from pathlib import Path
import hashlib,json,os,re,shutil,struct,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'diagnostics-v2'))
from pack_helpers import unpack,identity
here=Path(__file__).resolve().parent
src,out=map(Path,sys.argv[1:3]);expected=json.loads((here/'baseline.json').read_text())
assert all(identity(src/n)==v for n,v in expected.items()),'Wrong DEV15.21 bytes'
out.mkdir(parents=True,exist_ok=False)
for n in expected:shutil.copyfile(src/n,out/n)
original=(src/'index.pck').read_bytes();base,entries=unpack(original)
def raw(n):
 o,s,*_=entries[n];return original[base+o:base+o+s]
def target(n):return re.search(r'path="res://([^\"]+)"',raw(n+'.remap').decode())[1]
# ECFG records: length-prefixed key, length-prefixed encoded Variant.
# Preserve every other setting byte-for-byte, including save identity and graphics.
b=raw('project.binary');assert b[:4]==b'ECFG';count,=struct.unpack_from('<I',b,4);pos=8;records=[];changed=[]
for _ in range(count):
 start=pos;n,=struct.unpack_from('<I',b,pos);pos+=4;k=b[pos:pos+n].decode();pos+=n;n,=struct.unpack_from('<I',b,pos);pos+=4;v=b[pos:pos+n];pos+=n
 if k=='_custom_features':
  assert v==struct.pack('<II',4,15)+b'ever_deeper_dev\0';changed.append(k);continue
 record=b[start:pos]
 if k=='application/config/version':
  assert v==struct.pack('<II',4,5)+b'1.0.0\0\0\0';record=record[:-len(v)]+v.replace(b'1.0.0',b'1.0.1');changed.append(k)
 records.append(record)
assert pos==len(b) and set(changed)=={'_custom_features','application/config/version'}
replacements={'project.binary':b'ECFG'+struct.pack('<I',len(records))+b''.join(records)}
# Explicit browser observer must tolerate the intentionally absent DEV menu.
n='scripts/qa/suites/skills_browser_review.gd';active=target(n);text=raw(active).decode()
for old,new in [('_bounds(main.developer_menu.toggle_button)','(_bounds(main.developer_menu.toggle_button) if is_instance_valid(main.developer_menu) else [])'),('main.developer_menu.drawer.visible','(main.developer_menu.drawer.visible if is_instance_valid(main.developer_menu) else false)')]:
 assert text.count(old)==1;text=text.replace(old,new)
replacements[active]=text.encode()
assert '\treturn "1.0.1"' in raw(target('scripts/ui/premium_menu.gd')).decode()
removed={n for n in entries if n.startswith(('scripts/dev/developer_menu.','scripts/dev/render_probe.'))}
assert len(removed)==6
# Repack from the original header; omit removed resources and stale old payloads.
data=bytearray(original[:base]);after={}
for name in sorted(set(entries)-removed):
 payload=replacements.get(name,raw(name));data+=b'\0'*(-len(data)%32)
 after[name]=(len(data)-base,len(payload),hashlib.md5(payload).digest(),0);data+=payload
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(after))
for name,(o,s,d,f) in after.items():
 k=name.encode();k+=b'\0'*(-len(k)%4);data+=struct.pack('<I',len(k))+k+struct.pack('<QQ16sI',o,s,d,f)
newbase,verified=unpack(data)
for n,(o,s,d,f) in verified.items():
 assert bytes(data[newbase+o:newbase+o+s])==replacements.get(n,raw(n)),n
assert not removed.intersection(verified) and 'override.cfg' not in verified
(out/'index.pck').write_bytes(data)
html=(src/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);assert not c['args'];c['fileSizes']['index.pck']=len(data)
html=html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):];(out/'index.html').write_text(html)
manifest={n:identity(out/n) for n in expected};(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'build-receipt.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'baseline':expected,'files':manifest,'changed_resources':list(replacements),'removed_resources':sorted(removed),'changed_project_settings':changed,'unchanged_resources':len(verified)-len(replacements),'all_retained_payloads_verified':True,'physical_iphone_verified':False},indent=2))
print('LIVE_PACKAGE_PARITY_VERIFIED')
