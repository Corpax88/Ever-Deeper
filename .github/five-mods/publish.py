"""Publish reviewed five approved mods bytes, preserving LIVE and Worn."""
import sys,json,hashlib,urllib.request,os,shutil,time,re
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
HERE=Path(__file__).resolve().parent
PUBLIC='https://corpax88.github.io/Ever-Deeper/'
def ident(p):return {'size':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
def read(p):return json.loads(p.read_text())
def require(ok,why):
 if not ok:raise RuntimeError(why)
def reviewed():
 r=read(HERE/'accepted.json');m=read(HERE/'accepted-manifest.json');before=read(HERE/'public-before.json')
 require(r['accepted'] and r['images_inspected'] and r['core_passed'] and r['critic_accepted'],'Acceptance incomplete')
 require(r['version']=='1.0.0-dev.15.48' and r['destination']=='dev','Wrong release')
 require(re.fullmatch('[0-9a-f]{40}',r['source']),'Invalid source')
 require(set(m)=={n[4:] for n in before if n.startswith('dev/') and not n.startswith('dev/worn/')},'Wrong candidate files')
 for n in m:
  if n not in ['index.html','index.pck']:require(m[n]==before['dev/'+n],'Unexpected engine or asset change')
 for n,digest in r['reviewed_files'].items():require(ident(HERE/n)['sha256']==digest,'Review binding changed '+n)
 e=read(HERE/'evidence/browser/report.json')
 require(e['passed'] and e['version']==r['version'] and e['source']==r['source'] and e['files']==m,'Wrong icon test bytes')
 require(all(c['passed'] for c in e['checks']),'Failed icon tests')
 names={c['name'] for c in e['checks']}
 require('graphical-renderer' in names,'Missing actual GPU rendering')
 for mod in ['twin_auger','chainbreaker','ricochet','corebreaker','vortex']:
  for prefix in ['actual-touch-mines-','manual-no-auto-rush-','release-stops-','simultaneous-move-mine-']:
   require(prefix+mod in names,'Missing touch gameplay gate')
  for width in [667,844,932]:require('preview-visible-'+mod+str(width) in names,'Missing mobile preview')
 require({'distinct-effect-chainbreaker','distinct-effect-corebreaker','save-retains-five-mods'}<=names,'Missing effects or save gate')
 e=read(HERE/'evidence/ordinary/report.json')
 require(e.get('completed_observation') and not e.get('failure') and not e.get('crashed') and e['files']==m and e['version']==r['version'] and e['source_commit']==r['source'],'Startup not verified')
 require(read(HERE/'evidence/core/results.json')['passed'],'Core gameplay failed')
 n=read(HERE/'native-results.json')
 require(n['source']==r['source'] and n['files']==m and all(c['passed'] for c in n['checks']),'Native package mismatch')
 require(len(n['checks'])>=39 and all(c['passed'] for c in n['checks']),'Missing focused native checks')
 required_native=set(["chain-fixture-exceeds-three","chain-all-snapshot-nodes-after-motion","chain-excludes-buried-and-offscreen","chain-rebase-preserves-snapshot-and-shifts-origin","chain-continues-after-coordinate-rebase","chain-release-cancels-pending-without-extra-hit","core-three-hits-before-next-ordinary-hit-950","core-three-hits-before-next-ordinary-hit-974","core-three-hits-before-next-ordinary-hit-998","core-three-hits-before-next-ordinary-hit-1022","twin-reveals-without-mining-node","ricochet-three-distinct-rock-contacts","ricochet-reveals-three-without-mining-buried-nodes","vortex-bounded-work","vortex-save-during-flight","vortex-load-during-flight","vortex-reload-preserves-ledger","vortex-reset-preserves-uncollected-ledger","vortex-exact-once-loot","controller-motion-parity-24-bearings-twin_auger-level-0","controller-motion-parity-24-bearings-chainbreaker-level-0","controller-motion-parity-24-bearings-ricochet-level-0","controller-motion-parity-24-bearings-corebreaker-level-0","controller-motion-parity-24-bearings-vortex-level-0","controller-motion-parity-24-bearings-twin_auger-level-3","controller-motion-parity-24-bearings-chainbreaker-level-3","controller-motion-parity-24-bearings-ricochet-level-3","controller-motion-parity-24-bearings-corebreaker-level-3","controller-motion-parity-24-bearings-vortex-level-3","controller-motion-parity-24-bearings-twin_auger-level-10","controller-motion-parity-24-bearings-chainbreaker-level-10","controller-motion-parity-24-bearings-ricochet-level-10","controller-motion-parity-24-bearings-corebreaker-level-10","controller-motion-parity-24-bearings-vortex-level-10","controller-motion-parity-24-bearings-twin_auger-level-20","controller-motion-parity-24-bearings-chainbreaker-level-20","controller-motion-parity-24-bearings-ricochet-level-20","controller-motion-parity-24-bearings-corebreaker-level-20","controller-motion-parity-24-bearings-vortex-level-20"])
 require(required_native<={c['name'] for c in n['checks']},'Missing named native gate')
 require(r['critic_blockers']==0,'Independent critic blockers')
 return r,m,before

def fetch(name,p,want):
 p.parent.mkdir(parents=True,exist_ok=True);h=hashlib.sha256();size=0
 with urllib.request.urlopen(urllib.request.Request(PUBLIC+name,headers={'Cache-Control':'no-cache'}),timeout=120) as src,p.open('wb') as out:
  while b:=src.read(1024*1024):
   size+=len(b);require(size<=want['size'],'Unexpected public size '+name);h.update(b);out.write(b)
 require({'size':size,'sha256':h.hexdigest()}==want,'Public content changed '+name)

def prepare(work,candidate):
 r,m,before=reviewed();require(not work.exists(),'Use fresh staging')
 def api(path):
  with urllib.request.urlopen(urllib.request.Request('https://api.github.com/repos/Corpax88/Ever-Deeper/actions/'+path,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})) as s:return json.load(s)
 run=api('runs/'+str(r['run']));require(run['head_sha']==r['source'] and run['conclusion']=='success' and run['path']=='.github/workflows/five-mods.yml','Unaccepted run')
 a=api('artifacts/'+str(r['artifact']));require(not a['expired'] and a['name']=='five-mods-candidate' and a['digest']==r['digest'] and a['workflow_run']['id']==r['run'] and a['workflow_run']['head_sha']==r['source'],'Wrong artifact')
 require(read(candidate/'manifest.json')==m and all(ident(candidate/n)==v for n,v in m.items()),'Candidate hash mismatch')
 with ThreadPoolExecutor(max_workers=3) as pool:list(pool.map(lambda kv:fetch(kv[0],work/'previous'/kv[0],kv[1]),before.items()))
 shutil.copytree(work/'previous',work/'site')
 for n in m:shutil.copy2(candidate/n,work/'site/dev'/n)
 (work/'site/.nojekyll').write_text('')
 for n,v in before.items():
  if not n.startswith('dev/') or n.startswith('dev/worn/'):require(ident(work/'site'/n)==v,'Protected publication changed')
 require(sum(p.stat().st_size for p in (work/'site').rglob('*') if p.is_file())<1024**3,'Pages size')
 print('BALANCE_STAGED')

def verify(work):
 r,m,before=reviewed();expected={**before,**{'dev/'+n:v for n,v in m.items()}};pending=list(expected);work.mkdir(parents=True,exist_ok=True)
 def check(n):
  try:fetch(n,work/n,expected[n]);return True
  except Exception:return False
 for attempt in range(10):
  with ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(check,pending))
  pending=[n for n,ok in zip(pending,results) if not ok]
  if not pending:break
  if attempt<9:time.sleep(10)
 receipt={'passed':not pending,'version':r['version'],'source':r['source'],'artifact':r['artifact'],'run':r['run'],'files':expected,'unverified':pending,'live_preserved':9,'worn_preserved':9,'physical_iphone_verified':False}
 (work/'publication-receipt.json').write_text(json.dumps(receipt,indent=2));require(not pending,'Public hashes incomplete');print('BALANCE_PUBLIC_VERIFIED_27_FILES')
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare(Path(sys.argv[2]),Path(sys.argv[3]))
 else:verify(Path(sys.argv[2]))











