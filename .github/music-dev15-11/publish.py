"""Publish only the exact reviewed DEV15.11 artifact; preserve LIVE and Worn trial."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import argparse, hashlib, json, os, re, shutil, time, urllib.request
HERE=Path(__file__).resolve().parent
PUBLIC='https://corpax88.github.io/Ever-Deeper/'
VERSION='1.0.0-dev.15.11'
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
 require(review['destination']=='dev' and review['version']==VERSION and review['live_authorized'] is False,'Wrong destination')
 require(review['source_commit']=='ba396beeed9e587a8dc700edef7b28b79f1095d6','Unexpected candidate')
 require(review['accepted'] and review['prior_independent_visual_acceptance_retained'],'Incomplete candidate review')
 require(set(manifest)==FILES,'Incomplete candidate')
 required={'manifest.json','baseline.json','worn-bundle.json','evidence/core.json','evidence/webkit.json','evidence/perf1.json','evidence/perf2.json','evidence/acceptance.json','publish.py','../workflows/publish-music-dev15-11.yml'}
 require(required<=set(review['reviewed_files']),'Missing pinned evidence')
 for name,digest in review['reviewed_files'].items():require(identity(HERE/name)['sha256']==digest,'Reviewed file changed: '+name)
 require(baseline['displayed_dev_version']=='1.0.0-dev.15.10' and set(baseline['files'])=={'live','dev'},'Unexpected baseline')
 core=read(HERE/'evidence/core.json');web=read(HERE/'evidence/webkit.json');accepted=read(HERE/'evidence/acceptance.json')
 require(core['passed'] and all(c['passed'] for c in core['cases']) and {c['case'] for c in core['cases']}=={'input','touch','build-flavor','crusher','mole-autonomy','one-point-zero-world'},'Core failed')
 save=next(c for c in core['cases'] if c['case']=='build-flavor')
 require(any('save=user://ever_deeper_dev_run_v3.sav' in s and 'isolated=true' in s for s in save['completion']),'Save identity changed')
 require(web['files']==manifest and web['source_commit']==review['source_commit'] and web['version']==VERSION,'Wrong startup package')
 require(web['completed_observation'] and web['normal_startup'] and web['fixture_args']==[] and len(web['samples'])>=40,'Ordinary startup incomplete')
 require(all(s.get('lost') is False for s in web['samples']),'Context loss')
 require(not any(e.get('event') in {'error','pageerror','crash'} or re.search(r'SCRIPT ERROR|Parse Error|^ERROR:',e.get('text','')) for e in web['events']),'Startup error')
 import statistics,math
 blocks=[]
 for i in [1,2]:
  p=read(HERE/('evidence/perf'+str(i)+'.json'))
  require(p['original_source']=='ab0c12ff579134e0a092946bd92973e4599a073c' and p['candidate_source']==review['source_commit'],'Wrong comparison sources')
  require(p['files']['candidate']['index.js']==manifest['index.js'] and p['files']['original']['index.js']==baseline['files']['dev']['index.js'],'Wrong production audio glue')
  require(p['passed'] and p['source_commit']==review['performance_commit'] and len(p['windows'])==128 and all(c['passed'] for c in p['checks']),'Controlled comparison incomplete')
  require(sum(c['name'].startswith('inactive engine paused') for c in p['checks'])==128,'Missing inactive engine isolation')
  for gate in ['inactive frame unchanged','inactive frame still unchanged','render context intact','game pixels rendered']:
   require(sum(c['name'].startswith(gate+' ') and c['passed'] for c in p['checks'])==128,'Missing rendered workload gate: '+gate)
  require(any(c['name']=='disjoint process ownership' and c['passed'] for c in p['checks']),'Shared process ownership')
  require(any(c['name']=='all browser children exited' and c['passed'] for c in p['checks']),'Missing cleanup')
  require(all(r['canvas']==[2328,1260] and r['dpr']==3 and 'Apple' in r['renderer'] for r in p['runtimes']),'Wrong resolution/platform')
  values=[]
  for k in range(0,128,2):
   pair=p['windows'][k:k+2];a=next(w for w in pair if w['side']=='original');b=next(w for w in pair if w['side']=='candidate')
   require(all(w['native']['active'] and w['impacts']>=5 and w['audioElapsed']>3.5 and w['position']==[1400,312] and w['renderedFraction']>0.2 and w['contextState']=={'lost':False,'losses':0} and w['inactiveFrameUnchanged'] for w in pair),'Changed workload')
   values.append(100*((b['frames']/b['seconds'])/(a['frames']/a['seconds'])-1))
  require(statistics.mean(values)>-2,'Worker noninferiority failed')
  blocks.extend(statistics.mean(values[k:k+8]) for k in range(0,64,8))
 lower=statistics.mean(blocks)-2.131449545559323*statistics.stdev(blocks)/math.sqrt(16)
 require(lower>-2 and accepted['accepted'] and accepted['lower95_percent']>-2,'Noninferiority failed')
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
 jobs=api('runs/'+str(review['artifact_run_id'])+'/jobs?filter=latest')['jobs']
 require(all(any(j['name']==n and j['conclusion']=='success' for j in jobs) for n in ['build','browser']),'Build/browser gates incomplete')
 perf=api('runs/'+str(review['performance_run_id']))
 require(perf['conclusion']=='success' and perf['head_sha']==review['performance_commit'],'Wrong or failing performance run')
 require({a['name'] for a in review['performance_artifacts']}=={'music-controlled-1','music-controlled-2'},'Missing performance artifacts')
 for want in review['performance_artifacts']:
  actual=api('artifacts/'+str(want['id']))
  require(actual['name']==want['name'] and actual['digest']==want['digest'] and actual['workflow_run']['id']==review['performance_run_id'],'Performance provenance changed')
 require({label:want['name'] for label,want in review['artifacts'].items()}=={'candidate':'music-candidate','build':'music-build','browser':'music-startup'},'Required artifact set incomplete')
 for label,want in review['artifacts'].items():
  actual=api('artifacts/'+str(want['id']))
  require(actual['name']==want['name'] and actual['digest']==want['digest'] and actual['workflow_run']['id']==review['artifact_run_id'],'Artifact provenance changed: '+label)
 require(review['artifacts']['candidate']['name']=='music-candidate','Wrong candidate artifact')
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
 print('MUSIC_DEV15_11_STAGED reviewed_files=9 preserved=18')
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
   (output/'publication-receipt.json').write_text(json.dumps({'passed':True,'version':VERSION,'destination':PUBLIC+'dev/','source_commit':review['source_commit'],'run_id':review['artifact_run_id'],'files':expected,'live_files_unchanged':9,'retained_trial_files_unchanged':9,'physical_iphone_verified':False,'verification_scope':'Music streams and PCM reused. Six final core cases, ordinary startup/save, prior audio lifecycle and isolated process noninferiority verified. No physical-phone or sustained-FPS claim.'},indent=2)+'\n')
   print('MUSIC_DEV15_11_PUBLIC_VERIFY_OK files=27');return
  if attempt<9:time.sleep(10)
 raise RuntimeError('Public verification failed: '+str(pending))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('command',choices=['check-review','prepare','verify']);p.add_argument('output',type=Path,nargs='?');p.add_argument('--candidate',type=Path);a=p.parse_args()
 if a.command=='check-review':reviewed()
 elif a.command=='prepare':prepare(a.output.resolve(),a.candidate.resolve())
 else:verify(a.output.resolve())

