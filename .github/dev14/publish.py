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
    baseline=read(HERE/'baseline.json')
    worn=read(HERE.parent/'native-flow-trial/bundle.json')
    version='1.0.0-dev.14.2'
    require(review['destination']=='dev' and review['version']==version,'Wrong release destination')
    require(review['live_authorized'] is False,'LIVE is not authorized')
    require(all(review.get(k) is True for k in ['ordinary_game_adopted','independent_visual_accepted','exported_gameplay_passed','publisher_reviewed']),'Incomplete release review')
    require(set(manifest)==FILES,'Incomplete DEV file set')
    for filename,key in {
        'manifest.json':'manifest_sha256','baseline.json':'baseline_sha256',
        'evidence/browser-report.json':'browser_report_sha256',
        'evidence/core-results.json':'core_results_sha256',
        'evidence/build.json':'build_report_sha256',
        'evidence/native-preparation.json':'native_preparation_sha256',
        'evidence/webkit-startup.json':'webkit_startup_sha256',
        'evidence/native-optimization.json':'native_optimization_sha256',
        'evidence/local-regression.json':'native_regression_sha256',
        'evidence/sustained-render.json':'sustained_render_sha256',
        'evidence/independent-review.json':'independent_review_sha256',
        'publish.py':'publisher_sha256',
    }.items():
        require(identity(HERE/filename)['sha256']==review[key],'Reviewed file changed: '+filename)
    require(identity(HERE.parent/'workflows/publish-dev14.yml')['sha256']==review['publisher_workflow_sha256'],'Publisher workflow changed')
    require(identity(HERE.parent/'native-flow-trial/bundle.json')['sha256']==review['retained_trial_manifest_sha256'],'Retained trial changed')
    require(baseline['displayed_dev_version']=='1.0.0-dev.14.1' and set(baseline['files'])=={'live','dev'},'Wrong previous DEV baseline')
    proof=read(HERE/'evidence/browser-report.json')
    build=read(HERE/'evidence/build.json')
    for item in [proof,build]:
        require(item['version']==version and item['files']==manifest and item['source_commit']==review['source_commit'],'Tested package provenance differs')
    require(proof['passed'] is True,'Ordinary graphical gameplay failed')
    names={c['name'] for c in proof['checks']}
    require({'00-normal-dev14-menu','moss-up','moss-right','moss-down','moss-left','endless-up','endless-right','endless-down','endless-left','iron-restored','drill-restored','worn-outfit-reentry','surface-ordinary','depth-ordinary','hub-ordinary','deepheart-ordinary','surface-touch-release','dev14-pause','dev14-resumed','resume-real-input'}<=names,'Incomplete ordinary gameplay evidence')
    core=read(HERE/'evidence/core-results.json')
    require(core['passed'] and all(c['passed'] for c in core['cases']) and {c['case'] for c in core['cases']}=={'input','overhaul','touch','build-flavor'},'Core gameplay gate failed')
    native=read(HERE/'evidence/native-preparation.json')
    require(native['status']=='complete' and native['geometry_and_bindings_identical'] and native['source_fingerprint']==native['prepared_fingerprint'] and native['prepared_fingerprint']['vertices']==1033415,'Native geometry/bindings changed')
    webkit=read(HERE/'evidence/webkit-startup.json')
    for item in [webkit]:
        require(item.get('completed_observation') is True and not item.get('failure') and not item.get('crashed'),'Startup observer failed')
        require(item['files']==manifest and item['version']==version and item['source_commit']==review['source_commit'] and item['fixture_args']==[],'Startup checked a different or fixture package')
    require(len([e for e in webkit['events'] if e['event']=='navigation'])==2 and '06-confirmed-new-game.png' in webkit['images'],'Incomplete normal WebKit startup evidence')
    optimized=read(HERE/'evidence/native-optimization.json')
    reduction=optimized['optimization']
    require(optimized['status']=='complete' and optimized['animation_and_bindings_preserved'] and not optimized['geometry_and_bindings_identical'],'Derived geometry must be declared explicitly')
    require(optimized['original_scene_sha256']==native['scene_sha256'] and optimized['source_sha256']==native['source_sha256'],'LOD changed approved source')
    require(reduction['method']=='godot-importer-indexed-lod' and reduction['lod']==2 and reduction['source_vertices']==1033415 and reduction['triangles']<100000 and reduction['vertex_attributes_preserved'],'Unreviewed mesh reduction')
    regression=read(HERE/'evidence/local-regression.json')
    require(regression['baseline_empty_frames']==24 and regression['fixed_empty_frames']==0 and regression['paired_geometry_poses']==36 and regression['fixed_minimum_viewport_margin_px']>0,'Native regression evidence incomplete')
    require(regression['runtime_motion_sha256']==review['runtime_motion_sha256'] and regression['optimizer_sha256']==review['optimizer_sha256'],'Reviewed implementation changed')
    require({'moss-continuous-steering','sustained-render-120s','moss-after-120s'}<=names,'Missing steering or sustained rendering evidence')
    steering=next(c for c in proof['checks'] if c['name']=='moss-continuous-steering')['after']['steering']
    require(steering['done'] and steering['samples']==72 and steering['clipped']==0 and steering['margin']>0,'Exported steering clipped the hero')
    sustained=read(HERE/'evidence/sustained-render.json')
    require(proof['runtime']['dpr']==3 and len(sustained['windows'])==8 and sum(w['seconds'] for w in sustained['windows'])>=120,'Missing sustained DPR3 measurement')
    measured=next(c for c in proof['checks'] if c['name']=='sustained-render-120s')['windows']
    require(sustained['windows']==measured,'Sustained measurements belong to another package')
    require(all(w['after']['active_rigs']==1 and not w['after']['native']['failed'] for w in sustained['windows']),'Sustained renderer failed')
    require(all(w['after']['native']['updates']>w['before']['native']['updates'] for w in measured),'Sustained native renderer stopped updating')
    require(all(w['fps']>=50.0 for w in measured),'Mac DPR3 sustained cadence fell below 50 FPS; review before publishing')
    require(review['iphone_simulator_verified'] is False and review['physical_iphone_verified'] is False,'Unverified iPhone claim')
    critic=read(HERE/'evidence/independent-review.json')
    require(critic['accepted'] is True and critic['source_commit']==review['source_commit'] and critic['files']==manifest,'Independent review has not accepted this package')
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
    # Publish the exact candidate accepted by Mac graphical/core and normal WebKit checks.
    def api(path):
        request=urllib.request.Request('https://api.github.com/repos/Corpax88/Ever-Deeper/actions/'+path,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
        with urllib.request.urlopen(request,timeout=30) as response: return json.load(response)
    run=api('runs/'+str(review['run_id']))
    require(run['conclusion']=='success' and run['head_sha']==review['source_commit'] and review['run_id']==review['artifact_run_id'],'Wrong or failing candidate run')
    jobs=api('runs/'+str(review['run_id'])+'/jobs?filter=latest')['jobs']
    require(all(any(j['name']==name and j['conclusion']=='success' for j in jobs) for name in ['build','browser']),'Candidate build/browser gates did not pass')
    artifact=api('artifacts/'+str(review['candidate_artifact_id']))
    require(artifact['name']=='dev14-candidate' and artifact['workflow_run']['id']==review['artifact_run_id'] and artifact['digest']==review['candidate_artifact_digest'],'Candidate artifact provenance changed')
    for path,key in [('scripts/player/native_worn/task_motion.gd','runtime_motion_sha256'),('.github/dev14/optimize-native.gd','optimizer_sha256')]:
        url='https://raw.githubusercontent.com/Corpax88/Ever-Deeper/'+review['source_commit']+'/'+path
        with urllib.request.urlopen(url,timeout=30) as response: actual=hashlib.sha256(response.read()).hexdigest()
        require(actual==review[key],'Regression source differs from immutable candidate: '+path)
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
    (work/'staging.json').write_text(json.dumps({'version':'1.0.0-dev.14.2','source_commit':review['source_commit'],'preserved_files':18,'dev_files':9,'site_bytes':size},indent=2))
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
            (output/'publication-receipt.json').write_text(json.dumps({'passed':True,'version':'1.0.0-dev.14.2','destination':PUBLIC+'dev/','source_commit':review['source_commit'],'run_id':review['run_id'],'manifest_sha256':review['manifest_sha256'],'files':expected,'live_files_unchanged':9,'physical_iphone_verified':False,'iphone_simulator_verified':False,'verification_scope':'Mac Chromium DPR3 gameplay, steering regression and 120-second rendering; normal Mac WebKit startup. Physical iPhone remains unverified'},indent=2))
            print('DEV14_PUBLIC_VERIFY_OK live_unchanged=9 files=27');return
        if attempt<9: time.sleep(10)
    raise RuntimeError('Public verification failed: '+str(pending))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('command',choices=['check-review','prepare','verify']);p.add_argument('output',type=Path,nargs='?');p.add_argument('--candidate',type=Path);a=p.parse_args()
    if a.command=='check-review': reviewed()
    elif a.command=='prepare': prepare(a.output.resolve(),a.candidate.resolve())
    else: verify(a.output.resolve())
