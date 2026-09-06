import sys,json,hashlib,urllib.request,shutil,subprocess,time
from pathlib import Path
source=Path(__file__).parent;base=json.loads((source/'baseline.json').read_text());target=json.loads((source/'candidate.json').read_text());out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
sha=lambda b:hashlib.sha256(b).hexdigest()
def download(url,expected,path):
    for retry in range(4):
        try:
            with urllib.request.urlopen(url,timeout=90) as response:data=response.read()
            assert len(data)==expected['size'] and sha(data)==expected['sha256'],f'Identity mismatch: {url}'
            path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data);return
        except Exception:
            if retry==3:raise
            time.sleep(2**retry)
for name,expected in base['dev'].items():download('https://corpax88.github.io/Ever-Deeper/dev/'+name,expected,out/name)
subprocess.run([sys.executable,str(source/'apply_delta.py'),str(out/'index.pck'),str(source/'delta'),str(out/'index.pck')],check=True)
subprocess.run([sys.executable,str(source/'apply_delta.py'),str(out/'index.pck'),str(source/'fix-delta'),str(out/'index.pck')],check=True)
shutil.copyfile(source/'index.html',out/'index.html')
for name,expected in target['files'].items():
    data=(out/name).read_bytes();assert len(data)==expected['size'] and sha(data)==expected['sha256'],name
assert len(list(out.iterdir()))==9
print('Exact candidate ready:',target['version'],target['files']['index.pck']['sha256'])
