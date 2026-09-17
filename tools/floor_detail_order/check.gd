extends SceneTree
## Headless proof/opportunity gate only. No draw calls or FPS claims.
var output: String
var bound_pck: String
var results: Array[Dictionary] = []
var guards: Array[Dictionary] = []
var world: Node
var main: Node
var audit: Script
const PCK_SHA: String = "5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		elif argument.begins_with("--bound-pck="): bound_pck = argument.trim_prefix("--bound-pck=")
	if not output.is_absolute_path() or bound_pck != PCK_SHA or DisplayServer.get_name() != "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1696,780)
	var folder: String = get_script().resource_path.get_base_dir()
	audit = load(folder.path_join("audit.gd"))
	var proof: Dictionary = audit.geometry_proof()
	root.get_node("RunState").initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	main.get_node("EndlessDescentWorld").set_script(load(folder.path_join("candidate.gd")))
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	root.get_node("RunState").reset_run(false)
	root.get_node("RunState").world_seed = 4608
	seed(4608)
	if not main._dev_jump_endless(12): quit(3); return
	world = main.endless_world
	world.study_source_verified = true
	world.player.set_external_movement(Vector2.ZERO)
	for frame in 3: await process_frame
	_freeze(root)
	for tween in get_processed_tweens(): tween.pause()
	world._draw_partitioned_deep(Vector2i(16,20),Vector2i(27,31))
	var canvas: CanvasItem = world.lit_draw_sections._cached[Vector3i(20,16,1)]
	_expect("standard",true,canvas)
	world.study_source_verified = false; _expect("unbound-source",false,canvas); world.study_source_verified = true
	world.use_parent_material = true; _expect("inherited-world-material",false,canvas); world.use_parent_material = false
	world.material = ShaderMaterial.new(); _expect("external-world-material",false,canvas); world.material = null
	canvas.use_parent_material = true; _expect("inherited-section-material",false,canvas); canvas.use_parent_material = false
	var material: Material = canvas.material
	canvas.material = ShaderMaterial.new(); _expect("external-section-material",false,canvas); canvas.material = material
	var code: String = material.shader.code
	material.shader.code = code+"\n// external modification\n"; _expect("modified-standard-shader",false,canvas); material.shader.code = code
	guards.append({"id":"unaligned-strip","passed":not world.study_eligible(17,20,canvas)})
	guards.append({"id":"oversize-strip","passed":not world.study_eligible(16,20,canvas)})
	_expect("restored-standard",true,canvas)
	# Ordinary generated resident terrain at nine camera positions. These are
	# source inventories, not a real-time moving route or an FPS measurement.
	var original_position: Vector2 = world.player.position
	for index in 9:
		var center: Vector2 = Vector2(original_position.x,world.CHUNK_HEIGHT*(.55+float(index)*.23))
		var view_size: Vector2 = Vector2(1696,780)/world.player.camera.zoom
		var rect: Rect2 = Rect2(center-view_size*.5-Vector2.ONE*world.TILE_SIZE*3,view_size+Vector2.ONE*world.TILE_SIZE*6)
		var first: Vector2i = world._world_to_cell(rect.position).clamp(Vector2i.ZERO,world.GRID_SIZE-Vector2i.ONE)
		var last: Vector2i = world._world_to_cell(rect.end).clamp(Vector2i.ZERO,world.GRID_SIZE-Vector2i.ONE)
		var row: Dictionary = audit.inventory(world,first,last)
		row["id"] = "generated-window-%02d" % index
		row["camera_center"] = str(center)
		results.append(row)
	var success: bool = bool(proof.passed)
	var reductions: Array[int] = []
	for guard in guards: success = success and bool(guard.passed)
	for row in results:
		success = success and int(row.overlaps)==0
		reductions.append(int(row.concatenated_reduction))
	reductions.sort()
	var median_reduction: int = reductions[reductions.size()/2]
	# A predeclared opportunity screen: fewer than five modeled submission
	# reductions per representative view is too little to justify graphics.
	var worthwhile: bool = median_reduction >= 5
	var report: Dictionary = {"source":"8f5680defb9083bbe1e044d39a10612f2186e7f3","pck_sha256":bound_pck,
		"candidate_sha256":FileAccess.get_sha256(folder.path_join("candidate.gd")),"audit_sha256":FileAccess.get_sha256(folder.path_join("audit.gd")),
		"harness_sha256":FileAccess.get_sha256(get_script().resource_path),"geometry":proof,"guards":guards,"inventory":results,
		"headless_guards_passed":success,"median_modeled_reduction":median_reduction,"opportunity_threshold":5,
		"worthwhile_for_pixel_and_draw_gate":worthwhile,"rendered":false,"timed":false,"adopted":false,
		"limits":["Generated static inventory is not actual GL draw counts or live mining.","Same-pixel proof and actual draw-count reduction remain unmeasured.","No renderer or timing was run."]}
	FileAccess.open(output.path_join("headless-audit.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("FLOOR_DETAIL_AUDIT_COMPLETE guards=",success," median_modeled_reduction=",median_reduction," worthwhile=",worthwhile)
	printerr("FLOOR_DETAIL_AUDIT_COMPLETE guards=",success," median_modeled_reduction=",median_reduction," worthwhile=",worthwhile)
	quit(0 if success else 4)

func _expect(label: String, expected: bool, canvas: CanvasItem) -> void:
	guards.append({"id":label,"expected":expected,"passed":world.study_eligible(16,19,canvas)==expected})

func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)
