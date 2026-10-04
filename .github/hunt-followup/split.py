"""Split a compressed recovery bundle into independently downloadable <30MiB artifacts."""
from pathlib import Path
import hashlib,json,sys,zipfile
src,out=map(Path,sys.argv[1:3]);out.mkdir(parents=True,exist_ok=True)
archive=out/'recovery.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=1) as z:
    for p in sorted(src.rglob('*')):
        if p.is_file(): z.write(p,p.relative_to(src))
parts=[]
with archive.open('rb') as f:
    for i in range(99):
        data=f.read(28*1024*1024)
        if not data: break
        name='part-%02d.bin'%i;(out/name).write_bytes(data)
        parts.append({'name':name,'size':len(data),'sha256':hashlib.sha256(data).hexdigest()})
assert len(parts)<=4,'Evidence exceeds the four independently uploaded parts: '+str(len(parts))
(out/'recovery-manifest.json').write_text(json.dumps({'format':'Concatenate parts in manifest order, verify SHA256, then unzip','archive_size':archive.stat().st_size,'archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'parts':parts},indent=2))
archive.unlink()
print('RECOVERY_SPLIT',len(parts))
