"""Prepare imagegen PNGs for 84px game bays at up to DPR3; preserve alpha and aspect."""
from pathlib import Path
import hashlib,json,shutil
from PIL import Image
root=Path(__file__).resolve().parents[1]
originals=Path(__import__('sys').argv[1]);originals.mkdir(parents=True,exist_ok=True)
catalog=json.loads((root/'docs/treasury-growth/asset-catalog.json').read_text())
report=[]
assert len(catalog)==81
for item in catalog:
 name=f"{item['kind']}-{item['tier']}.png"
 target=root/'assets/treasury/upgrades'/name
 source=originals/name
 if not source.exists():shutil.copyfile(target,source)
 image=Image.open(source)
 assert image.mode=='RGBA' and image.getchannel('A').getextrema()[0]==0,name
 image.thumbnail((384,384),Image.Resampling.LANCZOS)
 image.save(target,optimize=True)
 report.append({'file':name,'original_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'runtime_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'size':list(image.size),'bytes':target.stat().st_size})
(root/'docs/treasury-growth/assets.json').write_text(json.dumps(report,indent=2))
print('Prepared',len(report),'transparent PNGs;',sum(x['bytes'] for x in report),'bytes')
