from pathlib import Path
import json,sys,urllib.request
from concurrent.futures import ThreadPoolExecutor
from pack_helpers import identity
p=Path(sys.argv[1]);p.mkdir(parents=True,exist_ok=True);m=json.loads((Path(__file__).parent/'live-baseline.json').read_text())
def fetch(n):
 urllib.request.urlretrieve('https://corpax88.github.io/Ever-Deeper/'+n,p/n)
 assert identity(p/n)==m[n],n
with ThreadPoolExecutor(max_workers=3) as pool:list(pool.map(fetch,m))
(p/'manifest.json').write_text(json.dumps(m))
