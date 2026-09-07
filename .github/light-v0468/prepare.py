import base64,concurrent.futures,hashlib,json,sys,urllib.request,zlib
from pathlib import Path
ROOT=Path(__file__).resolve().parent
BUNDLE=json.loads((ROOT/'bundle.json').read_text())
URL='https://corpax88.github.io/Ever-Deeper/'
sha=lambda b:hashlib.sha256(b).hexdigest()
def download(name,dev=False):
    return urllib.request.urlopen(URL+('dev/' if dev else '')+name,timeout=120).read()
def verify(data,info):
    assert len(data)==info['size'] and sha(data)==info['sha256'],'File identity mismatch'
def apply(base,m):
    assert len(base)==m['base_size'] and sha(base)==m['base_sha256'],'Baseline changed; stop and rebase'
    payload=base64.b64decode(''.join((ROOT/n).read_text() for n in m['payload_files']));assert sha(payload)==m['payload_sha256']
    literal=zlib.decompress(payload);assert sha(literal)==m['literal_sha256']
    data=b''.join((base if op=='copy' else literal)[start:start+size] for op,start,size in m['operations'])
    assert len(data)==m['target_size'] and sha(data)==m['target_sha256']
    return data
if sys.argv[1]=='--verify-public':
    for side,m in BUNDLE.items():
        for name,info in m['files'].items():verify(download(name,side=='dev'),info)
    print('All 18 public files verified');sys.exit()
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
base=download('index.pck');dev=apply(base,BUNDLE['dev']);live=apply(dev,BUNDLE['live'])
names=[n for n in BUNDLE['live']['files'] if n not in ('index.pck','index.html')]
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool: runtime=dict(zip(names,pool.map(download,names)))
for side,pack in [('dev',dev),('live',live)]:
    p=out/side;p.mkdir(parents=True,exist_ok=True)
    files={**runtime,'index.pck':pack,'index.html':BUNDLE[side]['html'].encode()}
    for name,data in files.items():
        verify(data,BUNDLE[side]['files'][name]);(p/name).write_bytes(data)
print('Exact DEV and live candidates reconstructed')
