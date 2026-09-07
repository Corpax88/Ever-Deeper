import sys,struct,hashlib,zlib,json
from pathlib import Path
sha=lambda b:hashlib.sha256(b).hexdigest()
a=Path(sys.argv[1]).read_bytes();b=Path(sys.argv[2]).read_bytes();out=Path(sys.argv[3]);out.mkdir(parents=True,exist_ok=True)
def inv(data):
 assert data[:4]==b'GDPC' and struct.unpack_from('<I',data,4)[0]==4
 base,di=struct.unpack_from('<QQ',data,24);n=struct.unpack_from('<I',data,di)[0];p=di+4;entries=[]
 for _ in range(n):
  sz=struct.unpack_from('<I',data,p)[0];p+=4;name=data[p:p+sz].rstrip(b'\0').decode();p+=sz
  offset,size=struct.unpack_from('<QQ',data,p);p+=16;md5=data[p:p+16];p+=20;offset+=base
  assert hashlib.md5(data[offset:offset+size]).digest()==md5,name
  entries.append((offset,size,md5,name))
 return sorted(entries)
old={(size,md5):(off,name) for off,size,md5,name in inv(a)};ops=[];literals=bytearray();cursor=0
for off,size,md5,name in inv(b):
 if off>cursor:
  ops.append(['add',len(literals),off-cursor]);literals.extend(b[cursor:off])
 if (size,md5) in old:ops.append(['copy',old[(size,md5)][0],size])
 else:ops.append(['add',len(literals),size]);literals.extend(b[off:off+size])
 cursor=off+size
if cursor<len(b):ops.append(['add',len(literals),len(b)-cursor]);literals.extend(b[cursor:])
payload=zlib.compress(literals,9);parts=[]
for i in range(0,len(payload),65536):
 data=payload[i:i+65536];name=f'payload.part{i//65536:04d}';(out/name).write_bytes(data);parts.append({'name':name,'size':len(data),'sha256':sha(data)})
m={'format':'ever-deeper-copy-add-v1','base_size':len(a),'base_sha256':sha(a),'target_size':len(b),'target_sha256':sha(b),'literal_size':len(literals),'literal_sha256':sha(literals),'payload_size':len(payload),'payload_sha256':sha(payload),'parts':parts,'operations':ops}
assert b''.join((a if op=='copy' else literals)[start:start+size] for op,start,size in ops)==b
(out/'delta.json').write_text(json.dumps(m,separators=(',',':'))+'\n');print(len(b),len(payload),len(parts))
