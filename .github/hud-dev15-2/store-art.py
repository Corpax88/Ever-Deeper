"""Store exactly one approved public PNG through the established art-transfer route."""
import hashlib, io, json, os, urllib.request, zipfile, base64
from pathlib import Path
m=json.loads(Path('.github/hud-dev15-2/art-transfer.json').read_text())
print('::add-mask::'+m['download_url'])
with urllib.request.urlopen(m['download_url'],timeout=120) as r: raw=r.read()
assert hashlib.sha256(raw).hexdigest()==m['sha256']
name='assets/ui/skills/icons/tools-premium-v1.png'
with zipfile.ZipFile(io.BytesIO(raw)) as z:
 assert set(z.namelist())=={name,'manifest.json'}
 data=z.read(name); manifest=json.loads(z.read('manifest.json'))
 assert set(manifest)=={name}
 assert len(data)==1540879 and hashlib.sha256(data).hexdigest()=='b0ddf462bcd25fca89bffa073f0dd9af2af5c82cf2a9f299224f3fe148f1d64f'
 assert manifest[name]=={'size':len(data),'sha256':hashlib.sha256(data).hexdigest()}
api='https://api.github.com/repos/'+os.environ['GITHUB_REPOSITORY']
def request(endpoint,data=None,method=None):
 req=urllib.request.Request(api+endpoint,data=json.dumps(data).encode() if data is not None else None,method=method,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json','Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=60) as r: return json.load(r)
parent=os.environ['GITHUB_SHA']; branch='codex/approved-tools-icon-20260923'
assert os.environ['GITHUB_REF']=='refs/heads/'+branch
assert request('/git/ref/heads/'+branch)['object']['sha']==parent
blob=request('/git/blobs',{'content':base64.b64encode(data).decode(),'encoding':'base64'})
base=request('/git/commits/'+parent)
entries=[{'path':name,'mode':'100644','type':'blob','sha':blob['sha']}]
for path in ['.github/hud-dev15-2/art-transfer.json','.github/hud-dev15-2/store-art.py','.github/workflows/ingest-tools-icon.yml']:
 entries.append({'path':path,'mode':'100644','type':'blob','sha':None})
tree=request('/git/trees',{'base_tree':base['tree']['sha'],'tree':entries})
new=request('/git/commits',{'message':'Store the approved transparent tools icon','tree':tree['sha'],'parents':[parent]})
request('/git/refs/heads/'+branch,{'sha':new['sha'],'force':False},'PATCH')
print('APPROVED_ICON_STORED '+new['sha'])
