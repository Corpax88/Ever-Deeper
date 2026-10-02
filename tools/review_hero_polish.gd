extends SceneTree
## Actual mining owner, damage clock, native animation and original tool meshes.
## Fixed 30fps capture is animation evidence, never a device FPS benchmark.
var main:Node
var world:Node
var state:Node
var output:String
var evidence:Array=[]
var frames:Array=[]
var failure:bool=false
func _initialize():run.call_deferred()
func check(label:String,ok:bool):
	evidence.append({'name':label,'passed':ok})
	if not ok:failure=true;push_error('HERO_POLISH_FAIL '+label)
func capture(label:String,full:bool):
	await process_frame
	await RenderingServer.frame_post_draw
	var visual=world.player.visual._native_worn
	if visual==null or visual.rig==null:check(label+'-native',false);return
	visual.rig.viewport.get_texture().get_image().save_png(output.path_join(label+'.png'))
	if full:root.get_texture().get_image().save_png(output.path_join(label+'-game.png'))
	var b:Dictionary=visual.rig.shown
	var right:Transform3D=b.tool.affine_inverse()*b['hand.R']
	var left:Transform3D=b.tool.affine_inverse()*b['hand.L']
	var idle:Dictionary=visual.motion.bank.idle[0].bones
	var grip_error:float=maxf(right.origin.distance_to((idle.tool.affine_inverse()*idle['hand.R']).origin),left.origin.distance_to((idle.tool.affine_inverse()*idle['hand.L']).origin))
	frames.append({'frame':label,'grip_error':grip_error,'motion':visual.motion.snapshot(),'hp':world.resources[0].hp,'hit_serial':world.player._mining_impact_serial})
	check(label+'-grips',grip_error<.00002)
	check(label+'-rig',not visual.failed and visual.motion.errors.is_empty())
func run():
	output=OS.get_environment('HERO_OUT');DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load('res://scenes/main/main.tscn').instantiate();root.add_child(main);current_scene=main
	for i in 5:await process_frame
	state=root.get_node('RunState');state.initialize_persistence(output.path_join('isolated-save.json'));state.reset_run(false)
	main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_jump_endless(1)
	world=main.endless_world;world.set_process(false);world.player.set_physics_process(false);world.player.visual.set_process(false)
	world.resonance_drill.set_enabled(false);world.drill_modes.dev_override='';main.achievement_toast.hide()
	var mole=main.get_node('CompanionInterface').active_mole();mole.autonomous_enabled=false;mole.recall()
	world._ground_props.clear();world.discovery_sites.clear()
	for item in world.resource_visuals.values():if is_instance_valid(item):item.queue_free()
	world.resource_visuals.clear();world.resources.clear()
	for y in range(5,19):
		for x in range(8,40):world._set_floor(Vector2i(x,y),true)
	world.player.global_position=world._cell_center(Vector2i(18,10));world.player.external_movement=Vector2.ZERO
	world.player.camera.reset_smoothing();world.player.camera.force_update_scroll()
	var resource:Dictionary={'id':'hero-review-rock','cell':Vector2i(19,10),'position':world._cell_center(Vector2i(19,10)),'hp':100000,'max_hp':100000,'mined':false,'kind':'deep_alloy','amount':1,'depth':1,'node_index':0}
	world.resources.append(resource);world._build_resource_visual(resource)
	check('visible-rock-texture',world.resource_visuals['hero-review-rock'].get_node('PremiumNode').texture!=null)
	var gears=['worn','iron','runed','moonglass','ember','crusher','comet','crown']
	for index in gears.size():
		var gear:String=gears[index];world._cancel_mining();world.set_mine_held(false)
		state.pickaxe_level=mini(index+1,5);state.drill_level=0;state.starforge_variant='' if index<5 else ['crusher','swift','prospector'][index-5];state.endless_tool_style='original'
		world.player.prepare_visual_cache();world.player.set_facing(Vector2.RIGHT)
		for wait_frame in 60:
			world.player.visual._process(1.0/30.0);await process_frame
			if world.player.visual.active_gear==gear and world.player.visual._native_worn!=null and world.player.visual._native_worn.rig!=null:break
		var visual=world.player.visual._native_worn
		check(gear+'-equipped',visual!=null and visual.rig!=null and visual.equipment.current==gear)
		if failure:break
		var before:int=world.resources[0].hp;var serial:int=world.player._mining_impact_serial
		world.set_mine_held(true)
		var count:int=75 if index==0 else 28
		for f in count:
			world.player._physics_process(1.0/30.0);world._update_mining(1.0/30.0);world.player.visual._process(1.0/30.0)
			await capture('%s-%03d'%[gear,f],index==0 or f in [0,10,20])
		check(gear+'-damage',int(world.resources[0].hp)<before)
		check(gear+'-earned-contact',world.player._mining_impact_serial>serial)
		world.set_mine_held(false);world._cancel_mining()
		for f in 10:
			world.player._physics_process(1.0/30.0);world.player.visual._process(1.0/30.0)
			await process_frame
		check(gear+'-stop-transition',not visual.failed and visual.motion.errors.is_empty())
	FileAccess.open(output.path_join('review.json'),FileAccess.WRITE).store_string(JSON.stringify({'passed':not failure,'checks':evidence,'frames':frames,'fps_claim':false}))
	print('HERO_POLISH_REVIEW_COMPLETE ',not failure);quit(1 if failure else 0)
