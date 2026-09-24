"""Build Skills DEV15 while preserving the exact approved native hero/tool resources."""
import argparse, concurrent.futures, hashlib, json, os, re, subprocess, urllib.request
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
PUBLIC='https://corpax88.github.io/Ever-Deeper/dev/'
NAMES=['index.html','index.js','index.pck','index.wasm','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js']
def identity(path):
 h=hashlib.sha256()
 with path.open('rb') as f:
  for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
 return {'size':path.stat().st_size,'sha256':h.hexdigest()}
def run(args,log):
 with log.open('w') as out: result=subprocess.run(args,cwd=ROOT,stdout=out,stderr=subprocess.STDOUT)
 text=log.read_text(errors='replace')
 if result.returncode or re.search(r'SCRIPT ERROR|Parse Error|^ERROR:',text,re.M):
  print(text[-12000:]); raise RuntimeError(log.name)
def download(name,path):
 request=urllib.request.Request(PUBLIC+name,headers={'Cache-Control':'no-cache'})
 with urllib.request.urlopen(request,timeout=120) as src,path.open('wb') as out:
  while b:=src.read(1024*1024): out.write(b)
def build(godot,work):
 icon=ROOT/'assets/ui/skills/icons/tools-premium-v1.png'
 assert identity(icon)=={'size':1540879,'sha256':'b0ddf462bcd25fca89bffa073f0dd9af2af5c82cf2a9f299224f3fe148f1d64f'},'Approved icon changed'
 work.mkdir(parents=True,exist_ok=False)
 candidate=work/'candidate';candidate.mkdir()
 carrier=work/'native-carrier.pck';download('index.pck',carrier)
 # Public DEV is only a carrier. Every extracted resource must equal the locked
 # DEV14.3 bytes, even after a subsequent release changes the carrier's PCK hash.
 run([godot,'--headless','--path',str(ROOT),'--script',str(ROOT/'.github/telemetry-dev15-7/extract-assets.gd'),'--',str(carrier),str(ROOT)],work/'extract.log')
 native=json.loads((ROOT/'.github/telemetry-dev15-7/native-input.json').read_text())
 assert all(identity(ROOT/n)==want for n,want in native['files'].items()),'Approved native resources changed'
 for name in ['tools','.github']:(ROOT/name/'.gdignore').touch()
 run([godot,'--headless','--editor','--path',str(ROOT),'--import'],work/'import.log')
 run([godot,'--headless','--path',str(ROOT),'--export-pack','Web DEV',str(candidate/'index.pck')],work/'export.log')
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
  list(pool.map(lambda n:download(n,candidate/n),[n for n in NAMES if n!='index.pck']))
 expected=json.loads((ROOT/'.github/world-scale-study/baseline.json').read_text())
 for n,want in expected.items():
  if n != 'index.pck': assert identity(candidate/n)==want,'Web runtime changed: '+n
 html=(candidate/'index.html').read_text()
 assert html.count((ROOT/'tools/session-reports-browser.js').read_text())==1,'Unchanged report shell missing'
 match=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);assert match
 config=json.loads(match[1]);config['fileSizes']['index.pck']=0
 normalized=html[:match.start(1)]+json.dumps(config,separators=(',',':'))+html[match.end(1):]
 config['fileSizes']['index.pck']=(candidate/'index.pck').stat().st_size
 html=html[:match.start(1)]+json.dumps(config,separators=(',',':'))+html[match.end(1):]
 (candidate/'index.html').write_text(html)
 files={n:identity(candidate/n) for n in NAMES}
 (candidate/'manifest.json').write_text(json.dumps(files,indent=2)+'\n')
 (work/'build.json').write_text(json.dumps({'version':'1.0.0-dev.15.9','source_commit':os.environ.get('GITHUB_SHA'),'files':files,'save_path':'user://ever_deeper_dev_run_v3.sav','native_carrier':identity(carrier),'native_files_unchanged':native,'physical_iphone_verified':False},indent=2)+'\n')
 print('SKILLS_DEV15_EXPORT_COMPLETE')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('godot');p.add_argument('work',type=Path);a=p.parse_args();build(a.godot,a.work.resolve())


