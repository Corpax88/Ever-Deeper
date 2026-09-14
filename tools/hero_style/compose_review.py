"""Lay out unchanged native captures and verify paired environment pixels."""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFont

p=argparse.ArgumentParser()
p.add_argument('--captures',type=Path,required=True)
p.add_argument('--output',type=Path,required=True)
a=p.parse_args()
font_dir=Path('/usr/share/fonts/truetype/dejavu')
def font(size,bold=False):
 return ImageFont.truetype(str(font_dir/('DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf')),size)

sheet=Image.new('RGB',(1740,2020),'#151b1b');d=ImageDraw.Draw(sheet)
d.text((44,30),'EVER-DEEPER · HELTEN I MILJØET',font=font(36,True),fill='#e4d8b6')
d.text((44,81),'Sammenlignbar Blender-prøve i ekte spillmiljø',font=font(25),fill='#b5c0ba')
d.text((44,126),'DAGENS SPRITE',font=font(25,True),fill='#d9c8a1')
d.text((893,126),'NY MATERIALPRØVE',font=font(25,True),fill='#b7d8bf')
fixtures=[('surface','OVERFLATEN',(65,375,480,650)),('mossvein','MOSSVEIN',(100,125,515,400)),('moonglass','MOONGLASS',(110,120,525,395))]
checks=[]
for i,(fixture,label,box) in enumerate(fixtures):
 top=174+i*592
 d.text((44,top),label,font=font(24,True),fill='#e4d8b6')
 for j,state in enumerate(['before','after']):
  im=Image.open(a.captures/f'{fixture}-{state}.png').convert('RGB')
  crop=im.crop(box).resize((802,531),Image.Resampling.LANCZOS)
  sheet.paste(crop,(44+j*849,top+39))
  d.rectangle((44+j*849,top+39,845+j*849,top+569),outline='#485046')
for fixture in ['surface','mossvein','moonglass','hub']:
 before=np.array(Image.open(a.captures/f'{fixture}-before.png').convert('RGBA'))
 after=np.array(Image.open(a.captures/f'{fixture}-after.png').convert('RGBA'))
 diff=np.any(before!=after,axis=2);ys,xs=np.where(diff)
 bounds=[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)]
 assert bounds[2]-bounds[0]<145 and bounds[3]-bounds[1]<190,(fixture,bounds)
 checks.append({'case':fixture,'changed_pixels':int(diff.sum()),'bounds_xyxy':bounds,'outside_hero_bounds_identical':True})
d.text((44,1958),'Samme modell, posering, utsnitt og 160 px spritecelle. Forstørrede utsnitt; spillgrensesnittet er skjult.',font=font(21),fill='#b5c0ba')
sheet.save(a.output)
(a.captures/'paired-pixel-check.json').write_text(json.dumps(checks,indent=2))
print(json.dumps({'comparison':str(a.output),'checks':checks}))
