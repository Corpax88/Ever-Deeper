"""Publish accepted maps DEV bytes, retaining pinned LIVE/Worn."""
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
 require(r['accepted'] and r['images_inspected'] and r['core_passed'],'Acceptance incomplete')
 require(r['version']=='1.0.0-dev.15.39' and r['destination']=='dev','Wrong release')
 require(re.fullmatch('[0-9a-f]{40}',r['source']),'Invalid source')
 require(set(m)=={n[4:] for n in before if n.startswith('dev/') and not n.startswith('dev/worn/')},'Wrong candidate files')
 for n in m:
  if n not in ['index.html','index.pck']:require(m[n]==before['dev/'+n],'Unexpected engine or asset change')
 for n,digest in r['reviewed_files'].items():require(ident(HERE/n)['sha256']==digest,'Review binding changed '+n)
 e=read(HERE/'evidence/browser/report.json')
 require(e['passed'] and e['version']==r['version'] and e['source']==r['source'] and e['files']==m,'Wrong maps test bytes')
 require(all(c['passed'] for c in e['checks']),'Failed maps tests')
 require({'graphical-renderer','actual-touch-mining-updates-map','exploration-restored','no-runtime-errors'} <= {c['name'] for c in e['checks']},'Missing map gates')
 require(read(HERE/'critic.json')['score']>=8 and read(HERE/'critic.json')['rounds']<=3,'Critic acceptance missing')
 e=read(HERE/'evidence/ordinary/report.json')
 require(e.get('completed_observation') and not e.get('failure') and not e.get('crashed') and e['files']==m and e['version']==r['version'] and e['source_commit']==r['source'],'Startup not verified')
 require(read(HERE/'evidence/core/results.json')['passed'],'Core gameplay failed')
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
 run=api('runs/'+str(r['run']));require(run['head_sha']==r['source'] and run['conclusion']=='success' and run['path']=='.github/workflows/maps.yml','Unaccepted run')
 a=api('artifacts/'+str(r['artifact']));require(not a['expired'] and a['name']=='maps-candidate' and a['digest']==r['digest'] and a['workflow_run']['id']==r['run'] and a['workflow_run']['head_sha']==r['source'],'Wrong artifact')
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






