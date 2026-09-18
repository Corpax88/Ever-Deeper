"""Download only the author's free Standard edition through its public form."""
import argparse
import hashlib
import http.cookiejar
import json
from pathlib import Path
import re
import struct
import urllib.parse
import urllib.request
import zipfile

p = argparse.ArgumentParser()
p.add_argument('--library', type=int, choices=(1, 2), required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
base = 'https://quaternius.itch.io/universal-animation-library' + ('-2' if a.library == 2 else '')
name = 'Universal Animation Library' + (' 2' if a.library == 2 else '') + '[Standard].zip'
op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

def get(url):
    return op.open(url, timeout=60).read()

def token(html):
    found = (re.search(r'"csrf_token"\s*:\s*"([^\"]+)"', html)
             or re.search(r'name="csrf_token"[^>]*value="([^\"]+)"', html))
    assert found, 'Public download form token not found'
    return found.group(1)

def post(url, data, ref):
    request = urllib.request.Request(url, data=urllib.parse.urlencode(data).encode(), headers={'Referer': ref})
    return json.loads(op.open(request, timeout=45).read())

page = get(base).decode()
download = post(base + '/download_url', {'csrf_token': token(page)}, base)['url']
free = get(download).decode()
matches = re.findall(r'data-upload_id="(\d+)".*?<strong[^>]*title="([^\"]+)"', free, re.S)
ids = [uid for uid, title in matches if title == name]
assert len(ids) == 1, 'Expected exactly the free Standard edition'
url = post(base + '/file/' + ids[0], {'csrf_token': token(free), 'source': 'game_download'}, download)['url']
data = get(url)
a.output.mkdir(parents=True, exist_ok=True)
archive = a.output / ('UAL%d-Standard.zip' % a.library)
archive.write_bytes(data)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    paths = [n for n in z.namelist() if Path(n).name == 'UAL%d_Standard.glb' % a.library]
    assert len(paths) == 1, paths
    model = a.output / Path(paths[0]).name
    model.write_bytes(z.read(paths[0]))
    for suffix in ('License.txt', 'README.txt'):
        found = [n for n in z.namelist() if n.endswith(suffix)]
        assert len(found) == 1, found
        (a.output / suffix).write_bytes(z.read(found[0]))
blob = model.read_bytes()
length, kind = struct.unpack_from('<II', blob, 12)
assert kind == 0x4E4F534A
gltf = json.loads(blob[20:20 + length])
result = {'official_page': base, 'edition': 'Standard', 'price_paid': 0,
          'upload_id': ids[0], 'archive_sha256': hashlib.sha256(data).hexdigest(),
          'asset_sha256': hashlib.sha256(blob).hexdigest(), 'asset': str(model),
          'license': 'CC0-1.0', 'animation_names': [x.get('name') for x in gltf['animations']]}
(a.output / 'inventory.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result))
