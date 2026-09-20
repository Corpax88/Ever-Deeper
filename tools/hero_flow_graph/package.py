"""Package genuine native frames, retaining approved color pixels exactly."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil

from PIL import Image

p = argparse.ArgumentParser()
p.add_argument('--native', type=Path, required=True)
p.add_argument('--flow', type=Path, required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
r = json.loads((a.native/'report.json').read_text())
assert r['complete'] and len(r['renders']) == 57
f = json.loads((a.flow/'atlas.json').read_text())
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
assert sha(a.flow/'atlas.png') == '6a869dc427d9d0e66c2582f02be9c6719842e8878dc88af7426d4dc1da70fca1'
a.output.mkdir(parents=True, exist_ok=True)
shutil.copyfile(a.flow/'atlas.png', a.output/'flow.png')

def pack(rows, root, name, color=True):
    atlas = Image.new('RGBA', (1600, 160*math.ceil(len(rows)/10)))
    masks = Image.new('RGBA', atlas.size)
    for i, row in enumerate(rows):
        file = row['file']
        xy = (i%10*160, i//10*160)
        if color:
            with Image.open(root/file) as im:
                atlas.paste(im.convert('RGBA').resize((160,160), Image.Resampling.LANCZOS), xy)
        matches = list(root.glob('mask-'+Path(file).stem+'-*.png'))
        assert len(matches) == 1, (file, matches)
        with Image.open(matches[0]) as im:
            masks.paste(im.convert('RGBA').resize((160,160), Image.Resampling.LANCZOS), xy)
    if color:
        atlas.save(a.output/(name+'.png'))
    masks.save(a.output/(name+'-cloth.png'))

pack([{'file':f'frame-{i:04d}.png'} for i in range(50)], a.flow, 'flow', color=False)
pack(r['renders'], a.native, 'edges')
edges = {}
for i, row in enumerate(r['renders']):
    if row['step'] == 0:
        edges[row['edge']] = dict(r['edges'][row['edge']], offset=i)
manifest = dict(schema=1, cell=[160,160], columns=10, anchor=f['anchor'], flow_count=50,
                contact_cell=21, contact_progress=.42, edges=edges,
                native_source_sha256=r['source_sha256'], approved_loop_unchanged=True,
                accepted_for_production=False,
                hashes={n:sha(a.output/n) for n in ('flow.png','flow-cloth.png','edges.png','edges-cloth.png')})
(a.output/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
print('FLOW_GRAPH_PACKAGED', len(r['renders']), manifest['hashes']['flow.png'])
