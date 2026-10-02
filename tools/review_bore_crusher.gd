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
 for k in 8:
  world.set_mine_held(false)
  var direction=Vector2.RIGHT.rotated(k*TAU/8)
  world.player.global_position=world._cell_center(Vector2i(18,10))
  world.player.external_movement=direction;world.player.set_facing(direction)
  for i in 12:
   world.player._physics_process(1.0/60.0)
   await process_frame
  await capture('normal-'+str(k))
  world.set_mine_held(true)
  var start=world.player.global_position
  for i in 32:
   world.drill_modes.tick(1.0/60.0);world.player._physics_process(1.0/60.0)
   await process_frame
  var visual=world.player.visual._native_worn
  verify(not visual.failed and visual.rig!=null and visual.equipment.current=='crusher','native-valid-'+str(k),visual.snapshot())
  verify(world.player.global_position.distance_to(start)>20,'rush-travel-'+str(k))
  var unchanged_feet: bool=true
  for side in ['R','L']:
   unchanged_feet=unchanged_feet and visual.rig.shown['foot.'+side].is_equal_approx(visual.motion.shown.bones['foot.'+side])
  verify(unchanged_feet,'authored-feet-retained-'+str(k))
  var grips: bool=true
  for side in ['R','L']:
   var expected: Transform3D=visual.motion.bank.idle[0].bones.tool.affine_inverse()*visual.motion.bank.idle[0].bones['hand.'+side]
   var actual: Transform3D=visual.rig.shown.tool.affine_inverse()*visual.rig.shown['hand.'+side]
   grips=grips and expected.origin.distance_to(actual.origin)<0.0001
  verify(grips,'two-rigid-grips-'+str(k))
  for frame in 4:
   for i in 5:
    world.drill_modes.tick(1.0/60.0);world.player._physics_process(1.0/60.0)
    await process_frame
   await capture('bore-'+str(k)+'-'+str(frame))
  if visual.equipment.get('bore_triangles')!=null:verify(visual.equipment.bore_triangles.x>0 and visual.equipment.bore_triangles.y>0,'mesh-partition-'+str(k),{'triangles':str(visual.equipment.bore_triangles)})
  world.set_mine_held(false);world.player.external_movement=Vector2.ZERO
  for i in 20:
   world.player._physics_process(1.0/60.0)
   await process_frame
  verify(not world.player.drill_motion_override,'released-'+str(k))
  verify(visual.bore_weight==0.0 and visual.equipment.bore_original.visible,'restored-original-'+str(k))
  await capture('released-'+str(k))
 for row in checks:
  if not row.passed:quit(1);return
 await process_frame
 print('BORE_CRUSHER_REVIEW_PASSED')
 quit(0)
