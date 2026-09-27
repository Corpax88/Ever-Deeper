from pathlib import Path
import hashlib,json,struct,shutil,sys,os,re
from pack_helpers import unpack,identity
source,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
manifest=json.loads((source/'manifest.json').read_text())
assert json.loads((source/'build.json').read_text())['source']=='ba396beeed9e587a8dc700edef7b28b79f1095d6'
assert all(identity(source/n)==v for n,v in manifest.items())
assert 'this._audioBuffer.duration>10' in (source/'index.js').read_text()
for n in manifest: shutil.copyfile(source/n,out/n)
data=bytearray((out/'index.pck').read_bytes());base,entries=unpack(data);before=dict(entries)
root=Path(__file__).parent
replace={}
for original,local in [('scripts/dev/developer_menu.gd','developer_menu.gd'),('scripts/ui/premium_menu.gd','premium_menu.gd')]:
    remap=original+'.remap';assert remap in entries
    # Canonical raw paths also support existing preloads whose remap was already resolved.
    replace[original]=(root/local).read_bytes()
    replace[remap]=('[remap]\npath="res://'+original+'"\n').encode()
    off,size,_,_=entries[remap]
    old=bytes(data[base+off:base+off+size]).decode()
    target=re.search(r'path="res://([^\"]+)"',old)[1]
    if target.endswith('.gd'): replace[target]=replace[original]
for name,raw in replace.items():
    data+=b'\0'*(-len(data)%32);entries[name]=(len(data)-base,len(raw),hashlib.md5(raw).digest(),0);data+=raw
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(entries))
for name,(off,size,md5,flags) in sorted(entries.items()):
    key=name.encode();key+=b'\0'*(-len(key)%4);data+=struct.pack('<I',len(key))+key+struct.pack('<QQ16sI',off,size,md5,flags)
_,after=unpack(data);assert all(after[n]==v for n,v in before.items() if n not in replace)
(out/'index.pck').write_bytes(data)
html=(out/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);c['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):])
html=(out/'index.html').read_text()
bridge="""<script>
window.everDeeperNativeDpr = window.devicePixelRatio;
window.everDeeperRenderDpr = 3;
Object.defineProperty(window, 'devicePixelRatio', {configurable:true, get:()=>window.everDeeperRenderDpr});
window.everDeeperSetDpr = value => {
 if (![1,2,3].includes(value)) return false;
 window.everDeeperRenderDpr=value;
 window.dispatchEvent(new Event('resize'));
 return true;
};
</script>"""
assert '<head>' in html
(out/'index.html').write_text(html.replace('<head>','<head>'+bridge,1))
(out/'manifest.json').write_text(json.dumps({n:identity(out/n) for n in manifest}))
(out/'build.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'base_source':'ba396beeed9e587a8dc700edef7b28b79f1095d6','base_run':36303234754,'unchanged_resources':len(before)-len(set(before)&set(replace)),'replaced':list(replace),'original_files':manifest},indent=2))
print('Preserved',len(before)-len(set(before)&set(replace)),'resources; production music candidate ready')
