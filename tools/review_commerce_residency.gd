extends SceneTree
## External, opt-in review of an immutable DEV PCK. Never publishes a build.
## Run baseline and candidate with the same harness and a fresh XDG_DATA_HOME.
## Required: --output=/absolute/directory --pack-source=/absolute/index.pck
## Candidate only: --require-release. Baseline retains resources without failing.
const FRAME_SIZE: = Vector2i(2532, 1170)
const PORTRAIT_PATH: = "res://assets/hero/dad/wardrobe/crossed-arms-v2.png"
const FIXTURE_SEED: int = 4608
var main: Node
var state: Node
var panel: Control
var output_dir: String = ""
var pack_source: String = ""
var require_release: bool = false
var checks: Array[Dictionary] = []
var stages: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var failures: Array[String] = []
var original_time_scale: float = 1.0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> bool:
	checks.append({"passed": ok, "assertion": message})
	if not ok:
		failures.append(message)
		print("COMMERCE_RENDER_FAIL " + message)
	return ok

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.trim_prefix("--output=")
		elif arg.begins_with("--pack-source="): pack_source = arg.trim_prefix("--pack-source=")
		elif arg == "--require-release": require_release = true
	if not _check(output_dir.is_absolute_path(), "Explicit absolute output directory required"):
		quit(3)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	if not _check(DisplayServer.get_name() != "headless", "Rendered display required"):
		_finish()
		return
	if not _check(FileAccess.file_exists("res://project.binary") and not FileAccess.file_exists("res://project.godot"), "Immutable exported resource root required"):
		_finish()
		return
	if not _check(OS.has_feature("ever_deeper_dev"), "DEV package required"):
		_finish()
		return
	if not _check(pack_source.is_absolute_path() and FileAccess.file_exists(pack_source), "Explicit hashable package file required"):
		_finish()
		return
	original_time_scale = Engine.time_scale
	# Start every authored animation at the same time in both packages. Deferred
	# setup and UPDATE_ONCE previews still receive rendered frames at zero delta.
	Engine.time_scale = 0.0
	root.position = Vector2i.ZERO
	root.size = FRAME_SIZE
	DisplayServer.window_set_size(FRAME_SIZE)
	await _settle()
	state = root.get_node("RunState")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _settle()
	# A fresh XDG_DATA_HOME isolates startup's save namespace as well. All
	# subsequent accelerated fixture transactions use this explicit test save.
	main.persistence_active = false
	state.initialize_persistence(output_dir.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed = FIXTURE_SEED
	seed(FIXTURE_SEED)
	main._dev_seed_victory_state()
	if not _check(main._dev_build_all_workshops_state(), "Existing fixture builds all five workshops"):
		_finish()
		return
	for workshop in ["light_lab", "wardrobe"]:
		state.endless_workshops[workshop].level = 5
	if not _check(main._dev_jump_hub(), "Existing fixture enters Hub"):
		_finish()
		return
	main.hub_world.restore_position(Vector2(720, 495))
	main.hub_world.player.camera.position_smoothing_enabled = false
	main.hub_world.player.camera.reset_smoothing()
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	state.endless_tool_style = "original"
	state.endless_outfit = "miner"
	state.endless_light_style = "standard"
	main.hub_world.player.visual.prepare_visual_cache()
	var gear: Script = load("res://scripts/player/hero_gear.gd")
	for frame in 600:
		gear.poll()
		if gear.current_gear == "worn" and gear.pending.is_empty(): break
		await process_frame
	if not _check(gear.current_gear == "worn" and gear.pending.is_empty(), "Current production hero finishes loading"):
		_finish()
		return
	main.hub_world.player.visual._poll_equipment()
	main.hub_world.player.set_facing(Vector2.RIGHT)
	await _settle(12)
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	main.premium_hud.set_status("")
	panel = main.commerce_panel
	# This frozen image/resource review is explicitly not a frame-time test.
	await _settle()
	stages.append(_snapshot("cold"))
	for workshop in ["wardrobe", "light_lab"]:
		await _review_shop(workshop)
	_finish()

func _settle(frames: int = 8) -> void:
	for frame in frames: await process_frame
	await RenderingServer.frame_post_draw

func _review_shop(workshop: String) -> void:
	var config: Dictionary = main.CommerceCatalogScript.workshop_config(workshop, state.workshop_status(workshop), main.hub_world.workshop_selection_preview(workshop))
	config["selected_item_id"] = "workshop:equip:deepheart"
	var unchanged: Array = [state.gold, state.cargo.duplicate(true), state.endless_outfit, state.endless_light_style]
	var first_selection: String = ""
	var first_card_count: int = -1
	stages.append(_snapshot(workshop + "-before"))
	for cycle in 2:
		var label: String = workshop + ("-opened" if cycle == 0 else "-reopened")
		main._open_commerce(config, "workshop:" + workshop)
		panel._showcase_clock = 0.0
		panel._process(0.0)
		var hover: = InputEventMouseMotion.new()
		hover.position = Vector2(-100, -100)
		hover.global_position = hover.position
		root.push_input(hover, true)
		await _settle(12)
		_check(panel.is_open(), label + " is visible")
		if cycle == 0:
			first_selection = panel.selected_item_id()
			first_card_count = panel.catalog_strip.get_child_count()
		else:
			_check(panel.selected_item_id() == first_selection and panel.catalog_strip.get_child_count() == first_card_count, label + " restores identical selection and catalog")
		var preview: Node = panel.hero_well.get_node_or_null("LightPreview") if workshop == "light_lab" else panel.hero_icon.get_node_or_null("OutfitPreview")
		if not _check(is_instance_valid(preview), label + " has its production preview"): return
		if workshop == "wardrobe":
			_check(preview._sprite.texture.get_size() == Vector2(1600, 2000) and preview._sprite.texture.resource_path == PORTRAIT_PATH, label + " uses original full-resolution portrait")
		else:
			_check(preview.viewport.size == Vector2i(1100, 1200), label + " keeps original preview resolution")
			_check(preview.lamp.applied_style_id == "deepheart", label + " displays selected production beam")
		var references: Array[WeakRef] = [weakref(preview)]
		for viewport in panel.find_children("*", "SubViewport", true, false):
			references.append(weakref(viewport))
		var opened: Dictionary = _snapshot(label)
		stages.append(opened)
		_check(int(opened.gpu_bytes) > 0, label + " reports actual rendered GPU allocation")
		await _capture(label, preview if workshop == "light_lab" else null)
		preview = null
		panel.close_commerce()
		await _settle(12)
		var freed: bool = true
		for reference in references:
			freed = freed and reference.get_ref() == null
		var closed: Dictionary = _snapshot(label + "-closed")
		closed["previous_preview_nodes_freed"] = freed
		closed["gpu_released_bytes"] = int(opened.gpu_bytes) - int(closed.gpu_bytes)
		closed["texture_released_bytes"] = int(opened.texture_bytes) - int(closed.texture_bytes)
		stages.append(closed)
		if require_release:
			_check(freed and int(closed.shop_viewports) == 0, label + " releases preview nodes and viewports on close")
			_check(panel.catalog_strip.get_child_count() == 0 and panel.overview_content.get_child_count() == 0 and panel.hero_icon.texture == null, label + " releases dynamic presentation references")
			_check(int(closed.gpu_released_bytes) > 0, label + " reduces measured GPU allocation after close")
			if workshop == "wardrobe":
				_check(not bool(closed.portrait_cached), label + " releases portrait from ResourceLoader")
		_check(unchanged == [state.gold, state.cargo.duplicate(true), state.endless_outfit, state.endless_light_style], label + " leaves cargo and equipped styles unchanged")

func _snapshot(label: String) -> Dictionary:
	var sizes: Array[Array] = []
	for viewport in panel.find_children("*", "SubViewport", true, false):
		sizes.append([viewport.size.x, viewport.size.y])
	return {
		"id": label,
		"gpu_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"texture_bytes": int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
		"buffer_bytes": int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),
		"scene_descendants": root.find_children("*", "", true, false).size(),
		"shop_descendants": panel.find_children("*", "", true, false).size(),
		"shop_viewports": sizes.size(),
		"preview_sizes": sizes,
		"portrait_cached": ResourceLoader.has_cached(PORTRAIT_PATH),
		"shop_visible": panel.is_open(),
		"selection": panel.selected_item_id(),
	}

func _capture(label: String, light_preview: Node) -> void:
	await RenderingServer.frame_post_draw
	_save_image(label + ".png", root.get_texture().get_image(), FRAME_SIZE)
	if light_preview != null:
		_save_image(label + "-beam.png", light_preview.viewport.get_texture().get_image(), Vector2i(1100, 1200))

func _save_image(filename: String, pixels: Image, expected: Vector2i) -> void:
	_check(pixels != null and not pixels.is_empty() and pixels.get_size() == expected, "Exact rendered pixels for " + filename)
	if pixels == null or pixels.is_empty(): return
	var path: String = output_dir.path_join(filename)
	if not _check(pixels.save_png(path) == OK, "Saved " + filename): return
	captures.append({"file": filename, "width": pixels.get_width(), "height": pixels.get_height(), "sha256": FileAccess.get_sha256(path)})

func _finish() -> void:
	Engine.time_scale = original_time_scale
	var report: Dictionary = {
		"schema": 1,
		"kind": "rendered_commerce_resource_lifetime",
		"package_sha256": FileAccess.get_sha256(pack_source) if FileAccess.file_exists(pack_source) else "",
		"harness_sha256": String(get_script().source_code).sha256_text(),
		"package_version": ProjectSettings.get_setting("application/config/version", ""),
		"engine": Engine.get_version_info(),
		"renderer": DisplayServer.get_name(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"physical_iphone": false,
		"frame_time_benchmark": false,
		"require_release": require_release,
		"fixture": {"seed": FIXTURE_SEED, "framebuffer": [FRAME_SIZE.x, FRAME_SIZE.y], "five_workshops": true, "light_and_wardrobe_level": 5, "tool": "worn", "selection": "deepheart", "animation_frozen_for_images": true},
		"measurement": "Godot Performance RENDER_VIDEO_MEM_USED / RENDER_TEXTURE_MEM_USED / RENDER_BUFFER_MEM_USED after twelve rendered settle frames; bytes, not physical phone measurements",
		"stages": stages,
		"captures": captures,
		"checks": checks,
		"failures": failures,
		"passed": failures.is_empty(),
	}
	var output: FileAccess = FileAccess.open(output_dir.path_join("commerce-residency.json"), FileAccess.WRITE)
	if output != null:
		output.store_string(JSON.stringify(report, "\t") + "\n")
		output.close()
	else:
		_check(false, "Report file opened")
	var report_sha256: String = FileAccess.get_sha256(output_dir.path_join("commerce-residency.json"))
	print("COMMERCE_RESIDENCY_RESULT checks=%d failed=%d captures=%d sha256=%s" % [checks.size(), failures.size(), captures.size(), report_sha256])
	quit(0 if failures.is_empty() else 1)
