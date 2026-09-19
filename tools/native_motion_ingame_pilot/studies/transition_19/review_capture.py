"""Extract exact gameplay crops, event sheets and mechanical parity evidence."""
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
assert r['complete']
crops=a.directory/'crops';crops.mkdir(exist_ok=True)
hashes={}
for s in r['samples']:
    name=f"frame-{s['frame']:04d}.png"
    path=a.directory/name
    hashes[name]=hashlib.sha256(path.read_bytes()).hexdigest()
    x,y=s['screen_position']
    # Canvas-items stretch is outside get_global_transform_with_canvas().
    # Older baseline reports lack it; derive the exact project expand rule.
    expand=min(1696/1280,780/720)
    derived=[1696*1.1/int(1696/expand),780*1.1/int(780/expand),0,0]
    sx,sy,ox,oy=s.get('screen_transform',derived)
    x,y=round(x*sx+ox),round(y*sy+oy)
    with Image.open(path) as im:
        assert im.size==(1696,780)
        im.crop((x-160,y-220,x+160,y+60)).save(crops/name)
(a.directory/'full-frame-sha256.json').write_text(json.dumps(hashes,indent=2)+'\n')
groups={'entry-cancel':[10,11,12,13,24,25,26,27,30,34,38,43],
        'restart-release':[43,44,45,48,60,61,62,69,70,74,78,85],
        'walk-exit':[123,124,125,126,128,130,132,134,136,138,146,148]}
if r.get('scenario')=='rapid':
    groups={'rapid-before-hit':[24,25,26,29,30,31,33,35,37,45,46,47],
            'rapid-after-hit':[54,55,56,58,59,60,61,62,63,64,75,76],
            'rapid-walk':[82,83,84,85,87,89,91,93,95,97,105,107]}
for name,indices in groups.items():
    im=Image.new('RGB',(1280,930),(25,29,33));d=ImageDraw.Draw(im)
    for n,i in enumerate(indices):
        s=r['samples'][i];x=n%4*320;y=n//4*310
        with Image.open(crops/f'frame-{i:04d}.png') as frame:im.paste(frame,(x,y+30))
        d.text((x+6,y+7),f"{i} | {s['seconds']:.3f}s | cell{s['cell']} | HP{s['hp']}",fill='white')
    im.save(a.directory/(name+'.jpg'))
result={'frames':len(r['samples']),'hits':r['hits'],'damage':r['damage'],
        'no_pre_hit_cancel_damage':all(s['hp']==950 for s in r['samples'][:(47 if r.get('scenario')=='rapid' else 61)]),
        'hit_frames':[s['frame'] for n,s in enumerate(r['samples']) if n and s['hp']!=r['samples'][n-1]['hp']]}
if a.baseline:
    b=json.loads((a.baseline/'report.json').read_text())
    keys=('event','progress','active','moving','direction','hp','serial','target','position')
    different=[{'frame':i,'keys':[k for k in keys if x[k]!=y[k]]}
               for i,(x,y) in enumerate(zip(b['samples'],r['samples'])) if any(x[k]!=y[k] for k in keys)]
    result.update(mechanics_identical=not different,mechanical_differences=different)
(a.directory/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
