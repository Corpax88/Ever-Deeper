"""Share exact existing DEV engine bytes; preserve the accepted LIVE PCK."""
from pathlib import Path
import json,hashlib,re,shutil,os,sys
here=Path(__file__).resolve().parent
src,out=map(Path,sys.argv[1:3])
def ident(p):return {'size':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
expected=json.loads((here/'accepted-manifest.json').read_text())
assert set(expected)==set(json.loads((src/'manifest.json').read_text()))
assert all(ident(src/n)==v for n,v in expected.items())
out.mkdir(parents=True,exist_ok=False)
for n in expected:
 dest=out/('dev/index.wasm' if n=='index.wasm' else n);dest.parent.mkdir(exist_ok=True,parents=True);shutil.copyfile(src/n,dest)
shared=['index.wasm','index.js','index.audio.worklet.js','index.audio.position.worklet.js']
before=json.loads((here/'public-before.json').read_text())
for n in shared:
 assert expected[n]==before['dev/'+n],n
 if n!='index.wasm':shutil.copyfile(src/n,out/'dev'/n)
html=(out/'index.html').read_text();match=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);config=json.loads(match[1]);assert config['executable']=='index' and not config['args']
config['executable']='dev/index';config['mainPack']='index.pck';config['fileSizes']['dev/index.wasm']=config['fileSizes'].pop('index.wasm')
(out/'index.html').write_text(html[:match.start(1)]+json.dumps(config,separators=(',',':'))+html[match.end(1):])
files={n:ident(out/n) for n in expected if n!='index.wasm'}|{'dev/'+n:ident(out/'dev'/n) for n in shared}
assert files['index.pck']==expected['index.pck']
receipt=json.loads((src/'build-receipt.json').read_text());receipt.update(source=os.environ.get('GITHUB_SHA'),files=files,original_live_source=receipt['source'],original_live_files=expected,shared_engine=shared,removed_public_files=['index.wasm'],only_additional_change='HTML engine path; exact PCK and engine bytes retained')
(out/'manifest.json').write_text(json.dumps(files,indent=2));(out/'build-receipt.json').write_text(json.dumps(receipt,indent=2))
if os.environ.get('RUNNER_TEMP'):
 evidence=Path(os.environ['RUNNER_TEMP'])/'evidence';evidence.mkdir(exist_ok=True);shutil.copyfile(out/'build-receipt.json',evidence/'build-receipt.json')
print('SHARED_ENGINE_BYTE_PARITY_VERIFIED')
