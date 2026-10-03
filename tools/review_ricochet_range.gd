extends SceneTree
var main: Node
var world: Node
var state: Node
var five: Node
var output: String
var checks: Array=[]
var render: bool=false
func _initialize(): run.call_deferred()
func check(label: String, passed: bool, details: Dictionary={}):
 checks.append({"name":label,"passed":passed,"details":details})
 FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
 if not passed: print("RICOCHET_MISMATCH "+label)
func fresh():
 five.reset();five.hit_log.clear();five.hits=0;world.resources.clear();world.dig_damage.clear();world._clear_loose_drop_visuals()
 world.drill_modes.dev_override="ricochet";five.mode="ricochet"
 world.player.global_position=world._cell_center(Vector2i(18,12));world.player.set_facing(Vector2.RIGHT);five.direction=Vector2.RIGHT
 for y in range(1,32):
  for x in range(1,39):world._set_floor(Vector2i(x,y),true)
 world.player.camera.reset_smoothing();world.player.camera.force_update_scroll()
func capture(label: String):
 if not render:return
 world.queue_redraw();world._update_buried_visibility()
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_jpg(output.path_join(label+".jpg"),0.95)
func run():
 output=OS.get_environment("MODS_OUT");DirAccess.make_dir_recursive_absolute(output)
 render=OS.get_environment("RIC_RENDER")=="1"
 await process_frame
 main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
 for i in 5:await process_frame
 state=root.get_node("RunState");state.initialize_persistence(output.path_join("save.json"));state.reset_run(false)
 main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_grant_max_tools_state();main._dev_build_all_workshops_state();main._dev_jump_endless(1)
 world=main.endless_world;five=world.drill_modes.five
 world.set_process(false);world.player.set_physics_process(false);world.resonance_drill.dev_override=false;world.resonance_drill.set_enabled(false)
 var mole: Node=main.get_node("CompanionInterface").active_mole();mole.autonomous_enabled=false;mole.recall()
 world._ground_props.clear();world.discovery_sites.clear();main.achievement_toast.hide()
 state.endless_workshops.tool_forge.level=5
 if OS.get_environment("RIC_ONLY_SKIN")!="1":
  # Exercise target acquisition at twice the previous reach, in eight bearings.
  for bearing in 8:
   fresh()
   var direction: Vector2=Vector2.RIGHT.rotated(float(bearing)*TAU/8.0)
   var cell: Vector2i=world._world_to_cell(world.player.global_position+direction*470.0)
   world._set_floor(cell,false);world.dig_damage[cell]=519
   five.direction=direction
   var target: Dictionary=five._target(512.0)
   check("long-target-bearing-"+str(bearing),target.has("cell") and Vector2i(target.cell)==cell)
   world.set_mine_held(true);world.player.external_movement=direction
   for i in 25:five.tick(0.05,"ricochet",true)
   check("actual-tick-long-hit-"+str(bearing),world._is_floor(cell) and five.hits>0)
   world.set_mine_held(false);world.player.external_movement=Vector2.ZERO
  fresh()
  var cells: Array[Vector2i]=[Vector2i(25,12),Vector2i(25,7),Vector2i(20,7)]
  for cell in cells:world._set_floor(cell,false);world.dig_damage[cell]=519
  var buried: Dictionary={"id":"ricochet-hidden","cell":cells[1],"position":world._cell_center(cells[1]),"hp":1022,"max_hp":1022,"mined":false,"kind":"rootiron","amount":1,"depth":1,"node_index":0}
  world.resources.append(buried);world._build_resource_visual(buried)
  five._impact({"cell":cells[0]},0.08)
  await capture("range-start")
  var longest: float=0.0
  for i in 150:
   if not five.projectile.is_empty():longest=maxf(longest,float(five.projectile.age))
   five._update_projectile(0.01)
   if i in [25,40,60,80,100]:await capture("range-"+str(i))
  check("three-long-range-contacts",five.hits==3 and five.projectile.is_empty(),{"hits":five.hits,"duration":longest})
  check("flight-survives-old-lifetime",longest>0.8)
  check("long-bounces-break-three-rocks",world._is_floor(cells[0]) and world._is_floor(cells[1]) and world._is_floor(cells[2]))
  check("long-bounces-only-reveal-buried-ore",int(world.resources[0].hp)==1022)
  fresh();var far: Vector2i=Vector2i(27,12);world._set_floor(far,false)
  check("range-remains-bounded",five._target(512.0).is_empty())
  fresh();world._set_floor(Vector2i(25,12),false);five._launch(Vector2i(25,12));five.held_last=true;five.tick(0.016,"ricochet",false)
  check("release-cancels-long-flight",five.projectile.is_empty() and five.hits==0)
 # Workshop-selected native gear must not wait for asynchronous sprite atlases.
 fresh();world.drill_modes.dev_override="";state.treasury_goals.clear();world.player.visual.set_process(false)
 var visual: Node=world.player.visual
 var native: Node=visual._native_worn
 if native != null:
  for row in [["crusher","crusher"],["comet","comet"],["crownseeker","crown"],["deepheart","ember"]]:
   check("workshop-selection-"+row[0],state.set_endless_tool_style(row[0]))
   visual._refresh_equipment()
   native.advance(0.016)
   check("same-frame-native-skin-"+row[0],not native.failed and (native.equipment.current if native.equipment != null else "fallback")==row[1],{"wanted":visual._wanted_gear,"atlas":visual.active_gear,"shown":native.equipment.current if native.equipment != null else "fallback"})
   visual._sprite.visible=false
   await capture("skin-"+row[0])
   world.drill_modes.dev_override="ricochet";native.advance(0.016)
   check("ricochet-does-not-change-saved-skin-"+row[0],state.endless_tool_style==row[0] and native.mod_active)
   world.drill_modes.dev_override="";native.advance(0.016)
   check("skin-restored-on-first-mod-off-frame-"+row[0],(native.equipment.current if native.equipment != null else "fallback")==row[1] and not native.mod_active)
   await capture("restored-"+row[0])
  visual.set_process(true)
  check("skin-saves",state.save_game(output.path_join("skin-save.json")))
  check("skin-reloads",state.load_game(output.path_join("skin-save.json")) and state.endless_tool_style=="deepheart")
 else: print("SKIN_CHECKS_REQUIRE_GRAPHICS")

 for row in checks:
  if not row.passed:await process_frame;quit(1);return
 await process_frame
 print("RICOCHET_RANGE_OK "+str(checks.size()));quit(0)
