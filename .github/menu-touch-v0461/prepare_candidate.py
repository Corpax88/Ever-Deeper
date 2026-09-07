import sys,json,hashlib,urllib.request,shutil,subprocess
from pathlib import Path
here=Path(__file__).parent;out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
base=json.loads((here/'dev-baseline.json').read_text())['files']
sha=lambda b:hashlib.sha256(b).hexdigest()
for side in ['dev','live']:(out/side).mkdir(exist_ok=True)
for name,i in base.items():
 b=urllib.request.urlopen('https://corpax88.github.io/Ever-Deeper/dev/'+name,timeout=180).read();assert len(b)==i['size'] and sha(b)==i['sha256'],name;(out/'dev'/name).write_bytes(b)
subprocess.run([sys.executable,str(here/'apply_delta.py'),str(out/'dev/index.pck'),str(here/'delta-dev'),str(out/'dev/index.pck')],check=True)
for p in (out/'dev').iterdir():shutil.copyfile(p,out/'live'/p.name)
subprocess.run([sys.executable,str(here/'apply_delta.py'),str(out/'dev/index.pck'),str(here/'delta-live'),str(out/'live/index.pck')],check=True)
for side in ['dev','live']:
 shutil.copyfile(here/(side+'-index.html'),out/side/'index.html')
 for name,i in json.loads((here/(side+'-candidate.json')).read_text())['files'].items():
  b=(out/side/name).read_bytes();assert len(b)==i['size'] and sha(b)==i['sha256'],(side,name)
print('Verified exact DEV and production candidates')
