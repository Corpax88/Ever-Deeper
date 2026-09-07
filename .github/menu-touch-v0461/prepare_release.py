"""Publish the exact reviewed DEV and production packages, retaining both predecessors."""
import sys,json,hashlib,urllib.request,shutil,time
from pathlib import Path
here=Path(__file__).parent
base={s:json.loads((here/(s+'-baseline.json')).read_text())['files'] for s in ['dev','live']}
target={s:json.loads((here/(s+'-candidate.json')).read_text())['files'] for s in ['dev','live']}
review=json.loads((here/'visual-review.json').read_text())
assert review['passed'] is True
assert review['touch_browsers']==['chromium','webkit']
assert review['pet_layout_states']==9
assert all(x['passed'] for x in review['touch_results'])
assert review['production_dev_menu'] is False
for side in target:
 for name in ['index.pck','index.html']:assert review['identities'][side][name]==target[side][name]['sha256']
sha=lambda b:hashlib.sha256(b).hexdigest()
def download(side,name,i,destination=None):
 url='https://corpax88.github.io/Ever-Deeper/'+('dev/' if side=='dev' else '')+name
 for attempt in range(5):
  try:
   b=urllib.request.urlopen(url,timeout=180).read();assert len(b)==i['size'] and sha(b)==i['sha256'],(side,name)
   if destination:
    destination.parent.mkdir(parents=True,exist_ok=True);destination.write_bytes(b)
   return
  except Exception:
   if attempt==4:raise
   time.sleep(2**attempt)
if '--verify-public' in sys.argv:
 for side,files in target.items():
  for name,i in files.items():download(side,name,i)
 print('Verified all 18 public files: DEV 0.46.1-dev.1 and production 0.46.1')
else:
 candidate,site,rollback=map(Path,sys.argv[1:4]);site.mkdir(parents=True,exist_ok=True)
 for side,files in base.items():
  for name,i in files.items():download(side,name,i,rollback/('dev' if side=='dev' else '')/name)
 for side,files in target.items():
  dest=site/('dev' if side=='dev' else '');dest.mkdir(exist_ok=True)
  for name,i in files.items():
   b=(candidate/side/name).read_bytes();assert len(b)==i['size'] and sha(b)==i['sha256'],(side,name);(dest/name).write_bytes(b)
 assert len([p for p in site.rglob('*') if p.is_file()])==18
 print('Both predecessors backed up; both reviewed releases packaged atomically')
