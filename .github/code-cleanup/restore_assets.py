"""One-time transfer of the exact reviewed source assets into the repository."""
from pathlib import Path
import base64,hashlib,json,os,shutil,tarfile,tempfile,urllib.request
ROOT=Path.cwd();META=Path(__file__).resolve().parent
manifest=json.loads((META/'asset-snapshot.json').read_text())
repo=os.environ['GITHUB_REPOSITORY'];token=os.environ['GH_TOKEN']
with tempfile.TemporaryDirectory(prefix='ever-deeper-source-') as folder:
    stage=Path(folder);archive=stage/'assets.tar.gz'
    with archive.open('wb') as stream:
        for index,part in enumerate(manifest['parts']):
            request=urllib.request.Request(f'https://api.github.com/repos/{repo}/git/blobs/{part["sha"]}',headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','User-Agent':'Ever-Deeper-source-restore'})
            data=json.loads(urllib.request.urlopen(request,timeout=180).read())
            raw=base64.b64decode(data['content'])
            assert len(raw)==part['size'] and hashlib.sha256(raw).hexdigest()==part['sha256'],'Snapshot part mismatch'
            stream.write(raw)
            print(f'Verified source asset segment {index+1}/{len(manifest["parts"])}',flush=True)
    assert hashlib.sha256(archive.read_bytes()).hexdigest()==manifest['sha256']
    with tarfile.open(archive) as tar:tar.extractall(stage,filter='data')
    expected=json.loads((ROOT/'docs/unchanged-files.json').read_text())
    expected={n:h for n,h in expected.items() if n.startswith('assets/')}
    actual={str(p.relative_to(stage)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (stage/'assets').rglob('*') if p.is_file()}
    assert actual==expected,'Authored assets or import options changed'
    target=ROOT/'assets'
    if target.exists():shutil.rmtree(target)
    shutil.move(stage/'assets',target)
print('Exact current source assets restored; no artwork changed')
