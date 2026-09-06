"""Rebuild only after every base, ordered payload and output identity matches."""
import sys,json,zlib,hashlib
from pathlib import Path
base=Path(sys.argv[1]);source=Path(sys.argv[2]);output=Path(sys.argv[3]);m=json.loads((source/'delta.json').read_text())
sha=lambda b:hashlib.sha256(b).hexdigest()
assert m['format']=='ever-deeper-copy-add-v1'
a=base.read_bytes();assert len(a)==m['base_size'] and sha(a)==m['base_sha256'],'wrong base'
parts=[]
for index,part in enumerate(m['parts']):
    assert part['name']==f'payload.part{index:04d}'
    data=(source/part['name']).read_bytes();assert len(data)==part['size'] and sha(data)==part['sha256'];parts.append(data)
payload=b''.join(parts);assert len(payload)==m['payload_size'] and sha(payload)==m['payload_sha256']
b=zlib.decompress(payload);assert len(b)==m['literal_size'] and sha(b)==m['literal_sha256']
chunks=[]
for mode,start,length in m['operations']:
    assert mode in ['copy','add'] and isinstance(start,int) and isinstance(length,int) and start>=0 and length>0
    data=a if mode=='copy' else b;assert start+length<=len(data);chunks.append(data[start:start+length])
result=b''.join(chunks);assert len(result)==m['target_size'] and sha(result)==m['target_sha256'],'wrong target'
output.parent.mkdir(parents=True,exist_ok=True);temp=output.with_suffix(output.suffix+'.tmp');temp.write_bytes(result);temp.replace(output)
print('Verified exact candidate',m['target_sha256'],len(result))
