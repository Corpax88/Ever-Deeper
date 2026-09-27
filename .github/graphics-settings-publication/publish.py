"""Publish only the exact reviewed DEV15.13 / LIVE1.0.1 artifact; preserve LIVE and Worn trial."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import argparse, hashlib, json, os, re, shutil, time, urllib.request
HERE=Path(__file__).resolve().parent
PUBLIC='https://corpax88.github.io/Ever-Deeper/'
VERSION='1.0.0-dev.15.13 / 1.0.1'
FILES={'index.html','index.pck','index.js','index.wasm','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js'}
def require(ok,message):
 if not ok: raise RuntimeError(message)
def read(path): return json.loads(path.read_text())
def identity(path):
 h=hashlib.sha256()
 with path.open('rb') as stream:
  for part in iter(lambda:stream.read(1024*1024),b''):h.update(part)
 return {'size':path.stat().st_size,'sha256':h.hexdigest()}
def reviewed():
 review=read(HERE/'review.json');manifest=read(HERE/'manifest.json');baseline=read(HERE/'baseline.json');worn=read(HERE/'worn-bundle.json')
 require(review['destination']==['dev','live'] and review['live_authorized'] is True,'Wrong destination')
 require(review['accepted'] and review['images_inspected'],'Review incomplete')
 require(set(manifest)=={'dev','live'} and all(set(m)==FILES for m in manifest.values()),'Incomplete candidate')
 for name,digest in review['reviewed_files'].items():require(identity(HERE/name)['sha256']==digest,'Reviewed file changed: '+name)
 for side in ['dev','live']:
  web=read(HERE/(side+'-evidence.json'))
  require(web['source']==review['source_commit'] and web['error'] is None and not web['errors'] and web['manifest']==manifest[side],'Wrong or failing test')
  checks=web['checks']
  require([c['ratio'] for c in checks if c['stage']=='persisted']==[1,3,2],'Persistence incomplete')
  require(any(c['stage']=='default' and c['ratio']==2 for c in checks),'Wrong default')
  require(any(c['stage']=='storage-unavailable' and c['ratio']==1 for c in checks),'Missing storage fallback')
  require(any(c['stage']=='gameplay-input' and c['before']!=c['after'] for c in checks),'Missing actual movement')
  for c in checks:
   if 'ratio' not in c:continue
   r=c['ratio'];v=c['state'];require(v['dpr']==r and v['canvas']==[776*r,420*r] and v['buffer']==v['canvas'] and not v['lost'] and v['ui']['selected']==r,'Rendering or selection failed')
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
 require(run['conclusion']=='success' and run['head_sha']==review['validation_commit'],'Wrong or failing candidate run')
 actual=api('artifacts/'+str(review['artifact_id']))
 require(actual['name']=='graphics-candidate' and actual['digest']==review['artifact_digest'] and actual['workflow_run']['id']==review['artifact_run_id'],'Artifact provenance changed')
 for side in ['dev','live']:
  require(read(candidate/side/'manifest.json')==manifest[side] and all(identity(candidate/side/n)==v for n,v in manifest[side].items()),'Downloaded candidate differs: '+side)
 tasks=[]
 for side,rows in baseline['files'].items():
  for n,want in rows.items():tasks.append((('dev/' if side=='dev' else '')+n,work/'previous'/side/n,want))
 for n,want in worn['files'].items():tasks.append(('dev/worn/'+n,work/'previous/worn'/n,want))
 with ThreadPoolExecutor(max_workers=3) as pool:list(pool.map(lambda args:fetch(*args),tasks))
 site=work/'site';site.mkdir();(site/'dev').mkdir()
 for side in ['dev','live']:
  for n in FILES:shutil.copy2(candidate/side/n,(site/'dev' if side=='dev' else site)/n)
 shutil.copytree(work/'previous/worn',site/'dev/worn');(site/'.nojekyll').write_text('')
 expected=FILES|{'dev/'+n for n in FILES}|{'dev/worn/'+n for n in FILES}|{'.nojekyll'}
 require({str(p.relative_to(site)) for p in site.rglob('*') if p.is_file()}==expected,'Unexpected public file set')
 for side in ['dev','live']:
  for n,want in manifest[side].items():require(identity((site/'dev' if side=='dev' else site)/n)==want,'Candidate changed')
 for n,want in worn['files'].items():require(identity(site/'dev/worn'/n)==want,'Trial changed')
 size=sum(p.stat().st_size for p in site.rglob('*') if p.is_file());require(size<1024**3,'Pages site too large')
 (work/'staging.json').write_text(json.dumps({'version':VERSION,'source_commit':review['source_commit'],'preserved_files':9,'updated_files':18,'site_bytes':size},indent=2))
 print('GRAPHICS_SETTINGS_STAGED updated=18 preserved=9')
def verify(output):
 review,manifest,baseline,worn=reviewed();output.mkdir(parents=True,exist_ok=False)
 expected={**manifest['live'],**{'dev/'+k:v for k,v in manifest['dev'].items()},**{'dev/worn/'+k:v for k,v in worn['files'].items()}};pending=list(expected)
 def check(name):
  try:fetch(name,output/name,expected[name]);return True
  except Exception:return False
 for attempt in range(10):
  with ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(check,pending))
  pending=[n for n,ok in zip(pending,results) if not ok]
  if not pending:
   (output/'publication-receipt.json').write_text(json.dumps({'passed':True,'version':VERSION,'destination':[PUBLIC,PUBLIC+'dev/'],'source_commit':review['source_commit'],'run_id':review['artifact_run_id'],'files':expected,'live_settings_updated':True,'retained_trial_files_unchanged':9,'physical_iphone_verified':False,'verification_scope':'Saved graphics choices only; touch, selection, framebuffer, reload persistence, blocked-storage fallback and gameplay input verified on DEV and isolated LIVE candidate. LIVE gameplay baseline preserved; no new FPS claim.'},indent=2)+'\n')
   print('GRAPHICS_SETTINGS_PUBLIC_VERIFY_OK files=27');return
  if attempt<9:time.sleep(10)
 raise RuntimeError('Public verification failed: '+str(pending))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('command',choices=['check-review','prepare','verify']);p.add_argument('output',type=Path,nargs='?');p.add_argument('--candidate',type=Path);a=p.parse_args()
 if a.command=='check-review':reviewed()
 elif a.command=='prepare':prepare(a.output.resolve(),a.candidate.resolve())
 else:verify(a.output.resolve())


