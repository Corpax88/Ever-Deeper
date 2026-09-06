"""Publish reviewed production runtime; preserve DEV and back up previous LIVE."""
import sys,json,hashlib,urllib.request,shutil,time
from pathlib import Path
source=Path(__file__).parent
base=json.loads((source/'old-baseline.json').read_text())
dev=json.loads((source/'dev-baseline.json').read_text())['files']
target=json.loads((source/'candidate.json').read_text())['files']
review=json.loads((source/'production-review.json').read_text())
assert review['passed'] is True
assert review['pck_sha256']==target['index.pck']['sha256']
assert review['html_sha256']==target['index.html']['sha256']
assert review['production_menu_present'] is False and review['production_menu_resource_present'] is False

def download(location,name,identity,path=None):
 url='https://corpax88.github.io/Ever-Deeper/'+location+name
 for retry in range(7):
  try:
   with urllib.request.urlopen(url,timeout=90) as response:data=response.read()
   assert len(data)==identity['size'] and hashlib.sha256(data).hexdigest()==identity['sha256'],url
   if path:
    path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
   return
  except Exception:
   if retry==6:raise
   time.sleep(min(2**retry,20))
if '--verify-public' in sys.argv:
 for location,identities in [('',target),('dev/',dev)]:
  for name,identity in identities.items():download(location,name,identity)
 print('All 18 public files verified: LIVE v0.45.0 production, DEV unchanged.')
else:
 candidate=Path(sys.argv[1]);site=Path(sys.argv[2]);rollback=Path(sys.argv[3]);site.mkdir(parents=True,exist_ok=True)
 for location,identities in [('',base['live']),('dev/',dev)]:
  for name,identity in identities.items():download(location,name,identity,rollback/location/name)
 (site/'dev').mkdir(exist_ok=True)
 for name in dev:shutil.copyfile(rollback/'dev'/name,site/'dev'/name)
 for name,identity in target.items():
  data=(candidate/name).read_bytes();assert len(data)==identity['size'] and hashlib.sha256(data).hexdigest()==identity['sha256'],name
  (site/name).write_bytes(data)
 assert len(list(site.rglob('*.*')))==18
 print('Reviewed production and unchanged DEV packaged; original runtime backed up.')
