extends SceneTree

const Icons := preload("res://scripts/ui/action_icons.gd")

var game: Node
var output: String
var checks := {}
var frames: Array[String] = []


func _initialize() -> void:
	run.call_deferred()


func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	checks[name + ":capture"] = image.save_png(output.path_join(name + ".png")) == OK
	frames.append(name)


func run() -> void:
	output = OS.get_environment("PAINTED_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.8).timeout
	game._start_new_game()
	await create_timer(0.36).timeout
	game.surface_world.restore_position(game.mara.approach())
	game._update_visual_guide()
	await create_timer(0.25).timeout
	var button: Button = game.premium_hud.context_button
	var art: Sprite2D = game.mara.actors.surface.get_node("Art")
	var motion := art.material as ShaderMaterial
	checks["live Mara has animated art"] = motion != null
	checks["talk shows the speech bubble"] = button.text == "TALK" and button.icon == Icons.TALK
	checks["skills shows a connected set of skills"] = game.premium_hud.menu_button.icon == Icons.SKILLS
	await capture("01-talk-idle")
	button.pressed.emit()
	await create_timer(0.22).timeout
	checks["TALK triggers Mara greeting"] = motion != null and float(motion.get_shader_parameter("greeting")) > 0.5
	checks["TALK still accepts the quest"] = root.get_node("RunState").camp_quest == root.get_node("RunState").CampQuest.ACTIVE
	await capture("02-talk-greeting")
	await create_timer(0.46).timeout
	checks["greeting eases back to idle"] = motion != null and is_zero_approx(float(motion.get_shader_parameter("greeting")))

	var expected := {
		"SELL ORE": Icons.GOLD, "SELLING": Icons.GOLD,
		"FORGE": Icons.ANVIL, "TOOL FORGE": Icons.ANVIL,
		"DESCEND": Icons.DOWN, "ASCEND": Icons.UP, "RETURN": Icons.EXIT,
		"OPEN": Icons.PORTAL, "SEALED": Icons.LOCK, "DELIVER": Icons.PARCEL, "LOAD": Icons.PARCEL,
		"BROWSE": Icons.SEARCH, "ATTACH ROPE": Icons.ROPE, "ATTUNE": Icons.RELIC,
		"POWER": Icons.POWER, "STABILIZE": Icons.STEADY, "OVERLOAD": Icons.BOOST,
		"TUNING": Icons.TUNE, "UPGRADE": Icons.UPGRADE, "BUILD": Icons.TOOLS,
		"TREASURY": Icons.TREASURY, "TUNNEL HOME": Icons.MOLE,
		"WARDROBE": Icons.WARDROBE, "LIGHT LAB": Icons.LANTERN,
	}
	var samples := {"FORGE": "03-forge", "DESCEND": "04-descend", "ATTACH ROPE": "05-rope", "POWER": "06-power"}
	for action in expected:
		game.premium_hud.set_context_action(action, true)
		checks["displayed icon: " + action] = button.icon == expected[action]
		if samples.has(action):
			await capture(samples[action])
	game.premium_hud.set_context_action("UNKNOWN ACTION", true)
	checks["unmapped action keeps text without an unrelated icon"] = button.icon == null and button.text == "UNKNOWN ACTION"

	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	var test_world := Node2D.new()
	root.add_child(test_world)
	var reduced: RefCounted = game.MaraQuests.new()
	reduced.install({"surface": test_world})
	reduced.actors.surface.show()
	reduced.greet("surface")
	checks["reduced motion disables the idle and greeting"] = reduced.actors.surface.get_node("Art").material == null
	test_world.queue_free()

	var passed := not checks.values().has(false)
	var report := {"passed": passed, "checks": checks, "frames": frames, "viewport": [root.size.x, root.size.y]}
	FileAccess.open(output.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	quit(0 if passed else 1)
