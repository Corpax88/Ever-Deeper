from pathlib import Path
import concurrent.futures,hashlib,json,sys,urllib.request
root=Path(__file__).resolve().parent
manifest=json.loads((root/'baseline-build.json').read_text())
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
def get(item):
    name,info=item
    data=urllib.request.urlopen('https://corpax88.github.io/Ever-Deeper/'+name,timeout=180).read()
    assert len(data)==info['size'] and hashlib.sha256(data).hexdigest()==info['sha256'],'Published baseline changed'
    (out/name).write_bytes(data)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:list(pool.map(get,manifest.items()))
print('Published v0.46.8 baseline identity verified')
