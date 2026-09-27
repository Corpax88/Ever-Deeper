from pathlib import Path
import json,sys,struct,hashlib,re,shutil
from pack_helpers import unpack,identity
src,out=map(Path,sys.argv[1:]);out.mkdir(parents=True,exist_ok=True)
root=Path(__file__).resolve().parents[2]
manifest=json.loads((src/'manifest.json').read_text())
assert all(identity(src/n)==v for n,v in manifest.items())
assert json.loads((src/'build.json').read_text())['source']=='ba396beeed9e587a8dc700edef7b28b79f1095d6'
assert 'this._audioBuffer.duration>10' in (src/'index.js').read_text()
for n in manifest: shutil.copyfile(src/n,out/n)
data=bytearray((src/'index.pck').read_bytes());base,entries=unpack(data);before=dict(entries);replace={}
def script(path,text):
    replace[path]=text.encode();remap=path+'.remap'
    assert remap in entries
    off,size,*_=entries[remap];old=bytes(data[base+off:base+off+size]).decode()
    target=re.search(r'path="res://([^\"]+)"',old)[1]
    replace[remap]=('[remap]\npath="res://'+path+'"\n').encode()
    if target.endswith('.gd'): replace[target]=text.encode()
def wrap(text,name,args,call,ret='void'):
    signature='func '+name+'('+args+') -> '+ret+':'
    assert text.count(signature)==1,(name,signature)
    text=text.replace(signature,signature.replace(name,'_focus_original_'+name,1))
    text+='\nvar focus_'+name+': Vector3 = Vector3.ZERO\n'+signature+'\n\tvar started: int = Time.get_ticks_usec()\n'
    text+='\t'+('var result: '+ret+' = ' if ret!='void' else '')+'_focus_original_'+name+'('+call+')\n'
    text+='\tvar elapsed: int = Time.get_ticks_usec()-started\n\tfocus_'+name+' += Vector3(1,elapsed,0)\n\tfocus_'+name+'.z = maxf(focus_'+name+'.z,elapsed)\n'
    if ret!='void': text+='\treturn result\n'
    return text
p='scripts/world/mossvein_mine.gd';text=(root/p).read_text().replace(' -> void :',' -> void:')
for name,args,call in [('_process','delta: float','delta'),('_draw_partitioned_mine','start: Vector2i, finish: Vector2i','start, finish')]: text=wrap(text,name,args,call)
script(p,text)
p='scripts/player/native_worn_visual.gd';script(p,wrap((root/p).read_text(),'advance','delta: float','delta','bool'))
p='scripts/lighting/cave_light_occluders.gd';script(p,wrap((root/p).read_text(),'refresh','',''))
p='scripts/player/player_visual.gd';script(p,(root/p).read_text())
p='scripts/qa/suites/fps_review.gd';text=(root/p).read_text();text+='''
func _focus_values(v: Vector3) -> Array:
	return [v.x,v.y,v.z]
var focus_clock: int = 0
func _focus_frame() -> void:
	var now: int = Time.get_ticks_usec()
	if now-focus_clock < 250000: return
	focus_clock = now
	var w: Node = main.mine_world
	if w == null or w.player == null: return
	var n: Node = w.player.visual._native_worn
	var o: Node = w.get_node_or_null("CaveLightOccluders")
	if n == null or o == null: return
	JavaScriptBridge.eval("window.FOCUS_STATE="+JSON.stringify({"world":_focus_values(w.focus__process),"terrain":_focus_values(w.focus__draw_partitioned_mine),"native":_focus_values(n.focus_advance),"occlusion":_focus_values(o.focus_refresh),"sections":w.lit_draw_sections.debug_snapshot()}),true)
'''
text=text.replace('func _frame() -> void:\n','func _frame() -> void:\n\t_focus_frame()\n')
script(p,text)
for name,raw in replace.items():
    data+=b'\0'*(-len(data)%32);entries[name]=(len(data)-base,len(raw),hashlib.md5(raw).digest(),0);data+=raw
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(entries))
for name,(off,size,md5,flags) in sorted(entries.items()):
    key=name.encode();key+=b'\0'*(-len(key)%4);data+=struct.pack('<I',len(key))+key+struct.pack('<QQ16sI',off,size,md5,flags)
_,after=unpack(data);assert all(after[n]==v for n,v in before.items() if n not in replace)
(out/'index.pck').write_bytes(data)
html=(out/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);c['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):])
(out/'manifest.json').write_text(json.dumps({n:identity(out/n) for n in manifest}))
(out/'focus-build.json').write_text(json.dumps({'baseline':manifest,'replaced':list(replace),'purpose':'Bounded function timing, no production candidate'},indent=2))
