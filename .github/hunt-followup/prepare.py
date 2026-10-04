"""Scoped source/QA overlays over the immutable published DEV15.56 package.

Production source in this checkout is intentionally ignored for the baseline.
Explicit future candidate overrides can be supplied as a JSON path list.
"""
from pathlib import Path
import hashlib,json,os,re,shutil,struct,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.github/five-mods'))
from pack_helpers import unpack,identity
BASE={'size':327914622,'sha256':'8de6ebae373816a37159327218f90cb9cb0419eae91eb9d833cba0810e0ac5de'}
BASE_SOURCE='deaa7088d75d473b0c16951bc05f19c4db7800c4'
BASE_VERSION='1.0.0-dev.15.56'
WEB=['index.html','index.js','index.wasm','index.pck','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js']
src,out=map(Path,sys.argv[1:3])
assert identity(src/'index.pck')==BASE,'Wrong published baseline'
before=json.loads((ROOT/'.github/hunt-followup/public-before.json').read_text())
for name in WEB:
    assert identity(src/name)==before['dev/'+name],'Wrong baseline distribution file: '+name
out.mkdir(parents=True,exist_ok=True)
for name in WEB: shutil.copyfile(src/name,out/name)
original=(src/'index.pck').read_bytes();base,entries=unpack(original)
def raw(name):
    o,s,*_=entries[name];return original[base+o:base+o+s]
def script(name):
    mapping=name+'.remap'
    if mapping in entries:
        target=re.search(r'path="res://([^\"]+)"',raw(mapping).decode())[1]
        return raw(target)
    return raw(name)
replacements={}
overrides=json.loads(Path(sys.argv[3]).read_text()) if len(sys.argv)>3 else []
production=len(sys.argv)>4 and sys.argv[4]=='production'
version=os.environ.get('CANDIDATE_VERSION','1.0.0-dev.15.57')
assert isinstance(overrides,list) and len(overrides)==len(set(overrides)),'Duplicate/non-list overrides'
if overrides:
    assert 'scripts/ui/premium_menu.gd' in overrides,'Candidate requires an explicit version owner'
for name in overrides:
    assert name.startswith(('scripts/','shaders/')) and not name.startswith('scripts/qa/') and '..' not in Path(name).parts,name
    replacements[name]=(ROOT/name).read_bytes()
    if name=='scripts/ui/premium_menu.gd':
        source=replacements[name].decode()
        source,count=re.subn(r'(const DEV_RELEASE_VERSION: = )"[^"]+"',lambda m:m[1]+json.dumps(version),source)
        assert count==1,'Version owner changed'
        replacements[name]=source.encode()
    if name.endswith('.gd'): replacements[name+'.remap']=('[remap]\npath="res://'+name+'"\n').encode()
# Extend exact baseline QA suite without importing unrelated source drift.
if not production:
    replacements['scripts/qa/suites/full_quality_base.gd']=script('scripts/qa/suites/skills_browser_review.gd')
    replacements['scripts/qa/suites/skills_browser_review.gd']=(ROOT/'.github/hunt-followup/fixture.gd').read_bytes()
    replacements['scripts/qa/suites/skills_browser_review.gd.remap']=b'[remap]\npath="res://scripts/qa/suites/skills_browser_review.gd"\n'
    # The inherited visual review clears notices every frame. Keep that
    # default, with a virtual opt-out used only by deliberate notice commands.
    name='scripts/qa/suites/dev14_review.gd'
    source=script(name).decode()
    old='\tif main.achievement_toast != null: main.achievement_toast.clear()'
    assert source.count(old)==1,'Inherited visual notice suppression changed'
    source=source.replace(old,'\tif _review_clear_toasts() and main.achievement_toast != null: main.achievement_toast.clear()')
    source+='\nfunc _review_clear_toasts() -> bool:\n\treturn true\n'
    replacements[name]=source.encode()
    replacements[name+'.remap']=('[remap]\npath="res://'+name+'"\n').encode()
    if 'scripts/state/treasury_goals.gd' in overrides:
        # Retain the existing premium suite; update only its two assertions
        # that intentionally required a completed mod to obscure future goals.
        name='scripts/qa/suites/premium_core.gd'
        source=script(name).decode()
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
    # The retained world fixture predates buried-ore shielding. Excavate its
    # generated target using real wall damage before testing ore/claim integrity.
    # Keep every original assertion; apply this fixture repair to baseline too.
    name='scripts/qa/suites/one_point_zero_world.gd'
    assert hashlib.sha256(script(name)).hexdigest()=='3c2a9cf8e8d405769634d47714ac34f965af35bf425d1ed403c1ed36da017bf6','Published world fixture changed'
    source_bytes=(ROOT/name).read_bytes()
    assert hashlib.sha256(source_bytes).hexdigest()=='5874695159de50ae7598d4edae81ad3f8029f96be1e0985df53673af75e96fe3','Canonical published world fixture source changed'
    source=source_bytes.decode()
    old='\tvar target_id: String = String(resource.id)\n\tfor _hit in 80:'
    new='''\tvar target_id: String = String(resource.id)
\tvar target_cell: Vector2i = Vector2i(resource.cell)
\tfor _wall_hit in 520:
\t\tif world._is_floor(target_cell):
\t\t\tbreak
\t\tworld._strike_wall(target_cell, 1.0)
\tif not _check(world._is_floor(target_cell), "Real terrain damage exposes generated deposit"):
\t\treturn false
\tfor _hit in 80:'''
    assert source.count(old)==1,'World claim integrity fixture owner changed'
    source=source.replace(old,new)
    old='\tvar site_index: int = int(site.index)\n\tvar result: Dictionary = world.qa_complete_site_activity(site_index, "overload")'
    new='''\tvar site_index: int = int(site.index)
\tvar site_points: Array = [Vector2(site.position) + Vector2(world.SITE_PAD_OFFSET, 36.0)]
\tsite_points.append_array(site.rune_positions)
\tfor point in site_points:
\t\tvar cell: Vector2i = world._world_to_cell(Vector2(point))
\t\tfor _wall_hit in 520:
\t\t\tif world._is_floor(cell):
\t\t\t\tbreak
\t\t\tworld._strike_wall(cell, 1.0)
\t\tif not _check(world._is_floor(cell), "Real terrain damage exposes cache approach and runes"):
\t\t\treturn false
\tvar result: Dictionary = world.qa_complete_site_activity(site_index, "overload")'''
    assert source.count(old)==1,'World cache approach fixture owner changed'
    source=source.replace(old,new)
    old='\tvar position: Vector2 = Vector2(site.position)\n\tworld.player.global_position = position + Vector2(128, 0)'
    new='''\tvar position: Vector2 = Vector2(site.position)
\tvar site_cell: Vector2i = world._world_to_cell(position)
\tfor _wall_hit in 520:
\t\tif world._is_floor(site_cell):
\t\t\tbreak
\t\tworld._strike_wall(site_cell, 1.0)
\t_check(world._is_floor(site_cell), "Guidance fixture exposes cache through actual terrain damage")
\tsaved_cells = world.floor_cells.duplicate()
\tworld.player.global_position = position + Vector2(128, 0)'''
    assert source.count(old)==1,'World guidance fixture owner changed'
    source=source.replace(old,new)
    old='\tworld.restore_position(Vector2(world.native_relic_position))\n\tworld._update_discoveries()'
    new='''\tvar relic_cell: Vector2i = world._world_to_cell(Vector2(world.native_relic_position))
\tfor dx in range(-1, 2):
\t\tfor dy in range(-1, 2):
\t\t\tvar cell: Vector2i = relic_cell + Vector2i(dx, dy)
\t\t\tfor _wall_hit in 520:
\t\t\t\tif world._is_floor(cell):
\t\t\t\t\tbreak
\t\t\t\tworld._strike_wall(cell, 1.0)
\t_check(world._is_floor(relic_cell), "Generated relic is exposed by actual terrain damage")
\tworld.restore_position(Vector2(world.native_relic_position))
\tworld._update_discoveries()'''
    assert source.count(old)==1,'World relic fixture owner changed'
    replacements[name]=source.replace(old,new).encode()
    replacements[name+'.remap']=('[remap]\npath="res://'+name+'"\n').encode()
data=bytearray(original[:base]);after={}
for name in sorted(set(entries)|set(replacements)):
    payload=replacements[name] if name in replacements else raw(name)
    data+=b'\0'*(-len(data)%32)
    after[name]=(len(data)-base,len(payload),hashlib.md5(payload).digest(),0)
    data+=payload
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(after))
for name,(o,s,d,f) in after.items():
    key=name.encode();key+=b'\0'*(-len(key)%4)
    data+=struct.pack('<I',len(key))+key+struct.pack('<QQ16sI',o,s,d,f)
newbase,verified=unpack(data)
for n,(o,s,*_) in verified.items():
    assert bytes(data[newbase+o:newbase+o+s])==(replacements[n] if n in replacements else raw(n)),n
# Verify the disk bytes, too; an in-memory pack check cannot detect a truncated
# output file. Atomic replacement never exposes a half-written candidate pack.
temporary=out/'index.pck.tmp'
with temporary.open('wb') as stream:
    stream.write(data);stream.flush();os.fsync(stream.fileno())
os.replace(temporary,out/'index.pck')
assert identity(out/'index.pck')=={'size':len(data),'sha256':hashlib.sha256(data).hexdigest()},'Written PCK changed'
html=(src/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html)
config=json.loads(m[1]);assert not config['args']
config['fileSizes']['index.pck']=len(data)
(out/'index.html').write_text(html[:m.start(1)]+json.dumps(config,separators=(',',':'))+html[m.end(1):])
manifest={name:identity(out/name) for name in WEB}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
(out/'qa-build-receipt.json').write_text(json.dumps({'baseline_pck':BASE,'baseline_source':BASE_SOURCE,'qa_source':os.environ.get('GITHUB_SHA'),'overrides':overrides,'production':production,'version':version if 'scripts/ui/premium_menu.gd' in overrides else BASE_VERSION,'replaced':list(replacements),'retained_payloads_verified':True,'files':manifest},indent=2))
print('QUALITY2_QA_PACKAGE_VERIFIED',manifest['index.pck'])
