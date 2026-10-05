extends SceneTree
var main: Node
var world: Node
var state: Node
var output: String
var samples: Array=[]
func _initialize(): run.call_deferred()
func capture(name: String):
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_jpg(output.path_join(name+".jpg"),0.94)
func run():
 output=OS.get_environment("MODS_OUT");DirAccess.make_dir_recursive_absolute(output)
 await process_frame
 main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
 for i in 5:await process_frame
 state=root.get_node("RunState");state.initialize_persistence(output.path_join("isolated.sav"));state.reset_run(false)
 main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_grant_max_tools_state();main._dev_build_all_workshops_state();main._dev_jump_endless(2)
 world=main.endless_world
 state.endless_workshops.tool_forge.level=5;state.set_endless_tool_style("comet")
 main._on_developer_command_requested("test_ricochet")
 state.set_movement_speed_level(20);main._apply_global_movement_speed()
 var mole: Node=main.get_node("CompanionInterface").active_mole();mole.autonomous_enabled=false;mole.recall()
 world._ground_props.clear();world.discovery_sites.clear();world.resources.clear()
 var start: Vector2=Vector2(1200,world.CHUNK_HEIGHT*2-100)
 for y in range(35,65):
  for x in range(15,25):
   var cell: Vector2i=Vector2i(x,y)
   if world._cell_diggable(cell):
    world._set_floor(cell,true);state.mark_endless_dug(world.depth_at_position(world._cell_center(cell)),world._chunk_cell_index(cell))
 world.player.release_visual_cache();world.player.global_position=start;world.player.prepare_visual_cache()
 world.player.camera.reset_smoothing();main.quick_tutorial.dismiss();main.achievement_toast.hide()
 for i in 8:await process_frame
 await capture("before-boundary")
 var shifts: int=world.origin_shift_count
 for i in 240:
  main.button_move=Vector2(0.15*sin(i*0.37),1).normalized();main._apply_button_movement();world.set_mine_held(true)
  await process_frame
  var snap: Dictionary=world.player.visual.native_worn_snapshot()
  samples.append({"frame":i,"position":str(world.player.global_position),"shifts":world.origin_shift_count,"selected":world.drill_modes.selected(),"native":snap})
  if snap.failed or not snap.mod_active:
   await capture("failure");break
  if world.origin_shift_count>shifts and i>60:
   await capture("after-boundary");break
 main._on_joystick_movement(Vector2.ZERO);world.set_mine_held(false)
 FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"samples":samples,"crossed":world.origin_shift_count>shifts},"\t"))
 print("MOD_BOUNDARY_DONE "+str(world.player.visual.native_worn_snapshot()));quit(0)
