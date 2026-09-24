"""Publish only the exact reviewed DEV15.8 artifact; preserve LIVE and Worn trial."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import argparse, hashlib, json, os, shutil, time, urllib.request
HERE=Path(__file__).resolve().parent
PUBLIC='https://corpax88.github.io/Ever-Deeper/'
VERSION='1.0.0-dev.15.8'
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
 review=read(HERE/'review.json');manifest=read(HERE/'manifest.json');baseline=read(HERE/'baseline.json')
 worn=read(HERE.parent/'native-flow-trial/bundle.json')
 require(review['destination']=='dev' and review['version']==VERSION and review['live_authorized'] is False,'Wrong authorized destination')
 require(all(review.get(k) is True for k in ['independent_visual_accepted','exported_gameplay_passed','publisher_reviewed']),'Incomplete acceptance')
 require(set(manifest)==FILES,'Incomplete candidate')
 required={'manifest.json','baseline.json','native-input.json','evidence/browser.json','evidence/report-webkit.json','evidence/core.json','evidence/build.json','evidence/webkit.json','evidence/light.json','evidence/light-webkit.json','evidence/receiver-schema.json','evidence/independent-review.json','publish.py','../workflows/publish-lighttest-dev15-8.yml','../workflows/lighttest-exact-review.yml','../native-flow-trial/bundle.json'}
 require(required<=set(review['reviewed_files']),'Missing pinned evidence')
 for name,digest in review['reviewed_files'].items():require(identity(HERE/name)['sha256']==digest,'Reviewed file changed: '+name)
 require(baseline['displayed_dev_version']=='1.0.0-dev.15.7' and set(baseline['files'])=={'live','dev'},'Unexpected previous release')
 proof=read(HERE/'evidence/browser.json');build=read(HERE/'evidence/build.json');webkit=read(HERE/'evidence/webkit.json');critic=read(HERE/'evidence/independent-review.json')
 light_names={'depth-one-started','completed','restored','canvas-unchanged','all-stage-markers','end-marker','no-network-during-test','pet-lights-isolated','shadows-isolated','all-lights-isolated','original-lights-return','phase-boundaries','result-fits','pending-report-protected','exact-labelled-transfer','receipt-clears-report','cancel-restores-1','cancel-restores-3','cancel-restores-5','no-script-errors'}
 normal_names={'version','opt-in','recording-started','real-windows','real-metrics','actual-mining','no-network-while-playing','recovered-after-reload','not-auto-recording','previous-report-protected','exact-transfer','receipt-clears-pending','new-session-after-receipt','stopped','clear-needs-confirmation','confirmed-clear','no-script-errors'}
 for name in ['browser','report-webkit','light','light-webkit']:
  item=read(HERE/('evidence/'+name+'.json'))
  require(item['files']==manifest and item['version']==VERSION and item['source_commit']==review['source_commit'],'Wrong package: '+name)
  require(item['passed'] and all(c['passed'] for c in item['checks']),'Failed browser checks: '+name)
  require((light_names if name.startswith('light') else normal_names)<={c['name'] for c in item['checks']},'Missing checks: '+name)
 for item in [build,webkit,critic]:require(item['files']==manifest and item['version']==VERSION and item['source_commit']==review['source_commit'],'Evidence belongs to another build')
 core=read(HERE/'evidence/core.json')
 require(core['passed'] and all(c['passed'] for c in core['cases']) and {c['case'] for c in core['cases']}=={'input','touch','dev-tools','build-flavor'},'Core gameplay failed')
 require(build['native_files_unchanged']==read(HERE/'native-input.json') and build['save_path']=='user://ever_deeper_dev_run_v3.sav','Native resources or saves changed')
 require(webkit.get('completed_observation') is True and not webkit.get('failure') and not webkit.get('crashed'),'Ordinary WebKit startup failed')
 require(webkit['normal_startup'] and webkit['fixture_args']==[] and '06-confirmed-new-game.png' in webkit['images'],'Missing normal saved-game observation')
 require(critic['accepted'] is True and critic['final_build_images_inspected'] is True,'Independent acceptance missing')
 receiver=read(HERE/'evidence/receiver-schema.json')
 require(receiver['passed'] and receiver['source_commit']==review['source_commit'] and receiver['labelled_reports_round_trip']==['chromium','webkit'],'Labelled reports rejected by existing receiver')
 require(review['physical_iphone_verified'] is False,'Unverified phone claim')
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
 exported=api('runs/'+str(review['export_run_id']))
 require(exported['head_sha']==review['source_commit'],'Wrong export source')
 origin=api('artifacts/'+str(review['export_artifact']['id']))
 require(origin['name']=='dev15-8-candidate' and origin['digest']==review['export_artifact']['digest'] and origin['workflow_run']['id']==review['export_run_id'],'Wrong original export artifact')
 jobs=api('runs/'+str(review['artifact_run_id'])+'/jobs?filter=latest')['jobs']
 require(all(any(j['name']==n and j['conclusion']=='success' for j in jobs) for n in ['build','browser']),'Build/browser gates incomplete')
 require({label:want['name'] for label,want in review['artifacts'].items()}=={'candidate':'dev15-8-candidate','build':'dev15-8-build-review','browser':'dev15-8-browser-review'},'Required artifact set incomplete')
 for label,want in review['artifacts'].items():
  actual=api('artifacts/'+str(want['id']))
  require(actual['name']==want['name'] and actual['digest']==want['digest'] and actual['workflow_run']['id']==review['artifact_run_id'],'Artifact provenance changed: '+label)
 require(review['artifacts']['candidate']['name']=='dev15-8-candidate','Wrong candidate artifact')
 require(read(candidate/'manifest.json')==manifest and all(identity(candidate/n)==v for n,v in manifest.items()),'Downloaded candidate differs from accepted bytes')
 tasks=[]
 for side,rows in baseline['files'].items():
  for n,want in rows.items():tasks.append((('dev/' if side=='dev' else '')+n,work/'previous'/side/n,want))
 for n,want in worn['files'].items():tasks.append(('dev/worn/'+n,work/'previous/worn'/n,want))
 with ThreadPoolExecutor(max_workers=3) as pool:list(pool.map(lambda args:fetch(*args),tasks))
 site=work/'site';shutil.copytree(work/'previous/live',site);(site/'dev').mkdir()
 for n in FILES:shutil.copy2(candidate/n,site/'dev'/n)
 shutil.copytree(work/'previous/worn',site/'dev/worn');(site/'.nojekyll').write_text('')
 expected=FILES|{'dev/'+n for n in FILES}|{'dev/worn/'+n for n in FILES}|{'.nojekyll'}
 require({str(p.relative_to(site)) for p in site.rglob('*') if p.is_file()}==expected,'Unexpected public file set')
 for n,want in baseline['files']['live'].items():require(identity(site/n)==want,'LIVE changed')
 for n,want in worn['files'].items():require(identity(site/'dev/worn'/n)==want,'Trial changed')
 size=sum(p.stat().st_size for p in site.rglob('*') if p.is_file());require(size<1024**3,'Pages site too large')
 (work/'staging.json').write_text(json.dumps({'version':VERSION,'source_commit':review['source_commit'],'preserved_files':18,'dev_files':9,'site_bytes':size},indent=2))
 print('LIGHTTEST_DEV15_8_STAGED reviewed_files=9 preserved=18')
def verify(output):
 review,manifest,baseline,worn=reviewed();output.mkdir(parents=True,exist_ok=False)
 expected={**baseline['files']['live'],**{'dev/'+k:v for k,v in manifest.items()},**{'dev/worn/'+k:v for k,v in worn['files'].items()}};pending=list(expected)
 def check(name):
  try:fetch(name,output/name,expected[name]);return True
  except Exception:return False
 for attempt in range(10):
  with ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(check,pending))
  pending=[n for n,ok in zip(pending,results) if not ok]
  if not pending:
   (output/'publication-receipt.json').write_text(json.dumps({'passed':True,'version':VERSION,'destination':PUBLIC+'dev/','source_commit':review['source_commit'],'run_id':review['artifact_run_id'],'files':expected,'live_files_unchanged':9,'retained_trial_files_unchanged':9,'physical_iphone_verified':False,'verification_scope':'DEV reversible depth-one lighting diagnostic with labelled recording/transfer in Mac Chromium and Apple WebKit, normal startup and input. Actual iPhone experiment remains pending; no FPS fix claimed.'},indent=2)+'\n')
   print('LIGHTTEST_DEV15_8_PUBLIC_VERIFY_OK files=27');return
  if attempt<9:time.sleep(10)
 raise RuntimeError('Public verification failed: '+str(pending))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('command',choices=['check-review','prepare','verify']);p.add_argument('output',type=Path,nargs='?');p.add_argument('--candidate',type=Path);a=p.parse_args()
 if a.command=='check-review':reviewed()
 elif a.command=='prepare':prepare(a.output.resolve(),a.candidate.resolve())
 else:verify(a.output.resolve())

