"""QA-only overlay over the immutable published DEV15.54 package.

Production source in this checkout is intentionally ignored for the baseline.
Explicit future candidate overrides can be supplied as a JSON path list.
"""
from pathlib import Path
import hashlib,json,os,re,shutil,struct,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.github/five-mods'))
from pack_helpers import unpack,identity
BASE={'size':327687342,'sha256':'7637ed10116bca208f841c11ea8d9359f4057b925fe2bc20bc1cda9ec267f56d'}
WEB=['index.html','index.js','index.wasm','index.pck','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js']
src,out=map(Path,sys.argv[1:3])
assert identity(src/'index.pck')==BASE,'Wrong published baseline'
out.mkdir(parents=True,exist_ok=True)
for name in WEB: shutil.copyfile(src/name,out/name)
original=(src/'index.pck').read_bytes();base,entries=unpack(original)
def raw(name):
    o,s,*_=entries[name];return original[base+o:base+o+s]
def script(name):
    mapping=name+'.remap'
    if mapping in entries:
        target=re.search(r'path="res://([^\"]+)"',raw(mapping).decode())[1]
        return raw(target)
    return raw(name)
replacements={}
overrides=json.loads(Path(sys.argv[3]).read_text()) if len(sys.argv)>3 else []
production=len(sys.argv)>4 and sys.argv[4]=='production'
version=os.environ.get('CANDIDATE_VERSION','1.0.0-dev.15.55')
for name in overrides:
    assert (name.startswith(('scripts/','shaders/')) or name=='data/ever_deeper_v0381.json') and '..' not in Path(name).parts,name
    replacements[name]=(ROOT/name).read_bytes()
    if name=='data/ever_deeper_v0381.json':
        before=json.loads(raw(name));current=json.loads(replacements[name])
        expected=json.loads(raw(name))
        for item in expected['ACHIEVEMENT_DEFINITIONS']:
            if item['id']=='quick_step': item['description']='Reach Running level 1.'
            if item['id']=='roadrunner': item['description']='Reach Running level 10.'
        for key,description in [('quick_step','Reach Running level 1.'),('roadrunner','Reach Running level 10.')]:
            expected['ACHIEVEMENT_BY_ID'][key]['description']=description
        assert current==expected,'Unreviewed game data change'
    if name=='scripts/ui/premium_menu.gd':
        source=replacements[name].decode()
        source,count=re.subn(r'(const DEV_RELEASE_VERSION: = )"[^"]+"',lambda m:m[1]+json.dumps(version),source)
        assert count==1,'Version owner changed'
        replacements[name]=source.encode()
    if name.endswith('.gd'): replacements[name+'.remap']=('[remap]\npath="res://'+name+'"\n').encode()
# Extend exact baseline QA suite without importing unrelated source drift.
if not production:
    replacements['scripts/qa/suites/full_quality_base.gd']=script('scripts/qa/suites/skills_browser_review.gd')
    replacements['scripts/qa/suites/skills_browser_review.gd']=(ROOT/'.github/full-quality/fixture.gd').read_bytes()
    replacements['scripts/qa/suites/skills_browser_review.gd.remap']=b'[remap]\npath="res://scripts/qa/suites/skills_browser_review.gd"\n'
data=bytearray(original[:base]);after={}
for name in sorted(set(entries)|set(replacements)):
    payload=replacements[name] if name in replacements else raw(name)
    data+=b'\0'*(-len(data)%32)
    after[name]=(len(data)-base,len(payload),hashlib.md5(payload).digest(),0)
    data+=payload
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(after))
for name,(o,s,d,f) in after.items():
    key=name.encode();key+=b'\0'*(-len(key)%4)
    data+=struct.pack('<I',len(key))+key+struct.pack('<QQ16sI',o,s,d,f)
newbase,verified=unpack(data)
for n,(o,s,*_) in verified.items():
    assert bytes(data[newbase+o:newbase+o+s])==(replacements[n] if n in replacements else raw(n)),n
(out/'index.pck').write_bytes(data)
html=(src/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html)
config=json.loads(m[1]);assert not config['args']
config['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(config,separators=(',',':'))+html[m.end(1):])
manifest={name:identity(out/name) for name in WEB}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'qa-build-receipt.json').write_text(json.dumps({'baseline_pck':BASE,'baseline_source':'be3a698e0ad8bedb91e877b9932a7bb05b80684a','qa_source':os.environ.get('GITHUB_SHA'),'overrides':overrides,'production':production,'version':version if 'scripts/ui/premium_menu.gd' in overrides else '1.0.0-dev.15.54','replaced':list(replacements),'retained_payloads_verified':True,'files':manifest},indent=2))
print('FULL_QUALITY_QA_PACKAGE_VERIFIED',manifest['index.pck'])
