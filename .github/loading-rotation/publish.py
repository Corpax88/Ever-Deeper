"""Publish only the inspected loading HTML; preserve all other public bytes."""
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
 r=read(HERE/'accepted.json');before=read(HERE/'public-before.json');m=read(HERE/'manifest.json');e=read(HERE/'evidence/report.json')
 require(r['accepted'] and r['images_inspected'],'Not accepted')
 require(re.fullmatch('[0-9a-f]{40}',r['source']),'Invalid source')
 for n,d in r['reviewed_files'].items():require(ident(HERE/n)['sha256']==d,'Review changed '+n)
 require(e['passed'] and e['source']==r['source'] and e['files']==m and not e.get('failure'),'Wrong tested bytes')
 require(len(m)==9 and set(m)==set(read(HERE/'baseline.json')),'Invalid manifest')
 require(all(m[n]==before[n] for n in m if n!='index.html'),'Only HTML may change')
 require(all(c['passed'] for c in e['checks']),'Failed loading check')
 names={c['name'] for c in e['checks']}
 require({'original-toolbar-fixture','candidate-toolbar-fixture','candidate-toolbar-change-bar-visible','no-runtime-errors'}<=names,'Missing viewport mismatch regression')
 for cycle in ['cold','reload']:
  for orientation in ['portrait','landscape','portrait-return','landscape-return']:
   require({cycle+'-'+orientation+'-bar-visible',cycle+'-'+orientation+'-image-centered'}<=names,'Missing rotation gate')
  require({cycle+'-ready',cycle+'-overlay-stays-removed'}<=names,'Missing startup gate')
 expected=dict(before);expected['index.html']=m['index.html']
 return r,before,expected
def fetch(name,p,want):
 p.parent.mkdir(parents=True,exist_ok=True);h=hashlib.sha256();size=0
 with urllib.request.urlopen(urllib.request.Request(PUBLIC+name,headers={'Cache-Control':'no-cache'}),timeout=120) as src,p.open('wb') as out:
  while b:=src.read(1024*1024):
   size+=len(b);require(size<=want['size'],'Unexpected public size '+name);h.update(b);out.write(b)
 require({'size':size,'sha256':h.hexdigest()}==want,'Public content changed '+name)
def prepare(work,candidate):
 r,before,expected=reviewed();require(not work.exists(),'Use fresh staging')
 def api(path):
  with urllib.request.urlopen(urllib.request.Request('https://api.github.com/repos/Corpax88/Ever-Deeper/actions/'+path,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})) as s:return json.load(s)
 run=api('runs/'+str(r['run']));require(run['head_sha']==r['source'] and run['conclusion']=='success' and run['path']=='.github/workflows/loading-rotation.yml','Unaccepted run')
 a=api('artifacts/'+str(r['artifact']))
 require(not a['expired'] and a['name']=='loading-rotation-candidate' and a['digest']==r['digest'] and a['workflow_run']['id']==r['run'] and a['workflow_run']['head_sha']==r['source'],'Wrong artifact')
 m=read(HERE/'manifest.json');require(read(candidate/'manifest.json')==m and all(ident(candidate/n)==v for n,v in m.items()),'Candidate hash mismatch')
 b=read(candidate/'build-receipt.json');require(b['source']==r['source'] and b['files']==m and b['changed_files']==['index.html'],'Invalid scope receipt')
 with ThreadPoolExecutor(max_workers=3) as pool:list(pool.map(lambda kv:fetch(kv[0],work/'previous'/kv[0],kv[1]),before.items()))
 shutil.copytree(work/'previous',work/'site');shutil.copy2(candidate/'index.html',work/'site/index.html');(work/'site/.nojekyll').write_text('')
 require(all(ident(work/'site'/n)==v for n,v in expected.items()),'Staged files mismatch')
 require(sum(p.stat().st_size for p in (work/'site').rglob('*') if p.is_file())<1024**3,'Pages size')
 (work/'rollback').mkdir();shutil.copy2(work/'previous/index.html',work/'rollback/index.html')
 (work/'rollback/README.txt').write_text('Loading-only rollback: restore this LIVE root index.html; retain all current engine/PCK/DEV/Worn files. Baseline LIVE1.0.2.\n')
 print('LOADING_STAGED_ONLY_ROOT_HTML_CHANGED')
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
 receipt={'passed':not pending,'version':'1.0.2','hotfix':'loading-rotation-1','source':r['source'],'run':r['run'],'files':expected,'unverified':pending,'changed_files':['index.html'],'physical_iphone_verified':False}
 (work/'publication-receipt.json').write_text(json.dumps(receipt,indent=2));require(not pending,'Public hashes incomplete');print('LOADING_PUBLIC_VERIFIED_27_FILES')
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare(Path(sys.argv[2]),Path(sys.argv[3]))
 else:verify(Path(sys.argv[2]))
