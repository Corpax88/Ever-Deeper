extends SceneTree
## Real goal/route owners and actual world transitions; isolated rendered probe.
var main: Node
var state: Node
var Goals: Script
var output: String
var checks: Array = []
var routes: Array = []
var assertions_only: bool = false

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not passed: print("TREASURY_ROUTES_MISMATCH " + label)

func pin(kind: String) -> void:
	state.treasury_goals = Goals.clean({})
	state.treasury_totals = {}
	state.cargo = state._empty_resource_store()
	state.gold = 0
	Goals.pin(kind)

func route(label: String) -> Dictionary:
	var goal: Dictionary = main._progression_goal()
	var proposal: Dictionary = main._guide_route_proposal(goal)
	routes.append({"case":label,"phase":main.phase,"goal":goal.duplicate(true),"proposal":proposal.duplicate(true)})
	return proposal

func target(proposal: Dictionary) -> Vector2:
	var candidates: Array = Array(proposal.get("candidates",[]))
	return Vector2(candidates[0].position) if not candidates.is_empty() else Vector2.ZERO

func capture(label: String) -> void:
	main._update_visual_guide()
	main.quick_tutorial.dismiss()
	main.achievement_toast.clear()
	for _frame in 4: await process_frame
	if assertions_only: return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	assertions_only = "--route-assertions-only" in OS.get_cmdline_user_args()
	if output.is_empty() or (DisplayServer.get_name()=="headless" and not assertions_only):
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	Goals = load("res://scripts/state/treasury_goals.gd")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for _frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated.sav"))
	state.reset_run(false)
	main._dev_jump_surface()
	check("fresh progression remains ordinary",not String(main._progression_goal().get("objective_id","")).begins_with("treasury:"))
	check("fixture enters actual Deep",main._dev_jump_endless(3))
	main.get_node("MinerTraining").set_process(false)
	pin("prismite")
	var proposal: Dictionary = route("deep gathering")
	check("tracked rich material seeks that material",proposal.waypoint_id=="endless:treasury:prismite" and target(proposal)==main.endless_world.guide_target("prismite"))
	state.leave_endless_descent_to_hub()
	main._return_from_endless_to_hub()
	proposal = route("hub gathering")
	check("Hub points at Deep elevator rather than surface",proposal.waypoint_id=="hub:deep_elevator" and target(proposal)==main.hub_world.DEEP_ELEVATOR_POSITION)
	await capture("hub-rich-material")
	main._dev_jump_surface()
	proposal = route("surface gathering")
	check("Surface rich material routes through Hub",proposal.waypoint_id=="surface:hub_entrance" and target(proposal)==main.surface_world.hub_guide_position())
	state.cargo.prismite=100000
	proposal=route("surface ready")
	check("carried target changes to actual donation action",Goals.hud_goal().treasury_route=="donate" and String(proposal.hud_action)=="Donate · Treasury plate" and proposal.waypoint_id=="surface:hub_entrance")
	main._dev_jump_endless(3)
	proposal=route("deep ready")
	check("ready Deep haul points home without downward arrow",Array(proposal.candidates).is_empty() and String(proposal.hud_action)=="Tunnel Home · donate")
	await capture("deep-ready-home")
	state.leave_endless_descent_to_hub()
	main._return_from_endless_to_hub()
	proposal=route("hub ready")
	check("Hub ready haul targets Treasury",proposal.waypoint_id=="hub:treasury" and target(proposal)==main.hub_world.TREASURY_DOOR)
	main.hub_world.treasury.enter()
	proposal=route("treasury donation")
	check("inside Treasury points to donation plate",proposal.waypoint_id=="treasury:donation" and target(proposal)==main.hub_world.treasury.DONATION)
	await capture("treasury-donation")
	var landed: int = load("res://scripts/state/treasury_state.gd").land("prismite",100000)
	check("real donation debits cargo and fills podium",landed==100000 and state.cargo.prismite==0 and state.treasury_totals.prismite==100000)
	proposal=route("treasury claim")
	check("full unclaimed mod targets correct podium",proposal.waypoint_id=="treasury:podium:prismite" and target(proposal)==main.hub_world.treasury.bay(main.hub_world.treasury.Ledger.keys().find("prismite")))
	await capture("treasury-claim")
	check("actual claim retires only completed goal",Goals.claim("prismite") and state.treasury_goals.pinned=="" and Goals.hud_goal().is_empty())
	main.hub_world.treasury.leave()
	main._update_visual_guide()
	check("ordinary postgame guide resumes after claim",not String(main._progression_goal().get("objective_id","")).begins_with("treasury:"))
	pin("wallet_gold")
	state.cargo.crownstone=200
	proposal=route("wallet sell in Hub")
	check("wallet target uses actual sale and Hub shop",int(state.assay_sale_snapshot().total)>0 and proposal.waypoint_id=="hub:shop" and target(proposal)==main.hub_world.HUB_SHOP)
	state.sell_all()
	proposal=route("wallet sold")
	check("real sale advances wallet target to donation",state.gold>=100000 and proposal.waypoint_id=="hub:treasury" and Goals.hud_goal().treasury_route=="donate")
	pin("wallet_gold")
	proposal=route("wallet empty")
	check("empty wallet routes to sellable ordinary ore",Goals.hud_goal().treasury_route=="mine" and Goals.hud_goal().route_resource_id=="crownstone" and proposal.waypoint_id=="hub:surface_lift")
	main._dev_jump_surface()
	proposal=route("wallet mine")
	check("wallet mining points to authored Starfall source",proposal.waypoint_id=="surface:mine:starMine")
	pin("moonglass")
	proposal=route("ordinary Depth 1")
	check("ordinary collection chooses actual area",Goals.hud_goal().mine_id=="moonMine" and Goals.hud_goal().depth==1 and proposal.waypoint_id=="surface:mine:moonMine")
	check("fixture enters actual target mine",main._dev_jump_mine("moonMine",1))
	proposal=route("ordinary target ore")
	var valid_material: bool = not Array(proposal.candidates).is_empty()
	for candidate in proposal.candidates:
		var cell: Vector2i=Vector2i(Vector2(candidate.position)/float(main.mine_world.TILE_SIZE))
		valid_material=valid_material and String(Dictionary(main.mine_world.blocks.get(cell,{})).get("kind",""))=="moonglass"
	check("collection arrow only names matching actual ore",valid_material)
	# Remove just the requested material in this isolated fixture; other ore stays.
	var saved_blocks: Dictionary=main.mine_world.blocks.duplicate(true)
	for cell in main.mine_world.blocks.keys():
		if String(Dictionary(main.mine_world.blocks[cell]).get("kind",""))=="moonglass": main.mine_world.blocks.erase(cell)
	proposal=route("ordinary requested seam exhausted")
	check("exhausted named material never points to different ore",Array(proposal.candidates).is_empty() and String(proposal.hud_action).begins_with("Explore · find "))
	main.mine_world.blocks=saved_blocks
	pin("ambercore")
	main._dev_jump_surface()
	proposal=route("ordinary Depth 2 surface")
	check("Depth 2 collection uses correct mine and depth",Goals.hud_goal().mine_id=="mossMine" and Goals.hud_goal().depth==2 and proposal.waypoint_id=="surface:mine:mossMine")
	main._dev_jump_mine("mossMine",1)
	proposal=route("ordinary Depth 2 shaft")
	check("Depth 2 collection reaches real shaft",proposal.waypoint_id=="mine:mossMine:shaft" and target(proposal)==main.mine_world.depth_entrance)
	main._dev_jump_mine("mossMine",2)
	proposal=route("ordinary Depth 2 resource")
	check("Depth 2 collection targets named accessible deposit",proposal.waypoint_id=="depth:mossMine:resource:ambercore" and not Array(proposal.candidates).is_empty())
	main._dev_jump_surface()
	state.area_unlocked=false
	state.emberdeep_unlocked=false
	pin("moonglass")
	check("locked worlds never receive a collection waypoint",Goals.hud_goal().treasury_route=="unavailable" and Array(route("locked collection").candidates).is_empty())
	main._dev_seed_all_zones_state()
	main._dev_jump_endless(3)
	pin("prismite")
	var world: Node=main.endless_world
	var site_index: int=-1
	for index in world.discovery_sites.size():
		var site: Dictionary=world.discovery_sites[index]
		if int(site.get("depth",-1))==world.current_depth and not bool(site.get("resolved",false)) and Array(site.get("rune_positions",[])).size()>=3:
			site_index=index
			break
	check("real discovery activity exists",site_index>=0)
	if site_index>=0:
		var site: Dictionary=world.discovery_sites[site_index]
		# This route probe places the hero at the real generated choice pad;
		# reaching the buried room through mining is covered by journey tests.
		world.player.global_position=Vector2(site.position)+Vector2(-world.SITE_PAD_OFFSET,36.0)
		var started: bool=world._start_site_activity(int(site.get("index",site_index)),"stabilize")
		routes.append({"case":"activity preflight","site":site.duplicate(true),"player":world.player.global_position,"current_depth":world.current_depth,"started":started})
		check("real activity was explicitly started",started and not world.site_activity.is_empty())
		proposal=route("active discovery")
		check("started discovery temporarily guides next seal",String(main._progression_goal().objective_id).contains(":rune:") and target(proposal)==Vector2(site.rune_positions[0]) and state.treasury_goals.pinned=="prismite")
		world._cancel_site_activity()
		check("pin resumes after activity without clearing player choice",main._progression_goal().objective_id=="treasury:prismite" and state.treasury_goals.pinned=="prismite")
	FileAccess.open(output.path_join("routes.json"),FileAccess.WRITE).store_string(JSON.stringify(routes,"\t"))
	FileAccess.open(output.path_join("mode.json"),FileAccess.WRITE).store_string(JSON.stringify({"renderer":DisplayServer.get_name(),"assertions_only":assertions_only,"png_capture":not assertions_only},"\t"))
	var failed: bool=false
	for item in checks: failed=failed or not bool(item.passed)
	print("TREASURY_ROUTES_FAILED" if failed else "TREASURY_ROUTES_OK")
	quit(1 if failed else 0)
