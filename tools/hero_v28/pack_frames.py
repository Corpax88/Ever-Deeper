"""Pack genuine native frames without changing runtime atlas layout or timing."""
from pathlib import Path
from PIL import Image
import json,math,hashlib,argparse
ap=argparse.ArgumentParser();ap.add_argument('--frames',type=Path,required=True);ap.add_argument('--game',type=Path,required=True);ap.add_argument('--gear',required=True);a=ap.parse_args()
source=a.frames/a.gear;m=json.loads((source/'manifest.json').read_text());out=a.game/'assets/hero/dad'/a.gear
old=json.loads((out/'manifest.json').read_text())
assert m['states']==old['states'] and m['max_grip_error']<1e-5
count=sum(v['count'] for v in m['states'].values());cell=160;cols=8;rows=math.ceil(count/cols);stats={}
for direction in ['down','left','up','right']:
 beauty=Image.new('RGBA',(cols*cell,rows*cell));cloth=Image.new('L',beauty.size);hashes=set();boxes=[]
 frames=[f for f in m['frames'] if f['direction']==direction];assert len(frames)==count
 for f in frames:
  im=Image.open(source/f['path']).convert('RGBA');mask=Image.open(source/f['mask']).convert('L')
  assert im.size==mask.size==(200,200)
  bbox=im.getchannel('A').point(lambda v:255 if v>32 else 0).getbbox()
  assert bbox and bbox[0]>0 and bbox[1]>=2 and bbox[2]<200 and bbox[3]<=198,(a.gear,f['path'],bbox)
  assert im.getchannel('A').getextrema()[0]==0
  hashes.add(hashlib.sha256(im.tobytes()).hexdigest());boxes.append(bbox)
  index=m['states'][f['state']]['offset']+f['index'];pos=((index%cols)*cell,(index//cols)*cell)
  beauty.paste(im.resize((cell,cell),Image.Resampling.LANCZOS),pos)
  cloth.paste(mask.resize((cell,cell),Image.Resampling.LANCZOS),pos)
 assert len(hashes)>count*.5
 assert cloth.getextrema()[1]>200

 for im,name in [(beauty,direction+'.png'),(cloth,direction+'-cloth.png')]:
  target=out/name;temporary=out/(name+'.partial')
  im.save(temporary,format='PNG',optimize=True)
  with Image.open(temporary) as check:check.verify()
  temporary.replace(target)
 stats[direction]={'frames':count,'unique':len(hashes),'edge_clipping':[],'atlas_size':list(beauty.size),'silhouette_bounds':[min(b[0] for b in boxes),min(b[1] for b in boxes),max(b[2] for b in boxes),max(b[3] for b in boxes)]}
 m['directions'][direction]['ground_anchor']=[v*.8 for v in m['directions'][direction]['ground_anchor']]
 # Old manifests sampled the previous camera transform. Use the actual
 # projected floor origin so the new feet align with the gameplay shadow.
 assert all(0<v<cell for v in m['directions'][direction]['ground_anchor'])
 stats[direction]['previous_ground_anchor']=old.get('qa',{}).get(direction,{}).get('previous_ground_anchor',old['directions'][direction]['ground_anchor'])
 stats[direction]['ground_anchor']=m['directions'][direction]['ground_anchor']
m.pop('frames');m['cell']=[cell,cell];m['qa']=stats;m['visual_model']='Gruvepappa v28, approved by Mats';m['runtime_3d']=False
(out/'manifest.json').write_text(json.dumps(m,indent=2)+'\n')
print('PACKED_V28',a.gear,json.dumps(stats),flush=True)
