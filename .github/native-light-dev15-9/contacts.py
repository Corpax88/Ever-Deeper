from pathlib import Path
import sys,shutil,json
from PIL import Image,ImageDraw
root=Path(sys.argv[1]);out=Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
for p in root.rglob('*'):
 if p.is_file() and (p.suffix in ['.json','.log'] or p.name in ['emberMine-intact-reference.png','emberMine-intact-cached.png','light-test-complete.png','06-confirmed-new-game.png']):
  q=out/p.relative_to(root);q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
report=root/'study/report.json'
if report.exists():
 pairs=json.loads(report.read_text()).get('pairs',[])
 for start in range(0,len(pairs),4):
  group=pairs[start:start+4];sheet=Image.new('RGB',(1266,318*len(group)),(12,16,14));draw=ImageDraw.Draw(sheet)
  for row,pair in enumerate(group):
   for col,mode in enumerate(['reference','cached']):
    p=root/'study'/(pair['label']+'-'+mode+'.png')
    im=Image.open(p).convert('RGB');im.thumbnail((633,293))
    sheet.paste(im,(col*633,row*318+25));draw.text((col*633+8,row*318+6),pair['label']+' / '+('original' if col==0 else 'native shader'),fill=(255,245,210))
  sheet.save(out/('pairs-%02d.png'%start))
