"""Actual continuous-capture crops, cadence and gameplay comparison."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image,ImageDraw

p=argparse.ArgumentParser()
p.add_argument('--game',type=Path,required=True)
p.add_argument('--baseline',type=Path,required=True)
p.add_argument('--native',type=Path,required=True)
p.add_argument('--old-native',type=Path,required=True)
a=p.parse_args()
game=json.loads((a.game/'report.json').read_text())
baseline=json.loads((a.baseline/'report.json').read_text())
assert game['complete'] and baseline['complete']
keys=('frame','seconds','progress','hp','serial','target','position')
different=[i for i,(x,y) in enumerate(zip(game['samples'],baseline['samples'])) if any(x[k]!=y[k] for k in keys)]
assert len(game['samples'])==len(baseline['samples']) and not different,different
hashes={}
crops=a.game/'crops';crops.mkdir(exist_ok=True)
for s in game['samples']:
    i=s['frame'];path=a.game/f'frame-{i:04d}.png'
    hashes[path.name]=hashlib.sha256(path.read_bytes()).hexdigest()
    x,y=s['screen_position'];sx,sy,ox,oy=s['screen_transform'];x,y=round(x*sx+ox),round(y*sy+oy)
    with Image.open(path) as im:im.crop((x-160,y-220,x+160,y+60)).save(crops/path.name)
(a.game/'full-frame-sha256.json').write_text(json.dumps(hashes,indent=2)+'\n')
for label,indices in {'contact-return':[55,56,57,58,59,60,61,62,63,64,65,66],
                      'next-load':[72,73,74,75,76,77,78,79,80,81,82,83]}.items():
    sheet=Image.new('RGB',(1280,930),(25,29,33));draw=ImageDraw.Draw(sheet)
    for n,i in enumerate(indices):
        s=game['samples'][i];x=n%4*320;y=n//4*310
        with Image.open(crops/f'frame-{i:04d}.png') as im:sheet.paste(im,(x,y+30))
        draw.text((x+6,y+7),f"{i} | {s['seconds']:.3f}s | cell{s['cell']} | HP{s['hp']}",fill='white')
    sheet.save(a.game/(label+'.jpg'))
def holds(directory):
    rows=json.loads((directory/'report.json').read_text())['renders']
    def values(p):return p['tool_cap']+[v for q in p['arm_quaternions'].values() for v in q]
    return [i for i in range(len(rows)) if max(abs(x-y) for x,y in zip(values(rows[i]),values(rows[(i+1)%len(rows)])))<1e-5]
result={'frames':len(game['samples']),'mechanics_identical':True,'hits':game['hits'],'damage':game['damage'],
        'old_identical_pose_steps':holds(a.old_native),'new_identical_pose_steps':holds(a.native),
        'capture_hz':60,'physical_device_fps_measured':False,'continuous_video_review':False}
(a.game/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
