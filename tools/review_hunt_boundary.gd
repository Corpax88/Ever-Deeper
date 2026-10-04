extends SceneTree
var main: Node
var state: Node
var world: Node
var output: String
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func check(name: String, ok: bool) -> void:
 checks.append({"name":name,"passed":ok})
 FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
 if not ok:print("HUNT_BOUNDARY_MISMATCH "+name)
func run() -> void:
 output=OS.get_environment("MODS_OUT");DirAccess.make_dir_recursive_absolute(output)
 await process_frame
 main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
 for i in 5:await process_frame
 state=root.get_node("RunState");state.initialize_persistence(output.path_join("isolated.sav"));state.reset_run(false)
 main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_grant_max_tools_state()
 state.world_seed=77411;state.endless_chunks={};state.endless_stream_anchor={};state.treasury_goals={"pinned":"phasecrystal"};state.cargo=state._empty_resource_store()
 main._dev_jump_endless(1);world=main.endless_world
 world.set_process(false);world.set_physics_process(false);world.player.set_physics_process(false)
 var old: Dictionary=state.endless_chunks.duplicate(true)
 state.treasury_goals={"pinned":"rootiron"}
 var target: Vector2=world.guide_target("rootiron")
 check("fallback crosses current band, not obsolete final-row shaft",world.depth_at_position(target)>world.current_depth)
 check("fallback is inside active streamed region",world._world_to_cell(target).y<world.GRID_SIZE.y)
 if world.has_method("treasury_hunt_action"):
  check("old/preloaded band explains new ground",world.treasury_hunt_action("rootiron")=="New ground · keep descending")
  check("ordinary Deep materials retain ordinary guidance",world.treasury_hunt_action("memory_silk")=="Mine · The Deep")
 else:check("contextual hunt guidance exists",false)
 check("pin and guidance do not rewrite old deposits",state.endless_chunks==old)
 var saved: Dictionary=state.serialize()
 check("goal-switch save reload succeeds",state.deserialize(saved))
 check("reload retains old deposit identities",state.endless_chunks==old)
 for depth in [2,3,4]:
  state.endless_current_depth=depth;world.current_depth=depth;world._generate_stream_window(maxi(1,depth-1))
  var next: Vector2=world.guide_target("rootiron")
  var found: bool=false
  for ore in world.resources:
   if not bool(ore.mined) and String(ore.kind)=="rootiron":found=true
  if not found:check("missing ore guides through next band "+str(depth),world.depth_at_position(next)>depth)
  elif world.has_method("treasury_hunt_action"):
   check("actual new band describes its real vein",world.treasury_hunt_action("rootiron")=="Rich vein · follow the marker")
   check("available vein remains actual target",world.resources.any(func(ore):return not bool(ore.mined) and String(ore.kind)=="rootiron" and Vector2(ore.position)==next))
 # Mixed ordinary/rich resources must label the same nearest target as the arrow.
 world.resources.clear()
 world.resources.append({"kind":"deep_alloy","position":world.player.global_position+Vector2(200,0),"mined":false,"treasury_seam":false})
 world.resources.append({"kind":"deep_alloy","position":world.player.global_position+Vector2(100,0),"mined":false,"treasury_seam":true})
 check("mixed ore label matches nearest rich target",world.treasury_hunt_action("deep_alloy")=="Rich vein · follow the marker")
 world.resources[1].mined=true
 check("mined rich target gives way to ordinary target",world.treasury_hunt_action("deep_alloy")=="Ore · follow the marker")
 for row in checks:
  if not row.passed:quit(1);return
 print("HUNT_BOUNDARY_OK "+str(checks.size()));quit(0)
