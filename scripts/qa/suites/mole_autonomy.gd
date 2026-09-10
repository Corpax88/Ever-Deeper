extends "res://scripts/qa/qa_context.gd"
## Real companion/world actions in controlled geometry; no fake skill implementation.
var world: Node
var mole: MoleCompanion
var checks: int = 0
var failures: Array[String] = []
const CENTER = Vector2i(15,15)

func check(condition: bool, label: String) -> void:
	checks+=1
	if not condition:
		failures.append(label)
		print("MOLE_AUTONOMY_CHECK_FAILED "+label)

func step(seconds: float) -> void:
	for frame in range(ceili(seconds*60.0)): mole._physics_process(1.0/60.0)

func fixture(skills: Dictionary, direction: Vector2i = Vector2i.RIGHT) -> void:
	# Isolated D1 room uses real collision, terrain authority, drops and impact.
	world.mine.barriers=[]
	for y in range(CENTER.y-7,CENTER.y+8):
		for x in range(CENTER.x-7,CENTER.x+8): world.blocks.erase(Vector2i(x,y))
	world.drops.clear()
	world.blocks[CENTER]=world._make_block("stone",20,0,"terrain")
	world._rebuild_role_counts()
	world.player.global_position=world._cell_center(CENTER-direction)
	world.player.set_facing(Vector2(direction))
	world.player.control_enabled=true
	world.external_mine_held=false
	RunState.overhaul_progress={"skills":skills.duplicate(),"companion_xp":0}
	mole._spawn_beside_hero()
	mole.global_position=world.player.global_position
	mole.was_active=true
	mole.think_clock=0.0
	mole.shake_cooldown=0.0
	mole.assist_cooldown=0.0
	mole.dug_total=0
	mole.collected_total=0

func natural_mining(label: String) -> void:
	world.set_process(false)
	world.player.set_physics_process(false)
	world.player.control_enabled=true
	mole=world.get_node("MoleCompanion")
	mole.set_physics_process(false)
	mole._spawn_beside_hero()
	mole.was_active=true
	RunState.overhaul_progress={"skills":{"shake":1,"teamwork":1}}
	var origin: Vector2i=world._world_to_cell(world.player.global_position)
	var landing: Vector2=Vector2(INF,INF)
	var target: Vector2=Vector2(INF,INF)
	for y in range(-8,9):
		for x in range(-8,9):
			var point: Vector2=world._cell_center(origin+Vector2i(x,y))
			if not world.companion_can_dig(point): continue
			var floor_point: Vector2=mole._reachable_floor(point)
			if is_finite(floor_point.x):
				landing=floor_point
				target=point
				break
		if is_finite(target.x): break
	check(is_finite(target.x),label+": eligible natural terrain exists")
	if not is_finite(target.x): return
	world.player.global_position=landing
	world.player.set_facing((target-landing).normalized())
	mole.global_position=landing
	mole.recall()
	mole.think_clock=0.0
	mole.shake_cooldown=0.0
	mole.assist_cooldown=0.0
	var before: int=mole.dug_total
	world.external_mine_held=true
	step(1.0)
	check(mole.dug_total>before,label+": automatic skill mines real natural terrain")
	world.external_mine_held=false

func run() -> void:
	main._dev_seed_all_zones_state()
	main._dev_ensure_playing()
	main._enter_mine("mossMine",false,false)
	await main.get_tree().process_frame
	world=main.mine_world
	world.set_process(false)
	world.player.set_physics_process(false)
	mole=world.get_node("MoleCompanion")
	mole.set_physics_process(false)
	for direction in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
		fixture({"shake":1},direction)
		step(1.0)
		check(world.blocks.has(CENTER) and mole.dug_total==0,"No idle digging "+str(direction))
		world.external_mine_held=true
		step(0.35)
		check(world.blocks.has(CENTER),"Automatic dig waits for authored impact "+str(direction))
		step(0.6)
		check(not world.blocks.has(CENTER) and mole.dug_total==1,"Earthshaker works without commands "+str(direction))
		check(mole.shake_cooldown>6.0,"Earthshaker really recharges "+str(direction))
		world.blocks[CENTER]=world._make_block("stone",20,0,"terrain")
		step(2.0)
		check(world.blocks.has(CENTER),"No repeated hit before recharge "+str(direction))
	fixture({"shake":1,"teamwork":1})
	world.external_mine_held=true
	step(1.0)
	world.blocks[CENTER]=world._make_block("stone",20,0,"terrain")
	step(1.0)
	check(not world.blocks.has(CENTER) and mole.dug_total==2 and mole.shake_cooldown>0.0,"Teamwork fills the gap between Earthshaker uses")
	world.blocks[CENTER]=world._make_block("stone",20,0,"terrain")
	step(0.6)
	check(world.blocks.has(CENTER),"Teamwork also respects its own recharge")
	for cancellation in ["release","turn","leave"]:
		fixture({"shake":1,"teamwork":1})
		world.external_mine_held=true
		step(0.2)
		if cancellation=="release": world.external_mine_held=false
		elif cancellation=="turn": world.player.set_facing(Vector2.LEFT)
		else: world.player.global_position+=Vector2(-400,0)
		step(1.0)
		check(world.blocks.has(CENTER),"Stops old dig when player chooses to "+cancellation)
	fixture({"shake":1})
	world.external_mine_held=true
	step(0.2)
	world.player.control_enabled=false
	var action_time: float=mole.action_clock
	step(5.0)
	check(world.blocks.has(CENTER) and mole.action_clock==action_time,"Menus pause work and animation impact")
	world.player.control_enabled=true
	step(0.6)
	check(not world.blocks.has(CENTER),"Closing menu safely resumes the same task")
	fixture({})
	world.external_mine_held=true
	step(2.0)
	check(world.blocks.has(CENTER),"Unlearned skills never activate")
	for kind in ["bedrock","gate","tool"]:
		fixture({"shake":1,"teamwork":1})
		world.blocks[CENTER]=world._make_block("bedrock" if kind=="bedrock" else "stone",20,0,"outer_rubble" if kind=="gate" else "terrain")
		if kind=="tool": world.blocks[CENTER].requires_tool=RunState.pickaxe_level+1
		world.external_mine_held=true
		step(2.0)
		check(world.blocks.has(CENTER),"Automatic skills respect "+kind)
	fixture({"shake":1})
	var command_point: Vector2=world.player.global_position+Vector2(-48,0)
	check(mole.command(command_point),"Optional command is still accepted")
	world.external_mine_held=true
	step(2.0)
	check(world.blocks.has(CENTER) and mole.mode=="hold","Explicit command gets a brief uninterrupted turn")
	fixture({"fetch":1,"big_paws":1,"trailrunner":1,"long_beam":1})
	world.blocks.erase(CENTER)
	var initial_ore: int=int(RunState.cargo.copper)
	world._spawn_drop(CENTER+Vector2i(2,0),"copper",3)
	world.drops[-1].position=world._cell_center(CENTER+Vector2i(2,0))
	world.drops[-1].age=1.0
	step(2.0)
	check(int(RunState.cargo.copper)==initial_ore+3 and mole.collected_total==3,"Fetch claims real loose ore without input")
	step(2.0)
	check(int(RunState.cargo.copper)==initial_ore+3,"Automatic pickup never double credits")
	check(is_equal_approx(mole.lamp.base_beam_length,440.0),"Learned Long Beam stays active")
	world._spawn_drop(CENTER+Vector2i(6,0),"copper",2)
	world.drops[-1].position=world._cell_center(CENTER+Vector2i(6,0))
	world.drops[-1].age=1.0
	step(2.0)
	check(mole.mode=="follow" and int(RunState.cargo.copper)==initial_ore+3,"Fetching stays near the player")
	fixture({"ore_nose":1})
	world.blocks[CENTER]=world._make_block("copper",20,0,"resource")
	mole.global_position-=Vector2(96,0)
	mole.sniff_clock=0.0
	step(0.1)
	check(mole.mode=="scout" and mole.automatic_task and mole.guide_kind=="ore_nose","Ore Nose automatically approaches a nearby exposed vein")
	check(not mole._blocked(mole.destination),"Scouting chooses walkable ground beside ore")
	world.external_mine_held=true
	step(0.1)
	check(mole.mode!="scout","Mining interrupts automatic scouting immediately")
	fixture({"echo":1,"homeward":1})
	mole.echo_clock=0.0
	step(0.1)
	check(mole.guide_kind=="echo" and mole.mode=="follow","Echo points deeper without taking control")
	step(26.0)
	check(mole.guide_time<=0.0,"Standing still does not repeat the same Echo hint")
	check(main.phase=="mine" and not main.tunnel_home_in_progress,"Homeward never takes the player away automatically")
	mole._react("First automatic hint",2.0,true)
	mole._react("Another automatic hint",2.0,true)
	check(mole.feedback=="First automatic hint","Routine hints are limited to one every eight seconds")
	mole._react("Your deliberate command",2.0)
	check(mole.feedback=="Your deliberate command","Manual feedback remains immediate")
	fixture({})
	for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
		world.blocks[CENTER+Vector2i(4,0)+offset]=world._make_block("stone",20,0,"terrain")
	world.player.global_position=world._cell_center(CENTER+Vector2i(4,0))
	var searches_before: int=mole.path_searches
	step(3.0)
	check(mole.path_searches-searches_before<=4,"Unreachable follow target cannot trigger pathfinding every frame")
	main._dev_jump_mine("mossMine",2)
	RunState.set_drill_level(3)
	world=main.depth_world
	natural_mining("Depth 2")
	main._dev_seed_victory_state()
	main._enter_endless(true,false)
	world=main.endless_world
	natural_mining("The Deep")
	print("MOLE_AUTONOMY_RESULT "+JSON.stringify({"checks":checks,"failures":failures}))
	if failures.is_empty(): print("EVER_DEEPER_MOLE_AUTONOMY_OK checks=%d" % checks)
	main.get_tree().quit(0 if failures.is_empty() else 4)
