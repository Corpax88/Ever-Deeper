"""Verify the original passed export/core artifacts without rebuilding the game."""
import hashlib,json,os,sys,urllib.request,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[2];candidate=Path(sys.argv[1]);evidence=Path(sys.argv[2])
m=json.loads((root/'.github/skills-dev15/reuse.json').read_text())
def api(route):
 request=urllib.request.Request('https://api.github.com/repos/Corpax88/Ever-Deeper/'+route,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
 with urllib.request.urlopen(request,timeout=60) as response:return json.load(response)
run=api('actions/runs/'+str(m['export_run_id']))
assert run['head_sha']==m['source_commit'] and run['status']=='completed'
jobs=api('actions/runs/'+str(m['export_run_id'])+'/jobs?filter=latest')['jobs']
assert any(j['name']=='build' and j['conclusion']=='success' for j in jobs)
for want in m['artifacts'].values():
 actual=api('actions/artifacts/'+str(want['id']))
 assert actual['name']==want['name'] and actual['digest']==want['digest'] and actual['workflow_run']['id']==m['export_run_id']
files=json.loads((candidate/'manifest.json').read_text())
for name,want in files.items():
 p=candidate/name;h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''):h.update(b)
 assert {'sha256':h.hexdigest(),'size':p.stat().st_size}==want
build=json.loads((evidence/'build.json').read_text());assert build['source_commit']==m['source_commit'] and build['files']==files
core=json.loads((evidence/'core/results.json').read_text());assert core['passed']
allowed={'.github/skills-dev15/review.mjs','.github/skills-dev15/reuse.py','.github/skills-dev15/reuse.json','.github/workflows/skills-dev15.yml','.github/workflows/skills-dev15-rereview.yml'}
changed=set(subprocess.check_output(['git','diff','--name-only',m['source_commit'],os.environ['GITHUB_SHA']],text=True,cwd=root).splitlines())
assert changed<=allowed,'Game source changed: '+str(changed-allowed)
(evidence/'reused-export.json').write_text(json.dumps({'passed':True,'game_rebuilt':False,'source_commit':m['source_commit'],'validation_commit':os.environ['GITHUB_SHA'],'export_run_id':m['export_run_id'],'original_artifacts':m['artifacts'],'validation_only_changed_paths':sorted(changed),'files':files},indent=2)+'\n')
print('SKILLS_EXACT_EXPORT_REUSED')
