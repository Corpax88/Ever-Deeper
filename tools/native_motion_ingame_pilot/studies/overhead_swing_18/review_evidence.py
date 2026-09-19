"""Contact sheets and lossless gameplay crops from actual recorded frames."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

p=argparse.ArgumentParser()
p.add_argument('--native',type=Path,required=True)
p.add_argument('--game',type=Path)
a=p.parse_args()
n=json.loads((a.native/'report.json').read_text())
assert n['complete'] and len(n['renders'])==50

def sheet(directory,records,indices,crop,output):
    size=(320,280) if crop else (250,250)
    result=Image.new('RGB',(4*size[0],4*(size[1]+30)),(31,36,41))
    draw=ImageDraw.Draw(result)
    for j,i in enumerate(indices):
        v=records[i]
        with Image.open(directory/f'frame-{i:04d}.png') as original:
            im=original.crop(crop) if crop else original.convert('RGBA').resize(size,Image.Resampling.NEAREST)
            x,y=j%4*size[0],j//4*(size[1]+30)
            result.paste(im,(x,y+30),im if im.mode=='RGBA' else None)
            label=f"{i:02d} | {v['seconds']:.3f}s"
            if 'cell' in v:label+=f" | cell {v['cell']} | HP {v['hp']}"
            draw.text((x+6,y+8),label,fill='white')
    result.save(output)

sheet(a.native,n['renders'],[0,3,6,9,12,15,17,19,21,24,26,30,35,40,45,49],None,a.native/'ordered-frames.jpg')
if a.game:
    g=json.loads((a.game/'report.json').read_text())
    assert g['complete'] and len(g['samples'])==150
    crop=(830,290,1150,570)
    sheet(a.game,g['samples'],[2,6,9,13,17,19,22,27,34,40,48,54,57,65,70,81],crop,a.game/'ordered-game-crops.jpg')
    out=a.game/'crops';out.mkdir(exist_ok=True)
    hashes={}
    for v in g['samples']:
        filename=f"frame-{v['frame']:04d}.png";source=a.game/filename
        hashes[filename]=hashlib.sha256(source.read_bytes()).hexdigest()
        with Image.open(source) as im:im.crop(crop).save(out/filename)
    (a.game/'full-frame-sha256.json').write_text(json.dumps(hashes,indent=2)+'\n')
    (out/'crop.json').write_text(json.dumps(dict(source_box=crop,source_dimensions=[1696,780],frames=150))+'\n')
print('Actual frame evidence prepared')
