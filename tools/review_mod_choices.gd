extends SceneTree
## Same equipment, seed, scene and inputs. Synthetic layouts isolate mod niches.
var main: Node
var world: Node
var state: Node
var output: String
var results: Array=[]
func _initialize() -> void: run.call_deferred()
func run() -> void:
 output=OS.get_environment("MODS_OUT")
 DirAccess.make_dir_recursive_absolute(output)
 await process_frame
 main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
 for i in 5: await process_frame
 state=root.get_node("RunState");state.initialize_persistence(output.path_join("isolated.sav"));state.reset_run(false)
 main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_grant_max_tools_state();main._dev_jump_endless(1)
 world=main.endless_world
 world.set_process(false);world.set_physics_process(false);world.player.set_physics_process(false)
 var training: Node=main.get_node("MinerTraining")
 training.set_process(false);training.set_physics_process(false)
 var mole: Node=main.get_node("CompanionInterface").active_mole()
 mole.autonomous_enabled=false;mole.recall();mole.set_process(false);mole.set_physics_process(false)
 main.quick_tutorial.dismiss()
 for layout in ["dense_rock","exposed_nodes","buried_vein"]:
  for mode in ["","corebreaker","chainbreaker"]:
   world.drill_modes.reset();world.resonance_drill.set_enabled(false)
   state.deep_events={};state.world_seed=77411;state.endless_chunks={};state.endless_stream_anchor={};state.endless_current_depth=1
   state.cargo=state._empty_resource_store();state.treasury_goals={}
   if not mode.is_empty():state.treasury_goals[mode+"_claimed"]=true;state.treasury_goals[mode+"_enabled"]=true
   world.current_depth=1;world.session_mined_nodes.clear();world.resources.clear()
   world._generate_stream_window(1)
   world._ground_props.clear();world.discovery_sites.clear()
   world.drill_modes.dev_override=""
   state.starforge_variant="crusher"
   state.endless_relics.forge_heart={"discovered":true,"collected":true,"placed":true,"found_depth":1};state.endless_workshops.tool_forge.built=true;state.endless_workshops.tool_forge.level=5
   for id in state.MinerSkills.IDS:state.miner_skills[id]=state.MinerSkills.threshold(id,25)
   state._miner_level_cache.clear();state.miner_skills.stamina=100.0
   var start_cell: Vector2i=Vector2i(8,12)
   if layout!="dense_rock":start_cell=Vector2i(world.resources[0].cell)-Vector2i(1,0)
   for y in world.GRID_SIZE.y:
    for x in range(2,38):world._set_floor(Vector2i(x,y),layout!="dense_rock")
   for y in range(start_cell.y-1,start_cell.y+2):
    for x in range(start_cell.x-1,start_cell.x+1):world._set_floor(Vector2i(x,y),true)
   if layout=="buried_vein":world._set_floor(Vector2i(world.resources[0].cell),false)
   world.player.global_position=world._cell_center(start_cell)
   world.player.external_movement=Vector2.RIGHT if layout=="dense_rock" else Vector2.ZERO
   world.player._actual_moving=false
   world.player.set_facing(Vector2.RIGHT);world.player.animation_bearing=Vector2.RIGHT
   world._update_buried_visibility()
   var initial_tool: Dictionary=world._current_endless_tool()
   var before_floor: int=world.floor_cells.count(1)
   var start: Vector2=world.player.global_position
   world.set_mine_held(true)
   main.set_process(false);main.set_physics_process(false)
   for step in 1200:
    if not world.drill_modes.tick(1.0/60.0):world._update_mining(1.0/60.0)
    world.player._physics_process(1.0/60.0)
    world._update_loose_drops(1.0/60.0)
    training._physics_process(1.0/60.0)
    if step in [59,239,599,1199]:
     world.queue_redraw()
     await process_frame
     await RenderingServer.frame_post_draw
     root.get_texture().get_image().save_png(output.path_join(layout+"-"+(mode if not mode.is_empty() else "none")+"-"+str(step)+".png"))
   world.set_mine_held(false)
   main.set_process(true);main.set_physics_process(true)
   var mined: int=0
   for ore in world.resources:
    if bool(ore.mined):mined+=1
   results.append({"layout":layout,"mod":mode,"seconds":20,"variant":"crusher","forge_level":5,"skill_level":25,"floor_delta":world.floor_cells.count(1)-before_floor,"ore_mined":mined,"cargo":state.cargo.duplicate(),"initial_tool":initial_tool,"tool":world._current_endless_tool(),"distance":world.player.global_position.distance_to(start),"final_stamina":state.stamina_value()})
   FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"method":"fixed 60Hz actual mechanics; equal synthetic terrain and loadout; 20sec each; not human enjoyment or FPS","results":results},"\t"))
   print("MOD_CHOICE "+JSON.stringify(results[-1]))
 print("MOD_CHOICES_COMPLETE");quit(0)
