"""Build isolated QA and clean production fixes from the immutable DEV15.16 export."""
from pathlib import Path
import hashlib, json, os, re, shutil, struct, sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'surface-light-probe'))
from pack_helpers import unpack, identity
import cpu_patch, audio_patch

src,out=map(Path,sys.argv[1:]);here=Path(__file__).resolve().parent
manifest=json.loads((here.parent/'fps-round2/baseline.json').read_text())
assert all(identity(src/n)==v for n,v in manifest.items()),'Exact baseline required'
original=(src/'index.pck').read_bytes();base,original_entries=unpack(original)
assert 'override.cfg' not in original_entries,'Depth prepass remains parked'
def raw(name):
    off,size,*_=original_entries[name]
    return original[base+off:base+off+size]
def script(replace,name,text):
    remap=name+'.remap';assert remap in original_entries,name
    target=re.search(r'path="res://([^\"]+)"',raw(remap).decode())[1]
    replace[name]=text.encode();replace[remap]=('[remap]\npath="res://'+name+'"\n').encode()
    if target.endswith('.gd'):replace[target]=text.encode()
original_sources={}
for kind,want in cpu_patch.EXPECTED.items():
    for field in ['remap','active']:
        assert hashlib.sha256(raw(want[field])).hexdigest()==want[field+'_sha256'],want[field]
    original_sources[kind]=(here/want['original_file']).read_text()
for name,digest in cpu_patch.PRESERVE.items():assert hashlib.sha256(raw(name)).hexdigest()==digest,name
production={}
for kind,want in cpu_patch.EXPECTED.items():script(production,want['source'],cpu_patch.transform(original_sources[kind],kind))
premium='scripts/ui/premium_menu.gd'
premium_target=re.search(r'path="res://([^\"]+)"',raw(premium+'.remap').decode())[1]
premium_text=raw(premium_target).decode();assert premium_text.count('1.0.0-dev.15.16')==1
script(production,premium,premium_text.replace('1.0.0-dev.15.16','1.0.0-dev.15.17'))
common={}
script(common,'scripts/qa/suites/fps_review.gd',(here/'fixture.gd').read_text())
common['scripts/qa/suites/fixes_native_base.gd']=(here/'fixture-base.gd').read_bytes()
common['scripts/qa/suites/fixes_cpu_fixture.gd']=(here/'cpu_fixture.gd').read_bytes()
for name,text in cpu_patch.qa_reference_scripts(original_sources['contact'],original_sources['pet'],raw('scripts/player/native_worn/runtime_motion.gd').decode()).items():common[name]=text.encode()
receipts={}
for label in ['baseline','candidate','release']:
    dest=out/label;dest.mkdir(parents=True,exist_ok=False)
    for n in manifest:shutil.copyfile(src/n,dest/n)
    replace={} if label=='release' else dict(common)
    if label!='baseline':replace.update(production)
    data=bytearray(original);entries=dict(original_entries)
    for name,content in replace.items():
        data+=b'\0'*(-len(data)%32);entries[name]=(len(data)-base,len(content),hashlib.md5(content).digest(),0);data+=content
    struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(entries))
    for name,(off,size,digest,flags) in sorted(entries.items()):
        key=name.encode();key+=b'\0'*(-len(key)%4);data+=struct.pack('<I',len(key))+key+struct.pack('<QQ16sI',off,size,digest,flags)
    _,after=unpack(data)
    assert all(after[n]==v for n,v in original_entries.items() if n not in replace)
    assert 'override.cfg' not in after
    if label=='release':assert not any(n.startswith('scripts/qa/suites/fixes_') for n in after)
    (dest/'index.pck').write_bytes(data)
    html=(dest/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);c['fileSizes']['index.pck']=len(data)
    html=html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):]
    if label!='baseline':
        html=html.replace('<script src="index.js"></script>','<script>\n'+(here/'fbo-candidate.js').read_text()+'\n</script>\n<script src="index.js"></script>')
        assert 'EVER_DEEPER_FBO' in html,'FBO startup injection missing'
        (dest/'index.js').write_text(audio_patch.transform_js((src/'index.js').read_text()))
        (dest/'index.audio.position.worklet.js').write_text(audio_patch.transform_worklet((src/'index.audio.position.worklet.js').read_text()))
    (dest/'index.html').write_text(html)
    files={n:identity(dest/n) for n in manifest};(dest/'manifest.json').write_text(json.dumps(files,indent=2))
    receipts[label]={'files':files,'replaced_resources':list(replace),'unchanged_original_resources':sum(n not in replace for n in original_entries),'all_original_md5_verified':True}
(out/'build.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'baseline_source':'0225855d5b243fadf75c5267898ac2cd6edb3d0b','baseline':manifest,'variants':receipts,'depth_prepass_unchanged':True,'physical_iphone_verified':False},indent=2))
print('FIXES_PACKAGES_VERIFIED')
