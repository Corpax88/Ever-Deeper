extends SceneTree
var main: Node
var world: Node
var state: Node
var output: String
var checks: Array=[]
func _initialize(): run.call_deferred()
func verify(ok: bool,label: String,details: Dictionary={}):
 checks.append({'name':label,'passed':ok,'details':details})
 FileAccess.open(output.path_join('checks.json'),FileAccess.WRITE).store_string(JSON.stringify(checks,'\t'))
func capture(label: String):
 world.player.camera.reset_smoothing()
 for i in 3: await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output.path_join(label+'.png'))
func run():
 output=OS.get_environment('MODS_OUT');DirAccess.make_dir_recursive_absolute(output)
 await process_frame
 main=load('res://scenes/main/main.tscn').instantiate();root.add_child(main);current_scene=main
 for i in 5: await process_frame
 state=root.get_node('RunState');state.initialize_persistence(output.path_join('save.json'));state.reset_run(false)
 main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_jump_endless(1);main._dev_grant_max_tools_state()
 world=main.endless_world;world.resonance_drill.set_enabled(false)
 main._dev_build_all_workshops_state()
 state.endless_workshops['tool_forge'].level=5
 state.set_endless_tool_style('crusher')
 main._dev_jump_endless(1)
 world.player.prepare_visual_cache()
 world.drill_modes.dev_override='bore_rush'
 main.achievement_toast.hide()
 var mole=main.get_node('CompanionInterface').active_mole();mole.autonomous_enabled=false;mole.recall()
 world.set_process(false);world.player.set_physics_process(false)
 world._ground_props.clear();world.discovery_sites.clear()
 for y in range(3,19):
  for x in range(8,31):world._set_floor(Vector2i(x,y),true)
 for y in range(3,18):
  for x in range(8,29):world._set_floor(Vector2i(x,y),false)
 for y in range(9,12):
  for x in range(17,20):world._set_floor(Vector2i(x,y),true)
 world.player.global_position=world._cell_center(Vector2i(18,10))+Vector2(0,24)
 world.player.set_facing(Vector2.RIGHT);world.player.external_movement=Vector2.ZERO
 for i in 10:await process_frame
 var visual=world.player.visual._native_worn
 world.player.visual.set_process(false)
 var before=world.drill_modes.impacts
 var valid: bool=true
 world.set_mine_held(true)
 for i in 240:
  world.drill_modes.tick(1.0/60.0);world.player._physics_process(1.0/60.0)
  valid=visual.advance(1.0/60.0) and valid
  if visual.failed:break
  if i%20==0:await process_frame
 verify(valid and not visual.failed,'held-mining-keeps-rigid-bore',visual.snapshot())
 verify(world.drill_modes.impacts>before+5,'real-terrain-impacts',{'impacts':world.drill_modes.impacts-before})
 await capture('crusher-mining-rock')
 # Explicitly feed an ordinary impact on an exposed ore in front of the rig.
 # This uses the real presentation serial that previously broke the braced pose.
 for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
  if visual.failed:break
  world.player.set_facing(direction)
  world.player.animation_bearing=direction
  world.player.animation_active=true
  world.player.animation_target_valid=true
  world.player.animation_target_position=world.player.global_position+direction*70
  world.player.animation_impact_target_valid=true
  world.player.animation_impact_target=world.player.animation_target_position
  world.player._mining_impact_serial+=1
  world.player.animation_swing_serial+=1
  for i in 12:valid=visual.advance(1.0/60.0) and valid
  verify(valid and not visual.failed,'impact-presentation-'+str(direction),visual.snapshot())
  if not visual.failed:await capture('impact-'+str(int(direction.angle()*100)))
 for row in checks:
  if not row.passed:quit(1);return
 await process_frame
 print('BORE_IMPACTS_PASSED')
 quit(0)
