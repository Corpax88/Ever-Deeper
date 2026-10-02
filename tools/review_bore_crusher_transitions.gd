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
 world.player.global_position=world._cell_center(Vector2i(18,10))
 world.player.set_facing(Vector2.RIGHT);world.player.external_movement=Vector2.ZERO
 for i in 10:await process_frame
 var visual=world.player.visual._native_worn
 world.player.visual.set_process(false)
 world.set_mine_held(true);world.drill_modes.tick(1.0/60.0)
 for i in 10:
  world.player._physics_process(1.0/60.0)
  visual.advance(1.0/60.0)
  if i in [0,3,8]:await capture('entry-'+str(i))
 verify(visual.bore_weight==1.0,'entry-reaches-bore')
 world.set_mine_held(false)
 for i in 14:
  visual.advance(1.0/60.0)
  if i in [0,3,8,13]:await capture('exit-'+str(i))
 verify(visual.bore_weight==0.0 and visual.bore_spin==0.0 and visual.equipment.bore_original.visible,'settles-original')
 world.set_mine_held(true);world.drill_modes.tick(1.0/60.0)
 for i in 10:visual.advance(1.0/60.0)
 state.set_endless_tool_style('comet')
 world.player.visual.set_process(true)
 for i in 20:
  world.player._physics_process(1.0/60.0)
  await process_frame
 verify(visual.equipment.current=='comet' and visual.bore_weight==0.0,'switch-comet-clears-overlay',visual.snapshot())
 await capture('comet-during-rush')
 state.set_endless_tool_style('crusher')
 for i in 20:
  world.player._physics_process(1.0/60.0)
  await process_frame
 verify(visual.equipment.current=='crusher' and visual.bore_weight==1.0,'switch-back-restores-bore',visual.snapshot())
 await capture('crusher-return')
 world.set_mine_held(false);world.drill_modes.dev_override='laser';world.set_mine_held(true);world.drill_modes.tick(1.0/60.0)
 for i in 12:await process_frame
 verify(visual.bore_weight==0.0 and not world.player.drill_motion_override,'laser-does-not-use-bore',visual.snapshot())
 await capture('crusher-laser')
 for row in checks:
  if not row.passed:quit(1);return
 await process_frame
 print('BORE_TRANSITIONS_PASSED')
 quit(0)
