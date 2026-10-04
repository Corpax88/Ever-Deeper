extends SceneTree
var main: Node
var world: Node
var state: Node
var five: Node
var output: String
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func check(name: String, passed: bool) -> void:
 checks.append({"name":name,"passed":passed})
 FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
 if not passed:print("CORE_CHARGING_MISMATCH "+name)
func fresh(variant: String) -> void:
 state.deep_events={};state.endless_chunks={};state.cargo=state._empty_resource_store()
 world._cancel_mining();five.reset();five.mode="corebreaker";five.direction=Vector2.RIGHT
 world.resources.clear();world.dig_damage.clear();world.session_mined_nodes.clear();world._clear_loose_drop_visuals()
 state.starforge_variant=variant
 state.endless_relics.forge_heart={"discovered":true,"collected":true,"placed":true,"found_depth":1}
 state.endless_workshops.tool_forge.built=true;state.endless_workshops.tool_forge.level=5
 world.player.global_position=world._cell_center(Vector2i(18,12))
 world.player.external_movement=Vector2.ZERO;world.player.set_facing(Vector2.RIGHT)
 for y in range(8,17):
  for x in range(14,28):world._set_floor(Vector2i(x,y),x<19)
 # Synthetic high-HP nodes test damage/reveal only; none may finish/claim loot.
 for cell in [Vector2i(19,12),Vector2i(20,12),Vector2i(19,13)]:
  world.resources.append({"id":"shield_"+str(cell),"cell":cell,"position":world._cell_center(cell),"hp":100000,"max_hp":100000,"mined":false,"kind":"deep_alloy","amount":10,"depth":1,"node_index":world.resources.size()})
func signature() -> Dictionary:
 var hp: Array=[]
 for ore in world.resources:hp.append(ore.hp)
 return {"floor":world.floor_cells.duplicate(),"hp":hp,"cargo":state.cargo.duplicate()}
func run() -> void:
 output=OS.get_environment("MODS_OUT");DirAccess.make_dir_recursive_absolute(output)
 await process_frame
 main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
 for i in 5:await process_frame
 state=root.get_node("RunState");state.initialize_persistence(output.path_join("isolated.sav"));state.reset_run(false)
 main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_grant_max_tools_state();main._dev_jump_endless(1)
 world=main.endless_world;five=world.drill_modes.five
 main.set_process(false);main.set_physics_process(false);world.set_process(false);world.set_physics_process(false);world.player.set_physics_process(false)
 for variant in ["crusher","swift","prospector"]:
  fresh(variant);world._strike_wall(Vector2i(19,12),1.0);var normal: Dictionary=signature()
  fresh(variant);five._impact({"cell":Vector2i(19,12)},0.1)
  check("uncharged normal rock spread/damage/yield retained "+variant,signature()==normal)
  check("charging does not hit newly revealed ore "+variant,signature().hp==[100000,100000,100000])
  check("charge advances once "+variant,is_equal_approx(five.charge,0.1))
  fresh(variant);world._set_floor(Vector2i(19,12),true);world._set_floor(Vector2i(19,13),true)
  world._strike_resource(0);normal=signature()
  fresh(variant);world._set_floor(Vector2i(19,12),true);world._set_floor(Vector2i(19,13),true)
  five._impact({"node":0},0.1)
  check("uncharged exposed node wave retained "+variant,signature()==normal)
  check("side buried ore remains untouched "+variant,int(world.resources[1].hp)==100000)
  five.cancel();check("release cancels burst and retains accrued charge "+variant,is_equal_approx(five.charge,0.1) and five.core_left==0)
  five.reset();check("lifecycle reset clears accrued charge "+variant,five.charge==0.0 and five.core_left==0)
 for row in checks:
  if not row.passed:quit(1);return
 print("CORE_CHARGING_OK "+str(checks.size()));quit(0)
