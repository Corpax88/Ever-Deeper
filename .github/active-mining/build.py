from pathlib import Path
import hashlib,json,struct,shutil,sys,os,re
from pack_helpers import unpack,identity
source,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
manifest=json.loads((source/'manifest.json').read_text())
assert all(identity(source/n)==v for n,v in manifest.items())
for n in manifest: shutil.copyfile(source/n,out/n)
data=bytearray((out/'index.pck').read_bytes());base,entries=unpack(data);before=dict(entries)
root=Path(__file__).parent
replace={'qa_profile.gd':(root/'profile.gd').read_bytes()}
for original,local in [('scripts/world/mossvein_mine.gd','world.gd'),('scripts/state/run_state.gd','state.gd'),('scripts/qa/suites/fps_review.gd','fps.gd'),('scripts/audio/audio_director.gd','qa_audio.gd')]:
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
(out/'manifest.json').write_text(json.dumps({n:identity(out/n) for n in manifest}))
(out/'build.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'base_source':'ab0c12ff579134e0a092946bd92973e4599a073c','base_run':36118561266,'unchanged_resources':len(before)-len(set(before)&set(replace)),'replaced':list(replace),'original_files':manifest},indent=2))
print('Preserved',len(before)-len(set(before)&set(replace)),'resources; isolated QA package ready')
