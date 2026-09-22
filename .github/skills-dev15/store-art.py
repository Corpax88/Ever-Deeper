"""One-time file transfer: authorized public production art, no renderer or deploy."""
import io,json,hashlib,urllib.request,zipfile,os,base64,subprocess
from pathlib import Path
m=json.loads(Path('.github/skills-dev15/art-transfer.json').read_text())
print('::add-mask::'+m['download_url'])
with urllib.request.urlopen(m['download_url'],timeout=60) as r: raw=r.read()
assert hashlib.sha256(raw).hexdigest()==m['sha256']
api='https://api.github.com/repos/'+os.environ['GITHUB_REPOSITORY']
def request(endpoint,data=None):
 req=urllib.request.Request(api+endpoint,data=json.dumps(data).encode() if data is not None else None,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json','Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=60) as r: return json.load(r)
expected={'assets/ui/skills/mine-backdrop-v1.png','assets/ui/skills/miner-mole-portrait-v1.png','assets/ui/skills/iron-panel-v1.png','assets/ui/skills/copper-button-v1.png','assets/ui/fonts/EBGaramond.ttf'}
with zipfile.ZipFile(io.BytesIO(raw)) as z:
 manifest=json.loads(z.read('manifest.json'))
 assert set(manifest)==expected and set(z.namelist())==expected|{'manifest.json'}
 entries=[]
 for name in sorted(expected):
  data=z.read(name); want=manifest[name]
  assert hashlib.sha256(data).hexdigest()==want['sha256'] and len(data)==want['size']
  blob=request('/git/blobs',{'content':base64.b64encode(data).decode(),'encoding':'base64'})
  entries.append({'path':name,'type':'blob','mode':'100644','sha':blob['sha']})
subprocess.run(['git','apply','--check','.github/skills-dev15/integration.patch'],check=True)
subprocess.run(['git','apply','.github/skills-dev15/integration.patch'],check=True)
changed=subprocess.check_output(['git','diff','--name-only'],text=True).splitlines()
allowed={'AGENTS.md','scripts/main.gd','scripts/player/player_controller.gd','scripts/qa/qa_launcher.gd','scripts/state/run_state.gd','scripts/ui/premium_hud.gd','scripts/ui/premium_menu.gd'}
assert set(changed)<=allowed
for name in changed:
 data=Path(name).read_bytes()
 blob=request('/git/blobs',{'content':base64.b64encode(data).decode(),'encoding':'base64'})
 entries.append({'path':name,'type':'blob','mode':'100644','sha':blob['sha']})
parent=os.environ['GITHUB_SHA']
commit=request('/git/commits/'+parent)
tree=request('/git/trees',{'base_tree':commit['tree']['sha'],'tree':entries})
new=request('/git/commits',{'message':'Store approved Skills artwork and licensed serif font','tree':tree['sha'],'parents':[parent]})
ref='/git/refs/heads/codex/locked-skills-ui-20260922'
req=urllib.request.Request(api+ref,data=json.dumps({'sha':new['sha'],'force':False}).encode(),method='PATCH',headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Content-Type':'application/json'})
with urllib.request.urlopen(req,timeout=60) as r: json.load(r)
print('ART_STORED '+new['sha'])
