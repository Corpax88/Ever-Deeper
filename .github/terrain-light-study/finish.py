"""Validate and finish the immutable PCK already exported by run36054823975.

That run completed import/export; its old15.8 HTML pin rejected the current15.9
shell before normalization. Keep the exported PCK, validate every runtime byte
against the exact published15.9 manifest, then update only its declared PCK size.
"""
import hashlib,json,re,sys
from pathlib import Path
p=Path(sys.argv[1]);baseline=json.loads(Path('.github/terrain-light-study/baseline.json').read_text())
def identity(f):
 h=hashlib.sha256()
 with f.open('rb') as stream:
  for chunk in iter(lambda:stream.read(1024*1024),b''):h.update(chunk)
 return {'size':f.stat().st_size,'sha256':h.hexdigest()}
for name,want in baseline.items():
 if name!='index.pck':assert identity(p/name)==want, 'Unexpected runtime bytes: '+name
html=(p/'index.html').read_text();match=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);assert match
config=json.loads(match[1]);config['fileSizes']['index.pck']=(p/'index.pck').stat().st_size
html=html[:match.start(1)]+json.dumps(config,separators=(',',':'))+html[match.end(1):]
(p/'index.html').write_text(html)
manifest={name:identity(p/name) for name in baseline};(p/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(p.parent/'build.json').write_text(json.dumps({'export_source':'8739b8c438ccbe2c979f6f92f79aad2f7814e067','export_run':36054823975,'export_artifact':10831309877,'runtime_reference':'c63aabd3e3e5120579285ce6e8b0b59a75f2727a','files':manifest,'reexported':False},indent=2)+'\n')
print('IMMUTABLE_EXPORT_RUNTIME_VALIDATED')
