"""Preserve LIVE byte-for-byte; release only the exact visually reviewed DEV."""
import sys,json,hashlib,urllib.request,shutil,time
from pathlib import Path
source=Path(__file__).parent;base=json.loads((source/'baseline.json').read_text());target=json.loads((source/'candidate.json').read_text());review=json.loads((source/'visual-review.json').read_text())
assert review['passed'] is True and review['pck_sha256']==target['files']['index.pck']['sha256']
assert review['viewport']==[932,430] and review['motion_damage_checks']==12
sha=lambda b:hashlib.sha256(b).hexdigest()
def download(url,identity,path=None):
    for retry in range(5):
        try:
            with urllib.request.urlopen(url,timeout=90) as response:data=response.read()
            assert len(data)==identity['size'] and sha(data)==identity['sha256'],url
            if path:
                path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
            return
        except Exception:
            if retry==4:raise
            time.sleep(2**retry)
if '--verify-public' in sys.argv:
    for location,identities in [('',base['live']),('dev/',target['files'])]:
        for name,identity in identities.items():download('https://corpax88.github.io/Ever-Deeper/'+location+name,identity)
    print('All 18 public files match: LIVE preserved, reviewed DEV published.')
else:
    candidate=Path(sys.argv[1]);site=Path(sys.argv[2]);rollback=Path(sys.argv[3]);site.mkdir(parents=True,exist_ok=True)
    for location,identities in [('',base['live']),('dev/',base['dev'])]:
        for name,identity in identities.items():download('https://corpax88.github.io/Ever-Deeper/'+location+name,identity,rollback/location/name)
    for name in base['live']:shutil.copyfile(rollback/name,site/name)
    (site/'dev').mkdir(exist_ok=True)
    for name,identity in target['files'].items():
        data=(candidate/name).read_bytes();assert len(data)==identity['size'] and sha(data)==identity['sha256'],name
        (site/'dev'/name).write_bytes(data)
    assert len(list(site.rglob('*.*')))==18
    print('Atomic Pages package ready; both baseline versions verified before replacement.')
