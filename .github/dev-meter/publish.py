"""Deploy reviewed DEV bytes and preserve every LIVE byte."""
import concurrent.futures,hashlib,json,shutil,sys,time,urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parent
BASE=json.loads((ROOT.parent/'performance-v0469/review.json').read_text())['files']
REVIEW=json.loads((ROOT/'review.json').read_text())
URL='https://corpax88.github.io/Ever-Deeper/'
def check(data,info):
    if len(data)!=info['size'] or hashlib.sha256(data).hexdigest()!=info['sha256']: raise RuntimeError('File identity mismatch; stop publication')
def fetch(side,name):
    return urllib.request.urlopen(URL+('dev/' if side=='dev' else '')+name,timeout=120).read()
def prepare(candidate,site,backup):
    if not REVIEW['visual_reviewed'] or not REVIEW['package_checks_passed']: raise RuntimeError('Review incomplete')
    files=REVIEW['files']
    if json.loads((candidate/'manifest.json').read_text())!=files: raise RuntimeError('Wrong artifact')
    if set(files)!=set(BASE['dev']): raise RuntimeError('Unexpected file set')
    for name,info in files.items(): check((candidate/name).read_bytes(),info)
    tasks=[(side,name,info) for side,fileset in BASE.items() for name,info in fileset.items()]
    def preserve(task):
        side,name,info=task;data=fetch(side,name);check(data,info)
        dest=backup/side/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool: list(pool.map(preserve,tasks))
    site.mkdir(parents=True,exist_ok=True)
    shutil.copytree(backup/'live',site,dirs_exist_ok=True)
    (site/'dev').mkdir()
    for name in files: shutil.copyfile(candidate/name,site/'dev'/name)
    (site/'.nojekyll').write_text('')
    print('Reviewed DEV staged; all LIVE bytes preserved')
def verify():
    pending=[(side,name,info) for side,files in {'live':BASE['live'],'dev':REVIEW['files']}.items() for name,info in files.items()]
    for attempt in range(10):
        remaining=[]
        for side,name,info in pending:
            try: check(fetch(side,name),info)
            except Exception: remaining.append((side,name,info))
        pending=remaining
        if not pending: print('All 18 public files verified; LIVE unchanged');return
        time.sleep(10)
    raise RuntimeError('Public files did not match')
if sys.argv[1]=='prepare': prepare(*map(Path,sys.argv[2:5]))
elif sys.argv[1]=='verify': verify()
else: raise SystemExit('Expected prepare or verify')
