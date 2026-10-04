"""Publish accepted LIVE 1.0.5 bytes, retaining pinned DEV and Worn."""
import sys,json,hashlib,urllib.request,urllib.error,os,shutil,time,re,http.client
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
 require(r['version']=='1.0.5' and r['destination']=='live','Wrong release')
 require(re.fullmatch('[0-9a-f]{40}',r['source']),'Invalid source')
 require(set(m)=={n for n in before if not n.startswith('dev/')},'Wrong candidate files')
 require(before['dev/index.pck']==read(HERE/'baseline.json')['index.pck'],'DEV changed since approval')
 for n in m:
  if n not in ['index.html','index.pck']:require(m[n]==before['dev/'+n],'Unexpected engine or asset change')
 for n,digest in r['reviewed_files'].items():require(ident(HERE/n)['sha256']==digest,'Review binding changed '+n)
 e=read(HERE/'evidence/browser/report.json')
 require(e['passed'] and e['version']==r['version'] and e['source_commit']==r['source'] and e['files']==m,'Wrong HUD test bytes')
 require(all(c['passed'] for c in e['checks']),'Failed HUD tests')
 require({'graphical-renderer','no-runtime-errors','production-flavor','existing-live-progress-preserved','old-live-save-created','mining-after-menu','production-save-written','production-save-reloaded'} <= {c['name'] for c in e['checks']},'Missing production/migration gates')
 e=read(HERE/'evidence/ordinary/report.json')
 require(e.get('completed_observation') and not e.get('failure') and not e.get('crashed') and e['files']==m and e['version']==r['version'] and e['source_commit']==r['source'],'Startup not verified')
 core=read(HERE/'evidence/core/results.json')
 require(core['passed'] and {c['case'] for c in core['cases'] if c['passed']}=={'input','premium-core','build-flavor','one-point-zero-migration'},'Production core gates failed')
 require('flavor=production menu=false resource=false' in (HERE/'evidence/core/build-flavor.log').read_text(),'DEV flavor leaked')
 parity=read(HERE/'evidence/build-receipt.json')
 require(parity['source']==r['source'] and parity['files']==m and parity['all_retained_payloads_verified'] and parity['unchanged_resources']>=1590 and parity['baseline']==read(HERE/'baseline.json'),'Package parity failed')
 return r,m,before

def fetch(name, path, want):
    path.parent.mkdir(parents=True, exist_ok=True)
    partial = path.with_name(path.name + '.download')
    for attempt in range(3):
        request = urllib.request.Request(PUBLIC + name, headers={'Cache-Control': 'no-cache'})
        h, size = hashlib.sha256(), 0
        try:
            print('LIVE_FETCH', name, 'attempt', attempt + 1, flush=True)
            with urllib.request.urlopen(request, timeout=45) as src, partial.open('wb') as out:
                while block := src.read(1024 * 1024):
                    size += len(block)
                    require(size <= want['size'], 'Unexpected public size: ' + name)
                    h.update(block)
                    out.write(block)
                out.flush()
                os.fsync(out.fileno())
            require({'size': size, 'sha256': h.hexdigest()} == want, 'Public content changed: ' + name)
            os.replace(partial, path)
            print('LIVE_FETCH_VERIFIED', name, flush=True)
            return
        except (urllib.error.URLError, TimeoutError, ConnectionError, http.client.IncompleteRead) as error:
            if isinstance(error, urllib.error.HTTPError) and error.code not in (429, 500, 502, 503, 504):
                raise
            print('LIVE_FETCH_RETRY', name, type(error).__name__, flush=True)
            if attempt == 2:
                raise RuntimeError('Public transfer failed after three attempts: ' + name) from error
            time.sleep(2 ** attempt)
        finally:
            partial.unlink(missing_ok=True)


def prepare(work,candidate):
 r,m,before=reviewed();require(not work.exists(),'Use fresh staging')
 def api(path):
  with urllib.request.urlopen(urllib.request.Request('https://api.github.com/repos/Corpax88/Ever-Deeper/actions/'+path,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})) as s:return json.load(s)
 run=api('runs/'+str(r['run']));require(run['head_sha']==r['source'] and run['conclusion']=='success' and run['path']=='.github/workflows/live-1-0-5.yml','Unaccepted run')
 a=api('artifacts/'+str(r['artifact']));require(not a['expired'] and a['name']=='live-1-0-5-candidate' and a['digest']==r['digest'] and a['workflow_run']['id']==r['run'] and a['workflow_run']['head_sha']==r['source'],'Wrong artifact')
 require(read(candidate/'manifest.json')==m and all(ident(candidate/n)==v for n,v in m.items()),'Candidate hash mismatch')
 with ThreadPoolExecutor(max_workers=3) as pool:list(pool.map(lambda kv:fetch(kv[0],work/'previous'/kv[0],kv[1]),before.items()))
 shutil.copytree(work/'previous',work/'site')
 for n in m:shutil.copy2(candidate/n,work/'site'/n)
 (work/'site/.nojekyll').write_text('')
 for n,v in before.items():
  if n.startswith('dev/'):require(ident(work/'site'/n)==v,'Protected publication changed')
 require(sum(p.stat().st_size for p in (work/'site').rglob('*') if p.is_file())<1024**3,'Pages size')
 rollback=work/'rollback';rollback.mkdir()
 for n in m:shutil.copy2(work/'previous'/n,rollback/n)
 print('LIVE_STAGED')

def verify(work):
 r,m,before=reviewed();expected={**before,**m};pending=list(expected);work.mkdir(parents=True,exist_ok=True)
 def check(n):
  try:fetch(n,work/n,expected[n]);return True
  except Exception:return False
 for attempt in range(10):
  with ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(check,pending))
  pending=[n for n,ok in zip(pending,results) if not ok]
  if not pending:break
  if attempt<9:time.sleep(10)
 receipt={'passed':not pending,'version':r['version'],'source':r['source'],'artifact':r['artifact'],'run':r['run'],'files':expected,'unverified':pending,'dev_preserved':9,'worn_preserved':9,'physical_iphone_verified':False}
 (work/'publication-receipt.json').write_text(json.dumps(receipt,indent=2));require(not pending,'Public hashes incomplete');print('LIVE_PUBLIC_VERIFIED_27_FILES')
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare(Path(sys.argv[2]),Path(sys.argv[3]))
 else:verify(Path(sys.argv[2]))

