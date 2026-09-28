"""Patch only telemetry and version into exact accepted DEV15.17, never rebuild historical main."""
import sys,json,re,hashlib,struct,shutil,os
from pathlib import Path
from pack_helpers import unpack,identity
ROOT=Path(__file__).resolve().parents[2]
src,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
expected=json.loads((ROOT/'.github/diagnostics-v2/baseline.json').read_text())
assert all(identity(src/n)==v for n,v in expected.items()),'Wrong DEV15.17 bytes'
for n in expected:shutil.copyfile(src/n,out/n)
data=bytearray((src/'index.pck').read_bytes());base,entries=unpack(data);before=dict(entries)
def raw(n):
 o,s,*_=entries[n];return bytes(data[base+o:base+o+s])
n='scripts/ui/premium_menu.gd';target=re.search(r'path="res://([^\"]+)"',raw(n+'.remap').decode())[1]
text=raw(target).decode();assert text.count('1.0.0-dev.15.17')==1
replace={n:text.replace('1.0.0-dev.15.17','1.0.0-dev.15.18').encode(),n+'.remap':('[remap]\npath="res://'+n+'"\n').encode()}
if target.endswith('.gd'):replace[target]=replace[n]
for name,b in replace.items():
 data+=b'\0'*(-len(data)%32);entries[name]=(len(data)-base,len(b),hashlib.md5(b).digest(),0);data+=b
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(entries))
for name,(o,s,d,f) in sorted(entries.items()):
 k=name.encode();k+=b'\0'*(-len(k)%4);data+=struct.pack('<I',len(k))+k+struct.pack('<QQ16sI',o,s,d,f)
_,after=unpack(data);assert all(after[n]==v for n,v in before.items() if n not in replace)
assert 'override.cfg' not in after
(out/'index.pck').write_bytes(data)
html=(src/'index.html').read_text();a=html.index('// DEV opt-in recorder.');b=html.index('const GODOT_CONFIG = ',a)
html=html[:a]+(ROOT/'tools/session-reports-browser.js').read_text()+'\n'+html[b:]
html=html.replace('<script src="index.js"></script>','<script>\n'+(ROOT/'tools/session-diagnostics.js').read_text()+'\n</script>\n<script src="index.js"></script>',1)
m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);c['fileSizes']['index.pck']=len(data)
html=html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):]
(out/'index.html').write_text(html)
s=(src/'index.js').read_text();needle='MainLoop.runIter(iterFunc);';assert s.count(needle)==1
s=s.replace(needle,'if(window.everDeeperDiagnostics?.active){window.everDeeperDiagnostics.before(GLctx,GodotAudio,wasmMemory);try{MainLoop.runIter(iterFunc);}finally{window.everDeeperDiagnostics.after();}}else{MainLoop.runIter(iterFunc);}',1)
(out/'index.js').write_text(s)
manifest={n:identity(out/n) for n in expected};(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'build-receipt.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'baseline':expected,'files':manifest,'changed_resources':list(replace),'unchanged_resources':sum(n not in replace for n in before),'scope':'telemetry only; version string is the sole game-resource change','physical_iphone_verified':False},indent=2))
print('TELEMETRY_PACKAGE_PARITY_VERIFIED')
