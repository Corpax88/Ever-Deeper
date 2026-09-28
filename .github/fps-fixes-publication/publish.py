"""Publish only the exact reviewed DEV15.17 artifact; preserve LIVE and Worn trial."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import argparse, hashlib, json, os, re, shutil, time, urllib.request
HERE=Path(__file__).resolve().parent
PUBLIC='https://corpax88.github.io/Ever-Deeper/'
VERSION='1.0.0-dev.15.17'
FILES={'index.html','index.pck','index.js','index.wasm','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js'}
REVIEWED_FILES={'publish.py','../workflows/publish-fps-fixes.yml','manifest.json','baseline.json','worn-bundle.json',
 'evidence/worker1.json','evidence/worker2.json','evidence/worker1-build.json','evidence/worker2-build.json',
 'evidence/core.json','evidence/startup.json','evidence/independent-review.json'}
CORE_CASES={'input','premium-core','mole-autonomy','crusher','one-point-zero-state','one-point-zero-migration'}
GRAPHICAL_GATES={'cpu-production-parity','owned-pose-parity','unchanged-music-gains','full-hero-in-game',
 'motion-bench-parity','real-mining-motion-parity','resize-restored','menu-pause','real-walking',
 'transition-hub','transition-depth','transition-endless','transition-deepheart','transition-surface'}
def require(ok,message):
 if not ok: raise RuntimeError(message)
def read(path): return json.loads(path.read_text())
def file_manifest(rows,label):
 require(set(rows)==FILES,'Incomplete '+label+' file set')
 for name,want in rows.items():
  require(type(want.get('size')) is int and want['size']>0 and re.fullmatch('[0-9a-f]{64}',want.get('sha256','')),'Invalid '+label+' identity: '+name)
def identity(path):
 h=hashlib.sha256()
 with path.open('rb') as stream:
  for part in iter(lambda:stream.read(1024*1024),b''):h.update(part)
 return {'size':path.stat().st_size,'sha256':h.hexdigest()}
def reviewed():
 review=read(HERE/'review.json');manifest=read(HERE/'manifest.json');baseline=read(HERE/'baseline.json');worn=read(HERE/'worn-bundle.json')
 require(review['destination']=='dev' and review['version']==VERSION and review['live_authorized'] is False,'Wrong destination')
 require(review['accepted'] is True and review['images_inspected'] is True,'Review incomplete')
 require(re.fullmatch('[0-9a-f]{40}',review['validation_commit']) and review['source_commit']==review['validation_commit'],'Wrong build source')
 require(all(type(review[k]) is int and review[k]>0 for k in ['artifact_run_id','artifact_id']),'Invalid artifact identifiers')
 require(re.fullmatch('sha256:[0-9a-f]{64}',review['artifact_digest']),'Invalid artifact digest')
 file_manifest(manifest,'candidate')
 require(set(baseline['files'])=={'live','dev'} and baseline['displayed_dev_version']=='1.0.0-dev.15.16','Wrong rollback baseline')
 for side,rows in baseline['files'].items():file_manifest(rows,side)
 require(worn['destination']=='dev/worn','Wrong retained trial')
 file_manifest(worn['files'],'retained trial')
 require(baseline['files']['dev']['index.pck']['sha256']=='ee5a77d6c0b15d84bb1b44c85f1aa777aeb555293e0ba11747a400d6bc9a4d72','Wrong DEV15.16 rollback PCK')
 for name in FILES-{'index.html','index.pck','index.js','index.audio.position.worklet.js'}:
  require(manifest[name]==baseline['files']['dev'][name],'Unexpected runtime/asset change: '+name)
 require(REVIEWED_FILES<=set(review['reviewed_files']),'Review does not bind all publisher, manifest and evidence files')
 for name,digest in review['reviewed_files'].items():
  path=(HERE/name).resolve()
  require(path.is_relative_to(HERE.parent.parent.resolve()) and re.fullmatch('[0-9a-f]{64}',digest),'Invalid reviewed file: '+name)
  require(identity(path)['sha256']==digest,'Reviewed file changed: '+name)
 for worker in [1,2]:
  web=read(HERE/('evidence/worker'+str(worker)+'.json'))
  build=read(HERE/('evidence/worker'+str(worker)+'-build.json'))
  require(build['source']==review['validation_commit'] and build['variants']['release']['files']==manifest,'Graphical test built different release bytes')
  require(build['baseline']==baseline['files']['dev'] and build['baseline_source']=='0225855d5b243fadf75c5267898ac2cd6edb3d0b','Graphical test used different baseline')
  require(all(build[k] is True for k in ['depth_prepass_unchanged','fbo_cache_excluded','contact_pitch_hoist_excluded']),'Parked experiment included')
  require(web['source']==review['validation_commit'] and str(web['worker'])==str(worker) and web['error'] is None,'Wrong or failing graphical test')
  require(GRAPHICAL_GATES<={c['label'] for c in web['checks']} and all(c['passed'] is True for c in web['checks']),'Missing or failed graphical gate')
  comparisons=[s for s in web['stages'] if s['purpose']=='original-package-vs-production-fixes']
  sequence=['baseline','candidate','candidate','baseline'] if worker==1 else ['candidate','baseline','baseline','candidate']
  require([s['label'] for s in comparisons]==sequence,'Missing original/candidate comparison')
  for stage in comparisons:
   require([w['scene'] for w in stage['windows']]==['surface','mining'],'Missing measured scene')
   require(all(w['raf']['elapsed_ms']>0 and w['raf']['frames']>0 and len(w['raf']['intervals_ms'])==w['raf']['frames'] for w in stage['windows']),'Empty or truncated timing evidence')
  require(all(s['error'] is None for s in web['stages']),'Failed stage')
  require(len(web['pairs'])==21 and all(sum(p['pose']==pose for p in web['pairs'])==3 for pose in range(7)),'Missing native-image comparisons')
  require(all(p['max']==0 and p['changed']==0 for p in web['pairs']),'Image mismatch')
 core=read(HERE/'evidence/core.json')
 require(core['passed'] is True and len(core['cases'])==6 and {c['case'] for c in core['cases']}==CORE_CASES and all(c['passed'] is True and c['exit_code']==0 for c in core['cases']) and core['files']==manifest,'Core gameplay/save checks missing or wrong candidate')
 startup=read(HERE/'evidence/startup.json')
 require(startup.get('completed_observation') is True and not startup.get('failure') and not startup.get('crashed'),'Ordinary startup failed')
 require(startup['source_commit']==review['validation_commit'] and startup['files']==manifest and startup['version']==VERSION,'Different ordinary-startup candidate')
 require(startup['normal_startup'] is True and startup['fixture_args']==[] and len(startup['images'])==6,'Ordinary startup evidence incomplete')
 critique=read(HERE/'evidence/independent-review.json')
 require(critique['accepted'] is True and critique['images_inspected'] is True,'Independent review incomplete')
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
 review,manifest,baseline,worn=reviewed();require(not work.exists(),'Use fresh publication workspace');work.mkdir(parents=True)
 def api(path):
  request=urllib.request.Request('https://api.github.com/repos/Corpax88/Ever-Deeper/actions/'+path,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
  with urllib.request.urlopen(request,timeout=30) as response:return json.load(response)
 run=api('runs/'+str(review['artifact_run_id']))
 require(run['status']=='completed' and run['conclusion']=='success' and run['head_sha']==review['validation_commit'] and run['path']=='.github/workflows/fps-fixes-v2.yml','Wrong or failing candidate run')
 actual=api('artifacts/'+str(review['artifact_id']))
 require(actual['id']==review['artifact_id'] and actual['expired'] is False and actual['name']=='fps-fixes-v2-candidate' and actual['digest']==review['artifact_digest'] and actual['workflow_run']['id']==review['artifact_run_id'] and actual['workflow_run']['head_sha']==review['validation_commit'],'Artifact provenance changed')
 require(read(candidate/'manifest.json')==manifest and all(identity(candidate/n)==v for n,v in manifest.items()),'Downloaded candidate differs from accepted bytes')
 tasks=[]
 for side,rows in baseline['files'].items():
  for n,want in rows.items():tasks.append((('dev/' if side=='dev' else '')+n,work/'previous'/side/n,want))
 for n,want in worn['files'].items():tasks.append(('dev/worn/'+n,work/'previous/worn'/n,want))
 with ThreadPoolExecutor(max_workers=3) as pool:list(pool.map(lambda args:fetch(*args),tasks))
 (work/'previous/dev/manifest.json').write_text(json.dumps(baseline['files']['dev'],indent=2)+'\n')
 site=work/'site';shutil.copytree(work/'previous/live',site);(site/'dev').mkdir()
 for n in FILES:shutil.copy2(candidate/n,site/'dev'/n)
 shutil.copytree(work/'previous/worn',site/'dev/worn');(site/'.nojekyll').write_text('')
 expected=FILES|{'dev/'+n for n in FILES}|{'dev/worn/'+n for n in FILES}|{'.nojekyll'}
 require({str(p.relative_to(site)) for p in site.rglob('*') if p.is_file()}==expected,'Unexpected public file set')
 for n,want in baseline['files']['live'].items():require(identity(site/n)==want,'LIVE changed')
 for n,want in worn['files'].items():require(identity(site/'dev/worn'/n)==want,'Trial changed')
 for n,want in manifest.items():require(identity(site/'dev'/n)==want,'Staged DEV differs from accepted artifact')
 size=sum(p.stat().st_size for p in site.rglob('*') if p.is_file());require(size<1024**3,'Pages site too large')
 (work/'staging.json').write_text(json.dumps({'version':VERSION,'source_commit':review['source_commit'],'artifact_run_id':review['artifact_run_id'],'artifact_id':review['artifact_id'],'artifact_digest':review['artifact_digest'],'review_sha256':identity(HERE/'review.json')['sha256'],'preserved_files':18,'dev_files':9,'site_bytes':size,'rollback_version':baseline['displayed_dev_version'],'rollback_files':baseline['files']['dev']},indent=2))
 print('FPS_FIXES_DEV15_17_STAGED reviewed_files=9 preserved=18')
def verify(output):
 review,manifest,baseline,worn=reviewed();output.mkdir(parents=True,exist_ok=False)
 expected={**baseline['files']['live'],**{'dev/'+k:v for k,v in manifest.items()},**{'dev/worn/'+k:v for k,v in worn['files'].items()}};pending=list(expected)
 require(len(expected)==27,'Wrong final public file count')
 def check(name):
  try:fetch(name,output/name,expected[name]);return True
  except Exception:return False
 for attempt in range(10):
  with ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(check,pending))
  pending=[n for n,ok in zip(pending,results) if not ok]
  if not pending:
   (output/'publication-receipt.json').write_text(json.dumps({'passed':True,'version':VERSION,'destination':PUBLIC+'dev/','source_commit':review['source_commit'],'run_id':review['artifact_run_id'],'artifact_id':review['artifact_id'],'artifact_digest':review['artifact_digest'],'review_sha256':identity(HERE/'review.json')['sha256'],'files':expected,'live_files_unchanged':9,'retained_trial_files_unchanged':9,'physical_iphone_verified':False,'verification_scope':'Four scoped runtime overhead reductions: private fresh-pose ownership, repeated music gains, music position messages and companion paths. FBO and contact pitch-hoist experiments excluded. Exact-image and gameplay checks plus original/candidate Mac timing; no physical-iPhone FPS guarantee. LIVE and saved-game identity preserved.'},indent=2)+'\n')
   print('FPS_FIXES_DEV15_17_PUBLIC_VERIFY_OK files=27');return
  if attempt<9:time.sleep(10)
 (output/'publication-receipt.json').write_text(json.dumps({'passed':False,'version':VERSION,'source_commit':review['source_commit'],'artifact_run_id':review['artifact_run_id'],'artifact_id':review['artifact_id'],'files':expected,'unverified_files':pending},indent=2)+'\n')
 raise RuntimeError('Public verification failed: '+str(pending))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('command',choices=['check-review','prepare','verify']);p.add_argument('output',type=Path,nargs='?');p.add_argument('--candidate',type=Path);a=p.parse_args()
 if a.command=='check-review':reviewed()
 elif a.command=='prepare':prepare(a.output.resolve(),a.candidate.resolve())
 else:verify(a.output.resolve())


