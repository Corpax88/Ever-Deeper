"""Review-bound DEV publication; reuse the verified26-file transport/preservation code."""
import importlib.util,json,os,re,sys,urllib.request,struct
from pathlib import Path
spec=importlib.util.spec_from_file_location('transport',Path(__file__).resolve().parents[1]/'visual-guidance/publish.py')
t=importlib.util.module_from_spec(spec);spec.loader.exec_module(t)
HERE=Path(__file__).resolve().parent
t.HERE=HERE;t.VERSION='1.0.0-dev.15.59'
REPORTS={'667':'report.json','844':'report.json','932':'report.json','input':'results.json','webkit':'report.json'}
BEFORE_SHA='e3d6b4b57cf6636608273a63cb5765e3d81675301dea3d8666e6f0358baff74f'

def acceptance():
 a=t.read(HERE/'accepted.json');b=t.read(HERE/'public-before.json')
 t.require(a.get('accepted') is True and a.get('images_inspected') is True and a.get('critic_accepted') is True,'Visual acceptance missing')
 t.require(a['version']==t.VERSION and a['destination']=='dev' and re.fullmatch('[0-9a-f]{40}',a['source']),'Wrong release')
 t.require(t.ident(HERE/'public-before.json')['sha256']==BEFORE_SHA,'Baseline changed')
 t.require(set(b)==t.LIVE_WEB|{'dev/'+n for n in t.WEB}|{'dev/worn/'+n for n in t.WEB},'Wrong26-file baseline')
 t.require(b['dev/index.pck']['sha256']=='a6a800c810eb09304d896783dec1310313b72498fcdab388fbc12ed60d075c21','Wrong15.58 baseline')
 t.require(set(a['production_manifest'])==t.WEB and set(a['report_sha256'])==set(REPORTS),'Incomplete bindings')
 for n in t.WEB-{'index.pck','index.html'}: t.require(a['production_manifest'][n]==b['dev/'+n],'Unreviewed engine/art '+n)
 t.require({x['name'] for x in a['artifacts']}=={'wall-focus-'+n for n in REPORTS}|{'wall-focus-production'},'Artifacts incomplete')
 for x in a['artifacts']:
  t.require(type(x['id']) is int and re.fullmatch('sha256:[0-9a-f]{64}',x['digest']),'Invalid artifact')
 return a,b

def api(path):
 req=urllib.request.Request('https://api.github.com/repos/Corpax88/Ever-Deeper/actions/'+path,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
 with urllib.request.urlopen(req,timeout=120) as r:return json.load(r)
def check_actions(a):
 r=api('runs/'+str(a['run']))
 t.require(r['head_sha']==a['source'] and r['conclusion']=='success' and r['status']=='completed' and r['path']=='.github/workflows/wall-focus.yml','QA source/run mismatch')
 for b in a['artifacts']:
  x=api('artifacts/'+str(b['id']))
  t.require(not x['expired'] and x['name']==b['name'] and x['digest']==b['digest'] and x['workflow_run']['id']==a['run'] and x['workflow_run']['head_sha']==a['source'],'Artifact identity mismatch')
def validate(artifacts):
 a,b=acceptance();p=artifacts/'wall-focus-production';m=a['production_manifest']
 t.require(t.read(p/'manifest.json')==m and all(t.ident(p/n)==v for n,v in m.items()),'Production bytes changed')
 receipt=t.read(p/'qa-build-receipt.json')
 t.require(receipt['qa_source']==a['source'] and receipt['baseline_pck']==b['dev/index.pck'] and receipt['retained_payloads_verified'] is True and receipt['production'] is True and receipt['files']==m,'Pack provenance changed')
 t.require(not any(n.startswith('scripts/qa/') for n in receipt['replaced']),'Fixture injected into production')
 for group,name in REPORTS.items():
  path=artifacts/('wall-focus-'+group)/name
  t.require(t.ident(path)['sha256']==a['report_sha256'][group],'Report changed '+group)
  r=t.read(path)
  if group in ('667','844','932'):
   t.require(r['source']==a['source'] and r['production_pck']==m['index.pck'] and r['actual_viewport'][0]==int(group),'Rendered pack identity changed')
   t.require(r['passed'] is True and len(r['checks'])==37 and all(c['passed'] is True for c in r['checks']),'Wall/layout checks failed')
   t.require(len(r['images'])==10 and all((path.parent/n).is_file() for n in r['images']),'Captures missing')
   size={'667':(667,375),'844':(844,390),'932':(932,430)}[group]
   t.require(tuple(r['actual_viewport'])==size and all(struct.unpack('>II',(path.parent/n).read_bytes()[16:24])==size for n in r['images']),'Actual framebuffer/capture dimensions differ')
  elif group=='input':t.require(r['passed'] is True and any(c['case']=='input' and c['passed'] for c in r['cases']),'Input regression failed')
  else:
   t.require(r['source_commit']==a['source'] and r['files']==m and r['version']==t.VERSION,'WebKit identity changed')
   t.require(r.get('completed_observation') is True and r.get('normal_startup') is True and r.get('fixture_args')==[] and not r.get('failure') and not r.get('crashed'),'Ordinary startup failed')
   t.require(any('Apple' in str(s.get('renderer','')) and s.get('lost') is False and s.get('frames',0)>0 for s in r['samples']),'Apple renderer absent')
 return a,b,p

t.acceptance=acceptance;t.validate=validate;t.check_actions=check_actions
if __name__=='__main__':
 if sys.argv[1]=='inputs':
  a,_=acceptance()
  with open(os.environ['GITHUB_OUTPUT'],'a') as f:
   print('run='+str(a['run']),file=f);print('artifacts='+','.join(str(x['id']) for x in a['artifacts']),file=f)
 elif sys.argv[1]=='prepare':t.prepare(Path(sys.argv[2]),Path(sys.argv[3]))
 elif sys.argv[1]=='verify':t.verify(Path(sys.argv[2]))
 elif sys.argv[1]=='validate':validate(Path(sys.argv[2]))
