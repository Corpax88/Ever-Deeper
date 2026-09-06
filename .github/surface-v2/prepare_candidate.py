import sys,json,hashlib,urllib.request,subprocess,time
from pathlib import Path
source=Path(__file__).parent;base=json.loads((source/'baseline.json').read_text());target=json.loads((source/'candidate.json').read_text());out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
sha=lambda b:hashlib.sha256(b).hexdigest()
for name,expected in base['files'].items():
 for attempt in range(4):
  try:
   with urllib.request.urlopen('https://corpax88.github.io/Ever-Deeper/dev/'+name,timeout=90) as response:data=response.read()
   assert len(data)==expected['size'] and sha(data)==expected['sha256'],name
   (out/name).write_bytes(data);break
  except Exception:
   if attempt==3:raise
   time.sleep(2**attempt)
subprocess.run([sys.executable,str(source/'apply_delta.py'),str(out/'index.pck'),str(source/'delta'),str(out/'index.pck')],check=True)
(out/'index.html').write_bytes((source/'index.html').read_bytes())
for name,expected in target['files'].items():
 data=(out/name).read_bytes();assert len(data)==expected['size'] and sha(data)==expected['sha256'],name
print('Exact surface candidate verified',target['version'])
