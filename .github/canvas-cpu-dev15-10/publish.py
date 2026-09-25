"""Publish only the exact reviewed DEV15.10 artifact; preserve LIVE and Worn trial."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import argparse, hashlib, json, os, re, shutil, time, urllib.request
HERE=Path(__file__).resolve().parent
PUBLIC='https://corpax88.github.io/Ever-Deeper/'
VERSION='1.0.0-dev.15.10'
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
 require(review['independent_visual_accepted'] and review['exported_gameplay_passed'] and review['publisher_reviewed'],'Incomplete review')
 require(set(manifest)==FILES,'Incomplete candidate')
 required={'manifest.json','baseline.json','worn-bundle.json','evidence/source-lineage.json','evidence/ui.json','evidence/ui-review.json','evidence/native-review.json','evidence/core.json','evidence/build.json','evidence/webkit.json','evidence/perf1.json','evidence/perf2.json','evidence/performance-review.json','evidence/independent-review.json','publish.py','../workflows/publish-canvas-cpu-dev15-10.yml'}
 require(required<=set(review['reviewed_files']),'Missing pinned evidence')
 for name,digest in review['reviewed_files'].items():require(identity(HERE/name)['sha256']==digest,'Reviewed file changed: '+name)
 require(baseline['displayed_dev_version']=='1.0.0-dev.15.9' and set(baseline['files'])=={'live','dev'},'Unexpected previous release')
 build=read(HERE/'evidence/build.json');webkit=read(HERE/'evidence/webkit.json');critic=read(HERE/'evidence/independent-review.json')
 for item in [build,webkit,critic]:require(item['files']==manifest and item['source_commit']==review['source_commit'],'Wrong final package evidence')
 require(webkit['version']==VERSION and critic['version']==VERSION,'Final version not reviewed')
 require(build['all_original_resource_md5_verified'] and build['original_files']==baseline['files']['dev'],'Original exported resources differ')
 require(set(build['replaced_remaps'])=={s+'.remap' for s in ['scripts/ui/premium_menu.gd', 'scripts/main.gd', 'scripts/companion/companion_interface.gd', 'scripts/qa/suites/skills_browser_review.gd', 'scripts/qa/overhaul_qa.gd', 'scripts/lighting/cave_light_occluders.gd', 'scripts/world/mossvein_mine.gd', 'scripts/player/native_worn_visual.gd', 'scripts/dev/visual_capture_driver.gd', 'scripts/qa/suites/fps_review.gd', 'scripts/qa/suites/smoke.gd', 'scripts/qa/suites/crusher.gd', 'scripts/qa/suites/mole_autonomy.gd', 'scripts/qa/suites/world_fixtures.gd', 'scripts/qa/suites/dev14_review.gd']},'Unexpected script remap set')
 require(len(build['replaced_remaps'])==15 and len(build['added_source_scripts'])==15,'Unexpected appended source count')
 core=read(HERE/'evidence/core.json');require(core['passed'] and all(c['passed'] for c in core['cases']) and {c['case'] for c in core['cases']}=={'input','touch','build-flavor','crusher','mole-autonomy','one-point-zero-world'},'Core gameplay failed')
 save=next(c for c in core['cases'] if c['case']=='build-flavor');require(any('save=user://ever_deeper_dev_run_v3.sav' in s and 'isolated=true' in s for s in save['completion']),'DEV save identity changed')
 require(webkit.get('completed_observation') is True and not webkit.get('failure') and not webkit.get('crashed') and webkit['normal_startup'] and webkit['fixture_args']==[] and '06-confirmed-new-game.png' in webkit['images'],'Ordinary WebKit save/startup failed')
 require(len(webkit['samples'])>=40 and all(sample.get('lost') is False for sample in webkit['samples']),'Context loss or missing context samples')
 require(not any(e.get('event') in {'error','pageerror','crash'} or re.search(r'SCRIPT ERROR|Parse Error|^ERROR:',e.get('text','')) for e in webkit['events']),'Recorded startup runtime error')
 lineage=read(HERE/'evidence/source-lineage.json');require(lineage['base_commit']==review['comparison_source'] and lineage['head_commit']==review['source_commit'] and lineage['only_runtime_source_change_is_version'] is True,'Missing explicit version-only lineage')
 require(set(lineage['changed_files'])=={'.github/integrated-candidate/build.py','.github/workflows/integrated-candidate.yml','scripts/ui/premium_menu.gd','scripts/dev/visual_capture_driver.gd'},'Unexpected final code change')
 ui=read(HERE/'evidence/ui.json');ui_review=read(HERE/'evidence/ui-review.json');native=read(HERE/'evidence/native-review.json')
 require(ui['source_commit']==review['comparison_source'] and ui['passed'] and len(ui['checks'])==122 and all(c['passed'] for c in ui['checks']),'Production UI gate failed')
 require(len(ui['pairs'])==24 and all(p['max']==0 and p['changed']==0 for p in ui['pairs']),'Production UI parity failed')
 require(ui_review['accepted'] and ui_review['source_commit']==ui['source_commit'] and ui_review['files']==ui['files'] and ui_review['all_actual_images_inspected'],'Independent UI review mismatch')
 require(native['accepted'] and native['source_commit']=='94f3302051b6f8662c3606a3695697094795b5c4' and native['native_exact_pairs']==26,'Independent native lifecycle review mismatch')
 require(lineage['native_production_source_unchanged_from']=='94f3302051b6f8662c3606a3695697094795b5c4' and lineage['native_production_files_match'],'Native source lineage missing')
 perf_review=read(HERE/'evidence/performance-review.json');require(perf_review['accepted'] and perf_review['candidate_source']==review['comparison_source'],'Performance review mismatch')
 for i in [1,2]:
  perf_path=HERE/('evidence/perf'+str(i)+'.json');p=read(perf_path)
  require(perf_review['workers']['worker'+str(i)]['report_sha256']==identity(perf_path)['sha256'],'Independent performance review mismatch')
  require(p['passed'] and p['candidate_source']==review['comparison_source'] and len(p['windows'])==12 and len(p['checks'])==48 and all(c['passed'] for c in p['checks']),'Incomplete original-package comparison')
  require(p['files']['candidate']==ui['files'] and p['files']['original']==baseline['files']['dev'],'Comparison package mismatch')
  require(p['order']==(['original','candidate','candidate','original'] if i==1 else ['candidate','original','original','candidate']),'Wrong balanced block order')
  ref=[w for w in p['windows'] if w['side']=='original'];cand=[w for w in p['windows'] if w['side']=='candidate']
  fps=lambda rows:sum(w['frames'] for w in rows)/sum(w['seconds'] for w in rows)
  require(fps(cand)>fps(ref) and sum(w['frame']['over_33_ms'] for w in cand)<sum(w['frame']['over_33_ms'] for w in ref),'No aggregate improvement')
  require(all(w['impacts']>=25 and w['native']['active'] and w['position']==[1400,312] for w in p['windows']),'Changed workload')
  require(all(r['canvas']==[2328,1260] and r['dpr']==3 and 'Apple' in r['renderer'] for r in p['runtimes']),'Changed resolution or platform')
 require(review['known_max_candidate_stall_ms']==546 and critic['stutter_fix_proven'] is False,'Known stutter limitation missing')
 require(critic['accepted'] and critic['final_build_images_inspected'] and min(critic['scores'].values())>=8,'Independent final acceptance missing')
 require(review['physical_iphone_verified'] is False and critic['physical_iphone_verified'] is False,'Unverified phone claim')
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
 require({label:want['name'] for label,want in review['artifacts'].items()}=={'candidate':'integrated-candidate','build':'integrated-build','browser':'integrated-startup'},'Required artifact set incomplete')
 for label,want in review['artifacts'].items():
  actual=api('artifacts/'+str(want['id']))
  require(actual['name']==want['name'] and actual['digest']==want['digest'] and actual['workflow_run']['id']==review['artifact_run_id'],'Artifact provenance changed: '+label)
 require(review['artifacts']['candidate']['name']=='integrated-candidate','Wrong candidate artifact')
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
 print('CANVAS_CPU_DEV15_10_STAGED reviewed_files=9 preserved=18')
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
   (output/'publication-receipt.json').write_text(json.dumps({'passed':True,'version':VERSION,'destination':PUBLIC+'dev/','source_commit':review['source_commit'],'run_id':review['artifact_run_id'],'files':expected,'live_files_unchanged':9,'retained_trial_files_unchanged':9,'physical_iphone_verified':False,'verification_scope':'CPU occupancy and two avoided canvas passes. Original-package comparisons improve weighted FPS11.25% and12.72% on two Mac WebKit workers; slowframe totals lower, retained546ms candidate stall. Native/UI exact parity, gameplay and final ordinary startup/save reviewed. No physical phone or stutter-fix claim.'},indent=2)+'\n')
   print('CANVAS_CPU_DEV15_10_PUBLIC_VERIFY_OK files=27');return
  if attempt<9:time.sleep(10)
 raise RuntimeError('Public verification failed: '+str(pending))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('command',choices=['check-review','prepare','verify']);p.add_argument('output',type=Path,nargs='?');p.add_argument('--candidate',type=Path);a=p.parse_args()
 if a.command=='check-review':reviewed()
 elif a.command=='prepare':prepare(a.output.resolve(),a.candidate.resolve())
 else:verify(a.output.resolve())

