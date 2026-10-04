extends SceneTree
## Agent steering uses only on-screen exposed ore and public guidance.
## Uses the existing visible guide marker/arrow, never unmarked hidden ore or pathfinding.
var main: Node
var world: Node
var state: Node
var output: String
var seconds: float = 0.0
var samples: Array = []
var messages: Array = []
var last_position: Vector2
var stalled: float = 0.0
var escape_until: float = 0.0
var escape: Vector2 = Vector2.RIGHT
var next_sample: float = 0.0
var first_find: float = -1.0
var policy_target: String = ""
var target_seconds: float = 0.0
func _initialize() -> void: run.call_deferred()
func run() -> void:
 output=OS.get_environment("MODS_OUT")
 DirAccess.make_dir_recursive_absolute(output)
 await process_frame
 main=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(main)
 current_scene=main
 for i in 5: await process_frame
 state=root.get_node("RunState")
 state.initialize_persistence(output.path_join("isolated.sav"))
 state.reset_run(false)
 main._dev_ensure_playing()
 main._dev_seed_victory_state()
 main._dev_grant_max_tools_state()
 state.world_seed=77411
 state.endless_chunks={}
 state.cargo=state._empty_resource_store()
 state.treasury_totals={}
 state.treasury_goals={"pinned":"phasecrystal"}
 main._dev_jump_endless(1)
 world=main.endless_world
 # Deliberate real lifecycle: select a different goal after bands were loaded.
 state.treasury_goals={"pinned":"rootiron"}
 state.starforge_variant="crusher"
 for id in state.MinerSkills.IDS: state.miner_skills[id]=state.MinerSkills.threshold(id,25)
 state._miner_level_cache.clear()
 state._state_changed()
 main.quick_tutorial.dismiss()
 world.message_changed.connect(func(message: String): messages.append({"seconds":seconds,"message":message}))
 last_position=world.player.global_position
 while seconds<600.0:
  await process_frame
  var dt: float=minf(root.get_process_delta_time(),0.1)
  seconds+=dt
  var direction: Vector2=Vector2.DOWN
  var visible_rect: Rect2=world.get_viewport_rect()
  var transform: Transform2D=world.get_viewport().get_canvas_transform()
  var nearest: float=INF
  var target: Dictionary={}
  for ore in world.resources:
   if bool(ore.mined) or not bool(ore.get("revealed",false)): continue
   var point: Vector2=Vector2(ore.position)
   if not visible_rect.grow(-90).has_point(transform*point): continue
   var distance: float=world.player.global_position.distance_to(point)
   if distance<nearest:
    nearest=distance
    target=ore
  if not target.is_empty():
   var id: String=String(target.id)
   if policy_target==id: target_seconds+=dt
   else: policy_target=id;target_seconds=0.0
   if target_seconds<8.0: direction=(Vector2(target.position)-world.player.global_position).normalized()
  else:
   policy_target=""
   # Sweep while descending, with no map/hidden resource lookup.
   direction=Vector2(0.45 if int(seconds/12.0)%2==0 else -0.45,1).normalized()
  if world.player.global_position.distance_to(last_position)<0.5: stalled+=dt
  else: stalled=0.0
  if stalled>2.0:
   escape=Vector2.RIGHT if int(seconds/3.0)%2==0 else Vector2.LEFT
   escape_until=seconds+1.4
   stalled=0.0
  if main.guide_overlay.has_target and main.guide_overlay.visible:
   direction=(main.guide_overlay.target_world-world.player.global_position).normalized()
  if seconds<escape_until: direction=escape
  main.button_move=direction
  main._apply_button_movement()
  world.set_mine_held(true)
  last_position=world.player.global_position
  if int(state.cargo.rootiron)>0 and first_find<0.0: first_find=seconds
  if seconds>=next_sample:
   next_sample+=30.0
   await RenderingServer.frame_post_draw
   var file: String="hunt-%03d.png" % int(seconds)
   root.get_texture().get_image().save_png(output.path_join(file))
   samples.append({"seconds":seconds,"rootiron":state.cargo.rootiron,"stone":state.cargo.stone,"depth":state.endless_current_depth,"position":str(world.player.global_position),"hud":main._progression_goal(),"image":file})
   FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"method":"600 real frame seconds, agent follows publicly rendered guide marker and exposed on-screen ore; no unmarked hidden coordinates/pathfinding, no teleport after start; not human enjoyment/FPS","first_rootiron_seconds":first_find,"samples":samples,"messages":messages},"\t"))
   print("VISIBLE_HUNT "+str(int(seconds))+" rootiron="+str(state.cargo.rootiron)+" depth="+str(state.endless_current_depth))
 world.set_mine_held(false)
 main.button_move=Vector2.ZERO
 main._apply_button_movement()
 print("VISIBLE_HUNT_COMPLETE")
 quit(0)
