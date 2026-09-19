"""Compare complete native edge endpoints with the actually consumed banks."""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

p=argparse.ArgumentParser()
p.add_argument('directory',type=Path)
p.add_argument('--flow',type=Path,required=True)
p.add_argument('--walk',type=Path,required=True)
p.add_argument('--legacy',type=Path,required=True)
a=p.parse_args()
bank=json.loads((a.directory/'atlas.json').read_text())
manifest=json.loads((a.legacy/'manifest.json').read_text())
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
assert bank['complete'] and bank['flow_atlas_sha256']==sha(a.flow/'atlas.png')
assert bank['walk_atlas_sha256']==sha(a.walk/'atlas.png')
cases=[
    ('brake source','interrupt-000.png',a.walk/'frame-0006.png',None,None),
    ('entry sink','walk-entry-008.png',a.flow/'frame-0010.png',None,None),
    ('entry source','walk-entry-000.png',a.legacy/'up.png','up',39),
    ('brake sink','interrupt-014.png',a.legacy/'down.png','down',0),
]
rows=[];sheet=Image.new('RGB',(700,720),(30,35,40));draw=ImageDraw.Draw(sheet)
for i,(label,new,old,direction,cell) in enumerate(cases):
    candidate=Image.open(a.directory/new).convert('RGBA').resize((160,160),Image.Resampling.LANCZOS)
    reference=Image.open(old).convert('RGBA')
    if direction:
        columns=manifest['columns'];size=manifest['cell'][0]
        reference=reference.crop((cell%columns*size,cell//columns*size,(cell%columns+1)*size,(cell//columns+1)*size))
        anchor=manifest['directions'][direction]['ground_anchor']
        dx,dy=[bank['anchor'][j]-anchor[j] for j in range(2)]
        reference=reference.transform((160,160),Image.Transform.AFFINE,(1,0,-dx,0,1,-dy),Image.Resampling.BICUBIC)
    else:
        reference=reference.resize((160,160),Image.Resampling.LANCZOS)
    aa,bb=np.array(reference,dtype=float),np.array(candidate,dtype=float)
    diff=np.abs(aa-bb);union=(aa[:,:,3]>20)|(bb[:,:,3]>20)
    masks=[im.getchannel('A').point(lambda v:255 if v>=128 else 0) for im in (reference,candidate)]
    binary=[np.array(im)>0 for im in masks]
    expanded=[np.array(im.filter(ImageFilter.MaxFilter(3)))>0 for im in masks]
    outside=int((binary[0]&~expanded[1]).sum()+(binary[1]&~expanded[0]).sum())
    rows.append({'label':label,'reference_sha256':sha(old),'candidate_sha256':sha(a.directory/new),
        'alpha_mean_error':float(diff[:,:,3].mean()),'alpha_max_error':float(diff[:,:,3].max()),
        'rgba_mean_error_visible':float(diff[union].mean()),'identical':bool(np.array_equal(aa,bb)),
        'silhouette_unmatched_beyond_1px':outside})
    assert outside==0,(label,outside)
    draw.text((8,i*180+8),label,fill='white')
    for x,im in [(160,reference),(340,candidate)]:sheet.paste(im,(x,i*180+20),im)
    sheet.paste(Image.fromarray(np.uint8(np.clip(diff[:,:,:3]*4,0,255))),(520,i*180+20))
(a.directory/'endpoint-comparison.json').write_text(json.dumps(rows,indent=2)+'\n')
sheet.save(a.directory/'endpoint-comparison.jpg')
print('TRANSITION21_ENDPOINTS_COMPLETE',len(rows),'silhouettes within1px; RGBA is not byte-identical')
