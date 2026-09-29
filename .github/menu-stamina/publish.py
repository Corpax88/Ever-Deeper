"""Publish reviewed LIVE/DEV menu recovery fixes and retain Worn exactly."""
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
 r=read(HERE/'accepted.json');before=read(HERE/'public-before.json');expected=dict(before)
 require(r['accepted'] and r['images_inspected'],'Not accepted')
 require(re.fullmatch('[0-9a-f]{40}',r['source']),'Invalid source')
 for n,d in r['reviewed_files'].items():require(ident(HERE/n)['sha256']==d,'Review changed '+n)
 for flavor,prefix,version in [('live','','1.0.2'),('dev','dev/','1.0.0-dev.15.22')]:
  d=r[flavor];m=read(HERE/(flavor+'-manifest.json'));e=read(HERE/'evidence'/flavor/'menus/report.json')
  require(d['version']==version and e['passed'] and e['version']==version and e['source_commit']==r['source'] and e['files']==m,'Wrong tested bytes')
  require(len(m)==9 and set(m)==set(read(HERE/(flavor+'-baseline.json'))),'Invalid candidate files')
  for n in m:
   if n not in ['index.html','index.pck']:require(m[n]==before[prefix+n],'Unexpected asset/engine change')
  require(all(c['passed'] for c in e['checks']),'Failed check')
  names={c['name'] for c in e['checks']}
  for label in ['skills','map','inventory','settings','pause','mole','forge','ordinary-idle','mine-skills']:
   require('recovery-rate-'+label in names and 'no-training-or-motion-'+label in names,'Missing recovery gate '+label)
  require({'no-start-screen-recovery','full-and-visible-skills','full-and-visible-mine-skills','mining-spends-stamina-and-earns-xp','no-runtime-errors'}<=names,'Missing gameplay gate')
  core=read(HERE/'evidence'/flavor/'core/results.json')
  require(core['passed'] and {c['case'] for c in core['cases'] if c['passed']}=={'input','premium-core','build-flavor'},'Core failed')
  expected.update({prefix+n:v for n,v in m.items()})
 e=read(HERE/'evidence/live/ordinary/report.json')
 require(e.get('completed_observation') and not e.get('failure') and not e.get('crashed') and e['files']==read(HERE/'live-manifest.json') and e['version']=='1.0.2' and e['source_commit']==r['source'],'Ordinary startup failed')
 return r,before,expected

def fetch(name,p,want):
 p.parent.mkdir(parents=True,exist_ok=True);h=hashlib.sha256();size=0
 with urllib.request.urlopen(urllib.request.Request(PUBLIC+name,headers={'Cache-Control':'no-cache'}),timeout=120) as src,p.open('wb') as out:
  while b:=src.read(1024*1024):
   size+=len(b);require(size<=want['size'],'Unexpected public size '+name);h.update(b);out.write(b)
 require({'size':size,'sha256':h.hexdigest()}==want,'Public content changed '+name)

def prepare(work,candidates):
 r,before,expected=reviewed();require(not work.exists(),'Use fresh staging')
 def api(path):
  with urllib.request.urlopen(urllib.request.Request('https://api.github.com/repos/Corpax88/Ever-Deeper/actions/'+path,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})) as s:return json.load(s)
 run=api('runs/'+str(r['run']));require(run['head_sha']==r['source'] and run['conclusion']=='success' and run['path']=='.github/workflows/menu-stamina.yml','Unaccepted run')
 for flavor in ['live','dev']:
  d=r[flavor];a=api('artifacts/'+str(d['artifact']))
  require(not a['expired'] and a['name']=='menu-stamina-'+flavor+'-candidate' and a['digest']==d['digest'] and a['workflow_run']['id']==r['run'] and a['workflow_run']['head_sha']==r['source'],'Wrong artifact')
  candidate=candidates/flavor;m=read(HERE/(flavor+'-manifest.json'))
  require(read(candidate/'manifest.json')==m and all(ident(candidate/n)==v for n,v in m.items()),'Candidate hash mismatch')
  b=read(candidate/'build-receipt.json');require(b['source']==r['source'] and b['files']==m and b['all_retained_payloads_verified'],'Invalid parity receipt')
 with ThreadPoolExecutor(max_workers=3) as pool:list(pool.map(lambda kv:fetch(kv[0],work/'previous'/kv[0],kv[1]),before.items()))
 shutil.copytree(work/'previous',work/'site')
 for flavor,prefix in [('live',''),('dev','dev')]:
  for n in read(HERE/(flavor+'-manifest.json')):shutil.copy2(candidates/flavor/n,work/'site'/prefix/n)
 (work/'site/.nojekyll').write_text('')
 require(all(ident(work/'site'/n)==v for n,v in expected.items()),'Staged files mismatch')
 require(sum(p.stat().st_size for p in (work/'site').rglob('*') if p.is_file())<1024**3,'Pages size')
 # Roll back both changed destinations together; no duplicate Worn payload.
 for n in before:
  if n.startswith('dev/worn/'):continue
  dest=work/'rollback'/n;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(work/'previous'/n,dest)
 print('STAMINA_STAGED')

def verify(work):
 r,before,expected=reviewed();pending=list(expected);work.mkdir(parents=True,exist_ok=True)
 def check(n):
  try:fetch(n,work/n,expected[n]);return True
  except Exception:return False
 for attempt in range(10):
  with ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(check,pending))
  pending=[n for n,ok in zip(pending,results) if not ok]
  if not pending:break
  if attempt<9:time.sleep(10)
 receipt={'passed':not pending,'versions':['1.0.2','1.0.0-dev.15.22'],'source':r['source'],'run':r['run'],'files':expected,'unverified':pending,'worn_preserved':9,'physical_iphone_verified':False}
 (work/'publication-receipt.json').write_text(json.dumps(receipt,indent=2));require(not pending,'Public hashes incomplete');print('STAMINA_PUBLIC_VERIFIED_27_FILES')
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare(Path(sys.argv[2]),Path(sys.argv[3]))
 else:verify(Path(sys.argv[2]))
