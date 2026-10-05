"""Overlay explicit source on verified DEV15.57; retain every other resource byte."""
import hashlib,json,os,re,struct,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.github/five-mods'))
from pack_helpers import unpack,identity
src,out=map(Path,sys.argv[1:3]);out.mkdir(parents=True,exist_ok=True)
mode=sys.argv[3] if len(sys.argv)>3 else 'production'
qa=mode in ('qa','baseline')
original=src.read_bytes()
assert hashlib.sha256(original).hexdigest()=='5a97a3346dfb623d36b80bfb4b37feb8651ca48b60b6a91430a4202a103d7c79'
base,entries=unpack(original)
overrides=[] if mode=='baseline' else json.loads((ROOT/'.github/visual-guidance/overrides.json').read_text())
replacements={}
for name in overrides:
 replacements[name]=(ROOT/name).read_bytes()
 replacements[name+'.remap']=('[remap]\npath="res://'+name+'"\n').encode()
def raw(n):
 o,s,*_=entries[n];return original[base+o:base+o+s]
def script(name):
 mapping=name+'.remap'
 if mapping in entries:
  target=re.search(r'path="res://([^\"]+)"',raw(mapping).decode())[1]
  return raw(target)
 return raw(name)
# Extend exact baseline QA suite without importing unrelated source drift.
if qa:
    replacements['scripts/qa/suites/full_quality_base.gd']=script('scripts/qa/suites/skills_browser_review.gd')
    replacements['scripts/qa/suites/guidance_quality_base.gd']=(ROOT/'.github/hunt-followup/fixture.gd').read_bytes()
    replacements['scripts/qa/suites/skills_browser_review.gd']=(ROOT/'.github/visual-guidance/fixture.gd').read_bytes()
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
    if True: # Current published gameplay already retires completed goals.
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
 payload=replacements.get(name,raw(name) if name in entries else b'')
 data+=b'\0'*(-len(data)%32);after[name]=(len(data)-base,len(payload),hashlib.md5(payload).digest(),0);data+=payload
struct.pack_into('<Q',data,32,len(data));data+=struct.pack('<I',len(after))
for name,(o,s,d,f) in after.items():
 key=name.encode();key+=b'\0'*(-len(key)%4);data+=struct.pack('<I',len(key))+key+struct.pack('<QQ16sI',o,s,d,f)
b,e=unpack(data)
for n,(o,s,*_) in e.items(): assert data[b+o:b+o+s]==replacements.get(n,raw(n) if n in entries else b'')
p=out/'index.pck';p.write_bytes(data)
assert identity(p)=={'size':len(data),'sha256':hashlib.sha256(data).hexdigest()}
(out/'receipt.json').write_text(json.dumps({'baseline_sha256':hashlib.sha256(original).hexdigest(),'overrides':overrides,'retained_verified':True,'pck':identity(p)},indent=2))
# Web shell and engine bytes are copied unchanged from the same immutable artifact.
web=['index.html','index.js','index.wasm','index.pck','index.png','index.icon.png','index.apple-touch-icon.png','index.audio.worklet.js','index.audio.position.worklet.js']
import shutil
if (src.parent/'index.html').exists():
 for n in web:
  if n!='index.pck': shutil.copyfile(src.parent/n,out/n)
 html=(out/'index.html').read_text();m=re.search(r'const GODOT_CONFIG = (\{[^\r\n]+\});',html)
 cfg=json.loads(m[1]);assert not cfg['args'];cfg['fileSizes']['index.pck']=len(data)
 (out/'index.html').write_text(html[:m.start(1)]+json.dumps(cfg,separators=(',',':'))+html[m.end(1):])
 manifest={n:identity(out/n) for n in web}
 (out/'manifest.json').write_text(json.dumps(manifest,indent=2))
 (out/'qa-build-receipt.json').write_text(json.dumps({'baseline_pck':identity(src),'baseline_source':'b8b7e0428c9aa2626861917f98b1b4b7d296f9e3','qa_source':os.environ.get('GITHUB_SHA'),'overrides':overrides,'production':not qa,'version':'1.0.0-dev.15.57' if mode=='baseline' else '1.0.0-dev.15.58','replaced':list(replacements),'retained_payloads_verified':True,'files':manifest},indent=2))
print(identity(p))
