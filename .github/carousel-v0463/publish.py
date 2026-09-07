import concurrent.futures,hashlib,json,shutil,sys,urllib.request
from pathlib import Path
root=Path(__file__).resolve().parent
bundle=json.loads((root/'bundle.json').read_text())
review=json.loads((root/'review.json').read_text())
assert review['passed'] is True
for side in ('live','dev'): assert review[side+'_pck_sha256']==bundle[side]['target_sha256']
candidate,site,backup=map(Path,sys.argv[1:])
baseline=json.loads((root/'baseline.json').read_text())
def checked(data,info):assert len(data)==info['size'] and hashlib.sha256(data).hexdigest()==info['sha256'],'Artifact or current deployment changed'
def get(item):
 side,name,info=item
 url='https://corpax88.github.io/Ever-Deeper/'+('dev/' if side=='dev' else '')+name
 data=urllib.request.urlopen(url,timeout=120).read();checked(data,info)
 p=backup/side/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:list(pool.map(get,[(s,n,i) for s,files in baseline.items() for n,i in files.items()]))
for side,m in bundle.items():
 dest=site/('dev' if side=='dev' else '');dest.mkdir(parents=True,exist_ok=True)
 for name,info in m['files'].items():
  p=candidate/side/name;checked(p.read_bytes(),info);shutil.copy2(p,dest/name)
print('Reviewed exact builds staged; previous public builds backed up')
