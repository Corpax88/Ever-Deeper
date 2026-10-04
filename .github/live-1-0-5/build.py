"""Promote immutable approved DEV15.56 resources to production, without re-export."""
from pathlib import Path
import hashlib,json,os,re,shutil,struct,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'diagnostics-v2'))
from pack_helpers import unpack,identity
here=Path(__file__).resolve().parent
src,out=map(Path,sys.argv[1:3]);expected=json.loads((here/'baseline.json').read_text())
assert all(identity(src/n)==v for n,v in expected.items()),'Wrong DEV15.56 bytes'
out.mkdir(parents=True,exist_ok=False)
for n in expected:shutil.copyfile(src/n,out/n)
original=(src/'index.pck').read_bytes();base,entries=unpack(original)
def raw(n):
 o,s,*_=entries[n];return original[base+o:base+o+s]
def target(n):return re.search(r'path="res://([^\"]+)"',raw(n+'.remap').decode())[1]
# ECFG records: length-prefixed key, length-prefixed encoded Variant.
# Preserve every other setting byte-for-byte, including save identity and graphics.
b=raw('project.binary');assert b[:4]==b'ECFG';count,=struct.unpack_from('<I',b,4);pos=8;records=[];changed=[]
for _ in range(count):
 start=pos;n,=struct.unpack_from('<I',b,pos);pos+=4;k=b[pos:pos+n].decode();pos+=n;n,=struct.unpack_from('<I',b,pos);pos+=4;v=b[pos:pos+n];pos+=n
 if k=='_custom_features':
  assert v==struct.pack('<II',4,15)+b'ever_deeper_dev\0';changed.append(k);continue
 record=b[start:pos]
 if k=='application/config/version':
  assert v==struct.pack('<II',4,5)+b'1.0.0\0\0\0';record=record[:-len(v)]+v.replace(b'1.0.0',b'1.0.5');changed.append(k)
 records.append(record)
assert pos==len(b) and set(changed)=={'_custom_features','application/config/version'}
replacements={'project.binary':b'ECFG'+struct.pack('<I',len(records))+b''.join(records)}
# Observer already tolerates absent DEV tools in the accepted package.
menu=target('scripts/ui/premium_menu.gd');text=raw(menu).decode()
assert text.count('return "1.0.1"')==1
replacements[menu]=text.replace('return "1.0.1"','return "1.0.5"').encode()
# Existing migration fixture predates persistent drops added in DEV15.28.
# Update its exact expected empty journal shape; gameplay sanitizer is unchanged.
n='scripts/qa/suites/one_point_zero_migration.gd';active=n;text=(here.parents[1]/n).read_text()
old='clean["1"] == {"dug": "", "nodes": 0, "sites": 0, "seen": 0}'
assert text.count(old)==1
text=text.replace(old,old[:-1]+', "drops": {}}')
text=text.replace('\tvar saved: Dictionary = RunState.serialize()\n\tvar expected:', '\tRunState.deep_events = {"kind": "", "mined": 8, "next": 96, "remaining": 0.0, "serial": 1, "x": 0, "y": 0}\n\tvar saved: Dictionary = RunState.serialize()\n\tvar expected:')
replacements[active]=text.encode()
replacements[n+'.remap']=('[remap]\npath="res://'+n+'"\n').encode()
n='scripts/qa/suites/premium_core.gd';name=n
source=raw(target(n)).decode()
edits={
    '_check(main.premium_hud.progression_goal_snapshot().get("objective_id","")=="treasury:wallet_gold","Shared HUD state-change refresh retains pinned treasury goal")':
    '_check(RunState.treasury_goals.pinned=="" and not String(main.premium_hud.progression_goal_snapshot().get("objective_id","")).begins_with("treasury:") and not main.premium_hud.progression_goal_snapshot().is_empty(),"Shared HUD resumes progression after completed treasury goal")',
    '_check(RunState.deserialize(mod_saved) and RunState.treasury_goals.resonance_enabled and RunState.treasury_goals.pinned=="wallet_gold","Claim, enabled state and pinned goal survive save roundtrip")':
    '_check(RunState.deserialize(mod_saved) and RunState.treasury_goals.resonance_claimed and RunState.treasury_goals.resonance_enabled and RunState.treasury_goals.pinned=="","Claim and enabled state survive roundtrip with completed goal retired")',
}
for old,new in edits.items():
    assert source.count(old)==1,'Premium contract owner changed'
    source=source.replace(old,new)
replacements[name]=source.encode()
replacements[name+'.remap']=('[remap]\npath="res://'+name+'"\n').encode()
removed={n for n in entries if n.startswith(('scripts/dev/developer_menu.','scripts/dev/render_probe.'))}
assert len(removed)==6
# Repack from the original header; omit removed resources and stale old payloads.
data=bytearray(original[:base]);after={}
for name in sorted((set(entries)|set(replacements))-removed):
 payload=(replacements[name] if name in replacements else raw(name));data+=b'\0'*(-len(data)%32)
 after[name]=(len(data)-base,len(payload),hashlib.md5(payload).digest(),0);data+=payload
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(after))
for name,(o,s,d,f) in after.items():
 k=name.encode();k+=b'\0'*(-len(k)%4);data+=struct.pack('<I',len(k))+k+struct.pack('<QQ16sI',o,s,d,f)
newbase,verified=unpack(data)
for n,(o,s,d,f) in verified.items():
 assert bytes(data[newbase+o:newbase+o+s])==(replacements[n] if n in replacements else raw(n)),n
assert not removed.intersection(verified) and 'override.cfg' not in verified
(out/'index.pck').write_bytes(data)
html=(src/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html);c=json.loads(m[1]);assert not c['args'];c['fileSizes']['index.pck']=len(data)
html=html[:m.start(1)]+json.dumps(c,separators=(',',':'))+html[m.end(1):]
# Retain the already-published LIVE loading rotation hotfix.
css='''
/* Keep the loader inside Safari's visible viewport during rotation/toolbars. */
#status {
 position: fixed;
 right: auto;
 bottom: auto;
 width: 100%;
 height: 100vh;
 height: 100dvh;
 overflow: hidden;
 z-index: 1;
}
#status-progress {
 bottom: max(10%, calc(env(safe-area-inset-bottom, 0px) + 12px));
}
'''
script='''
        <script>
// Only the loading overlay follows visualViewport; the game owns its canvas.
const disposeLoadingViewport = (() => {
 const overlay = document.getElementById('status');
 const viewport = window.visualViewport;
 let frame = 0;
 function sync() {
  frame = 0;
  const width = viewport ? viewport.width : window.innerWidth;
  const height = viewport ? viewport.height : window.innerHeight;
  if (width <= 0 || height <= 0) return;
  overlay.style.width = width + 'px';
  overlay.style.height = height + 'px';
  overlay.style.left = (viewport ? viewport.offsetLeft : 0) + 'px';
  overlay.style.top = (viewport ? viewport.offsetTop : 0) + 'px';
 }
 function schedule() { if (!frame) frame = requestAnimationFrame(sync); }
 window.addEventListener('resize', schedule);
 window.addEventListener('orientationchange', schedule);
 viewport?.addEventListener('resize', schedule);
 viewport?.addEventListener('scroll', schedule);
 sync();
 return () => {
  cancelAnimationFrame(frame);
  window.removeEventListener('resize', schedule);
  window.removeEventListener('orientationchange', schedule);
  viewport?.removeEventListener('resize', schedule);
  viewport?.removeEventListener('scroll', schedule);
 };
})();
        </script>
'''
assert html.count('\t\t</style>')==1
html=html.replace('\t\t</style>',css+'\t\t</style>')
marker='\t\t<script>\n// Opt-in diagnostics'
assert html.count(marker)==1
html=html.replace(marker,script+marker)
marker="if (mode === 'hidden') {\n\t\t\tstatusOverlay.remove();"
assert html.count(marker)==1
html=html.replace(marker,"if (mode === 'hidden') {\n\t\t\tdisposeLoadingViewport();\n\t\t\tstatusOverlay.remove();")
(out/'index.html').write_text(html)
manifest={n:identity(out/n) for n in expected};(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'build-receipt.json').write_text(json.dumps({'source':os.environ.get('GITHUB_SHA'),'baseline':expected,'files':manifest,'changed_resources':list(replacements),'removed_resources':sorted(removed),'changed_project_settings':changed,'unchanged_resources':len(verified)-len(replacements),'all_retained_payloads_verified':True,'physical_iphone_verified':False},indent=2))
if os.environ.get('RUNNER_TEMP'):
 evidence=Path(os.environ['RUNNER_TEMP'])/'evidence';evidence.mkdir(exist_ok=True)
 shutil.copyfile(out/'build-receipt.json',evidence/'build-receipt.json')
print('LIVE_PACKAGE_PARITY_VERIFIED')
