extends SceneTree
var main: Node
var world: Node
var state: Node
var output: String
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func verify(ok: bool,label: String,details: Dictionary={}) -> void:
	checks.append({"name":label,"passed":ok,"details":details})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
func capture(label: String) -> void:
	world.player.camera.reset_smoothing()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func drive(seconds: float) -> void:
	for i in int(seconds*60):
		world.drill_modes.tick(1.0/60.0)
		world.player._physics_process(1.0/60.0)
		if i%30==0: await process_frame
func run() -> void:
	output=OS.get_environment("MODS_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
	for i in 5: await process_frame
	state=root.get_node("RunState");state.initialize_persistence(output.path_join("save.json"));state.reset_run(false)
	main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_jump_endless(1);main._dev_grant_max_tools_state()
	world=main.endless_world;world.resonance_drill.set_enabled(false)
	var mole: Node=main.get_node("CompanionInterface").active_mole();mole.autonomous_enabled=false;mole.recall()
	world.set_process(false);world.player.set_physics_process(false)
	world.drill_modes.dev_override="bore_rush"
	main.achievement_toast.hide()
	# Each approach starts off-centre; nearby walls outside the travel line must
	# not invoke ordinary mining's stationary lock.
	var original_props: Dictionary=world._ground_props.duplicate(true)
	world._ground_props.clear()
	var original_sites: Array=world.discovery_sites.duplicate(true)
	world.discovery_sites.clear()
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		for offset in [-24.0,0.0,24.0]:
			world.set_mine_held(false)
			var center: Vector2=world._cell_center(Vector2i(18,10))
			for y in range(3,18):
				for x in range(8,29): world._set_floor(Vector2i(x,y),false)
			for y in range(9,12):
				for x in range(17,20): world._set_floor(Vector2i(x,y),true)
			var side: Vector2=Vector2(-direction.y,direction.x)
			world.player.global_position=center+side*offset
			world.player.external_movement=direction
			world.player.set_facing(direction)
			world.set_mine_held(true)
			var before: Vector2=world.player.global_position
			await drive(2.5)
			var travel: float=(world.player.global_position-before).dot(direction)
			verify(travel>180.0,"offcentre-"+str(direction)+"-"+str(offset),{"travel":travel})
			verify(world._position_walkable(world.player.global_position),"no-wall-clipping-"+str(direction)+str(offset))
			if offset==24.0: await capture("offcentre-"+str(int(direction.angle()*100)))
	world.set_mine_held(false)
	world._ground_props=original_props;world.discovery_sites=original_sites
	# Real generated boost site, unchanged base collider/visual/interaction.
	var site: Dictionary=world.discovery_sites[0]
	var center: Vector2=Vector2(site.position)+Vector2(0,24)
	var cell: Vector2i=world._world_to_cell(center)
	for y in range(cell.y-5,cell.y+6):
		for x in range(cell.x-6,cell.x+7): world._set_floor(Vector2i(x,y),true)
	# Keep real discovery collision; remove unrelated ore for isolated approaches.
	world._ground_props.clear()
	for item in world.discovery_sites: world._index_ground_prop(Vector2(item.position)+Vector2(0,24),Vector2(70,27),-1)
	var resolved: bool=bool(site.get("resolved",false))
	for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
		world.set_mine_held(false)
		world.player.external_movement=Vector2.ZERO
		world.player.global_position=center-direction*150.0
		world.player.set_facing(direction)
		world.set_mine_held(true)
		var clipped: bool=false
		for part in 8:
			await drive(0.2)
			clipped=clipped or not world._position_walkable(world.player.global_position)
			if part==2: await capture("boost-passing-"+str(int(direction.angle()*100)))
		var travel: float=(world.player.global_position-center).dot(direction)
		verify(travel>110.0,"boost-passed-"+str(direction),{"past_center":travel,"position":str(world.player.global_position)})
		verify(not clipped,"boost-solid-"+str(direction))
		verify(bool(site.get("resolved",false))==resolved,"boost-not-auto-claimed-"+str(direction))
	world.set_mine_held(false)
	world.player.external_movement=Vector2(1,1).normalized()
	world.player.global_position=center+Vector2(160,160)
	world.set_mine_held(true)
	var before: Vector2=world.player.global_position
	await drive(0.25)
	var delta: Vector2=world.player.global_position-before
	verify(delta.x>20 and delta.y>20,"analogue-diagonal",{"delta":str(delta)})
	world.player.external_movement=Vector2.LEFT
	before=world.player.global_position;await drive(0.25)
	verify(world.player.global_position.x<before.x-30,"held-steering-turns")
	world.player.external_movement=Vector2.ZERO;world.set_mine_held(false)
	before=world.player.global_position;await drive(0.2)
	verify(world.player.global_position.distance_to(before)<0.1,"release-stops")
	world.resources.clear();world._ground_props.clear();world.discovery_sites.clear()
	for y in range(2,27):
		for x in range(3,37): world._set_floor(Vector2i(x,y),true)
	world.player.global_position=world._cell_center(Vector2i(19,14))
	world.drill_modes.dev_override="laser"
	world.set_mine_held(true)
	for i in 24:
		var aim: Vector2=Vector2.RIGHT.rotated(TAU*float(i)/24.0)
		world.player.external_movement=aim
		world.drill_modes.tick(1.0/60.0)
		var beam: Vector2=(world.drill_modes.beam_end-world.drill_modes.beam_start).normalized()
		verify(beam.dot(aim)>0.999,"laser-360-"+str(i))
		if i in [3,9,15,21]: await capture("laser-angle-"+str(i))
	world.player.external_movement=Vector2(1,1).normalized()
	var diagonal: Vector2i=Vector2i(22,17)
	world._set_floor(diagonal,false)
	world._set_floor(diagonal+Vector2i.LEFT,false)
	world._set_floor(diagonal+Vector2i.UP,false)
	var ray: Dictionary=world.drill_modes._laser_target(world.player.global_position,world.player.external_movement)
	verify(ray.get("cell",Vector2i.ZERO)==diagonal,"laser-diagonal-ray-first-hit")
	world.drill_modes.target_key=""
	world.drill_modes.tick(0.04)
	verify(not world._is_floor(diagonal),"laser-diagonal-not-instant")
	for i in 7: world.drill_modes.tick(0.04)
	verify(world._is_floor(diagonal) and not world._is_floor(diagonal+Vector2i.LEFT) and not world._is_floor(diagonal+Vector2i.UP),"laser-diagonal-single-cell-damage")
	world.player.external_movement=Vector2(1,1).normalized()
	var laser_before: Vector2=world.player.global_position
	# Nearby rock off the beam used to lock all movement, even with a laser.
	world._set_floor(Vector2i(19,13),false)
	await drive(0.25)
	var laser_move: Vector2=world.player.global_position-laser_before
	verify(laser_move.x>20 and laser_move.y>20,"laser-diagonal-movement",{"delta":str(laser_move)})
	world.set_mine_held(false);world.player.external_movement=Vector2.ZERO
	verify(not world.drill_modes.firing,"laser-release-stops")
	await capture("final")
	var passed: bool=true
	for c in checks: passed=passed and c.passed
	await process_frame
	print("BORE_FLOW_OK" if passed else "BORE_FLOW_FAILED")
	quit(0 if passed else 1)
