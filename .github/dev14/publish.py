"""Publish immutable reviewed ordinary DEV14; preserve LIVE and retained Worn trial."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import argparse, hashlib, json, os, shutil, time, urllib.request
HERE=Path(__file__).resolve().parent
PUBLIC='https://corpax88.github.io/Ever-Deeper/'
FILES={'index.html','index.pck','index.js','index.wasm','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js'}
def require(ok,message):
    if not ok: raise RuntimeError(message)
def read(path): return json.loads(path.read_text())
def identity(path):
    h=hashlib.sha256()
    with path.open('rb') as stream:
        for part in iter(lambda:stream.read(1024*1024),b''): h.update(part)
    return {'size':path.stat().st_size,'sha256':h.hexdigest()}
def reviewed():
    review=read(HERE/'review.json'); manifest=read(HERE/'manifest.json')
    baseline=read(HERE.parent/'native-flow-trial/baseline.json')
    worn=read(HERE.parent/'native-flow-trial/bundle.json')
    require(review['destination']=='dev' and review['version']=='1.0.0-dev.14','Wrong release destination')
    require(review['live_authorized'] is False,'LIVE is not authorized')
    require(all(review.get(k) is True for k in ['ordinary_game_adopted','independent_visual_accepted','exported_gameplay_passed','publisher_reviewed']),'Incomplete release review')
    require(set(manifest)==FILES,'Incomplete DEV14 file set')
    require(identity(HERE/'manifest.json')['sha256']==review['manifest_sha256'],'Manifest changed after review')
    require(identity(HERE.parent/'native-flow-trial/baseline.json')['sha256']==review['baseline_sha256'],'DEV13/LIVE baseline changed')
    require(identity(HERE.parent/'native-flow-trial/bundle.json')['sha256']==review['retained_trial_manifest_sha256'],'Retained trial changed')
    proof=read(HERE/'evidence/browser-report.json')
    require(identity(HERE/'evidence/browser-report.json')['sha256']==review['browser_report_sha256'],'Browser evidence changed')
    require(proof['passed'] is True and proof['version']=='1.0.0-dev.14' and proof['files']==manifest,'Browser tested different package')
    require(proof['source_commit']==review['source_commit'] and proof['preceding_run']==review['artifact_run_id'],'Browser provenance differs')
    prior=HERE/'evidence/preceding-browser-report.json'
    require(identity(prior)['sha256']==proof['preceding_report_sha256'],'Preceding evidence changed')
    preceding=read(prior)
    require(preceding['files']==manifest and preceding['passed'] is False and 'ordinary resume timeout:' in preceding['error'],'Unexpected preceding observer result')
    names={c['name'] for c in proof['checks']}
    require({'00-normal-dev14-menu','moss-up','moss-right','moss-down','moss-left','endless-up','endless-right','endless-down','endless-left','iron-restored','drill-restored','worn-outfit-reentry','surface-ordinary','depth-ordinary','hub-ordinary','deepheart-ordinary','surface-touch-release','dev14-pause','dev14-resumed','resume-real-input'}<=names,'Incomplete ordinary gameplay evidence')
    return review,manifest,baseline,worn

def fetch(relative,target,expected):
    target.parent.mkdir(parents=True,exist_ok=True)
    request=urllib.request.Request(PUBLIC+relative,headers={'Cache-Control':'no-cache','Pragma':'no-cache'})
    h=hashlib.sha256();size=0
    with urllib.request.urlopen(request,timeout=120) as response,target.open('wb') as out:
        while block:=response.read(1024*1024):
            size+=len(block);require(size<=expected['size'],'Pinned public size exceeded: '+relative)
            h.update(block);out.write(block)
    require({'size':size,'sha256':h.hexdigest()}==expected,'Public bytes changed: '+relative)

def prepare(work,candidate):
    review,manifest,baseline,worn=reviewed()
    require(not work.exists(),'Use fresh publication workspace')
    work.mkdir(parents=True)
    # Build provenance and final acceptance are separate runs of the SAME bytes.
    # The original observer failure stays recorded; only its remaining gate was repeated.
    def api(path):
        request=urllib.request.Request('https://api.github.com/repos/Corpax88/Ever-Deeper/actions/'+path,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
        with urllib.request.urlopen(request,timeout=30) as response: return json.load(response)
    run=api('runs/'+str(review['run_id']))
    require(run['conclusion']=='success' and run['head_sha']==review['verification_commit'],'Wrong or failing final verification run')
    source=api('runs/'+str(review['artifact_run_id']))
    require(source['head_sha']==review['source_commit'],'Wrong candidate source run')
    jobs=api('runs/'+str(review['artifact_run_id'])+'/jobs?filter=latest')['jobs']
    require(any(j['name']=='build' and j['conclusion']=='success' for j in jobs),'Candidate build/core gate did not pass')
    artifact=api('artifacts/'+str(review['candidate_artifact_id']))
    require(artifact['name']=='dev14-candidate' and artifact['workflow_run']['id']==review['artifact_run_id'] and artifact['digest']==review['candidate_artifact_digest'],'Candidate artifact provenance changed')
    require(read(candidate/'manifest.json')==manifest,'Downloaded artifact manifest differs')
    require(all(identity(candidate/name)==want for name,want in manifest.items()),'Downloaded candidate differs from reviewed bytes')
    tasks=[]
    for side,rows in baseline['files'].items():
        for name,want in rows.items(): tasks.append((('dev/' if side=='dev' else '')+name,work/'previous'/side/name,want))
    for name,want in worn['files'].items(): tasks.append(('dev/worn/'+name,work/'previous/worn'/name,want))
    with ThreadPoolExecutor(max_workers=3) as pool: list(pool.map(lambda args:fetch(*args),tasks))
    site=work/'site'
    shutil.copytree(work/'previous/live',site)
    (site/'dev').mkdir()
    for name in FILES: shutil.copy2(candidate/name,site/'dev'/name)
    shutil.copytree(work/'previous/worn',site/'dev/worn')
    (site/'.nojekyll').write_text('')
    expected=FILES|{'dev/'+n for n in FILES}|{'dev/worn/'+n for n in FILES}|{'.nojekyll'}
    require({str(p.relative_to(site)) for p in site.rglob('*') if p.is_file()}==expected,'Unexpected public file set')
    for name,want in baseline['files']['live'].items(): require(identity(site/name)==want,'LIVE changed during staging')
    for name,want in worn['files'].items(): require(identity(site/'dev/worn'/name)==want,'Retained trial changed during staging')
    size=sum(p.stat().st_size for p in site.rglob('*') if p.is_file())
    require(size<1024**3,'Pages package exceeds supported site limit')
    (work/'staging.json').write_text(json.dumps({'version':'1.0.0-dev.14','source_commit':review['source_commit'],'preserved_files':18,'dev_files':9,'site_bytes':size},indent=2))
    print('DEV14_STAGED reviewed_files=9 preserved_live_and_trial=18')

def verify(output):
    review,manifest,baseline,worn=reviewed()
    output.mkdir(parents=True,exist_ok=False)
    expected={**baseline['files']['live'],**{'dev/'+k:v for k,v in manifest.items()},**{'dev/worn/'+k:v for k,v in worn['files'].items()}}
    pending=list(expected)
    def check(name):
        try: fetch(name,output/name,expected[name]);return True
        except Exception: return False
    for attempt in range(10):
        with ThreadPoolExecutor(max_workers=3) as pool: results=list(pool.map(check,pending))
        pending=[n for n,ok in zip(pending,results) if not ok]
        if not pending:
            (output/'publication-receipt.json').write_text(json.dumps({'passed':True,'version':'1.0.0-dev.14','destination':PUBLIC+'dev/','source_commit':review['source_commit'],'run_id':review['run_id'],'manifest_sha256':review['manifest_sha256'],'files':expected,'live_files_unchanged':9,'physical_iphone_verified':False},indent=2))
            print('DEV14_PUBLIC_VERIFY_OK live_unchanged=9 files=27');return
        if attempt<9: time.sleep(10)
    raise RuntimeError('Public verification failed: '+str(pending))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('command',choices=['check-review','prepare','verify']);p.add_argument('output',type=Path,nargs='?');p.add_argument('--candidate',type=Path);a=p.parse_args()
    if a.command=='check-review': reviewed()
    elif a.command=='prepare': prepare(a.output.resolve(),a.candidate.resolve())
    else: verify(a.output.resolve())
