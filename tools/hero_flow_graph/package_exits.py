"""Trim only transparent margins and page real native exit frames for WebGL."""
import argparse
import hashlib
import json
import math
from pathlib import Path

from PIL import Image

p = argparse.ArgumentParser()
p.add_argument('--native', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
r = json.loads((a.native/'report.json').read_text())
assert r['complete'] and not r['failures'] and len(r['renders']) == 650
m = json.loads((a.output/'manifest.json').read_text())
images = []
masks = []
bounds = [160, 160, 0, 0]
for row in r['renders']:
    with Image.open(a.native/row['file']) as im:
        image = im.convert('RGBA').resize((160,160), Image.Resampling.LANCZOS)
    box = image.getchannel('A').getbbox()
    bounds = [min(bounds[0],box[0]), min(bounds[1],box[1]), max(bounds[2],box[2]), max(bounds[3],box[3])]
    images.append(image)
    path = next(a.native.glob('mask-'+Path(row['file']).stem+'-*.png'))
    with Image.open(path) as im:
        masks.append(im.convert('L').resize((160,160), Image.Resampling.LANCZOS))
# Two transparent guard pixels keep bilinear clipping independent of neighbours.
bounds = [max(0,bounds[0]-2), max(0,bounds[1]-2), min(160,bounds[2]+2), min(160,bounds[3]+2)]
width, height = bounds[2]-bounds[0], bounds[3]-bounds[1]
columns = 10
page_rows = min(25, 4000//height)
capacity = columns*page_rows
textures = []
for page in range(math.ceil(len(images)/capacity)):
    start = page*capacity
    rows = math.ceil(min(capacity,len(images)-start)/columns)
    atlas = Image.new('RGBA',(width*columns,height*rows))
    mask_atlas = Image.new('L',atlas.size)
    for i in range(start,min(start+capacity,len(images))):
        local = i-start
        xy = (local%columns*width,local//columns*height)
        atlas.paste(images[i].crop(bounds),xy)
        mask_atlas.paste(masks[i].crop(bounds),xy)
    color_name = f'exits-{page:02d}.png'
    mask_name = f'exits-{page:02d}-cloth.png'
    atlas.save(a.output/color_name)
    mask_atlas.save(a.output/mask_name)
    textures.extend([color_name,mask_name])
edges = {}
for i,row in enumerate(r['renders']):
    if row['step'] == 0:
        edges[row['edge']] = dict(r['edges'][row['edge']],offset=i)
m['exits'] = edges
m['exit_textures'] = textures
m['exit_profile'] = dict(steps=12,duration=r['duration'],distance_pixels=r['distance_pixels'],
                         cell=[width,height],columns=columns,page_capacity=capacity,
                         anchor=[r['anchor'][0]-bounds[0],r['anchor'][1]-bounds[1]],
                         crop=bounds,native_source_sha256=r['source_sha256'])
for name in textures:
    m['hashes'][name] = hashlib.sha256((a.output/name).read_bytes()).hexdigest()
(a.output/'manifest.json').write_text(json.dumps(m,indent=2)+'\n')
print('FLOW_GRAPH_EXITS_PACKAGED',len(images),'cell',width,height,'pages',len(textures)//2)
