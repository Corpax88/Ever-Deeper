"""Inspect exact real-game seam frames and compare gameplay, not screenshots."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

p=argparse.ArgumentParser()
p.add_argument('directory',type=Path)
p.add_argument('--baseline',type=Path)
a=p.parse_args()
r=json.loads((a.directory/'report.json').read_text())
assert r['complete'] and r['mechanical_pass']
rows=r['samples'];assert len(rows)==(126 if r['scenario']=='interrupt' else 106)
assert [s['frame'] for s in rows]==list(range(len(rows)))
crops=a.directory/'crops';crops.mkdir(exist_ok=True)
hashes={}
for s in rows:
    path=a.directory/f"frame-{s['frame']:04d}.png"
    hashes[path.name]=hashlib.sha256(path.read_bytes()).hexdigest()
    x,y=s['screen_position'];sx,sy,ox,oy=s['screen_transform']
    x,y=round(x*sx+ox),round(y*sy+oy)
    with Image.open(path) as im:
        assert im.size==(1696,780)
        im.crop((x-160,y-220,x+160,y+60)).save(crops/path.name)
indices=[87,89,90,92,95,97,100,102,103,104,105,108] if r['scenario']=='interrupt' else [4,6,7,8,9,10,11,12,14,15,16,25]
sheet=Image.new('RGB',(1280,930),(25,29,33));draw=ImageDraw.Draw(sheet)
for n,i in enumerate(indices):
    s=rows[i];x=n%4*320;y=n//4*310
    with Image.open(crops/f'frame-{i:04d}.png') as im:sheet.paste(im,(x,y+30))
    draw.text((x+6,y+7),f"{i} | {s['seconds']:.3f}s | {s['transition']['mode']} | cell{s['cell']}",fill='white')
sheet.save(a.directory/'seam.jpg')
(a.directory/'full-frame-sha256.json').write_text(json.dumps(hashes,indent=2)+'\n')
result={'frames':len(rows),'hits':r['hits'],'damage':r['damage'],
        'report_sha256':hashlib.sha256((a.directory/'report.json').read_bytes()).hexdigest(),
        'hit_frames':[s['frame'] for n,s in enumerate(rows) if n and s['hp']!=rows[n-1]['hp']]}
if a.baseline:
    b=json.loads((a.baseline/'report.json').read_text())
    assert len(b['samples'])==len(rows)
    keys=('event','seconds','progress','active','moving','direction','hp','serial','target','position')
    differences=[i for i,(x,y) in enumerate(zip(b['samples'],rows)) if any(x[k]!=y[k] for k in keys)]
    assert not differences,differences
    result['mechanics_identical']=True
(a.directory/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
