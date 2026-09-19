"""Pack genuine edge frames and bind them to the unchanged approved banks."""
import argparse
import hashlib
import json
import math
from pathlib import Path
from PIL import Image

p=argparse.ArgumentParser()
p.add_argument('directory',type=Path)
p.add_argument('--flow',type=Path,required=True)
p.add_argument('--walk',type=Path,required=True)
a=p.parse_args()
r=json.loads((a.directory/'report.json').read_text())
assert r['complete'] and len(r['renders'])==sum(e['steps']+1 for e in r['edges'].values())
atlas=Image.new('RGBA',(1600,160*math.ceil(len(r['renders'])/10)))
seen={}
for i,s in enumerate(r['renders']):
    if s['edge'] not in seen:
        assert s['step']==0
        seen[s['edge']]=i
        r['edges'][s['edge']]['offset']=i
    assert s['step']==i-seen[s['edge']]
    with Image.open(a.directory/s['file']) as im:
        im.load();assert im.size==(200,200)
        atlas.paste(im.resize((160,160),Image.Resampling.LANCZOS),(i%10*160,i//10*160))
atlas.save(a.directory/'atlas.png')
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
r.update(atlas_sha256=sha(a.directory/'atlas.png'),flow_atlas_sha256=sha(a.flow/'atlas.png'),walk_atlas_sha256=sha(a.walk/'atlas.png'))
(a.directory/'atlas.json').write_text(json.dumps(r,indent=2)+'\n')
print('TRANSITION21_PACKAGED',len(r['renders']),r['atlas_sha256'])
