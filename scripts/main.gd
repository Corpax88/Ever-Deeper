extends Node

const PremiumMenuScript = preload("res://scripts/ui/premium_menu.gd")
const GuideOverlayScript = preload("res://scripts/ui/guide_overlay.gd")
const PremiumHudScript = preload("res://scripts/ui/premium_hud.gd")
const WorkshopPanelScript = preload("res://scripts/ui/workshop_panel.gd")
const CommercePanelScript = preload("res://scripts/ui/commerce_panel.gd")
const CommerceCatalogScript = preload("res://scripts/ui/commerce_catalog.gd")
const ResourceInventoryScript = preload("res://scripts/ui/resource_inventory.gd")
const DropVisualsScript = preload("res://scripts/world/drop_visuals.gd")
const StationTransactionFxScript = preload("res://scripts/world/station_transaction_fx.gd")
const GuideDirectorScript = preload("res://scripts/progression/guide_director.gd")
const AchievementToastScript = preload("res://scripts/ui/achievement_toast.gd")
const MinimapOverlayScript = preload("res://scripts/ui/minimap_overlay.gd")
const QuickTutorialScript = preload("res://scripts/ui/quick_tutorial.gd")
const WorldCatalogScript = preload("res://scripts/world/world_catalog.gd")
const DEV_BUILD_FEATURE: = "ever_deeper_dev"
const DEV_SAVE_PATH: = "user://ever_deeper_dev_run_v2.json"
const DEV_QA_SAVE_PATH: = "user://ever_deeper_dev_qa_run_v2.json"
const VISUAL_CAPTURE_SUITE_ARG: = "--visual-capture-suite"
const VISUAL_CAPTURE_DRIVER_PATH: = "res://scripts/dev/visual_capture_driver.gd"
const STARFORGE_BUTTON_ICONS: = {
	"crusher": preload("res://assets/tools/starforge-crusher.png"),
	"swift": preload("res://assets/tools/starforge-swift.png"),
	"prospector": preload("res://assets/tools/starforge-prospector.png"),
}
const MINE_IDS: = ["mossMine", "moonMine", "emberMine", "starMine"]
const WORLD_BY_MINE: = {
	"mossMine": "mossvein", "moonMine": "moonglass", "emberMine": "emberdeep", "starMine": "starfall"
}
const GATE_REQUIREMENTS: = {
	"moonglass": {"pickaxe": 3, "gold": 120, "mastery": 0, "title": "Moonglass Gate"},
	"emberdeep": {"pickaxe": 4, "gold": 360, "mastery": 0, "title": "Emberdeep Seal"},
	"starfall": {"pickaxe": 0, "gold": 0, "mastery": 5, "title": "Starfall Master Seal"}
}
const STARFORGE_VARIANT_IDS: = ["crusher", "swift", "prospector"]
const ENDLESS_RESOURCE_NAMES: = {
	"deep_alloy": "Deep Alloy",
	"lumenstone": "Lumenstone",
	"memory_silk": "Memory Silk",
	"echo_crystal": "Echo Crystal",
	"waystone": "Waystone",
}
const GUIDE_UPDATE_INTERVAL: = 0.2
const LOCATION_CHECKPOINT_INTERVAL: = 8.0
const ACHIEVEMENT_ANCHOR_UPDATE_INTERVAL: = 1.0 / 30.0
const MINIMAP_UPDATE_INTERVAL: = 0.1
const IPHONE_LANDSCAPE_ASPECT: = 1.95
const JOURNEY_PERFORMANCE_WARMUP_SECONDS: = 0.75
const JOURNEY_PERFORMANCE_SAMPLE_SECONDS: = 2.5
const JOURNEY_PERFORMANCE_MIN_PREFLIGHT_FPS: = 45.0
const JOURNEY_PERFORMANCE_P95_LIMIT_MS: = 35.0
const JOURNEY_PERFORMANCE_MAX_FRAME_MS: = 250.0
const JOURNEY_PERFORMANCE_MAX_TRANSITION_MS: = 500.0
const JOURNEY_PERFORMANCE_MAX_STATIC_BYTES: = 256 * 1024 * 1024
const JOURNEY_PERFORMANCE_MAX_SAVE_MS: = 100.0
const JOURNEY_PERFORMANCE_MAX_SAVE_BYTES: = 3 * 1024 * 1024
const JOURNEY_PERFORMANCE_MATURE_DUG_CELLS: = 1500

@onready var surface_world: Node2D = $SurfaceWorld
@onready var mine_world: Node2D = $MossveinMine
@onready var depth_world: Node2D = $RootwoundWorld
@onready var hub_world: Node2D = $HubWorld
@onready var deepheart_world: Node2D = $DeepheartWorld
@onready var endless_world: Node2D = $EndlessDescentWorld
@onready var source_label: Label = $HUD / TopPanel / Source
@onready var objective_label: Label = $HUD / TopPanel / Objective
@onready var gold_label: Label = $HUD / TopPanel / Gold
@onready var status_label: Label = $HUD / BottomPanel / Status
@onready var cargo_label: Label = $HUD / BottomPanel / Cargo
@onready var tool_label: Label = $HUD / BottomPanel / Tool
@onready var action_button: Button = $HUD / TouchControls / Action
@onready var mine_button: Button = $HUD / TouchControls / Mine
@onready var touch_controls: Control = $HUD / TouchControls
@onready var movement_pad: Control = $HUD / MovementPad
@onready var context_card: Panel = $HUD / ContextCard
@onready var context_card_title: Label = $HUD / ContextCard / Title
@onready var context_card_detail: Label = $HUD / ContextCard / Detail
@onready var context_card_hint: Label = $HUD / ContextCard / Hint
@onready var starforge_panel: Control = $HUD / StarforgePanel
@onready var menu_button: Button = $HUD / TopPanel / MenuButton
@onready var start_menu: Control = $HUD / StartMenu
@onready var continue_button: Button = $HUD / StartMenu / Card / Continue
@onready var new_game_button: Button = $HUD / StartMenu / Card / NewGame
@onready var menu_hint: Label = $HUD / StartMenu / Card / Hint
@onready var new_game_confirm: Control = $HUD / StartMenu / NewGameConfirm
@onready var keep_save_button: Button = $HUD / StartMenu / NewGameConfirm / Card / Cancel
@onready var confirm_new_game_button: Button = $HUD / StartMenu / NewGameConfirm / Card / Confirm
@onready var conclusion_overlay: Control = $HUD / ConclusionOverlay
@onready var conclusion_card: Panel = $HUD / ConclusionOverlay / Card
@onready var conclusion_stats: Label = $HUD / ConclusionOverlay / Card / Stats
@onready var conclusion_continue_button: Button = $HUD / ConclusionOverlay / Card / ContinueMining
@onready var conclusion_hub_button: Button = $HUD / ConclusionOverlay / Card / ReturnToHub
@onready var orientation_guard: Control = $HUD / OrientationGuard
@onready var starforge_buttons: = {
	"crusher": $HUD / StarforgePanel / Crusher,
	"swift": $HUD / StarforgePanel / Swift,
	"prospector": $HUD / StarforgePanel / Prospector,
}

var phase: = "surface"
var current_mine_id: = "mossMine"
var surface_context: = ""
var mine_exit_context: = false
var mine_depth_context: = false
var depth_context: = ""
var hub_context: = ""
var deepheart_context: = ""
var endless_context: = ""
var deepheart_hub_return_position: = Vector2(720, 300)
var endless_hub_return_position: = Vector2(720, 300)
var button_move: = Vector2.ZERO
var persistence_active: = false
var checkpoint_elapsed: = 0.0
var performance_qa_active: = false
var performance_qa_warmup: = 0.0
var performance_qa_elapsed: = 0.0
var performance_qa_frames: = 0
var performance_qa_mode: = "mossvein"
var menu_open: = false
var game_started: = false
var save_available: = false
var automated_mode: = false
var dev_build_active: = false
var web_storage_uncertain: = false
var premium_menu
var guide_overlay
var premium_hud
var workshop_panel
var commerce_panel
var station_transaction_fx
var resource_inventory
var achievement_toast
var minimap_overlay
var quick_tutorial
var developer_menu
var guide_director = GuideDirectorScript.new()
var inventory_open: = false
var tutorial_open: = false
var orientation_guard_active: = false
var guide_update_elapsed: = GUIDE_UPDATE_INTERVAL
var guide_route_update_count: = 0
var achievement_anchor_elapsed: = ACHIEVEMENT_ANCHOR_UPDATE_INTERVAL
var minimap_update_elapsed: = MINIMAP_UPDATE_INTERVAL
var mine_held: = false
var mine_touch_index: = -1
var mine_mouse_held: = false
var hud_refresh_pending: = false
var commerce_context: = ""
var commerce_transaction: Dictionary = {}
var commerce_fx_id: = -1
var commerce_fx_nonce: = 0
var commerce_presented_gold: = -1
var assay_auto_armed: = true
var commerce_confirm_close: = false


func _ready() -> void :
	var args: = OS.get_cmdline_user_args()
	var dev_qa_active: = "--qa-dev-tools" in args
	var visual_capture_active: = VISUAL_CAPTURE_SUITE_ARG in args
	# Visual capture is a QA mode, not a build flavor. Production captures must
	# exercise the production HUD and save namespace without a developer menu.
	dev_build_active = OS.has_feature(DEV_BUILD_FEATURE) or dev_qa_active
	if OS.has_feature("web"):
		web_storage_uncertain = not OS.is_userfs_persistent()
	automated_mode = visual_capture_active or _has_any_arg(args, ["--smoke-test", "--qa-input-release", "--qa-mine", "--qa-swing", "--qa-up", "--qa-camera", "--qa-performance", "--qa-surface-performance", "--qa-journey-performance", "--qa-barrier", "--qa-moss-overview", "--qa-surface-camp", "--qa-assay", "--qa-forge", "--qa-mine-entrance", "--qa-surface-decor", "--qa-gate", "--qa-gate-ready", "--qa-open-gate", "--qa-moon-surface", "--qa-moon-mine", "--qa-moon-resource", "--qa-ember-resource", "--qa-starfall-resource", "--qa-surface-mountain", "--qa-surface-mountain-damage", "--qa-surface-mountains", "--qa-moon-mountain", "--qa-ember-mountain", "--qa-starfall-mountain", "--qa-starforge", "--qa-crusher-impact", "--qa-rootwound", "--qa-rootwound-locked", "--qa-rootwound-performance", "--qa-depth-loop", "--qa-drill", "--qa-prismatic", "--qa-molten", "--qa-molten-performance", "--qa-voidstar", "--qa-hub", "--qa-deepheart", "--qa-endgame", "--qa-endless", "--qa-workshop-overlap", "--qa-workshop-panel", "--qa-commerce", "--qa-landscape", "--qa-iphone-layout", "--qa-portrait", "--qa-version-menu", "--qa-onboarding", "--qa-dev-tools", "--qa-build-flavor"])
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	if not automated_mode or dev_qa_active:
		var save_path: = DEV_QA_SAVE_PATH if dev_qa_active else DEV_SAVE_PATH if dev_build_active else RunState.DEFAULT_SAVE_PATH
		save_available = RunState.initialize_persistence(save_path)
		persistence_active = true
		surface_world.restore_ore_mountain_state()
	_apply_global_movement_speed()
	source_label.text = GameData.source_label()
	_install_premium_menu()
	_install_guide_overlay()
	_install_premium_hud()
	_install_workshop_panel()
	_install_commerce_panel()
	_install_station_transaction_fx()
	_install_minimap()
	_install_quick_tutorial()
	_install_resource_inventory()
	_install_achievement_toast()
	_install_developer_menu()
	_polish_asset_buttons()
	if dev_build_active:
		source_label.text += " · DEV"
		DisplayServer.window_set_title("Ever Deeper · DEV BUILD")
	if not _validate_release_version(args):
		return
	call_deferred("_apply_responsive_ui_layout")
	surface_world.context_changed.connect(_on_surface_context_changed)
	surface_world.message_changed.connect(_set_status)
	mine_world.exit_context_changed.connect(_on_mine_exit_context_changed)
	mine_world.depth_context_changed.connect(_on_mine_depth_context_changed)
	mine_world.depth_discovered.connect(_on_depth_discovered)
	mine_world.message_changed.connect(_set_status)
	depth_world.context_changed.connect(_on_depth_context_changed)
	depth_world.depth_exit_requested.connect(_exit_depth)
	depth_world.message_changed.connect(_set_status)
	depth_world.final_resource_mined.connect(_on_final_resource_mined)
	hub_world.context_changed.connect(_on_hub_context_changed)
	hub_world.workshop_panel_requested.connect(_on_workshop_panel_requested)
	hub_world.hub_exit_requested.connect(_exit_hub)
	hub_world.deep_elevator_checked.connect(_on_deep_elevator_checked)
	hub_world.message_changed.connect(_set_status)
	hub_world.runtime_state_changed.connect(_on_hub_runtime_state_changed)
	hub_world.module_activated.connect(_on_hub_module_activated)
	if hub_world.has_signal("deep_elevator_enter_requested"):
		hub_world.connect("deep_elevator_enter_requested", Callable(self, "_on_deep_elevator_enter_requested"))
	deepheart_world.context_changed.connect(_on_deepheart_context_changed)
	deepheart_world.message_changed.connect(_set_status)
	deepheart_world.exit_requested.connect(_exit_deepheart)
	deepheart_world.finale_completed.connect(_on_deepheart_finale_completed)
	_connect_optional_signal(endless_world, "context_changed", "_on_endless_context_changed")
	_connect_optional_signal(endless_world, "message_changed", "_set_status")
	_connect_optional_signal(endless_world, "depth_changed", "_on_endless_depth_changed")
	_connect_optional_signal(endless_world, "depth_change_requested", "_on_endless_depth_change_requested")
	_connect_optional_signal(endless_world, "hub_exit_requested", "_on_endless_hub_exit_requested")
	_connect_optional_signal(endless_world, "resource_collected", "_on_endless_resource_collected")
	_connect_optional_signal(endless_world, "discovery_found", "_on_endless_discovery_found")
	_connect_optional_signal(endless_world, "relic_discovered", "_on_endless_relic_discovered")
	_connect_optional_signal(endless_world, "relic_attached", "_on_endless_relic_attached")
	_connect_optional_signal(endless_world, "relic_hauled_to_hub", "_on_endless_relic_hauled_to_hub")
	_connect_optional_signal(endless_world, "rope_state_changed", "_on_endless_rope_state_changed")
	RunState.changed.connect(_queue_hud_refresh)
	RunState.resource_collected.connect(_on_resource_collected)


	AchievementService.evaluate()
	AchievementService.achievement_unlocked.connect(_on_achievement_unlocked)
	movement_pad.movement_changed.connect(_on_joystick_movement)
	mine_button.gui_input.connect(_on_mine_button_gui_input)
	mine_button.button_up.connect(_on_mine_button_up)
	mine_button.visibility_changed.connect(_on_mine_button_visibility_changed)
	action_button.pressed.connect(_perform_context)
	menu_button.pressed.connect(_open_start_menu)
	continue_button.pressed.connect(_continue_from_menu)
	new_game_button.pressed.connect(_request_new_game)
	keep_save_button.pressed.connect(_cancel_new_game)
	confirm_new_game_button.pressed.connect(_start_new_game)
	conclusion_continue_button.pressed.connect(_return_to_hub_from_conclusion)
	conclusion_hub_button.pressed.connect(_stay_in_deepheart_from_conclusion)
	for variant_id in STARFORGE_VARIANT_IDS:
		var button: Button = starforge_buttons[variant_id]
		button.pressed.connect(_on_starforge_choice.bind(variant_id))
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	conclusion_overlay.visible = false
	start_menu.visible = false
	status_label.get_parent().visible = false
	action_button.visible = false
	_refresh_hud()
	if "--qa-input-release" in args:
		surface_world.set_active(true)
		call_deferred("_run_input_release_qa")
	elif "--smoke-test" in args:
		surface_world.set_active(true)
		call_deferred("_run_smoke_test")
	elif "--qa-landscape" in args:
		call_deferred("_run_landscape_qa")
	elif "--qa-iphone-layout" in args:
		call_deferred("_run_iphone_layout_qa")
	elif "--qa-portrait" in args:
		call_deferred("_run_portrait_qa")
	elif "--qa-version-menu" in args:
		call_deferred("_start_qa_version_menu")
	elif "--qa-onboarding" in args:
		call_deferred("_run_onboarding_qa")
	elif _has_any_arg(args, ["--qa-mine", "--qa-swing", "--qa-up", "--qa-camera", "--qa-performance"]):
		surface_world.set_active(true)
		call_deferred("_start_qa_mine")
	elif "--qa-barrier" in args:
		call_deferred("_start_qa_barrier")
	elif "--qa-moss-overview" in args:
		call_deferred("_start_qa_moss_overview")
	elif "--qa-surface-camp" in args:
		call_deferred("_start_qa_surface_camp")
	elif "--qa-assay" in args:
		call_deferred("_start_qa_surface_context", "sell")
	elif "--qa-forge" in args:
		call_deferred("_start_qa_surface_context", "forge")
	elif "--qa-mine-entrance" in args:
		call_deferred("_start_qa_surface_context", "mine")
	elif "--qa-surface-decor" in args:
		call_deferred("_start_qa_surface_decor")
	elif "--qa-gate" in args:
		call_deferred("_start_qa_surface", "gate")
	elif "--qa-gate-ready" in args:
		call_deferred("_start_qa_surface", "gate_ready")
	elif "--qa-open-gate" in args:
		call_deferred("_start_qa_surface", "open_gate")
	elif "--qa-moon-surface" in args:
		call_deferred("_start_qa_surface", "moon_surface")
	elif "--qa-moon-mine" in args:
		call_deferred("_start_qa_surface", "moon_mine")
	elif "--qa-surface-performance" in args:
		call_deferred("_start_qa_surface_performance")
	elif "--qa-journey-performance" in args:
		call_deferred("_run_journey_performance_qa")
	elif "--qa-moon-resource" in args:
		call_deferred("_start_qa_moon_resource")
	elif "--qa-ember-resource" in args:
		call_deferred("_start_qa_surface_resource", "ember_fault")
	elif "--qa-starfall-resource" in args:
		call_deferred("_start_qa_surface_resource", "starfall_lattice")
	elif "--qa-surface-mountain" in args or "--qa-surface-mountain-damage" in args:
		call_deferred("_start_qa_surface_mountain", "--qa-surface-mountain-damage" in args)
	elif "--qa-surface-mountains" in args or "--qa-moon-mountain" in args:
		call_deferred("_start_qa_surface_mountains", "moonglass_mountain")
	elif "--qa-ember-mountain" in args:
		call_deferred("_start_qa_surface_mountains", "emberdeep_mountain")
	elif "--qa-starfall-mountain" in args:
		call_deferred("_start_qa_surface_mountains", "starfall_mountain")
	elif "--qa-starforge" in args:
		call_deferred("_start_qa_starforge")
	elif "--qa-crusher-impact" in args:
		call_deferred("_run_crusher_impact_qa")
	elif "--qa-rootwound-locked" in args:
		call_deferred("_start_qa_rootwound", "locked")
	elif "--qa-drill" in args:
		call_deferred("_start_qa_rootwound", "drill")
	elif "--qa-depth-loop" in args:
		call_deferred("_start_qa_rootwound", "loop")
	elif "--qa-rootwound-performance" in args:
		call_deferred("_start_qa_rootwound", "performance")
	elif "--qa-rootwound" in args:
		call_deferred("_start_qa_rootwound", "starforge")
	elif "--qa-prismatic" in args:
		call_deferred("_start_qa_prismatic")
	elif "--qa-molten-performance" in args:
		call_deferred("_start_qa_endgame_depth", "emberMine", 2, true)
	elif "--qa-molten" in args:
		call_deferred("_start_qa_endgame_depth", "emberMine", 2)
	elif "--qa-voidstar" in args:
		call_deferred("_start_qa_endgame_depth", "starMine", 3)
	elif "--qa-hub" in args:
		call_deferred("_start_qa_hub")
	elif "--qa-deepheart" in args:
		call_deferred("_start_qa_deepheart")
	elif "--qa-endgame" in args:
		call_deferred("_run_endgame_qa")
	elif "--qa-endless" in args:
		call_deferred("_run_endless_qa")
	elif "--qa-workshop-overlap" in args:
		call_deferred("_run_workshop_overlap_qa")
	elif "--qa-workshop-panel" in args:
		call_deferred("_run_workshop_panel_qa")
	elif "--qa-commerce" in args:
		call_deferred("_run_commerce_integration_qa")
	elif visual_capture_active:
		call_deferred("_start_visual_capture_suite")
	elif "--qa-dev-tools" in args:
		call_deferred("_run_dev_tools_qa")
	elif "--qa-build-flavor" in args:
		call_deferred("_run_build_flavor_qa")
	else:
		AudioDirector.set_environment("menu")
		_open_start_menu()
	call_deferred("_sync_orientation_guard")


func _process(delta: float) -> void :
	_update_station_transaction_targets()
	_enforce_shop_player_control()
	_maybe_start_assay_transaction()
	achievement_anchor_elapsed += maxf(0.0, delta)
	if achievement_anchor_elapsed >= ACHIEVEMENT_ANCHOR_UPDATE_INTERVAL:
		achievement_anchor_elapsed = fmod(achievement_anchor_elapsed, ACHIEVEMENT_ANCHOR_UPDATE_INTERVAL)
		_update_achievement_toast_anchor()
	minimap_update_elapsed += maxf(0.0, delta)
	if minimap_update_elapsed >= MINIMAP_UPDATE_INTERVAL:
		minimap_update_elapsed = fmod(minimap_update_elapsed, MINIMAP_UPDATE_INTERVAL)
		_update_minimap()
	if orientation_guard_active:
		if guide_overlay != null:
			guide_overlay.clear_target()
		return
	if performance_qa_active:
		performance_qa_warmup += delta
		if performance_qa_warmup < 1.0:
			return
		performance_qa_elapsed += delta
		performance_qa_frames += 1
		if performance_qa_elapsed >= 3.0:
			var average_fps: = float(performance_qa_frames) / performance_qa_elapsed
			var surface_detail: = ""
			if performance_qa_mode == "ember_surface":
				var surface_metrics: Dictionary = surface_world.mobile_performance_snapshot()
				var route_metrics: Dictionary = surface_world.route_steering_snapshot()
				assert (is_equal_approx(float(surface_metrics.dynamic_visual_hz), 30.0))
				assert (int(surface_metrics.dynamic_visual_updates) > 0)
				assert (int(surface_metrics.dynamic_visual_updates_skipped) > int(surface_metrics.dynamic_visual_updates))
				assert (int(route_metrics.events) > 0, "Surface performance QA must exercise soft route steering while moving")
				surface_detail = " dynamic_visuals=%d skipped=%d route_steers=%d" % [
					int(surface_metrics.dynamic_visual_updates),
					int(surface_metrics.dynamic_visual_updates_skipped),
					int(route_metrics.events),
				]
			print("EVER_DEEPER_PERFORMANCE_OK mode=%s average_fps=%.1f frames=%d redraw_interval=30 target=ray_aabb%s" % [performance_qa_mode, average_fps, performance_qa_frames, surface_detail])
			get_tree().quit(0)
			return
	if menu_open or inventory_open or conclusion_overlay.visible or _shop_panel_is_open():
		guide_overlay.clear_target()
		return
	if Input.is_action_just_pressed("interact"):
		_perform_context()
	if persistence_active:
		checkpoint_elapsed += delta
		if checkpoint_elapsed >= LOCATION_CHECKPOINT_INTERVAL:
			checkpoint_elapsed = fmod(checkpoint_elapsed, LOCATION_CHECKPOINT_INTERVAL)
			_checkpoint_location()




	guide_update_elapsed += maxf(0.0, delta)
	if guide_update_elapsed >= GUIDE_UPDATE_INTERVAL:
		guide_update_elapsed = fmod(guide_update_elapsed, GUIDE_UPDATE_INTERVAL)
		_update_visual_guide()


func _install_premium_menu() -> void :
	premium_menu = PremiumMenuScript.new()
	premium_menu.name = "PremiumMenu"
	$HUD.add_child(premium_menu)
	premium_menu.continue_requested.connect(_continue_from_menu)
	premium_menu.new_game_requested.connect(_request_new_game)
	premium_menu.new_game_confirmed.connect(_start_new_game)


func _install_developer_menu() -> void :
	if not dev_build_active:
		return
	var developer_menu_script: Script = load("res://scripts/dev/developer_menu.gd")
	if developer_menu_script == null:
		push_error("DEV build is missing scripts/dev/developer_menu.gd")
		return
	developer_menu = developer_menu_script.new()
	developer_menu.name = "DeveloperMenu"
	$HUD.add_child(developer_menu)
	developer_menu.command_requested.connect(_on_developer_command_requested)


func _start_visual_capture_suite() -> void :
	var driver_script: Script = load(VISUAL_CAPTURE_DRIVER_PATH)
	if driver_script == null:
		push_error("DEV visual capture driver is missing: %s" % VISUAL_CAPTURE_DRIVER_PATH)
		get_tree().quit(71)
		return
	var driver: Node = driver_script.new()
	driver.name = "VisualCaptureDriver"
	add_child(driver)
	driver.call_deferred("run", self)


func _on_developer_command_requested(command: String) -> void :
	if not dev_build_active:
		return
	_settle_commerce_before_world_change()
	var ok: = true
	var message: = "DEV ACTION COMPLETE"
	match command:
		"reset_dev":
			_start_new_game()
			message = "DEV SAVE RESET · FRESH SURFACE RUN"
		"preset_all_zones":
			_dev_start_clean_run()
			_dev_seed_all_zones_state()
			_dev_jump_surface()
			message = "ALL D1 + D2 ZONES UNLOCKED"
		"preset_hub":
			_dev_start_clean_run()
			_dev_seed_hub_state()
			ok = _dev_jump_hub()
			message = "HUB READY · SINGULARITY SECURED"
		"preset_deepheart":
			_dev_start_clean_run()
			_dev_seed_deepheart_state()
			ok = _dev_jump_deepheart()
			message = "DEEPHEART READY · FOUR SEALS WAIT"
		"preset_endless":
			_dev_start_clean_run()
			_dev_seed_victory_state()
			ok = _dev_jump_endless(1)
			message = "ENDLESS READY · LAYER 1"
		"jump_surface":
			_dev_jump_surface()
			message = "JUMPED TO SURFACE"
		"jump_hub":
			ok = _dev_jump_hub()
			message = "JUMPED TO BASE HUB"
		"jump_deepheart":
			ok = _dev_jump_deepheart()
			message = "JUMPED TO THE DEEPHEART"
		"jump_endless_1":
			ok = _dev_jump_endless(1)
			message = "JUMPED TO ENDLESS · LAYER 1"
		"jump_endless_12":
			ok = _dev_jump_endless(12)
			message = "JUMPED TO ENDLESS · LAYER 12"
		"grant_resources_200":
			_dev_grant_all_resources(200)
			message = "+200 OF EVERY RESOURCE"
		"grant_gold_10000":
			RunState.gold += 10000
			message = "+10 000 GOLD"
		"grant_max_tools":
			_dev_grant_max_tools_state()
			message = "MAX PICKAXE + DEEPCORE DRILL"
		"grant_all_relics":
			_dev_seed_victory_state()
			ok = _dev_grant_all_relics_state()
			if ok:
				ok = _dev_jump_hub()
			message = "ALL FIVE RELICS PLACED"
		"build_all_workshops":
			_dev_seed_victory_state()
			ok = _dev_build_all_workshops_state()
			if ok:
				ok = _dev_jump_hub()
			message = "ALL FIVE WORKSHOPS BUILT"
		_:
			if command.begins_with("jump_"):
				var jump_parts: = command.trim_prefix("jump_").split("_")
				if jump_parts.size() == 2 and String(jump_parts[0]) in MINE_IDS:
					var target_depth: = 2 if String(jump_parts[1]) == "d2" else 1
					ok = _dev_jump_mine(String(jump_parts[0]), target_depth)
					message = "JUMPED TO %s · D%d" % [_mine_name(String(jump_parts[0])).to_upper(), target_depth]
				else:
					ok = false
			else:
				ok = false
	if not ok:
		message = "DEV ACTION BLOCKED · RESET DEV SAVE AND TRY AGAIN"
	_apply_global_movement_speed()
	if phase == "hub":
		_sync_hub_runtime()
	_refresh_context_button()
	_refresh_hud()
	if persistence_active:
		_checkpoint_location()
		RunState.flush_save()
	if developer_menu != null and developer_menu.has_method("set_status"):
		developer_menu.set_status(message, not ok)


func _dev_start_clean_run() -> void :
	_start_new_game()
	_dev_ensure_playing()


func _dev_ensure_playing() -> void :
	if not game_started:
		game_started = true
		save_available = true
	if menu_open:
		_hide_start_menu()
	if inventory_open:
		_close_inventory()
	if quick_tutorial != null:
		quick_tutorial.dismiss()


func _dev_grant_max_tools_state() -> void :
	RunState.begin_state_batch()
	RunState.pickaxe_level = maxi(1, Array(GameData.data.PICKAXES).size() - 1)
	RunState.set_ember_mastery(maxi(0, Array(GameData.data.EMBER_MASTERY).size() - 1))
	for variant_id_value in STARFORGE_VARIANT_IDS:
		RunState.set_starforge_variant(String(variant_id_value))
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(maxi(0, Array(GameData.data.DRILLS).size() - 1))
	RunState.end_state_batch()


func _dev_seed_all_zones_state() -> void :
	_dev_grant_max_tools_state()
	RunState.begin_state_batch()
	for mine_id_value in MINE_IDS:
		var mine_id: = String(mine_id_value)
		RunState.unlock_world(String(WORLD_BY_MINE[mine_id]))
		RunState.mark_mine_discovered(mine_id)
		RunState.mark_depth_entrance_discovered(mine_id)
		RunState.enter_depth(mine_id)
	RunState.end_state_batch()


func _dev_seed_hub_state() -> void :
	_dev_seed_all_zones_state()
	if bool(RunState.singularity_secured):
		return
	RunState.set_location("starMine", Vector2(1704, 5160), 2)
	if int(RunState.mined.get("singularity", 0)) <= 0:
		RunState.record_mined("singularity", 1)
	RunState.secure_singularity("singularity")


func _dev_seed_deepheart_state() -> void :
	_dev_seed_hub_state()
	var elevator: = Dictionary(RunState.deep_elevator_status())
	var missing: = Dictionary(elevator.get("missing", {}))
	for resource_id_value in RunState.DEEP_ELEVATOR_RECIPE:
		var resource_id: = String(resource_id_value)
		var amount: = int(missing.get(resource_id, 0))
		if amount <= 0:
			continue
		RunState.add_resource(resource_id, amount, false)
		RunState.deliver_deep_elevator_material(resource_id, amount)
	RunState.power_deep_elevator()
	RunState.begin_final_expedition()


func _dev_seed_victory_state() -> void :
	_dev_seed_deepheart_state()
	if not bool(RunState.victory):
		for seal_id_value in RunState.DEEPHEART_SEAL_IDS:
			RunState.open_deepheart_seal(String(seal_id_value))
		RunState.complete_final_expedition()
	RunState.mark_conclusion_seen()


func _dev_grant_all_resources(amount: int) -> void :
	RunState.begin_state_batch()
	for resource_id_value in RunState.RESOURCE_IDS:
		RunState.add_resource(String(resource_id_value), amount, false)
	RunState.end_state_batch()


func _dev_jump_surface() -> void :
	_dev_ensure_playing()
	_dismiss_deepheart_conclusion(false)
	phase = "surface"
	current_mine_id = "mossMine"
	surface_context = ""
	mine_exit_context = false
	mine_depth_context = false
	depth_context = ""
	hub_context = ""
	deepheart_context = ""
	endless_context = ""
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	surface_world.restore_position(Vector2(RunState.last_surface_position))
	surface_world.set_active(true)
	AudioDirector.set_environment("surface")
	objective_label.text = _surface_objective()
	_set_status("DEV · Surface expedition")
	RunState.set_location("surface", surface_world.player.global_position)


func _dev_jump_mine(mine_id: String, target_depth: int) -> bool:
	if mine_id not in MINE_IDS or target_depth not in [1, 2]:
		return false
	_dev_ensure_playing()
	RunState.unlock_world(String(WORLD_BY_MINE[mine_id]))
	RunState.mark_mine_discovered(mine_id)
	if target_depth == 2:
		_dev_grant_max_tools_state()
		RunState.mark_depth_entrance_discovered(mine_id)
	_enter_mine(mine_id, false, false)
	if target_depth == 2:
		_enter_depth(false, false)
		if phase != "depth":
			return false
		RunState.set_location(mine_id, depth_world.player.global_position, 2)
	else:
		RunState.set_location(mine_id, mine_world.player.global_position, 1)
	_set_status("DEV · %s · Depth %d" % [_depth_name(mine_id) if target_depth == 2 else _mine_name(mine_id), target_depth])
	return true


func _dev_jump_hub() -> bool:
	_dev_ensure_playing()
	_dev_seed_hub_state()
	if not RunState.is_hub_unlocked():
		return false
	_enter_hub(false, false)
	hub_world.restore_position(Vector2(hub_world.entry_spawn()))
	RunState.set_location("hub", hub_world.player.global_position)
	_set_status("DEV · Base Hub ready")
	return phase == "hub"


func _dev_jump_deepheart() -> bool:
	_dev_ensure_playing()
	_dev_seed_deepheart_state()
	_enter_deepheart(false, false, false)
	if phase != "deepheart":
		return false
	RunState.set_location("deepheart", deepheart_world.player.global_position, 1)
	_set_status("DEV · Deepheart ready · awaken the four seals")
	return true


func _dev_jump_endless(target_depth: int) -> bool:
	if target_depth < 1:
		return false
	_dev_ensure_playing()
	_dev_seed_victory_state()
	var descent: = Dictionary(RunState.endless_descent_status())
	if not bool(descent.get("active", false)):
		_enter_endless(false, false, false)
	elif phase != "endless":
		_enter_endless(false, false, true)
	if phase != "endless" or not _dev_move_endless_state_to(target_depth):
		return false
	endless_world.load_depth(target_depth, "from_above")
	endless_world.set_active(true, false)
	endless_context = String(endless_world.current_context())
	objective_label.text = _endless_objective()
	RunState.set_location("endless", endless_world.player.global_position)
	_set_status("DEV · Endless Descent · Layer %d" % target_depth)
	return true


func _dev_move_endless_state_to(target_depth: int) -> bool:
	var status: = Dictionary(RunState.endless_descent_status())
	if not bool(status.get("active", false)):
		return false
	var current: = int(status.get("current_depth", 0))
	if absi(target_depth - current) > 512:
		return false
	var carried_id: = String(status.get("carried_relic_id", ""))
	if not carried_id.is_empty():
		RunState.attach_carried_relic(carried_id)
	while current != target_depth:
		var next_depth: = current + (1 if target_depth > current else -1)
		if not RunState.reach_endless_depth(next_depth):
			return false
		current = next_depth
	return true


func _dev_return_descent_to_hub_state() -> bool:
	var status: = Dictionary(RunState.endless_descent_status())
	if not bool(status.get("active", false)):
		return true
	var carried_id: = String(status.get("carried_relic_id", ""))
	if not carried_id.is_empty():
		RunState.attach_carried_relic(carried_id)
	if not _dev_move_endless_state_to(0):
		return false
	var returned: = Dictionary(RunState.leave_endless_descent_to_hub())
	if not bool(returned.get("ok", false)):
		return false
	return RunState.set_location("hub", Vector2(hub_world.entry_spawn()))


func _dev_grant_all_relics_state() -> bool:
	if not _dev_return_descent_to_hub_state():
		return false
	var carried: = String(Dictionary(RunState.endless_descent_status()).get("carried_relic_id", ""))
	if not carried.is_empty():
		RunState.set_location("hub", Vector2(hub_world.entry_spawn()))
		if not bool(Dictionary(RunState.place_carried_relic()).get("ok", false)):
			return false
	for relic_id_value in RunState.ENDLESS_RELIC_IDS:
		var relic_id: = String(relic_id_value)
		var relic: = Dictionary(RunState.relic_status(relic_id))
		if bool(relic.get("placed", false)):
			continue
		var started: = Dictionary(RunState.start_endless_descent())
		if not bool(started.get("ok", false)):
			return false
		var found_depth: = int(relic.get("found_depth", 0))
		if not bool(relic.get("discovered", false)):
			found_depth = int(started.get("depth", 1))
			if not RunState.discover_endless_relic(relic_id, found_depth):
				return false
		elif not _dev_move_endless_state_to(found_depth):
			return false
		if not bool(Dictionary(RunState.collect_endless_relic(relic_id, found_depth)).get("ok", false)):
			return false
		if not RunState.attach_carried_relic(relic_id):
			return false
		if not _dev_return_descent_to_hub_state():
			return false
		if not bool(Dictionary(RunState.place_carried_relic()).get("ok", false)):
			return false
	return true


func _dev_build_all_workshops_state() -> bool:
	if not _dev_grant_all_relics_state():
		return false
	for workshop_id_value in RunState.ENDLESS_WORKSHOP_IDS:
		var workshop_id: = String(workshop_id_value)
		var status: = Dictionary(RunState.workshop_status(workshop_id))
		if bool(status.get("built", false)):
			continue
		var resource_id: = String(status.get("build_resource", ""))
		var remaining: = int(status.get("remaining", 0))
		if resource_id.is_empty() or remaining <= 0:
			return false
		RunState.add_resource(resource_id, remaining, false)
		var delivered: = Dictionary(RunState.deliver_workshop_material(workshop_id, resource_id, remaining))
		if not bool(delivered.get("ok", false)):
			return false
		if not bool(Dictionary(RunState.build_workshop(workshop_id)).get("ok", false)):
			return false
	return true


func _run_dev_tools_qa() -> void :
	if not _dev_qa_require(dev_build_active, "feature_guard"):
		return
	if not _dev_qa_require(developer_menu != null, "menu_installed"):
		return
	if not _dev_qa_require(String(RunState.persistence_path()) == DEV_QA_SAVE_PATH, "isolated_save_path"):
		return
	var command_ids: PackedStringArray = developer_menu.command_ids()
	if not _dev_qa_require(command_ids.size() == 23 and command_ids.has("jump_starMine_d2"), "command_contract"):
		return
	var layout: = Dictionary(developer_menu.apply_iphone_layout_for_test(Vector2(932, 430)))
	if not _dev_qa_require(bool(layout.get("touch_targets_valid", false)), "iphone_touch_targets"):
		return
	if not _dev_qa_require(bool(layout.get("finger_scroll", false)), "iphone_finger_scroll"):
		return
	if not _dev_qa_require(int(layout.get("button_font_size", 0)) >= 13, "iphone_readable_text"):
		return
	developer_menu.open_menu()
	await get_tree().process_frame
	var dev_scroll: ScrollContainer = developer_menu.scroll
	var touch: = InputEventScreenTouch.new()
	touch.index = 3
	touch.pressed = true
	touch.position = dev_scroll.get_global_rect().get_center()
	developer_menu._input(touch)
	var drag: = InputEventScreenDrag.new()
	drag.index = 3
	drag.position = touch.position - Vector2(0, 80)
	drag.relative = Vector2(0, -80)
	developer_menu._input(drag)
	if not _dev_qa_require(dev_scroll.scroll_vertical > 0, "iphone_finger_drag_moves_content"):
		return
	developer_menu.close_menu()
	_on_developer_command_requested("preset_all_zones")
	if not _dev_qa_require(bool(RunState.fourth_unlocked) and RunState.is_depth_visited("starMine"), "all_zones_preset"):
		return
	_on_developer_command_requested("jump_moonMine_d2")
	if not _dev_qa_require(phase == "depth" and current_mine_id == "moonMine" and int(RunState.current_depth) == 2, "exact_depth_jump"):
		return
	_on_developer_command_requested("preset_hub")
	if not _dev_qa_require(phase == "hub" and bool(RunState.singularity_secured), "hub_preset"):
		return
	_on_developer_command_requested("preset_endless")
	_on_developer_command_requested("jump_endless_12")
	if not _dev_qa_require(phase == "endless" and int(Dictionary(RunState.endless_descent_status()).get("current_depth", 0)) == 12, "endless_layer_jump"):
		return
	_on_developer_command_requested("grant_all_relics")
	if not _dev_qa_require(int(Dictionary(RunState.endless_descent_status()).get("placed_relic_count", 0)) == RunState.ENDLESS_RELIC_IDS.size(), "all_relics"):
		return
	_on_developer_command_requested("build_all_workshops")
	if not _dev_qa_require(int(Dictionary(RunState.endless_descent_status()).get("built_workshop_count", 0)) == RunState.ENDLESS_WORKSHOP_IDS.size(), "all_workshops"):
		return
	_on_developer_command_requested("reset_dev")
	if not _dev_qa_require( not bool(RunState.victory) and int(RunState.gold) == 0, "dev_reset"):
		return
	for suffix in ["", ".tmp", ".bak"]:
		var path: = DEV_QA_SAVE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("EVER_DEEPER_DEV_TOOLS_QA_OK commands=23 isolated_save=true iphone=932x430 finger_scroll=true readable_text=true exact_depths=true relics=5 workshops=5")
	get_tree().quit(0)


func _dev_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	push_error("EVER_DEEPER_DEV_TOOLS_QA_FAIL step=%s" % step)
	get_tree().quit(1)
	return false


func _run_build_flavor_qa() -> void :
	var feature_enabled: = OS.has_feature(DEV_BUILD_FEATURE)
	var menu_present: = developer_menu != null
	var dev_resource_present: = ResourceLoader.exists("res://scripts/dev/developer_menu.gd")
	var user_dir_name: = String(ProjectSettings.get_setting_with_override("application/config/custom_user_dir_name"))
	var expected_user_dir: = (
		"Ever Deeper- Godot Development Port"
		if feature_enabled
		else "Ever Deeper- Godot Production Port"
	)
	var expected_save_path: = DEV_SAVE_PATH if feature_enabled else RunState.DEFAULT_SAVE_PATH
	var save_contract_valid: = (
		DEV_SAVE_PATH != RunState.DEFAULT_SAVE_PATH
		and expected_save_path == (DEV_SAVE_PATH if feature_enabled else RunState.DEFAULT_SAVE_PATH)
		and user_dir_name == expected_user_dir
	)
	if (
		feature_enabled != menu_present
		or feature_enabled != dev_resource_present
		or not save_contract_valid
	):
		push_error(
			"EVER_DEEPER_BUILD_FLAVOR_QA_FAIL feature=%s menu=%s resource=%s save=%s user_dir=%s"
			%[feature_enabled, menu_present, dev_resource_present, expected_save_path, user_dir_name]
		)
		get_tree().quit(1)
		return
	var user_dir_path: = String(OS.get_user_data_dir())
	print(
		"EVER_DEEPER_BUILD_FLAVOR_QA_OK flavor=%s menu=%s resource=%s save=%s user_dir=%s path=%s isolated=true"
		%[
			"dev" if feature_enabled else "production",
			menu_present,
			dev_resource_present,
			expected_save_path,
			user_dir_name,
			user_dir_path,
		]
	)
	get_tree().quit(0)


func _connect_optional_signal(source: Object, signal_name: String, method_name: String) -> void :
	if not is_instance_valid(source) or not source.has_signal(signal_name) or not has_method(method_name):
		return
	var callback: = Callable(self, method_name)
	if not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)


func _install_guide_overlay() -> void :
	guide_overlay = GuideOverlayScript.new()
	guide_overlay.name = "VisualGuide"
	$HUD.add_child(guide_overlay)


func _install_premium_hud() -> void :
	premium_hud = PremiumHudScript.new()
	premium_hud.name = "PremiumHud"
	$HUD.add_child(premium_hud)
	premium_hud.bag_requested.connect(_open_inventory)
	premium_hud.context_requested.connect(_perform_context)
	premium_hud.menu_requested.connect(_open_start_menu)
	premium_hud.build_button.visible = false
	premium_hud.build_button.disabled = true
	premium_hud.build_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _install_workshop_panel() -> void :
	workshop_panel = WorkshopPanelScript.new()
	workshop_panel.name = "WorkshopPanel"
	$HUD.add_child(workshop_panel)
	workshop_panel.action_confirmed.connect(_on_workshop_panel_action_confirmed)
	workshop_panel.preview_changed.connect(_on_workshop_panel_preview_changed)
	workshop_panel.closed.connect(_on_workshop_panel_closed)


func _install_commerce_panel() -> void :
	commerce_panel = CommercePanelScript.new()
	commerce_panel.name = "CommercePanel"
	$HUD.add_child(commerce_panel)
	commerce_panel.action_confirmed.connect(_on_commerce_action_confirmed)
	commerce_panel.selection_changed.connect(_on_commerce_selection_changed)
	commerce_panel.closed.connect(_on_commerce_closed)


func _install_station_transaction_fx() -> void :
	station_transaction_fx = StationTransactionFxScript.new()
	station_transaction_fx.name = "StationTransactionFx"
	station_transaction_fx.z_index = 58
	station_transaction_fx.default_gold_texture = load("res://assets/ui/gold-bars-v1.png")
	surface_world.add_child(station_transaction_fx)
	station_transaction_fx.gold_tick.connect(_on_commerce_gold_tick)
	station_transaction_fx.transaction_completed.connect(_on_station_transaction_completed)


func _workshop_panel_is_open() -> bool:
	return workshop_panel != null and workshop_panel.is_open()


func _commerce_panel_is_open() -> bool:
	return commerce_panel != null and commerce_panel.is_open()


func _shop_panel_is_open() -> bool:
	return _workshop_panel_is_open() or _commerce_panel_is_open()


func _install_minimap() -> void :
	minimap_overlay = MinimapOverlayScript.new()
	minimap_overlay.name = "Minimap"
	$HUD.add_child(minimap_overlay)
	minimap_overlay.hide_map()


func _install_quick_tutorial() -> void :
	quick_tutorial = QuickTutorialScript.new()
	quick_tutorial.name = "QuickTutorial"
	$HUD.add_child(quick_tutorial)
	quick_tutorial.closed.connect(_on_quick_tutorial_closed)


func _install_resource_inventory() -> void :
	resource_inventory = ResourceInventoryScript.new()
	resource_inventory.name = "ResourceInventory"
	$HUD.add_child(resource_inventory)
	resource_inventory.close_requested.connect(_close_inventory)
	resource_inventory.auto_sort_requested.connect(_auto_sort_inventory)


func _install_achievement_toast() -> void :
	achievement_toast = AchievementToastScript.new()
	achievement_toast.name = "AchievementToast"
	$HUD.add_child(achievement_toast)
	achievement_toast.activated.connect(_on_achievement_toast_activated)


func _polish_asset_buttons() -> void :
	for variant_id in STARFORGE_VARIANT_IDS:
		var button: Button = starforge_buttons[variant_id]
		button.icon = STARFORGE_BUTTON_ICONS[variant_id]
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_asset_button(button, 82)


func _style_asset_button(button: Button, icon_width: int) -> void :
	button.add_theme_constant_override("icon_max_width", icon_width)
	button.add_theme_constant_override("h_separation", 10)
	button.add_theme_stylebox_override("normal", _asset_button_style(Color(0.035, 0.085, 0.06, 0.58)))
	button.add_theme_stylebox_override("hover", _asset_button_style(Color(0.11, 0.19, 0.11, 0.76)))
	button.add_theme_stylebox_override("pressed", _asset_button_style(Color(0.18, 0.24, 0.1, 0.88)))
	button.add_theme_stylebox_override("disabled", _asset_button_style(Color(0.025, 0.045, 0.035, 0.42)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _asset_button_style(color: Color) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _open_inventory() -> void :
	if automated_mode or menu_open or inventory_open or conclusion_overlay.visible or _shop_panel_is_open() or not commerce_transaction.is_empty() or not game_started:
		return
	AudioDirector.play_ui("open")
	_cancel_held_input()
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	inventory_open = true
	resource_inventory.open_inventory(
		Dictionary(RunState.cargo),
		Dictionary(RunState.protected_progress_cargo()),
		phase == "hub"
	)
	if quick_tutorial != null:
		quick_tutorial.dismiss()
	guide_overlay.clear_target()


func _close_inventory() -> void :
	if not inventory_open:
		return
	AudioDirector.play_ui("cancel")
	inventory_open = false
	resource_inventory.close_inventory()
	_resume_current_phase()


func _auto_sort_inventory() -> void :
	if not inventory_open or phase != "hub":
		AudioDirector.play_blocked()
		return
	var moved: = RunState.auto_sort_resources(hub_world.player.global_position, "hub", 1)
	if moved > 0:
		AudioDirector.play_pickup("stone", moved)
		_set_status("Storage sorted · %d resources secured" % moved)
		_sync_hub_runtime()
	else:
		AudioDirector.play_blocked()
		_set_status("No nearby storage has room for sellable materials")
	resource_inventory.refresh_contents(
		Dictionary(RunState.cargo),
		Dictionary(RunState.protected_progress_cargo()),
		true
	)


func _update_visual_guide() -> void :
	if guide_overlay == null or menu_open or inventory_open or not game_started:
		return
	guide_route_update_count += 1
	var goal: Dictionary = guide_director.goal_for_state()
	if goal.is_empty():
		guide_director.reset()
		guide_overlay.clear_target()
		if premium_hud != null:
			premium_hud.set_objective("", "")
		return
	if premium_hud != null:
		premium_hud.set_objective(String(goal.get("title", "")), String(goal.get("detail", "")))
	var proposal: = _guide_route_proposal(goal)
	var resolved: Dictionary = guide_director.resolve(proposal)
	if resolved.is_empty() or String(resolved.get("target_key", "")).is_empty():
		guide_overlay.clear_target()
		return
	var camera: Camera2D
	var color: = Color("e9c86d")
	match phase:
		"surface":
			camera = surface_world.player.camera
		"mine":
			camera = mine_world.player.camera
			color = Color(String(GameData.mine(current_mine_id).detail))
		"depth":
			camera = depth_world.player.camera
			color = Color(String(Dictionary(GameData.data.MINE_DEPTH_PROFILES[current_mine_id]).detail))
		"hub":
			camera = hub_world.player.camera
		"deepheart":
			camera = deepheart_world.player.camera
			var seal_status: = Dictionary(RunState.deepheart_seal_status())
			var missing_seals: = Array(seal_status.get("missing", []))
			if not missing_seals.is_empty():
				color = Color(deepheart_world.SEAL_COLORS[String(missing_seals[0])])
		"endless":
			camera = endless_world.player.camera
			color = Color("8fe5bd")
	var target: = Vector2(resolved.get("target_position", Vector2.ZERO))
	if target == Vector2.ZERO or not is_instance_valid(camera):
		guide_overlay.clear_target()
	else:
		guide_overlay.set_world_target(camera, target, color)


func mobile_guide_performance_snapshot() -> Dictionary:
	return {
		"route_update_hz": 1.0 / GUIDE_UPDATE_INTERVAL,
		"route_updates": guide_route_update_count,
		"marker_redraw_hz": 30.0,
	}


func _guide_route_proposal(goal: Dictionary) -> Dictionary:
	var objective_id: = String(goal.get("objective_id", ""))
	var proposal: = {
		"objective_id": objective_id,
		"waypoint_id": "%s:%s" % [phase, objective_id],
		"title": String(goal.get("title", "")),
		"detail": String(goal.get("detail", "")),
		"candidates": [],
	}
	var kind: = String(goal.get("kind", ""))
	var target_mine: = String(goal.get("mine_id", "mossMine"))
	if target_mine.is_empty() or target_mine not in MINE_IDS:
		target_mine = "mossMine"
	match phase:
		"surface":
			proposal = _surface_guide_proposal(goal, proposal, kind, target_mine)
		"mine":
			proposal = _mine_guide_proposal(goal, proposal, kind, target_mine)
		"depth":
			proposal = _depth_guide_proposal(goal, proposal, kind, target_mine)
		"hub":
			if kind == "relic_place":
				proposal.waypoint_id = "hub:relic_pedestal"
				proposal.candidates = [_guide_candidate("hub:relic_pedestal", Vector2(hub_world.RELIC_PEDESTAL_POSITION), 0.0)]
			elif kind == "workshop":
				var workshop_id: = String(goal.get("station_id", ""))
				var workshop_positions: = Dictionary(hub_world.WORKSHOP_POSITIONS)
				if workshop_positions.has(workshop_id):
					proposal.waypoint_id = "hub:workshop:%s" % workshop_id
					proposal.candidates = [_guide_candidate("hub:workshop:%s" % workshop_id, Vector2(workshop_positions[workshop_id]), 0.0)]
			elif kind in ["hub_elevator", "deepheart", "endless_enter", "endless_resource", "endless_explore"]:
				proposal.waypoint_id = "hub:deep_elevator"
				proposal.candidates = [_guide_candidate("hub:deep_elevator", Vector2(hub_world.DEEP_ELEVATOR_POSITION), 0.0)]
			elif kind not in ["hub", "endless_return"]:
				proposal.waypoint_id = "hub:surface_lift"
				proposal.candidates = [_guide_candidate("hub:surface_lift", Vector2(hub_world.SURFACE_LIFT), 0.0)]
		"deepheart":
			proposal = _deepheart_guide_proposal(proposal)
		"endless":
			var target_kind: = ""
			if kind == "endless_return":
				target_kind = "up"
			elif kind == "endless_resource":
				target_kind = String(goal.get("resource_id", ""))
			elif kind == "endless_explore":
				target_kind = "relic"
			proposal.waypoint_id = "endless:%s" % (target_kind if not target_kind.is_empty() else "deeper")
			proposal.candidates = [_guide_candidate(proposal.waypoint_id, Vector2(endless_world.guide_target(target_kind)), 0.0)]
	return proposal


func _deepheart_guide_proposal(proposal: Dictionary) -> Dictionary:
	if bool(RunState.victory):
		proposal.waypoint_id = "deepheart:exit"
		proposal.candidates = [_guide_candidate("deepheart:exit", Vector2(deepheart_world.EXIT_POSITION), 0.0)]
		return proposal
	var seals: = Dictionary(RunState.deepheart_seal_status())
	var missing: = Array(seals.get("missing", []))
	if not missing.is_empty():
		var seal_id: = String(missing[0])
		proposal.waypoint_id = "deepheart:seal:%s" % seal_id
		proposal.candidates = [_guide_candidate(
			"deepheart:seal:%s" % seal_id,
			Vector2(deepheart_world.SEAL_POSITIONS[seal_id]),
			0.0
		)]
		return proposal
	proposal.waypoint_id = "deepheart:core"
	proposal.candidates = [_guide_candidate("deepheart:core", Vector2(deepheart_world.CORE_CONTEXT_POSITION), 0.0)]
	return proposal


func _surface_guide_proposal(goal: Dictionary, proposal: Dictionary, kind: String, target_mine: String) -> Dictionary:
	var station_id: = String(goal.get("station_id", ""))
	if kind in ["hub", "hub_elevator", "deepheart", "relic_place", "workshop", "endless_enter", "endless_return", "endless_resource", "endless_explore"]:
		proposal.waypoint_id = "surface:hub_entrance"
		proposal.candidates = [_guide_candidate("surface:hub_entrance", Vector2(4245, 650), 0.0)]
		return proposal
	if kind in ["station", "assay", "gate", "starforge"]:
		if kind == "assay":
			station_id = "sell"
		if not station_id.is_empty():
			var station_position: = _surface_station_guide_position(station_id)
			if station_position != Vector2.ZERO:
				proposal.waypoint_id = "surface:station:%s" % station_id
				proposal.candidates = [_guide_candidate("surface:station:%s" % station_id, station_position, 0.0)]
				return proposal
	var entrance: Dictionary = GameData.mine(target_mine).surfaceEntrance
	var entrance_position: = Vector2(float(entrance.x), float(entrance.y))
	proposal.waypoint_id = "surface:mine:%s" % target_mine
	proposal.candidates = [_guide_candidate("surface:mine:%s" % target_mine, entrance_position, 0.0)]
	return proposal


func _mine_guide_proposal(goal: Dictionary, proposal: Dictionary, kind: String, target_mine: String) -> Dictionary:
	var entrance: = Vector2(float(mine_world.mine.entrance.x), float(mine_world.mine.entrance.y))
	if target_mine != current_mine_id or kind in ["station", "assay", "gate", "starforge", "hub", "hub_elevator", "deepheart", "relic_place", "workshop", "endless_enter", "endless_return", "endless_resource", "endless_explore"]:
		proposal.waypoint_id = "mine:%s:exit" % current_mine_id
		proposal.candidates = [_guide_candidate("mine:%s:exit" % current_mine_id, entrance, 0.0)]
		return proposal
	if kind in ["depth_resource", "drill_forge"]:
		proposal.waypoint_id = "mine:%s:shaft" % current_mine_id
		proposal.candidates = [_guide_candidate("mine:%s:shaft" % current_mine_id, mine_world.depth_entrance, 0.0)]
		return proposal
	var requested_resource: = String(goal.get("resource_id", ""))
	proposal.waypoint_id = "mine:%s:resource:%s" % [current_mine_id, requested_resource]
	proposal.candidates = mine_world.guide_resource_candidates(requested_resource)
	return proposal


func _depth_guide_proposal(goal: Dictionary, proposal: Dictionary, kind: String, target_mine: String) -> Dictionary:
	if target_mine != current_mine_id or kind not in ["depth_resource", "drill_forge", "assay"]:
		proposal.waypoint_id = "depth:%s:exit" % current_mine_id
		proposal.candidates = [_guide_candidate("depth:%s:exit" % current_mine_id, depth_world.depth_entrance, 0.0)]
		return proposal
	if kind in ["drill_forge", "assay"]:
		var station_id: = "forge" if kind == "drill_forge" else "sell"
		var stations: = Dictionary(depth_world.get_station_positions())
		var position: = Vector2(stations.get(station_id, depth_world.depth_entrance))
		proposal.waypoint_id = "depth:%s:%s" % [current_mine_id, station_id]
		proposal.candidates = [_guide_candidate("depth:%s:%s" % [current_mine_id, station_id], position, 0.0)]
		return proposal
	var requested_resource: = String(goal.get("resource_id", ""))
	var all_candidates: Array[Dictionary] = []
	var matching_candidates: Array[Dictionary] = []
	for index in depth_world.rocks.size():
		var rock: = Dictionary(depth_world.rocks[index])
		if bool(rock.get("broken", false)):
			continue
		if int(rock.get("requires_drill_level", 0)) > int(RunState.drill_level):
			continue
		var position: = Vector2(rock.position)
		var key: = String(rock.get("deposit_id", "rock"))
		var candidate: = _guide_candidate(
			"depth:%s:%s:%d" % [current_mine_id, key, index],
			position,
			depth_world.player.global_position.distance_squared_to(position)
		)
		all_candidates.append(candidate)
		if requested_resource.is_empty() or String(rock.get("type", "")) == requested_resource:
			matching_candidates.append(candidate)
	proposal.waypoint_id = "depth:%s:resource:%s" % [current_mine_id, requested_resource]
	proposal.candidates = matching_candidates if not matching_candidates.is_empty() else all_candidates
	if Array(proposal.candidates).is_empty():
		proposal.waypoint_id = "depth:%s:exit" % current_mine_id
		proposal.candidates = [_guide_candidate("depth:%s:exit" % current_mine_id, depth_world.depth_entrance, 0.0)]
	return proposal


func _surface_station_guide_position(station_id: String) -> Vector2:
	if station_id in ["sell", "forge"]:
		return surface_world.station_interaction_position(station_id)
	if station_id == "hubEntrance":
		return Vector2(4245, 650)
	if station_id in ["gate", "emberGate", "starfallGate"]:
		return surface_world.gate_interaction_position(station_id)
	var station: Dictionary = GameData.station(station_id)
	if station.is_empty():
		return Vector2.ZERO
	return Vector2(float(station.x), float(station.y))


func _guide_candidate(key: String, position: Vector2, priority: float) -> Dictionary:
	return {"key": key, "position": position, "priority": priority}


func _surface_guide_target() -> Vector2:
	var mine_id: = "mossMine"
	var station_id: = ""
	if RunState.singularity_secured:
		return Vector2(4245, 650)
	if not RunState.area_unlocked:
		if int(RunState.pickaxe_level) < 3:
			var next_pickaxe: Dictionary = RunState.next_pickaxe()
			station_id = "forge" if not next_pickaxe.is_empty() and int(RunState.gold) >= int(next_pickaxe.cost) else ""
		else:
			station_id = "gate"
	elif not RunState.emberdeep_unlocked:
		mine_id = "moonMine"
		if int(RunState.pickaxe_level) >= 4:
			station_id = "emberGate"
	elif not RunState.fourth_unlocked:
		mine_id = "emberMine"
		if int(RunState.ember_mastery) >= 5:
			station_id = "starfallGate"
	elif String(RunState.starforge_variant).is_empty():
		mine_id = "starMine"
		if int(RunState.cargo.get("astralite", 0)) >= 200 and int(RunState.cargo.get("crownstone", 0)) >= 200:
			station_id = "starforge"
	elif RunState.hub_tutorial_pending():
		return Vector2(4245, 650)
	elif not RunState.is_depth_entrance_discovered("mossMine") or int(RunState.drill_level) <= 0:
		mine_id = "mossMine"
	else:
		var drill_status: Dictionary = RunState.drill_upgrade_status()
		var missing: Array = Array(drill_status.get("missing", []))
		if not missing.is_empty():
			mine_id = String(Dictionary(missing[0]).get("scene", "mossMine"))
		elif int(drill_status.get("missing_gold", 0)) > 0:
			station_id = "sell"
		elif bool(drill_status.get("ready", false)):
			mine_id = String(RunState.drill_goal_scene) if not String(RunState.drill_goal_scene).is_empty() else "mossMine"
		else:
			mine_id = "starMine"
	if not station_id.is_empty():
		if station_id in ["sell", "forge"]:
			return surface_world.station_interaction_position(station_id)
		var station: Dictionary = GameData.station(station_id)
		return Vector2(float(station.x), float(station.y))
	var entrance: Dictionary = GameData.mine(mine_id).surfaceEntrance
	return Vector2(float(entrance.x), float(entrance.y))


func _current_depth_guide_resource() -> String:
	if RunState.singularity_secured:
		return ""
	var status: Dictionary = RunState.drill_upgrade_status()
	var missing: Array = Array(status.get("missing", []))
	for value in missing:
		var requirement: = Dictionary(value)
		if String(requirement.get("scene", "")) == current_mine_id:
			return String(requirement.get("type", ""))
	if current_mine_id == "starMine" and int(RunState.drill_level) >= 3:
		return "singularity"
	return ""


func _input(event: InputEvent) -> void :
	if event is InputEventScreenTouch:
		var touch: = event as InputEventScreenTouch
		if touch.index == mine_touch_index and ( not touch.pressed or touch.canceled):
			_cancel_mine_hold()
	elif event is InputEventMouseButton:
		var mouse_button: = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed and mine_mouse_held:
			_cancel_mine_hold()


func _unhandled_input(event: InputEvent) -> void :
	if orientation_guard_active:
		get_viewport().set_input_as_handled()
		return
	if _commerce_panel_is_open():
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			commerce_panel.close_commerce()
		return
	if _workshop_panel_is_open():
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			workshop_panel.close_workshop()
		return
	if conclusion_overlay.visible:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_stay_in_deepheart_from_conclusion()
		return
	if automated_mode:
		return
	if inventory_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_inventory()
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if new_game_confirm.visible:
		new_game_confirm.visible = false
		AudioDirector.play_ui("cancel")
	elif menu_open:
		if game_started:
			AudioDirector.play_ui("cancel")
			_continue_from_menu()
	elif game_started:
		_open_start_menu()


func _open_start_menu() -> void :
	if automated_mode or menu_open or conclusion_overlay.visible or _shop_panel_is_open() or not commerce_transaction.is_empty():
		return
	if game_started:
		AudioDirector.play_ui("open")
	AudioDirector.set_environment("menu")
	if game_started and persistence_active:
		_checkpoint_location()
		RunState.flush_save()
		save_available = true
	_cancel_mine_hold()
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	if quick_tutorial != null:
		quick_tutorial.dismiss()
	menu_open = true
	new_game_confirm.visible = false
	_refresh_start_menu()
	start_menu.visible = false
	premium_menu.modulate.a = 0.0
	premium_menu.open_menu(save_available or game_started, _menu_location_label(), game_started, web_storage_uncertain)
	var tween: = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(premium_menu, "modulate:a", 1.0, 0.18)


func _refresh_start_menu() -> void :
	var can_continue: = save_available or game_started
	continue_button.disabled = not can_continue
	menu_hint.text = (
		"PROGRESS MAY NOT SURVIVE A CLOSED TAB\nIN THIS BROWSER"
		if web_storage_uncertain
		else "YOUR EXPEDITION SAVES AUTOMATICALLY\nUSE MENU ANY TIME TO PAUSE"
	)
	if can_continue:
		continue_button.text = "CONTINUE\n%s" % _menu_location_label()
	elif String(RunState.last_load_status) == "corrupt":
		continue_button.text = "CONTINUE\nSAVE COULD NOT BE READ"
	else:
		continue_button.text = "CONTINUE\nNO EXPEDITION FOUND"


func _menu_location_label() -> String:
	if String(RunState.current_scene) == "endless":
		return "ENDLESS DESCENT · LAYER %d" % int(Dictionary(RunState.endless_descent_status()).get("current_depth", 1))
	if String(RunState.current_scene) == "deepheart":
		return "THE DEEPHEART"
	if String(RunState.current_scene) == "hub":
		return "BASE HUB"
	if int(RunState.current_depth) == 2:
		var depth_scene: = String(RunState.current_scene)
		if depth_scene in MINE_IDS:
			return _depth_name(depth_scene)
	var scene: = String(RunState.current_scene)
	if scene in MINE_IDS:
		return String(GameData.mine(scene).name).to_upper()
	return "SURFACE EXPEDITION"


func _continue_from_menu() -> void :
	if not (save_available or game_started):
		return
	AudioDirector.play_ui("confirm")
	new_game_confirm.visible = false
	_hide_start_menu()
	if not game_started:
		game_started = true
		_restore_saved_location()
	else:
		_resume_current_phase()
	call_deferred("_maybe_show_quick_tutorial")


func _hide_start_menu() -> void :
	menu_open = false
	start_menu.visible = false
	start_menu.modulate.a = 1.0
	if premium_menu != null:
		premium_menu.close_menu()
		premium_menu.modulate.a = 1.0


func _resume_current_phase() -> void :
	if orientation_guard_active:
		_pause_all_worlds_for_orientation()
		return
	match phase:
		"mine":
			mine_world.set_active(true, false)
		"depth":
			depth_world.set_active(true, false)
		"hub":
			hub_world.set_active(true, false)
		"deepheart":
			deepheart_world.set_active(true, false)
		"endless":
			endless_world.set_active(true, false)
		_:
			surface_world.set_active(true)
	AudioDirector.set_environment("deepheart" if phase == "deepheart" else "depth" if phase in ["depth", "endless"] else "mine" if phase == "mine" else "hub" if phase == "hub" else "surface")
	_enforce_shop_player_control()
	_refresh_context_button()
	_refresh_hud()


func _request_new_game() -> void :
	if save_available or game_started:
		AudioDirector.play_ui("open")
		if premium_menu != null:
			premium_menu.show_new_game_confirmation()
		else:
			new_game_confirm.visible = true
			keep_save_button.grab_focus()
		return
	_start_new_game()


func _cancel_new_game() -> void :
	new_game_confirm.visible = false
	if premium_menu != null and premium_menu.is_confirming():
		premium_menu.cancel_confirmation()
		return
	AudioDirector.play_ui("cancel")


func _start_new_game() -> void :
	_settle_commerce_before_world_change()
	AudioDirector.play_ui("confirm")
	AudioDirector.set_environment("surface")
	_dismiss_deepheart_conclusion(false)
	new_game_confirm.visible = false
	RunState.start_new_run()
	deepheart_world.reset_runtime_state()
	if endless_world.has_method("import_runtime_state"):
		endless_world.import_runtime_state({
			"depth": 0, "arrival": "from_above",
			"session_mined_nodes": {}, "session_discovered_sites": {},
			"rope_attached": false, "carried_relic_id": "",
			"carried_relic_discovery_depth": -1,
		})
	_apply_global_movement_speed()
	save_available = true
	game_started = true
	phase = "surface"
	current_mine_id = "mossMine"
	surface_context = ""
	mine_exit_context = false
	mine_depth_context = false
	depth_context = ""
	hub_context = ""
	deepheart_context = ""
	endless_context = ""
	guide_director.reset()
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	surface_world.reset_for_new_run()
	mine_world.load_mine("mossMine")
	depth_world.use_deterministic_depth_entrance()
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	_hide_start_menu()
	surface_world.set_active(true)
	objective_label.text = _surface_objective()
	_set_status("A fresh expedition begins · follow the lower road")
	_refresh_hud()
	RunState.set_location("surface", surface_world.player.global_position)
	RunState.flush_save()
	call_deferred("_maybe_show_quick_tutorial")


func _maybe_show_quick_tutorial() -> void :
	if automated_mode or tutorial_open or quick_tutorial == null or quick_tutorial.has_been_seen():
		return
	tutorial_open = true
	quick_tutorial.open(DisplayServer.is_touchscreen_available())


func _on_quick_tutorial_closed() -> void :
	tutorial_open = false


func _update_minimap() -> void :
	if minimap_overlay == null:
		return
	if not game_started or menu_open or inventory_open or conclusion_overlay.visible or orientation_guard_active:
		minimap_overlay.hide_map()
		return
	var active_player: Node2D = _active_player_node()
	if not is_instance_valid(active_player):
		minimap_overlay.hide_map()
		return
	var world_size: Vector2 = Vector2(surface_world._world_size())
	var location_name: String = "SURFACE"
	match phase:
		"mine":
			world_size = Vector2(mine_world.world_size)
			location_name = _mine_name(current_mine_id)
		"depth":
			world_size = Vector2(depth_world.world_size)
			location_name = _depth_name(current_mine_id)
		"hub":
			world_size = Vector2(hub_world.WORLD_SIZE)
			location_name = "BASE HUB"
		"deepheart":
			world_size = Vector2(deepheart_world.WORLD_SIZE)
			location_name = "THE DEEPHEART"
		"endless":
			world_size = Vector2(endless_world.WORLD_SIZE)
			location_name = "ENDLESS · LAYER %d" % int(Dictionary(RunState.endless_descent_status()).get("current_depth", 1))
	var camera: Camera2D = active_player.camera
	if not is_instance_valid(camera):
		minimap_overlay.hide_map()
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var zoom: Vector2 = Vector2(maxf(absf(camera.zoom.x), 0.001), maxf(absf(camera.zoom.y), 0.001))
	var view_size: Vector2 = viewport_size / zoom
	var view_rect: Rect2 = Rect2(camera.get_screen_center_position() - view_size * 0.5, view_size)
	var objective_position: Vector2 = Vector2.ZERO
	var has_objective: bool = guide_overlay != null and guide_overlay.has_target and guide_overlay.target_camera == camera
	if has_objective:
		objective_position = Vector2(guide_overlay.target_world)
	minimap_overlay.set_snapshot(
		phase,
		location_name,
		active_player.global_position,
		Rect2(Vector2.ZERO, world_size),
		view_rect,
		objective_position,
		has_objective
	)


func _cancel_held_input() -> void :
	_cancel_mine_hold()
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()


func _on_viewport_size_changed() -> void :
	_sync_orientation_guard()
	call_deferred("_apply_responsive_ui_layout")


func _apply_responsive_ui_layout(size_override: Vector2 = Vector2.ZERO) -> void :
	var viewport_size: Vector2 = size_override if size_override != Vector2.ZERO else get_viewport().get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	_layout_touch_actions(viewport_size)
	_layout_starforge_panel(viewport_size)
	_layout_conclusion(viewport_size)
	_layout_orientation_guard(viewport_size)


func _layout_touch_actions(viewport_size: Vector2) -> void :
	var iphone: = _is_iphone_landscape(viewport_size)
	_place_control(touch_controls, Rect2(Vector2.ZERO, viewport_size))
	if iphone:
		var mine_rect: = _iphone_layout_metrics(viewport_size).mine as Rect2
		_place_control(mine_button, mine_rect)
		_place_control(action_button, Rect2(mine_rect.position.x - 258, mine_rect.position.y + 19, 238, 86))
		mine_button.custom_minimum_size = mine_rect.size
		mine_button.add_theme_constant_override("icon_max_width", 144)
		action_button.custom_minimum_size = Vector2(238, 86)
		action_button.add_theme_font_size_override("font_size", 20)
	else:
		_place_control(mine_button, Rect2(viewport_size.x - 128, viewport_size.y - 200, 112, 112))
		_place_control(action_button, Rect2(viewport_size.x - 228, viewport_size.y - 255, 212, 58))
		mine_button.custom_minimum_size = Vector2(112, 112)
		mine_button.add_theme_constant_override("icon_max_width", 104)
		action_button.custom_minimum_size = Vector2(212, 58)
		action_button.add_theme_font_size_override("font_size", 12)


func _layout_starforge_panel(viewport_size: Vector2) -> void :
	var iphone: = _is_iphone_landscape(viewport_size)
	if iphone:
		var rect: Rect2 = _iphone_layout_metrics(viewport_size).starforge as Rect2
		_place_control(starforge_panel, rect)
		var title: Label = starforge_panel.get_node("Title") as Label
		var cost: Label = starforge_panel.get_node("Cost") as Label
		_place_control(title, Rect2(18, 8, rect.size.x - 36, 30))
		_place_control(cost, Rect2(18, 38, rect.size.x - 36, 26))
		title.add_theme_font_size_override("font_size", 21)
		cost.add_theme_font_size_override("font_size", 15)
		var gap: = 14.0
		var button_width: = (rect.size.x - 36.0 - gap * 2.0) / 3.0
		for index in STARFORGE_VARIANT_IDS.size():
			var button: Button = starforge_buttons[STARFORGE_VARIANT_IDS[index]]
			_place_control(button, Rect2(18 + index * (button_width + gap), 74, button_width, 96))
			button.custom_minimum_size.y = 96
			button.add_theme_font_size_override("font_size", 20)
	else:
		_place_control(starforge_panel, Rect2((viewport_size.x - 720) * 0.5, viewport_size.y - 172, 720, 148))
		var design_rects: = [Rect2(12, 54, 212, 82), Rect2(254, 54, 212, 82), Rect2(496, 54, 212, 82)]
		for index in STARFORGE_VARIANT_IDS.size():
			var button: Button = starforge_buttons[STARFORGE_VARIANT_IDS[index]]
			_place_control(button, design_rects[index])
			button.custom_minimum_size.y = 82
			button.add_theme_font_size_override("font_size", 8)


func _layout_conclusion(viewport_size: Vector2) -> void :
	var iphone: = _is_iphone_landscape(viewport_size)
	if not iphone:
		_place_control(conclusion_card, Rect2((viewport_size.x - 374) * 0.5, (viewport_size.y - 552) * 0.5, 374, 552))
		return
	var rect: Rect2 = _iphone_layout_metrics(viewport_size).conclusion as Rect2
	_place_control(conclusion_card, rect)
	var kicker: Label = conclusion_card.get_node("Kicker") as Label
	var title: Label = conclusion_card.get_node("Title") as Label
	var awakened: Label = conclusion_card.get_node("Awakened") as Label
	var divider: ColorRect = conclusion_card.get_node("Divider") as ColorRect
	var epilogue: Label = conclusion_card.get_node("Epilogue") as Label
	var worlds: Label = conclusion_card.get_node("Worlds") as Label
	var legacy: Label = conclusion_card.get_node("Legacy") as Label
	_place_control(kicker, Rect2(34, 24, 500, 28))
	_place_control(title, Rect2(34, 58, 500, 54))
	_place_control(awakened, Rect2(34, 116, 500, 32))
	_place_control(divider, Rect2(58, 166, 452, 2))
	_place_control(epilogue, Rect2(42, 184, 484, 116))
	_place_control(worlds, Rect2(34, 310, 500, 42))
	_place_control(legacy, Rect2(34, 384, 500, 48))
	_place_control(conclusion_stats, Rect2(596, 70, 480, 190))
	_place_control(conclusion_continue_button, Rect2(596, 294, 480, 98))
	_place_control(conclusion_hub_button, Rect2(596, 414, 480, 82))
	kicker.add_theme_font_size_override("font_size", 17)
	title.add_theme_font_size_override("font_size", 36)
	awakened.add_theme_font_size_override("font_size", 20)
	epilogue.add_theme_font_size_override("font_size", 19)
	worlds.add_theme_font_size_override("font_size", 17)
	legacy.add_theme_font_size_override("font_size", 15)
	conclusion_stats.add_theme_font_size_override("font_size", 20)
	conclusion_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	conclusion_continue_button.custom_minimum_size.y = 98
	conclusion_continue_button.add_theme_font_size_override("font_size", 23)
	conclusion_hub_button.custom_minimum_size.y = 82
	conclusion_hub_button.add_theme_font_size_override("font_size", 20)


func _layout_orientation_guard(viewport_size: Vector2) -> void :
	if viewport_size.y <= viewport_size.x:
		return
	var card: Panel = orientation_guard.get_node("Card") as Panel
	var card_size: = Vector2(minf(1080.0, viewport_size.x - 120.0), 720)
	_place_control(card, Rect2((viewport_size - card_size) * 0.5, card_size))
	var kicker: Label = card.get_node("Kicker") as Label
	var phone: Panel = card.get_node("Phone") as Panel
	var title: Label = card.get_node("Title") as Label
	var rule: ColorRect = card.get_node("Rule") as ColorRect
	var message: Label = card.get_node("Message") as Label
	var paused: Label = card.get_node("Paused") as Label
	_place_control(kicker, Rect2(50, 34, card_size.x - 100, 50))
	_place_control(phone, Rect2((card_size.x - 300) * 0.5, 112, 100, 58))
	phone.scale = Vector2(3, 3)
	_place_control(title, Rect2(40, 330, card_size.x - 80, 74))
	_place_control(rule, Rect2(130, 420, card_size.x - 260, 3))
	_place_control(message, Rect2(80, 448, card_size.x - 160, 100))
	_place_control(paused, Rect2(80, 600, card_size.x - 160, 48))
	kicker.add_theme_font_size_override("font_size", 28)
	title.add_theme_font_size_override("font_size", 48)
	message.add_theme_font_size_override("font_size", 31)
	paused.add_theme_font_size_override("font_size", 23)


func _iphone_layout_metrics(viewport_size: Vector2) -> Dictionary:
	var right: = 116.0
	var bottom: = 42.0
	var mine_size: = Vector2(154, 154)
	return {
		"safe_rect": Rect2(110, 18, viewport_size.x - 220, viewport_size.y - 60),
		"mine": Rect2(viewport_size.x - right - mine_size.x, viewport_size.y - bottom - mine_size.y, mine_size.x, mine_size.y),
		"starforge": Rect2((viewport_size.x - 1020) * 0.5, viewport_size.y - bottom - 190, 1020, 190),
		"conclusion": Rect2((viewport_size.x - 1120) * 0.5, (viewport_size.y - 520) * 0.5, 1120, 520),
	}


func _is_iphone_landscape(viewport_size: Vector2) -> bool:
	return viewport_size.x > viewport_size.y and viewport_size.x / maxf(viewport_size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT


func _place_control(control: Control, rect: Rect2) -> void :
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y


func _sync_orientation_guard(size_override: Vector2 = Vector2.ZERO, force_for_test: bool = false) -> void :


	if automated_mode and not force_for_test:
		return
	var viewport_size: = size_override
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport().get_visible_rect().size
	if viewport_size.x < 2.0 or viewport_size.y < 2.0:
		return


	if is_equal_approx(viewport_size.x, viewport_size.y):
		return
	_set_orientation_guard_active(viewport_size.y > viewport_size.x)


func _set_orientation_guard_active(active: bool) -> void :
	if orientation_guard_active == active:
		return
	orientation_guard_active = active
	orientation_guard.visible = active
	if active:
		_cancel_held_input()
		_pause_all_worlds_for_orientation()
		if guide_overlay != null:
			guide_overlay.clear_target()
		orientation_guard.grab_focus()
		return

	orientation_guard.release_focus()
	if conclusion_overlay.visible:
		conclusion_continue_button.grab_focus()
		return
	if inventory_open:
		var inventory_close: = resource_inventory.get_node_or_null("Card/Layout/Header/Close") as Button
		if inventory_close != null:
			inventory_close.grab_focus()
		return
	if menu_open:
		if premium_menu != null and premium_menu.continue_button != null:
			premium_menu.continue_button.grab_focus()
		return
	if _commerce_panel_is_open():
		_resume_current_phase()
		if commerce_panel.primary_button != null and not commerce_panel.primary_button.disabled:
			commerce_panel.primary_button.grab_focus()
		elif commerce_panel.cancel_button != null:
			commerce_panel.cancel_button.grab_focus()
		return
	if game_started:
		_resume_current_phase()


func _pause_all_worlds_for_orientation() -> void :
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)


func _notification(what: int) -> void :
	if not is_node_ready():
		return
	var loses_input: = what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST]
	if loses_input:
		_cancel_held_input()
	if not persistence_active:
		return
	if loses_input and game_started:
		_checkpoint_location()
		RunState.flush_save()


func _restore_saved_location() -> void :


	_dismiss_deepheart_conclusion(false)
	var saved_scene: = String(RunState.current_scene)
	if saved_scene == "endless" and bool(Dictionary(RunState.endless_descent_status()).get("active", false)):
		_enter_endless(false, false, true)
		endless_world.restore_position(Vector2(RunState.current_position))
		endless_context = String(endless_world.current_context())
		_set_status(_endless_progress_text())
		_refresh_context_button()
		return
	if saved_scene == "deepheart":
		_enter_deepheart(false, false, true)
		_restore_deepheart_position(Vector2(RunState.current_position))
		if bool(RunState.victory):
			if not bool(RunState.conclusion_seen):
				_open_deepheart_conclusion()
			else:
				_set_status("%s · return to the Hub when ready" % _deep_hoard_status_text())
		else:
			_set_status("Deepheart restored · the current resonance still waits")
		return
	if saved_scene == "hub" and bool(Dictionary(RunState.hub).get("unlocked", false)):
		_enter_hub(false, false)
		hub_world.restore_position(Vector2(RunState.current_position))
		_set_status(_deep_hoard_status_text() if bool(RunState.victory) else "Base restored · your expedition remains intact")
		return
	if saved_scene in MINE_IDS and _mine_is_unlocked(saved_scene):
		_enter_mine(saved_scene, false, false)
		if int(RunState.current_depth) == 2 and RunState.is_depth_entrance_discovered(saved_scene) and RunState.is_depth_visited(saved_scene):
			_enter_depth(false, false)
			depth_world.restore_position(Vector2(RunState.current_position))
			_set_status("Run restored · %s" % _depth_name(saved_scene).capitalize())
		else:
			mine_world.restore_position(Vector2(RunState.current_position))
			_set_status("Run restored · %s" % String(GameData.mine(saved_scene).name).capitalize())
		return
	phase = "surface"
	surface_world.set_active(true)
	AudioDirector.set_environment("surface")
	mine_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	surface_world.restore_position(Vector2(RunState.last_surface_position))
	objective_label.text = _surface_objective()
	_set_status("Progress restored · follow the road deeper")
	_refresh_context_button()


func _bind_move_button(button: Button, direction: Vector2) -> void :
	button.button_down.connect( func():
		button_move += direction
		_apply_button_movement()
	)
	button.button_up.connect( func():
		button_move -= direction
		_apply_button_movement()
	)


func _apply_button_movement() -> void :
	surface_world.player.set_external_movement(button_move)
	mine_world.player.set_external_movement(button_move)
	depth_world.set_external_movement(button_move)
	hub_world.set_external_movement(button_move)
	deepheart_world.player.set_external_movement(button_move)
	endless_world.set_external_movement(button_move)


func _apply_global_movement_speed() -> void :
	var multiplier: = RunState.movement_speed_multiplier()
	var speed: = float(GameData.data.PLAYER_SPEED) * multiplier
	surface_world.player.movement_speed = speed
	mine_world.player.movement_speed = speed
	depth_world.player.movement_speed = speed
	hub_world.set_movement_speed_multiplier(multiplier)
	deepheart_world.player.movement_speed = speed
	endless_world.player.movement_speed = speed


func _set_mine_held(held: bool) -> void :
	mine_held = held
	surface_world.set_mine_held(held if phase == "surface" else false)
	mine_world.set_mine_held(held if phase == "mine" else false)
	depth_world.set_mine_held(held if phase == "depth" else false)
	deepheart_world.set_mine_held(held if phase == "deepheart" else false)
	endless_world.set_mine_held(held if phase == "endless" else false)


func _cancel_mine_hold() -> void :
	mine_touch_index = -1
	mine_mouse_held = false
	_set_mine_held(false)


func _on_mine_button_gui_input(event: InputEvent) -> void :
	if event is InputEventScreenTouch:
		var touch: = event as InputEventScreenTouch
		if touch.index == mine_touch_index and ( not touch.pressed or touch.canceled):
			_cancel_mine_hold()
		elif touch.pressed and not touch.canceled and mine_touch_index < 0 and not mine_mouse_held:
			mine_touch_index = touch.index
			_set_mine_held(true)
	elif event is InputEventMouseButton:
		var mouse_button: = event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT or mine_touch_index >= 0:
			return
		if mouse_button.pressed and not mine_mouse_held:
			mine_mouse_held = true
			_set_mine_held(true)
		elif not mouse_button.pressed and mine_mouse_held:
			_cancel_mine_hold()


func _on_mine_button_up() -> void :
	_cancel_mine_hold()


func _on_mine_button_visibility_changed() -> void :
	if not mine_button.is_visible_in_tree():
		_cancel_mine_hold()


func _on_joystick_movement(direction: Vector2) -> void :
	if _shop_panel_is_open():
		button_move = Vector2.ZERO
		_apply_button_movement()
		return
	button_move = direction
	_apply_button_movement()


func _on_surface_context_changed(context: String) -> void :
	surface_context = context
	if context != "sell":
		assay_auto_armed = true
	elif assay_auto_armed:
		if not automated_mode:
			call_deferred("_start_assay_transaction")
	_refresh_context_button()
	if context.begins_with("chest:"):
		_set_status(_surface_chest_status(context.trim_prefix("chest:")))
	elif context.begins_with("gate:"):
		_set_status(_gate_status(context.trim_prefix("gate:")))
	else:
		match context:
			"starforge":
				_set_status(_starforge_status())
			"moonglass_resource":
				_set_status("Moonglass Bloom · break all three crystals before resonance fades")
			"ember_resource":
				_set_status("Ember Fault · crack the armored vents before the pressure cools")
			"starfall_resource":
				_set_status("Starfall Lattice · discharge all three astral anchors in time")
			_:
				pass
	_refresh_starforge_panel()


func _on_mine_exit_context_changed(is_near: bool) -> void :
	mine_exit_context = is_near
	_refresh_context_button()


func _on_mine_depth_context_changed(is_near: bool) -> void :
	mine_depth_context = is_near
	_refresh_context_button()


func _on_depth_discovered(_world_position: Vector2) -> void :
	AudioDirector.play_discovery()
	objective_label.text = "HIDDEN DESCENT FOUND · ENTER %s" % _depth_name(current_mine_id)
	_set_status("Hidden descent uncovered · a new layer waits below")
	_refresh_context_button()


func _on_depth_context_changed(context: String) -> void :
	depth_context = context
	_refresh_context_button()
	match context:
		"drillForge":
			_set_status(_drill_forge_status())
		_:
			pass


func _on_hub_context_changed(context: String) -> void :
	hub_context = context
	_refresh_context_button()
	if context == "deepElevator":
		_set_status(_deep_elevator_status_text())
	elif context == "deepHoard":
		_set_status(_deep_hoard_status_text())
	elif context == "relicPedestal":
		var carried: = Dictionary(Dictionary(RunState.endless_descent_status()).get("carried_relic", {}))
		var relic_id: = String(carried.get("id", ""))
		var relic: = Dictionary(RunState.relic_status(relic_id))
		_set_status("Museum pedestal · place the %s" % String(relic.get("display_name", "carried relic")))
	elif context.begins_with("workshop:"):
		_set_status(_workshop_status_text(context.trim_prefix("workshop:")))


func _on_workshop_panel_requested(workshop_id: String) -> void :
	if phase != "hub" or commerce_panel == null or not bool(Dictionary(RunState.workshop_status(workshop_id)).get("built", false)):
		return
	_open_commerce(
		CommerceCatalogScript.workshop_config(
			workshop_id,
			Dictionary(RunState.workshop_status(workshop_id)),
			Dictionary(hub_world.workshop_selection_preview(workshop_id))
		),
		"workshop:%s" % workshop_id
	)


func _workshop_panel_config(workshop_id: String) -> Dictionary:
	var status: = Dictionary(RunState.workshop_status(workshop_id))
	var selection: = Dictionary(hub_world.workshop_selection_preview(workshop_id))
	var upgrade: = Dictionary(status.get("next_upgrade", {})).duplicate(true)
	if not upgrade.is_empty():
		var resource_id: = String(upgrade.get("resource", ""))
		upgrade["resource_name"] = String(ENDLESS_RESOURCE_NAMES.get(resource_id, resource_id.capitalize()))
	var details: Dictionary = {
		"tool_forge": "Tool impact and mining profile",
		"light_lab": "Beam shape and lens response",
		"wardrobe": "Expedition outfit and station finish",
		"treasure_chamber": "Relic archive and recovered discoveries",
		"lift_workshop": "Deepest route and return checkpoint",
	}
	return {
		"workshop_id": workshop_id,
		"title": String(status.get("display_name", workshop_id.capitalize())),
		"detail": String(details.get(workshop_id, "Workshop configuration")),
		"level": int(status.get("level", 1)),
		"max_level": int(status.get("max_level", 1)),
		"equipment_current": String(selection.get("current", "")),
		"equipment_options": Array(selection.get("options", [])).duplicate(),
		"style_current": String(status.get("style", "original")),
		"style_options": Array(status.get("available_styles", [])).duplicate(),
		"upgrade": upgrade,
		"upgrade_ready": bool(status.get("ready_to_upgrade", false)),
	}


func _on_workshop_panel_preview_changed(action: String, value: String) -> void :
	if workshop_panel == null or not workshop_panel.is_open():
		return
	var workshop_id: = String(Dictionary(workshop_panel.interaction_snapshot()).get("workshop_id", ""))
	hub_world.set_workshop_panel_preview(workshop_id, action, value)


func _on_workshop_panel_action_confirmed(action: String, value: String) -> void :
	if workshop_panel == null or not workshop_panel.is_open():
		return
	var workshop_id: = String(Dictionary(workshop_panel.interaction_snapshot()).get("workshop_id", ""))
	var transaction: = Dictionary(hub_world.confirm_workshop_action(workshop_id, action, value))
	if bool(transaction.get("ok", false)):
		hub_world.clear_workshop_panel_preview()
		workshop_panel.refresh_workshop(_workshop_panel_config(workshop_id))
		_refresh_hud()


func _on_workshop_panel_closed() -> void :
	hub_world.clear_workshop_panel_preview()
	if phase == "hub" and bool(hub_world.active):
		hub_world.player.control_enabled = not bool(hub_world.build_mode)
	AudioDirector.play_ui("cancel")
	_refresh_context_button()


func _close_commerce_for_action() -> void :
	commerce_confirm_close = true
	commerce_panel.close_commerce()
	commerce_confirm_close = false


func _open_commerce(config: Dictionary, context_id: String) -> void :
	if (
		commerce_panel == null
		or _shop_panel_is_open()
		or (station_transaction_fx != null and station_transaction_fx.busy)
		or config.is_empty()
	):
		return
	commerce_context = context_id
	_cancel_held_input()
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	if phase == "surface":
		surface_world.player.control_enabled = false
	elif phase == "hub":
		hub_world.player.control_enabled = false
	_set_developer_menu_shop_suppressed(true)
	AudioDirector.play_ui("open")
	commerce_panel.open_commerce(config)


func _on_commerce_closed() -> void :
	_set_developer_menu_shop_suppressed(false)
	if commerce_context.begins_with("workshop:"):
		hub_world.clear_workshop_panel_preview()
	commerce_context = ""
	if phase == "surface":
		surface_world.player.control_enabled = true
	elif phase == "hub" and bool(hub_world.active):
		hub_world.player.control_enabled = not bool(hub_world.build_mode)
	if not commerce_confirm_close:
		AudioDirector.play_ui("cancel")
	_refresh_context_button()


func _set_developer_menu_shop_suppressed(suppressed: bool) -> void :
	if developer_menu == null or not is_instance_valid(developer_menu):
		return
	if suppressed and developer_menu.has_method("close_menu"):
		developer_menu.close_menu()
	var dev_toggle: Control = developer_menu.get("toggle_button") as Control
	if dev_toggle != null:
		dev_toggle.visible = not suppressed


func _on_commerce_selection_changed(item_id: String) -> void :
	if not commerce_context.begins_with("workshop:"):
		return
	var workshop_id: = commerce_context.trim_prefix("workshop:")
	if item_id.begins_with("workshop:equip:"):
		hub_world.set_workshop_panel_preview(workshop_id, "equip", item_id.trim_prefix("workshop:equip:"))
	elif item_id.begins_with("workshop:style:"):
		hub_world.set_workshop_panel_preview(workshop_id, "style", item_id.trim_prefix("workshop:style:"))
	else:
		hub_world.clear_workshop_panel_preview()


func _on_commerce_action_confirmed(item_id: String) -> void :
	if commerce_transaction.size() > 0 or commerce_panel == null:
		return
	if item_id.begins_with("forge:"):
		_start_forge_transaction(item_id.trim_prefix("forge:"))
	elif item_id == "wayfarer:speed":
		_confirm_wayfarer_purchase()
	elif item_id.begins_with("starforge:"):
		_confirm_starforge_purchase(item_id.trim_prefix("starforge:"))
	elif item_id.begins_with("workshop:"):
		_confirm_workshop_commerce_action(item_id)


func _confirm_workshop_commerce_action(item_id: String) -> void :
	if not commerce_context.begins_with("workshop:"):
		return
	var workshop_id: = commerce_context.trim_prefix("workshop:")
	var action: = ""
	var value: = ""
	if item_id == "workshop:upgrade":
		action = "upgrade"
	elif item_id.begins_with("workshop:equip:"):
		action = "equip"
		value = item_id.trim_prefix("workshop:equip:")
	elif item_id.begins_with("workshop:style:"):
		action = "style"
		value = item_id.trim_prefix("workshop:style:")
	if action.is_empty():
		return
	_close_commerce_for_action()
	var transaction: = Dictionary(hub_world.confirm_workshop_action(workshop_id, action, value))
	if bool(transaction.get("ok", false)):
		_refresh_hud()
	else:
		_set_status("Workshop action unavailable · %s" % String(transaction.get("reason", "requirements changed")).replace("_", " "))


func _open_forge_commerce() -> void :
	_open_commerce(CommerceCatalogScript.forge_config(Dictionary(RunState.forge_purchase_snapshot())), "forge")


func _open_wayfarer_commerce() -> void :
	_open_commerce(CommerceCatalogScript.wayfarer_config(), "wayfarer")


func _open_starforge_commerce() -> void :
	_open_commerce(CommerceCatalogScript.starforge_config(), "starforge")


func _start_assay_transaction() -> void :
	if (
		phase != "surface"
		or surface_context != "sell"
		or ( not game_started and not automated_mode)
		or menu_open
		or inventory_open
		or conclusion_overlay.visible
		or orientation_guard_active
		or _shop_panel_is_open()
		or not commerce_transaction.is_empty()
		or (station_transaction_fx != null and station_transaction_fx.busy)
	):
		return
	assay_auto_armed = false
	var begun: Dictionary = Dictionary(RunState.begin_assay_sale())
	if not bool(begun.get("ok", false)):
		match String(begun.get("reason", "empty")):
			"protected":
				AudioDirector.play_ui("confirm")
				_set_status("Assay skipped · upgrade and workshop materials stay protected")
			_:
				AudioDirector.play_blocked()
				_set_status("Assay ready · bring mined resources through the station")
		return
	commerce_presented_gold = int(begun.get("gold_before", RunState.gold))
	commerce_transaction = {
		"kind": "assay",
		"state_id": String(begun.get("transaction_id", "")),
		"snapshot": begun.duplicate(true),
		"gold_before": commerce_presented_gold,
		"station": "sell",
	}
	_set_status(
		"Assay receiving %d resources · gold is counted as each bar returns" %
		int(begun.get("sellable_pieces", 0))
	)
	_refresh_hud()
	var options: Dictionary = _commerce_fx_options(String(begun.get("transaction_id", "")))
	var fx_id: = -1
	if station_transaction_fx != null:
		fx_id = station_transaction_fx.play_sale(
			_commerce_resource_batches(Array(begun.get("rows", [])), "sellable"),
			int(begun.get("total", 0)),
			_commerce_bag_position(),
			_surface_station_fx_position("sell"),
			_commerce_wallet_position(),
			station_transaction_fx.default_gold_texture,
			options
		)
	commerce_fx_id = fx_id
	if fx_id < 0:
		_on_station_transaction_completed(-1, "sale", true)


func _start_forge_transaction(purchase_kind: String) -> void :
	if phase != "surface" or commerce_context != "forge" or not commerce_transaction.is_empty():
		return
	var begun: Dictionary = Dictionary(RunState.begin_forge_purchase(purchase_kind))
	if not bool(begun.get("ok", false)):
		AudioDirector.play_blocked()
		_set_status(_forge_status())
		if commerce_panel != null and commerce_panel.is_open():
			commerce_panel.refresh(CommerceCatalogScript.forge_config(Dictionary(RunState.forge_purchase_snapshot())))
		return
	var cost: Dictionary = Dictionary(begun.get("cost", {}))
	var gold_cost: = int(Dictionary(cost.get("gold", {})).get("required", 0))
	commerce_presented_gold = int(RunState.gold)
	commerce_transaction = {
		"kind": "forge",
		"state_id": String(begun.get("transaction_id", "")),
		"snapshot": begun.duplicate(true),
		"gold_before": commerce_presented_gold,
		"station": "forge",
	}
	_close_commerce_for_action()
	_set_status("Forge primed · ore and gold are moving into the crucible")
	_refresh_hud()
	var options: Dictionary = _commerce_fx_options(String(begun.get("transaction_id", "")))
	options["reward_texture_path"] = String(Dictionary(begun.get("next", {})).get("texture_path", ""))
	options["reward_size"] = Vector2(72, 72)
	var fx_id: = -1
	if station_transaction_fx != null:
		fx_id = station_transaction_fx.play_forge(
			_commerce_resource_batches(Array(cost.get("resources", [])), "required"),
			gold_cost,
			_commerce_bag_position(),
			_commerce_wallet_position(),
			_surface_station_fx_position("forge"),
			station_transaction_fx.default_gold_texture,
			options
		)
	commerce_fx_id = fx_id
	if fx_id < 0:
		_on_station_transaction_completed(-1, "forge", true)


func _confirm_wayfarer_purchase() -> void :
	if phase != "surface" or commerce_context != "wayfarer" or not commerce_transaction.is_empty():
		return
	var gold_before: = int(RunState.gold)
	commerce_presented_gold = gold_before
	var result: Dictionary = Dictionary(RunState.buy_movement_speed())
	if not bool(result.get("ok", false)):
		commerce_presented_gold = -1
		AudioDirector.play_blocked()
		_set_status("Wayfarer · need %d more gold" % int(result.get("missing_gold", 0)))
		if commerce_panel != null and commerce_panel.is_open():
			commerce_panel.refresh(CommerceCatalogScript.wayfarer_config())
		return
	commerce_transaction = {
		"kind": "wayfarer",
		"result": result.duplicate(true),
		"gold_before": gold_before,
		"station": "speedShop",
	}
	_close_commerce_for_action()
	_set_status("Wayfarer tuning underway · follow the gold into the workshop")
	_refresh_hud()
	var transaction_key: = "wayfarer:%d:%d" % [int(result.get("level", 0)), Time.get_ticks_usec()]
	var options: Dictionary = _commerce_fx_options(transaction_key)
	options["reward_texture_path"] = "res://assets/achievements/roadrunner.png"
	options["reward_size"] = Vector2(64, 64)
	var fx_id: = -1
	if station_transaction_fx != null:
		var empty_resources: Array[Dictionary] = []
		fx_id = station_transaction_fx.play_forge(
			empty_resources,
			int(result.get("cost", 0)),
			_commerce_bag_position(),
			_commerce_wallet_position(),
			_surface_station_fx_position("speedShop"),
			station_transaction_fx.default_gold_texture,
			options
		)
	commerce_fx_id = fx_id
	if fx_id < 0:
		_on_station_transaction_completed(-1, "forge", true)


func _confirm_starforge_purchase(variant_id: String) -> void :
	if phase != "surface" or commerce_context != "starforge" or not commerce_transaction.is_empty():
		return
	var status: Dictionary = Dictionary(RunState.starforge_crafting_status(variant_id))
	var variant: Dictionary = Dictionary(status.get("variant", {}))
	var forged: = false
	var resources: Array[Dictionary] = []
	if bool(status.get("can_equip", false)):
		if not RunState.equip_starforge_variant(variant_id):
			return
	elif bool(status.get("ready", false)):
		for resource_value in Dictionary(variant.get("cost", {})):
			var resource_id: = String(resource_value)
			resources.append({
				"id": resource_id,
				"kind": resource_id,
				"amount": int(Dictionary(variant.get("cost", {})).get(resource_id, 0)),
				"texture_path": "res://assets/drops/%s-drop.png" % resource_id,
				"size": Vector2(34, 34),
			})
		if not RunState.forge_starforge_variant(variant_id):
			return
		forged = true
	else:
		AudioDirector.play_blocked()
		_set_status(_starforge_status())
		if commerce_panel != null and commerce_panel.is_open():
			commerce_panel.refresh(CommerceCatalogScript.starforge_config())
		return
	commerce_transaction = {
		"kind": "starforge",
		"variant_id": variant_id,
		"variant_name": String(variant.get("name", variant_id.capitalize())),
		"forged": forged,
		"station": "starforge",
	}
	_close_commerce_for_action()
	_set_status("Starforge attunement underway · the core is taking shape")
	var transaction_key: = "starforge:%s:%d" % [variant_id, Time.get_ticks_usec()]
	var options: Dictionary = _commerce_fx_options(transaction_key)
	options["reward_texture"] = STARFORGE_BUTTON_ICONS.get(variant_id)
	options["reward_size"] = Vector2(76, 76)
	var fx_id: = -1
	if station_transaction_fx != null:
		fx_id = station_transaction_fx.play_forge(
			resources,
			0,
			_commerce_bag_position(),
			_commerce_wallet_position(),
			_surface_station_fx_position("starforge"),
			station_transaction_fx.default_gold_texture,
			options
		)
	commerce_fx_id = fx_id
	if fx_id < 0:
		_on_station_transaction_completed(-1, "forge", true)


func _on_commerce_gold_tick(
	transaction_id: int,
	delta: int,
	cumulative_delta: int,
	_total_delta: int
) -> void :
	if commerce_transaction.is_empty() or transaction_id != commerce_fx_id:
		return
	commerce_presented_gold = maxi(
		0,
		int(commerce_transaction.get("gold_before", RunState.gold)) + cumulative_delta
	)
	_update_presented_gold_labels()
	if delta > 0:
		AudioDirector.play_pickup("gold", maxi(1, delta))


func _on_station_transaction_completed(
	transaction_id: int,
	_flow: String,
	_skipped: bool
) -> void :
	if commerce_transaction.is_empty():
		return
	if commerce_fx_id >= 0 and transaction_id != commerce_fx_id:
		return
	var transaction: Dictionary = commerce_transaction.duplicate(true)
	commerce_transaction.clear()
	commerce_fx_id = -1
	var succeeded: = true
	match String(transaction.get("kind", "")):
		"assay":
			var result: Dictionary = Dictionary(RunState.commit_assay_sale(String(transaction.get("state_id", ""))))
			succeeded = bool(result.get("ok", false))
			if succeeded:
				AudioDirector.play_economy("sell")
				_set_status(
					"Assay complete · +%d gold from %d resources · protected materials kept safe" % [
						int(result.get("earned", 0)),
						int(result.get("sellable_pieces", 0)),
					]
				)
			else:
				_set_status("Assay interrupted · resources remained in your pouch")
		"forge":
			var result: Dictionary = Dictionary(RunState.commit_forge_purchase(String(transaction.get("state_id", ""))))
			succeeded = bool(result.get("ok", false))
			if succeeded:
				var purchased: Dictionary = Dictionary(result.get("purchased", {}))
				AudioDirector.play_economy("upgrade")
				_set_status("%s forged and equipped · the upgrade is permanent" % String(purchased.get("name", "Tool upgrade")))
			else:
				_set_status("Forge interrupted · no materials or gold were spent")
		"wayfarer":
			var result: Dictionary = Dictionary(transaction.get("result", {}))
			_apply_global_movement_speed()
			AudioDirector.play_economy("upgrade")
			_set_status("Permanent movement speed %.2fx · the next tune is already available" % float(result.get("multiplier", 1.0)))
		"starforge":
			AudioDirector.play_economy("upgrade")
			var variant_name: = String(transaction.get("variant_name", "Starforge core"))
			_set_status(
				"%s forged and attached · its drill trait is active" % variant_name
				if bool(transaction.get("forged", false))
				else "%s core attached · its mining trait is active" % variant_name
			)
	commerce_presented_gold = -1
	if not succeeded:
		AudioDirector.play_blocked()
	_refresh_hud()
	if persistence_active and succeeded:
		RunState.flush_save()


func _commerce_resource_batches(rows: Array, amount_key: String) -> Array[Dictionary]:
	var batches: Array[Dictionary] = []
	for row_value in rows:
		if not row_value is Dictionary:
			continue
		var row: Dictionary = Dictionary(row_value)
		var amount: = maxi(0, int(row.get(amount_key, row.get("amount", 0))))
		if amount <= 0:
			continue
		batches.append({
			"id": String(row.get("kind", row.get("id", "resource"))),
			"kind": String(row.get("kind", row.get("id", "resource"))),
			"amount": amount,
			"texture_path": String(row.get("texture_path", "")),
			"size": Vector2(34, 34),
		})
	return batches


func _commerce_fx_options(transaction_key: Variant) -> Dictionary:
	commerce_fx_nonce += 1
	return {
		"transaction_key": "%d:%s" % [commerce_fx_nonce, String(transaction_key)],
		"positions_are_local": true,
		"visual_cap": 16,
		"visual_refresh_hz": 30.0,
		"reduced_motion": bool(ProjectSettings.get_setting("accessibility/reduced_motion", false)),
	}


func _commerce_bag_position() -> Vector2:
	return Vector2(surface_world.player.position) + Vector2(-18, -42)


func _commerce_wallet_position() -> Vector2:
	return Vector2(surface_world.player.position) + Vector2(18, -48)


func _surface_station_fx_position(station_id: String) -> Vector2:
	var station_position: Vector2 = Vector2(surface_world.station_interaction_position(station_id))
	if station_id in ["sell", "forge"]:
		station_position -= Vector2(0, 140)
	return station_position + Vector2(0, -12)


func _update_station_transaction_targets() -> void :
	if (
		station_transaction_fx == null
		or not station_transaction_fx.busy
		or commerce_transaction.is_empty()
		or phase != "surface"
	):
		return
	station_transaction_fx.set_runtime_targets(
		_commerce_bag_position(),
		_surface_station_fx_position(String(commerce_transaction.get("station", "sell"))),
		_commerce_wallet_position(),
		true
	)


func _maybe_start_assay_transaction() -> void :
	if automated_mode or not assay_auto_armed or phase != "surface" or surface_context != "sell":
		return
	_start_assay_transaction()


func _enforce_shop_player_control() -> void :
	if not _shop_panel_is_open():
		return
	var active_player: Node2D = _active_player_node()
	if is_instance_valid(active_player):
		active_player.set("control_enabled", false)


func _settle_commerce_before_world_change() -> void :
	if station_transaction_fx != null and station_transaction_fx.busy:
		station_transaction_fx.complete_immediately()
	if not commerce_transaction.is_empty():
		commerce_fx_id = -1
		_on_station_transaction_completed(-1, "", true)
	if commerce_panel != null and commerce_panel.is_open():
		commerce_confirm_close = true
		commerce_panel.close_commerce()
		commerce_confirm_close = false
	commerce_context = ""
	commerce_transaction.clear()
	commerce_fx_id = -1
	commerce_presented_gold = -1
	assay_auto_armed = true


func _update_presented_gold_labels() -> void :
	var displayed_gold: = int(RunState.gold) if commerce_presented_gold < 0 else commerce_presented_gold
	gold_label.text = "%d GOLD" % displayed_gold
	if premium_hud != null and premium_hud.gold_value != null:
		premium_hud.gold_value.text = str(displayed_gold)
		premium_hud.gold_value.tooltip_text = "%d gold" % displayed_gold


func _on_deepheart_context_changed(context: String) -> void :
	deepheart_context = context
	_refresh_context_button()
	if context == "deepheart_exit":
		_set_status("Hub lift · return whenever you are ready")
	elif context.begins_with("deepheart_seal:"):
		var seal_id: = context.trim_prefix("deepheart_seal:")
		_set_status("%s resonance · hold MINE until the seal opens" % seal_id.capitalize())
	elif context == "deepheart_core":
		var seals: = Dictionary(RunState.deepheart_seal_status())
		_set_status(
			"Deepheart Core · begin the final attunement"
			if bool(seals.get("all_open", false))
			else "Deepheart Core · %d of %d resonances open" % [int(seals.get("opened", 0)), int(seals.get("total", 4))]
		)
	else:
		_set_status(_deepheart_progress_text())


func _on_endless_context_changed(context: String) -> void :
	endless_context = context
	_refresh_context_button()
	if context == "endless_up":
		_set_status("Upper passage · haul discoveries toward the Hub" if int(Dictionary(RunState.endless_descent_status()).get("current_depth", 0)) > 0 else "Hub lift · return with everything you found")
	elif context == "endless_down":
		_set_status("Lower passage · explore one layer deeper")
	elif context.begins_with("endless_site:"):
		var choice: = String(context.get_slice(":", 2))
		_set_status(
			"Calm seal · cross three floor seals for a safe cache and a quieter surge"
			if choice == "stabilize"
			else "Power seal · cross four floor seals for a double cache and a stronger surge"
		)
	elif context.begins_with("endless_relic:"):
		var relic_id: = context.trim_prefix("endless_relic:")
		var relic: = Dictionary(RunState.relic_status(relic_id))
		_set_status("%s · attach the rope and haul it to the Hub" % String(relic.get("display_name", "Relic")))


func _perform_context() -> void :
	if conclusion_overlay.visible or _shop_panel_is_open() or not commerce_transaction.is_empty():
		return
	if phase == "deepheart":
		deepheart_world.interact()
		return
	if phase == "endless":
		endless_world.perform_context()
		return
	if phase == "hub":
		hub_world.perform_context()
		objective_label.text = _hub_objective()
		_refresh_hud()
		return
	if phase == "depth":
		if depth_context == "drillForge":
			_try_upgrade_drill()
		else:
			var gold_before: = int(RunState.gold)
			var depth_result: = String(depth_world.perform_context())
			if depth_result == "depthSell":
				if int(RunState.gold) > gold_before:
					AudioDirector.play_economy("sell")
				else:
					AudioDirector.play_blocked()
		return
	if phase == "mine":
		if mine_depth_context:
			_enter_depth()
		elif mine_exit_context:
			_exit_mine()
		return
	if surface_context.begins_with("chest:"):
		_open_surface_chest(surface_context.trim_prefix("chest:"))
		return
	if surface_context.begins_with("storage:"):
		_use_surface_storage(surface_context.trim_prefix("storage:"))
		return
	if surface_context.begins_with("enter:"):
		_enter_mine(surface_context.trim_prefix("enter:"))
		return
	if surface_context.begins_with("gate:"):
		_try_unlock_gate(surface_context.trim_prefix("gate:"))
		return
	match surface_context:
		"hubEntrance":
			_enter_hub()
		"sell":
			_start_assay_transaction()
		"forge":
			_open_forge_commerce()
		"starforge":
			_open_starforge_commerce()
		"speedShop":
			_open_wayfarer_commerce()


func _open_surface_chest(chest_id: String) -> void :
	var definition: = _surface_chest_definition(chest_id)
	if definition.is_empty():
		AudioDirector.play_blocked()
		return
	var result: Dictionary = RunState.open_surface_chest(chest_id)
	if bool(result.get("ok", false)):
		AudioDirector.play_discovery()
		_set_status("%s opened · %s scattered nearby" % [String(definition.name), _surface_chest_reward_label(definition)])
		if persistence_active:
			RunState.flush_save()
	else:
		AudioDirector.play_blocked()
		_set_status(_surface_chest_status(chest_id))
	_refresh_hud()


func _buy_wayfarer_speed() -> void :
	var result: Dictionary = RunState.buy_movement_speed()
	if bool(result.get("ok", false)):
		_apply_global_movement_speed()
		AudioDirector.play_economy("upgrade")
		_set_status("Permanent movement speed %.2fx · no level cap" % float(result.multiplier))
		if persistence_active:
			RunState.flush_save()
	else:
		AudioDirector.play_blocked()
		_set_status("Wayfarer · need %d more gold" % int(result.get("missing_gold", 0)))
	_refresh_hud()


func _use_surface_storage(module_id: String) -> void :
	var actor_position: Vector2 = surface_world.player.global_position
	var moved: = RunState.auto_sort_resources(actor_position, "surface", 1)
	if moved > 0:
		AudioDirector.play_pickup("stone", moved)
		_set_status("Storage sorted · %d resources secured · active upgrades kept in pouch" % moved)
	else:
		var taken: = RunState.take_all_from_storage(module_id, actor_position, "surface", 1)
		if taken > 0:
			AudioDirector.play_pickup("gold", taken)
			_set_status("Storage opened · %d resources returned to your pouch" % taken)
		else:
			AudioDirector.play_blocked()
			_set_status("Storage empty · active upgrade materials remain in your pouch")
	if persistence_active:
		RunState.flush_save()
	_refresh_hud()


func _use_forge() -> void :
	var next: = RunState.next_pickaxe()
	if next.is_empty():
		var mastery: = RunState.next_ember_mastery()
		if RunState.upgrade_ember_mastery():
			AudioDirector.play_economy("upgrade")
			_set_status("EMBER MASTERY %d · %s" % [RunState.ember_mastery, String(RunState.current_pickaxe().name)])
		elif mastery.is_empty():
			_set_status("Depth Mastery complete · the Starfall Seal can be opened")
		elif int(RunState.cargo.get("sunslag", 0)) < int(mastery.sunslag):
			AudioDirector.play_blocked()
			_set_status("Depth Mastery %d needs %d Sunslag" % [int(mastery.rank), int(mastery.sunslag)])
		else:
			AudioDirector.play_blocked()
			_set_status("Depth Mastery %d needs %d gold" % [int(mastery.rank), int(mastery.gold)])
	elif RunState.upgrade_pickaxe():
		AudioDirector.play_economy("upgrade")
		_set_status("%s equipped · stronger and faster mining" % String(RunState.current_pickaxe().name))
	elif RunState.pickaxe_level == 4 and not RunState.emberdeep_unlocked:
		AudioDirector.play_blocked()
		_set_status("Open Emberdeep Foundry before forging the Ember Pickaxe")
	elif RunState.pickaxe_level == 4 and int(RunState.cargo.get("emberstone", 0)) < int(GameData.data.EMBER_PICKAXE_ORE_REQUIRED):
		AudioDirector.play_blocked()
		_set_status("Ember Pickaxe needs %d Emberstone" % int(GameData.data.EMBER_PICKAXE_ORE_REQUIRED))
	else:
		AudioDirector.play_blocked()
		_set_status("You need %d gold for the %s" % [int(next.cost), String(next.name)])


func _try_unlock_gate(world_id: String) -> void :
	if not GATE_REQUIREMENTS.has(world_id):
		return
	if RunState.is_world_unlocked(world_id):
		AudioDirector.play_ui("confirm")
		_set_status("The passage is opening · stand clear")
		return
	var requirement: Dictionary = Dictionary(GATE_REQUIREMENTS[world_id])
	var pickaxe_required: = int(requirement.pickaxe)
	var mastery_required: = int(requirement.mastery)
	var gold_required: = int(requirement.gold)
	if pickaxe_required > 0 and RunState.pickaxe_level < pickaxe_required:
		AudioDirector.play_blocked()
		_set_status("%s requires the %s" % [String(requirement.title), String(GameData.data.PICKAXES[pickaxe_required].name)])
		return
	if mastery_required > 0 and int(RunState.get("ember_mastery")) < mastery_required:
		AudioDirector.play_blocked()
		_set_status("%s requires Depth Mastery %d" % [String(requirement.title), mastery_required])
		return
	if RunState.gold < gold_required:
		AudioDirector.play_blocked()
		_set_status("%s needs %d more gold" % [String(requirement.title), gold_required - RunState.gold])
		return
	RunState.gold -= gold_required
	RunState.unlock_world(world_id)
	AudioDirector.play_transition("gate")
	objective_label.text = _surface_objective()
	_set_status("%s opened · the road continues" % String(requirement.title))
	_refresh_hud()


func _enter_mine(mine_id: String, entering: bool = true, persist_location: bool = true) -> void :
	if not _mine_is_unlocked(mine_id):
		AudioDirector.play_blocked()
		return
	current_mine_id = mine_id
	phase = "mine"
	mine_exit_context = false
	mine_depth_context = false
	depth_context = ""
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	mine_world.load_mine(mine_id)
	mine_world.set_active(true, entering)
	AudioDirector.set_environment("mine")
	if entering:
		AudioDirector.play_transition("descend")
	RunState.begin_state_batch()
	RunState.mark_mine_discovered(mine_id)
	var mine_data: Dictionary = GameData.mine(mine_id)
	objective_label.text = "%s · %s" % [String(mine_data.name), String(mine_data.finalGoal).to_upper()]
	_set_status("%s · your helmet lamp follows every strike" % String(mine_data.name).capitalize())
	_refresh_context_button()
	if persistence_active and persist_location:
		surface_world.persist_ore_mountain_state()
		RunState.set_location("surface", surface_world.player.global_position)
		RunState.set_location(mine_id, mine_world.player.global_position)
	RunState.end_state_batch()


func _enter_depth(entering: bool = true, persist_location: bool = true) -> void :
	var entry_status: Dictionary = RunState.depth_entry_status(current_mine_id)
	if not bool(entry_status.get("can_enter", false)):
		AudioDirector.play_blocked()
		if String(entry_status.get("reason", "")) == "deepcore_required":
			_set_status("The Deepcore Drill is required before entering %s" % _depth_name(current_mine_id).capitalize())
		else:
			_set_status("The hidden descent must be uncovered from %s first" % _mine_name(current_mine_id).capitalize())
		return
	if not depth_world.load_depth(current_mine_id, Vector2(mine_world.depth_entrance)):
		AudioDirector.play_blocked()
		_set_status("%s is sealed while this depth is being restored" % _depth_name(current_mine_id).capitalize())
		return
	phase = "depth"
	mine_exit_context = false
	mine_depth_context = false
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	RunState.begin_state_batch()
	RunState.enter_depth(current_mine_id)
	depth_world.set_active(true, entering)
	AudioDirector.set_environment("depth")
	if entering:
		AudioDirector.play_transition("depth")
	depth_context = depth_world.current_context()
	objective_label.text = _depth_objective()
	_set_status("%s · new materials and the Drill Forge await below" % _depth_name(current_mine_id).capitalize())
	_refresh_context_button()
	_refresh_hud()
	if persistence_active and persist_location:
		RunState.set_location(current_mine_id, depth_world.player.global_position, 2)
	RunState.end_state_batch()


func _enter_mossvein() -> void :
	_enter_mine("mossMine")


func _start_qa_version_menu() -> void :
	menu_open = true
	premium_menu.modulate = Color.WHITE
	premium_menu.open_menu(false, "NO EXPEDITION", false, false)
	print("EVER_DEEPER_VERSION_MENU_READY label=%s" % premium_menu.displayed_release_label())


func _start_qa_mine() -> void :


	if "--qa-up" in OS.get_cmdline_user_args():
		RunState.pickaxe_level = 4
	_enter_mine("mossMine")
	if _has_any_arg(OS.get_cmdline_user_args(), ["--qa-camera", "--qa-performance"]):
		for col in range(4, 40):
			for row in range(11, 15):
				mine_world.blocks.erase(Vector2i(col, row))
		mine_world.player.global_position = Vector2(300, 624)
		mine_world.player.movement_speed = 80.0
		mine_world.player.set_facing(Vector2.RIGHT)
		mine_world.player.camera.reset_smoothing()
		mine_world.player.set_external_movement(Vector2.RIGHT)
		if "--qa-performance" in OS.get_cmdline_user_args():
			performance_qa_active = true
	elif "--qa-up" in OS.get_cmdline_user_args():
		mine_world.player.global_position = Vector2(230, 560)
		mine_world.player.set_facing(Vector2.UP)
		mine_world.player.camera.reset_smoothing()
		mine_world.set_mine_held(true)
	elif "--qa-swing" in OS.get_cmdline_user_args():
		mine_world.set_mine_held(true)


func _start_qa_barrier() -> void :
	RunState.reset_run(false)
	_enter_mine("mossMine", false, false)
	mine_world.restore_position(Vector2(1165, 640))
	mine_world.player.set_facing(Vector2.RIGHT)
	mine_world.target_dirty = true
	objective_label.text = "IRONBOUND COLLAPSE · THREE AUTHORED ROCKS"
	_set_status("QA · exact barrier collision · Runed Pickaxe required")
	_refresh_hud()


func _start_qa_surface_camp() -> void :
	DisplayServer.window_set_title("Ever Deeper · Mossvein Camp QA")
	RunState.reset_run(false)
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	surface_world.set_active(true)
	surface_world.restore_position(Vector2(240, 680))
	surface_world.player.set_facing(Vector2.RIGHT)
	objective_label.text = "MOSSVEIN CAMP · FORGE AND ASSAY"
	_set_status("QA · camp composition, paths, stations and living environment")
	_refresh_hud()


func _start_qa_moss_overview() -> void :
	DisplayServer.window_set_title("Ever Deeper · Full Mossvein Composition QA")
	RunState.reset_run(false)
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	surface_world.set_active(true)
	surface_world.restore_position(Vector2(567, 640))
	surface_world.player.control_enabled = false

	surface_world.player.camera.zoom = Vector2.ONE * 0.35
	surface_world.player.camera.position_smoothing_enabled = false
	surface_world.player.camera.reset_smoothing()
	$HUD.visible = false


func _start_qa_surface_context(context: String) -> void :
	DisplayServer.window_set_title("Ever Deeper · Surface Context QA")
	RunState.reset_run(false)
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	surface_world.set_active(true)
	if context == "sell":
		RunState.add_resource("stone", 4)
		RunState.add_resource("copper", 3)
		surface_world.restore_position(surface_world.station_interaction_position("sell"))
	elif context == "forge":
		RunState.gold = int(RunState.next_pickaxe().cost)
		surface_world.restore_position(surface_world.station_interaction_position("forge"))
	else:
		surface_world.restore_position(surface_world._mine_entrance("mossMine"))
	_refresh_hud()


func _start_qa_surface_decor() -> void :
	DisplayServer.window_set_title("Ever Deeper · Mossvein Decor QA")
	RunState.reset_run(false)
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	surface_world.set_active(true)


	surface_world.restore_position(Vector2(790, 820))
	surface_world.player.set_facing(Vector2.DOWN)
	objective_label.text = "MOSSVEIN · DESCENT TO THE MINE"
	_set_status("QA · readable branch, living forest edges and a clear mine destination")
	_refresh_hud()


func _start_qa_surface(mode: String) -> void :
	if mode == "open_gate":
		DisplayServer.window_set_title("Ever Deeper · Open Moonglass Gate QA")
	RunState.reset_run(false)
	if mode == "gate_ready":
		RunState.pickaxe_level = 3
		RunState.gold = 120
	if mode in ["open_gate", "moon_surface", "moon_mine"]:
		RunState.pickaxe_level = 3
		RunState.unlock_world("moonglass")
	if mode == "moon_mine":
		_enter_mine("moonMine")
		return
	phase = "surface"
	mine_world.set_active(false)
	surface_world.set_active(true)
	var qa_position: Vector2 = (
		Vector2(980, 650)
		if mode in ["gate", "gate_ready"]
		else Vector2(1165, 650)
		if mode == "open_gate"
		else surface_world._mine_entrance("moonMine")
	)
	surface_world.restore_position(qa_position)
	objective_label.text = _surface_objective()
	_set_status("QA · gate ready to open" if mode == "gate_ready" else "QA · locked Moonglass Gate" if mode == "gate" else "QA · opened Moonglass passage" if mode == "open_gate" else "QA · Moonglass surface and mine entrance")


func _start_qa_surface_mountain(damaged: bool = false) -> void :
	DisplayServer.window_set_title("Ever Deeper · Copper Ridge Damage QA" if damaged else "Ever Deeper · Copper Ridge QA")
	RunState.reset_run(false)
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	surface_world.set_active(true)
	surface_world.restore_position(Vector2(600, 700))
	if damaged:
		surface_world.ore_mountain_hp = 108
		surface_world._update_ore_mountain(0.0)
	surface_world.player.set_facing(Vector2.DOWN)
	objective_label.text = "COPPER RIDGE · SURFACE QUARRY"
	_set_status("QA · hold MINE to quarry Copper and Gold")
	_refresh_hud()


func _start_qa_surface_mountains(mountain_id: String = "moonglass_mountain") -> void :
	var profiles: = {
		"moonglass_mountain": {
			"name": "Moonglass Mountain", "world": "moonglass", "pickaxe": 3,
			"position": Vector2(1665, 575), "vein": "Bloom",
		},
		"emberdeep_mountain": {
			"name": "Emberdeep Mountain", "world": "emberdeep", "pickaxe": 4,
			"position": Vector2(3078, 1030), "vein": "Fault",
		},
		"starfall_mountain": {
			"name": "Starfall Mountain", "world": "starfall", "pickaxe": 5,
			"position": Vector2(4020, 1042), "vein": "Lattice",
		},
	}
	var profile: Dictionary = Dictionary(profiles.get(mountain_id, profiles.moonglass_mountain))
	DisplayServer.window_set_title("Ever Deeper · %s QA" % String(profile.name))
	RunState.reset_run(false)
	RunState.pickaxe_level = int(profile.pickaxe)
	if mountain_id == "starfall_mountain":
		RunState.ember_mastery = 5
	RunState.unlock_world(String(profile.world))
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	surface_world.reset_for_new_run()
	surface_world.set_active(true)
	surface_world.restore_position(Vector2(profile.position))
	surface_world.player.set_facing(Vector2.UP)
	surface_world.player.camera.position_smoothing_enabled = false
	surface_world.player.camera.reset_smoothing()
	objective_label.text = "%s · INDEPENDENT QUARRY" % String(profile.name).to_upper()
	_set_status("QA · the mountain reacts only to its own hits; the %s stays separate" % String(profile.vein))
	_refresh_hud()


func _start_qa_moon_resource() -> void :
	DisplayServer.window_set_title("Ever Deeper · Moonglass Bloom QA")
	RunState.reset_run(false)
	RunState.unlock_world("moonglass")
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	surface_world.set_active(true)
	surface_world.restore_position(Vector2(1820, 800))
	surface_world.player.set_facing(Vector2.UP)
	objective_label.text = "MOONGLASS BLOOM · BREAK THREE CRYSTALS IN 18 SECONDS"
	_set_status("QA · original timed Bloom · physical Moonglass and Starshard drops")
	_refresh_hud()


func _start_qa_surface_resource(resource_id: String) -> void :
	RunState.reset_run(false)
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	surface_world.set_active(true)
	if resource_id == "ember_fault":
		DisplayServer.window_set_title("Ever Deeper · Ember Fault QA")
		RunState.pickaxe_level = 4
		RunState.unlock_world("emberdeep")
		surface_world.restore_position(Vector2(3078, 1150))
		surface_world.player.set_facing(Vector2.UP)
		objective_label.text = "EMBER FAULT · BREAK THE PRESSURE VENTS IN 22 SECONDS"
		_set_status("QA · armored heat fault · physical Emberstone and Sunslag drops")
	else:
		DisplayServer.window_set_title("Ever Deeper · Starfall Lattice QA")
		RunState.pickaxe_level = 5
		RunState.ember_mastery = 5
		RunState.unlock_world("starfall")
		RunState.set_starforge_variant("crusher")
		surface_world.restore_position(Vector2(3810, 1050))
		surface_world.player.set_facing(Vector2.UP)
		objective_label.text = "STARFALL LATTICE · DISCHARGE THREE ANCHORS IN 20 SECONDS"
		_set_status("QA · charged astral lattice · physical Astralite and Crownstone drops")
	_refresh_hud()


func _start_qa_surface_performance() -> void :
	DisplayServer.window_set_title("Ever Deeper · Emberdeep Surface Performance QA")
	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.unlock_world("starfall")
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	surface_world.reset_for_new_run()
	surface_world.set_active(true)
	var ember_route: Array = surface_world.LATER_MINE_BRANCH_ROUTES.emberMine
	var edge_start: Vector2 = Vector2(ember_route[3])
	var edge_end: Vector2 = Vector2(ember_route[4])
	var edge_tangent: Vector2 = (edge_end - edge_start).normalized()
	var edge_normal: Vector2 = Vector2( - edge_tangent.y, edge_tangent.x)
	var edge_position: Vector2 = (edge_start + edge_end) * 0.5 + edge_normal * (surface_world.LATER_BRANCH_ROUTE_HALF_WIDTH - 0.25)
	surface_world.restore_position(edge_position)
	surface_world.player.set_facing(edge_tangent)
	surface_world.player.set_external_movement((edge_tangent + edge_normal * 0.65).normalized())
	surface_world.player.camera.position_smoothing_enabled = false
	surface_world.player.camera.reset_smoothing()
	performance_qa_mode = "ember_surface"
	performance_qa_active = true
	objective_label.text = "EMBERDEEP WORKS · MOBILE PERFORMANCE"
	_set_status("QA · mountain, Fault and both biome seams visible together")
	_refresh_hud()


func _run_journey_performance_qa() -> void :
	DisplayServer.window_set_title("Ever Deeper · Full Journey Performance QA")
	game_started = true
	assert (
		int(ProjectSettings.get_setting("application/run/max_fps", 0)) == 60,
		"The mobile release must keep its 60 FPS ceiling"
	)
	var rows: Array[Dictionary] = []
	var transition_started: int
	var transition_ms: float

	transition_started = Time.get_ticks_usec()
	_start_qa_surface_camp()
	for world_id_value in ["moonglass", "emberdeep", "starfall"]:
		RunState.unlock_world(String(world_id_value))
	surface_world.restore_position(Vector2(surface_world.MOSS_WAYFARER_POSITION))
	surface_world.player.set_external_movement(Vector2.RIGHT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("surface_wayfarer", transition_ms))

	transition_started = Time.get_ticks_usec()
	surface_world.restore_position(Vector2(1070, 650))
	surface_world.player.set_external_movement(Vector2.RIGHT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("surface_moss_moon_seam", transition_ms))

	transition_started = Time.get_ticks_usec()
	surface_world.restore_position(Vector2(3300, 650))
	surface_world.player.set_external_movement(Vector2.RIGHT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("surface_late_worlds", transition_ms))
	surface_world.player.set_external_movement(Vector2.ZERO)

	for mine_id_value in MINE_IDS:
		var mine_id: = String(mine_id_value)
		transition_started = Time.get_ticks_usec()
		_prepare_journey_mine_performance(mine_id)
		transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
		rows.append( await _measure_journey_performance_stage("%s_depth_1" % mine_id, transition_ms))
		mine_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	_start_qa_rootwound("starforge")
	depth_world.player.set_external_movement(Vector2.LEFT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("rootwound_depth_2", transition_ms))
	depth_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	_start_qa_prismatic()
	depth_world.player.set_external_movement(Vector2.LEFT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("prismatic_depth_2", transition_ms))
	depth_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	_start_qa_endgame_depth("emberMine", 2)
	depth_world.player.set_external_movement(Vector2.LEFT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("molten_depth_2", transition_ms))
	depth_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	_start_qa_endgame_depth("starMine", 3)
	depth_world.player.set_external_movement(Vector2.LEFT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("voidstar_depth_2", transition_ms))
	depth_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	_start_qa_hub()
	hub_world.player.set_external_movement(Vector2.RIGHT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("base_hub", transition_ms))
	hub_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	_start_qa_deepheart()
	deepheart_world.player.set_external_movement(Vector2.RIGHT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("deepheart", transition_ms))
	deepheart_world.player.set_external_movement(Vector2.ZERO)

	var surface_budget: Dictionary = surface_world.mobile_performance_snapshot()
	assert (int(surface_budget.get("moss_bank_shader_taps", 99)) <= 5)
	var surface_drop_budget: Dictionary = surface_world.assert_surface_loose_drop_budget()
	assert (int(surface_drop_budget.get("live", 999)) <= int(surface_drop_budget.get("total_limit", 0)))
	var hub_belt_budget: Dictionary = hub_world.belt_performance_snapshot()
	assert (is_equal_approx(float(hub_belt_budget.get("visual_hz", 0.0)), 30.0))
	assert (int(hub_belt_budget.get("max_draw_packets", 999)) <= 48)
	var mine_lighting: Dictionary = mine_world.lighting_snapshot()
	assert (int(mine_lighting.get("visible_count", 999)) <= int(mine_lighting.get("max_visible", 0)))
	var depth_lighting: Dictionary = depth_world.lighting_snapshot()
	assert (int(depth_lighting.get("active_count", 999)) <= int(depth_lighting.get("max_active", 0)))
	var save_budget: Dictionary = _measure_journey_mature_save()
	assert (float(save_budget.save_ms) <= JOURNEY_PERFORMANCE_MAX_SAVE_MS)
	assert (int(save_budget.bytes) <= JOURNEY_PERFORMANCE_MAX_SAVE_BYTES)

	var worst_p95_ms: = 0.0
	var worst_frame_ms: = 0.0
	var slow_frame_total: = 0
	var max_static_bytes: = 0
	for row in rows:
		worst_p95_ms = maxf(worst_p95_ms, float(row.p95_ms))
		worst_frame_ms = maxf(worst_frame_ms, float(row.max_ms))
		slow_frame_total += int(row.slow_frames)
		max_static_bytes = maxi(max_static_bytes, int(row.static_bytes))
		assert (
			float(row.average_fps) >= JOURNEY_PERFORMANCE_MIN_PREFLIGHT_FPS,
			"%s fell below the native preflight floor" % String(row.stage)
		)
		assert (
			float(row.p95_ms) <= JOURNEY_PERFORMANCE_P95_LIMIT_MS,
			"%s exceeded the p95 frame budget" % String(row.stage)
		)
		assert (
			float(row.max_ms) <= JOURNEY_PERFORMANCE_MAX_FRAME_MS,
			"%s produced a catastrophic render stall" % String(row.stage)
		)
		assert (
			float(row.transition_ms) <= JOURNEY_PERFORMANCE_MAX_TRANSITION_MS,
			"%s transition exceeded the cold-load budget" % String(row.stage)
		)
	assert (max_static_bytes <= JOURNEY_PERFORMANCE_MAX_STATIC_BYTES)
	print(
		"EVER_DEEPER_JOURNEY_PERFORMANCE_OK stages=%d target_fps=60 worst_p95_ms=%.2f max_frame_ms=%.2f slow_frames=%d max_static_mib=%.1f mature_save_ms=%.2f mature_save_kib=%.1f"
		%[
			rows.size(), worst_p95_ms, worst_frame_ms, slow_frame_total,
			float(max_static_bytes) / (1024.0 * 1024.0),
			float(save_budget.save_ms), float(save_budget.bytes) / 1024.0,
		]
	)
	get_tree().quit(0)


func _prepare_journey_mine_performance(mine_id: String) -> void :
	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.unlock_world(String(WORLD_BY_MINE[mine_id]))
	_enter_mine(mine_id, false, false)
	mine_world.restore_position(Vector2(300, 624))
	mine_world.player.set_facing(Vector2.RIGHT)
	mine_world.player.camera.position_smoothing_enabled = false
	mine_world.player.camera.reset_smoothing()
	mine_world.player.set_external_movement(Vector2.RIGHT)


func _measure_journey_performance_stage(stage: String, transition_ms: float) -> Dictionary:
	await get_tree().create_timer(JOURNEY_PERFORMANCE_WARMUP_SECONDS).timeout
	var frame_times_ms: Array[float] = []
	var previous_usec: = Time.get_ticks_usec()
	var deadline_usec: = previous_usec + int(JOURNEY_PERFORMANCE_SAMPLE_SECONDS * 1000000.0)
	while Time.get_ticks_usec() < deadline_usec:
		await get_tree().process_frame
		var now_usec: = Time.get_ticks_usec()
		frame_times_ms.append(float(now_usec - previous_usec) / 1000.0)
		previous_usec = now_usec
	var stats: Dictionary = _journey_performance_frame_stats(frame_times_ms)
	stats["stage"] = stage
	stats["transition_ms"] = transition_ms
	stats["static_bytes"] = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	print(
		"EVER_DEEPER_PERFORMANCE_STAGE stage=%s average_fps=%.1f p95_ms=%.2f p99_ms=%.2f max_ms=%.2f slow_frames=%d transition_ms=%.2f static_mib=%.1f"
		%[
			stage, float(stats.average_fps), float(stats.p95_ms), float(stats.p99_ms),
			float(stats.max_ms), int(stats.slow_frames), transition_ms,
			float(stats.static_bytes) / (1024.0 * 1024.0),
		]
	)
	return stats


func _journey_performance_frame_stats(samples_ms: Array[float]) -> Dictionary:
	assert ( not samples_ms.is_empty())
	var sorted_samples: Array[float] = samples_ms.duplicate()
	sorted_samples.sort()
	var total_ms: = 0.0
	var slow_frames: = 0
	for sample_ms in samples_ms:
		total_ms += sample_ms
		if sample_ms > 33.34:
			slow_frames += 1
	var average_ms: = total_ms / float(samples_ms.size())
	return {
		"average_fps": 1000.0 / maxf(0.001, average_ms),
		"p95_ms": _journey_percentile(sorted_samples, 0.95),
		"p99_ms": _journey_percentile(sorted_samples, 0.99),
		"max_ms": float(sorted_samples[-1]),
		"slow_frames": slow_frames,
		"frames": samples_ms.size(),
	}


func _journey_percentile(sorted_samples: Array[float], percentile: float) -> float:
	var index: = clampi(ceili(float(sorted_samples.size()) * percentile) - 1, 0, sorted_samples.size() - 1)
	return float(sorted_samples[index])


func _measure_journey_mature_save() -> Dictionary:
	RunState.begin_state_batch()
	for mine_id_value in MINE_IDS:
		var mine_id: = String(mine_id_value)
		for depth in [1, 2]:
			for cell_index in range(JOURNEY_PERFORMANCE_MATURE_DUG_CELLS):
				RunState.mark_terrain_dug(mine_id, cell_index, depth)
	RunState.end_state_batch()
	assert ( not RunState.mark_terrain_dug("mossMine", JOURNEY_PERFORMANCE_MATURE_DUG_CELLS - 1, 1))
	var save_path: = "user://journey-performance-mature-save-%d.json" % Time.get_ticks_usec()
	var save_started: = Time.get_ticks_usec()
	assert (RunState.save_game(save_path), "Mature journey save failed")
	var save_ms: = float(Time.get_ticks_usec() - save_started) / 1000.0
	var save_file: = FileAccess.open(save_path, FileAccess.READ)
	assert (save_file != null, "Mature journey save could not be reopened")
	var save_bytes: = save_file.get_length()
	save_file = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print(
		"EVER_DEEPER_MATURE_SAVE_OK cells=%d save_ms=%.2f bytes=%d"
		%[MINE_IDS.size() * 2 * JOURNEY_PERFORMANCE_MATURE_DUG_CELLS, save_ms, save_bytes]
	)
	return {"save_ms": save_ms, "bytes": save_bytes}


func _start_qa_starforge() -> void :
	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.unlock_world("starfall")
	RunState.cargo.astralite = 200
	RunState.cargo.crownstone = 200
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	surface_world.set_active(true)
	surface_world.restore_position(surface_world._station_position("starforge") + Vector2(0, 70))
	objective_label.text = _surface_objective()
	_set_status("QA · Starforge ready · choose one final pickaxe form")
	_refresh_hud()


func _start_qa_rootwound(mode: String) -> void :
	RunState.reset_run(false)
	RunState.mark_depth_entrance_discovered("mossMine")
	if mode != "locked":
		RunState.pickaxe_level = 5
		RunState.ember_mastery = 5
		RunState.set_starforge_variant("crusher")
	if mode == "drill":
		RunState.set_drill_level(1)
	_enter_mine("mossMine", false, false)
	mine_world.restore_position(Vector2(mine_world.depth_entrance) + Vector2(92, 0))
	_enter_depth(true, false)
	if mode == "performance":
		performance_qa_mode = "rootwound"
		performance_qa_active = true
		depth_world.player.set_external_movement(Vector2.LEFT)
	_set_status("QA · Rootwound locked without Starforge" if mode == "locked" else "QA · Burrower Drill and Burrowsteel" if mode == "drill" else "QA · complete Mossvein to Rootwound transition" if mode == "loop" else "QA · Starforge Rootwound mining")


func _start_qa_prismatic() -> void :
	RunState.reset_run(false)
	RunState.unlock_world("moonglass")
	RunState.mark_depth_entrance_discovered("moonMine")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(1)
	_enter_mine("moonMine", false, false)
	mine_world.restore_position(Vector2(mine_world.depth_entrance) + Vector2(92, 0))
	_enter_depth(true, false)
	_set_status("QA · Prismatic Depths · Burrower to Pulse Drill route")


func _start_qa_endgame_depth(mine_id: String, qa_drill_level: int, measure_performance: bool = false) -> void :
	RunState.reset_run(false)
	RunState.unlock_world(String(WORLD_BY_MINE[mine_id]))
	RunState.mark_depth_entrance_discovered(mine_id)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(qa_drill_level)
	_enter_mine(mine_id, false, false)
	mine_world.restore_position(Vector2(mine_world.depth_entrance) + Vector2(92, 0))
	_enter_depth(true, false)
	RunState.set_location(mine_id, depth_world.player.global_position, 2)
	if measure_performance:
		performance_qa_mode = "molten"
		performance_qa_active = true
		depth_world.player.set_external_movement(Vector2.LEFT)
	if mine_id == "starMine":
		DisplayServer.window_set_title("Ever Deeper · Voidstar Deepcore QA")
		_set_status("QA · Voidstar Deep · mine a true Singularity Core")
	else:
		DisplayServer.window_set_title("Ever Deeper · Molten Depths QA")
		_set_status("QA · Molten Depths · Pulse Drill and Infernium gates")


func _start_qa_hub() -> void :
	RunState.reset_run(false)
	RunState.unlock_world("starfall")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(3)
	RunState.mark_depth_entrance_discovered("starMine")
	RunState.enter_depth("starMine")
	RunState.set_location("starMine", Vector2(1704, 5160), 2)
	RunState.record_mined("singularity", 1)
	assert (RunState.secure_singularity("singularity"))
	RunState.gold = 1000
	RunState.cargo.stone = 100
	RunState.set_location("surface", Vector2(4245, 650))
	surface_world.restore_position(Vector2(4245, 650))
	_enter_hub(true, false)
	DisplayServer.window_set_title("Ever Deeper · Base Hub QA")
	_set_status("QA · permanent base · museum, workshops, and return without resetting")


func _start_qa_deepheart() -> void :
	RunState.reset_run(false)
	RunState.unlock_world("starfall")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(3)
	RunState.current_scene = "starMine"
	RunState.current_depth = 2
	RunState.record_mined("singularity", 1)
	assert (RunState.secure_singularity("singularity"))
	RunState.cargo.ambercore = 3
	RunState.cargo.lunacore = 3
	RunState.cargo.furnaceheart = 3
	RunState.cargo.singularity = 1
	for resource_id_value in ["ambercore", "lunacore", "furnaceheart", "singularity"]:
		var resource_id: = String(resource_id_value)
		assert (bool(RunState.deliver_deep_elevator_material(resource_id, int(RunState.cargo[resource_id])).get("ok", false)))
	assert (RunState.power_deep_elevator())
	game_started = true
	_enter_hub(false, false)
	hub_world.restore_position(Vector2(720, 280))
	_enter_deepheart(true, false)
	RunState.set_location("deepheart", deepheart_world.player.global_position, 1)
	DisplayServer.window_set_title("Ever Deeper · Deepheart Finale QA")
	_set_status("Four worlds are ready · awaken one resonance at a time")


func _run_endgame_qa() -> void :
	RunState.reset_run(false)
	game_started = true
	RunState.unlock_world("starfall")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(3)
	RunState.current_scene = "starMine"
	RunState.current_depth = 2
	RunState.add_resource("singularity", 1, true)
	if not _endgame_qa_require(bool(RunState.singularity_secured), "singularity_pickup"):
		return
	if not _endgame_qa_require(int(RunState.cargo.get("singularity", 0)) == 1, "singularity_cargo"):
		return

	var recipe: = Dictionary(RunState.deep_elevator_recipe())
	for resource_id_value in recipe:
		var resource_id: = String(resource_id_value)
		var required: = int(recipe[resource_id])
		var carried: = int(RunState.cargo.get(resource_id, 0))
		if carried < required:
			RunState.add_resource(resource_id, required - carried, true)
		var delivery: = Dictionary(RunState.deliver_deep_elevator_material(resource_id, required))
		if not _endgame_qa_require(bool(delivery.get("ok", false)), "deliver_%s" % resource_id):
			return
	if not _endgame_qa_require(bool(RunState.deep_elevator_status().get("repaired", false)), "elevator_repaired"):
		return
	if not _endgame_qa_require(RunState.power_deep_elevator(), "elevator_powered"):
		return

	_enter_hub(false, false)
	if not _endgame_qa_require(phase == "hub", "enter_hub"):
		return
	_enter_deepheart(true, false)
	if not _endgame_qa_require(phase == "deepheart" and bool(RunState.final_expedition_begun), "enter_deepheart"):
		return
	for seal_id_value in RunState.DEEPHEART_SEAL_IDS:
		var seal_id: = String(seal_id_value)
		if not _endgame_qa_require(RunState.open_deepheart_seal(seal_id), "seal_%s" % seal_id):
			return
	if not _endgame_qa_require(bool(RunState.deepheart_seal_status().get("all_open", false)), "all_seals"):
		return
	if not _endgame_qa_require(RunState.complete_final_expedition(), "complete_final_expedition"):
		return
	if not _endgame_qa_require(bool(RunState.victory), "victory"):
		return

	_on_deepheart_finale_completed()
	if not _endgame_qa_require(conclusion_overlay.visible and not bool(RunState.conclusion_seen), "conclusion_unseen"):
		return
	_stay_in_deepheart_from_conclusion()
	if not _endgame_qa_require(bool(RunState.conclusion_seen) and not conclusion_overlay.visible and phase == "deepheart", "conclusion_stay"):
		return

	var endless: = Dictionary(RunState.endless_descent_status())
	if not _endgame_qa_require(bool(endless.get("unlocked", false)) and not bool(endless.get("active", false)), "endless_unlock"):
		return
	var goal: = Dictionary(guide_director.goal_for_state())
	if not _endgame_qa_require(String(goal.get("kind", "")) == "endless_enter" and String(goal.get("station_id", "")) == "deepElevator", "endless_guide"):
		return

	_open_deepheart_conclusion()
	if not _endgame_qa_require(conclusion_overlay.visible, "conclusion_reopen"):
		return
	_return_to_hub_from_conclusion()
	if not _endgame_qa_require(phase == "hub" and not conclusion_overlay.visible, "conclusion_return_hub"):
		return
	_enter_deepheart()
	if not _endgame_qa_require(phase == "hub", "victory_reentry_blocked"):
		return
	_on_deep_elevator_enter_requested()
	if not _endgame_qa_require(phase == "endless" and bool(Dictionary(RunState.endless_descent_status()).get("active", false)), "postgame_elevator_enters_endless"):
		return
	var world_snapshot: = Dictionary(endless_world.debug_snapshot())
	if not _endgame_qa_require(bool(world_snapshot.get("path_connected", false)) and not bool(world_snapshot.get("health_required", true)), "endless_world_safe_connected"):
		return
	_on_endless_depth_change_requested(0, "from_below")
	_on_endless_hub_exit_requested()
	if not _endgame_qa_require(phase == "hub" and not bool(Dictionary(RunState.endless_descent_status()).get("active", true)), "endless_return_hub"):
		return

	RunState.set_location("hub", hub_world.player.global_position, 1)
	var saved: = Dictionary(RunState.serialize())
	RunState.reset_run(false)
	if not _endgame_qa_require(RunState.deserialize(saved), "deserialize"):
		return
	var restored_endless: = Dictionary(RunState.endless_descent_status())
	var restored_goal: = Dictionary(guide_director.goal_for_state())
	if not _endgame_qa_require(
		bool(RunState.victory)
		and bool(RunState.conclusion_seen)
		and bool(restored_endless.get("unlocked", false))
		and int(restored_endless.get("deepest_depth", 0)) >= 1
		and String(restored_goal.get("kind", "")) == "endless_enter",
		"persistence"
	):
		return
	print("EVER_DEEPER_ENDGAME_OK seals=4 endless=unlocked gateway=true persistence=true conclusion=true deepheart_reentry=blocked")
	get_tree().quit(0)


func _endgame_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	print("EVER_DEEPER_ENDGAME_FAIL step=%s" % step)
	push_error("Endgame QA failed: %s" % step)
	get_tree().quit(3)
	return false


func _run_endless_qa() -> void :
	if not _prepare_endless_qa_victory():
		_endless_qa_require(false, "victory_setup")
		return
	RunState.mark_conclusion_seen()
	RunState.set_location("hub", Vector2(hub_world.entry_spawn()))
	var legacy_save: = Dictionary(RunState.serialize())
	var legacy_state: = Dictionary(legacy_save.get("state", {}))
	legacy_state.erase("endless_descent")
	legacy_save["state"] = legacy_state
	RunState.reset_run(false)
	if not _endless_qa_require(RunState.deserialize(legacy_save), "legacy_victory_deserialize"):
		return
	var legacy_status: = Dictionary(RunState.endless_descent_status())
	if not _endless_qa_require(bool(RunState.victory) and bool(legacy_status.get("unlocked", false)) and int(legacy_status.get("start_depth", 0)) == 1, "legacy_victory_unlock"):
		return

	game_started = true
	_enter_hub(false, false)
	hub_world.restore_position(Vector2(hub_world.DEEP_ELEVATOR_POSITION))
	if not _endless_qa_require(String(hub_world.current_context()) == "deepElevator", "endless_elevator_context"):
		return
	hub_world.perform_context()
	var entered: = Dictionary(RunState.endless_descent_status())
	if not _endless_qa_require(phase == "endless" and bool(entered.get("active", false)) and int(entered.get("current_depth", 0)) == 1, "enter_endless"):
		return
	if not _endless_qa_require(_endless_premium_asset_contract(), "premium_assets_20"):
		return
	var layout: = Dictionary(endless_world.debug_snapshot())
	var signature: = String(layout.get("signature", ""))
	if not _endless_qa_require(
		not signature.is_empty()
		and bool(layout.get("path_connected", false))
		and bool(layout.get("spawn_clear", false))
		and int(layout.get("branch_count", 0)) >= 1
		and int(layout.get("site_count", 0)) >= 2
		and int(layout.get("hazards", 0)) >= 1
		and int(layout.get("enemies", -1)) == 0
		and not bool(layout.get("health_required", true))
		and not bool(layout.get("timer", true))
		and String(layout.get("ruin_gameplay", "")) == "choose_path_then_cross_ordered_floor_seals"
		and String(layout.get("hazard_model", "")) == "telegraphed_resonance_push_no_damage",
		"exploration_layout"
	):
		return
	endless_world.load_depth(1, "from_above")
	if not _endless_qa_require(String(Dictionary(endless_world.debug_snapshot()).get("signature", "")) == signature, "deterministic_layout"):
		return
	var site_result: = Dictionary(endless_world.qa_complete_site_activity(1, "overload"))
	var site_kind: = String(site_result.get("reward_kind", ""))
	var site_reward_after: = int(RunState.cargo.get(site_kind, 0))
	var site_replay: = Dictionary(endless_world.qa_complete_site_activity(1, "overload"))
	var site_state: = Dictionary(RunState.endless_floor_site_state(1, 1))
	if not _endless_qa_require(
		bool(site_result.get("ok", false))
		and String(site_result.get("choice", "")) == "overload"
		and not site_kind.is_empty()
		and site_reward_after > 0
		and not bool(site_replay.get("ok", false))
		and int(RunState.cargo.get(site_kind, 0)) == site_reward_after
		and bool(site_state.get("resolved", false))
		and String(site_state.get("choice", "")) == "overload",
		"site_activity_one_claim"
	):
		return
	var hazard_probe: = Dictionary(endless_world.qa_resonance_hazard_probe())
	if not _endless_qa_require(
		bool(hazard_probe.get("found", false))
		and bool(hazard_probe.get("telegraphed", false))
		and bool(hazard_probe.get("triggered", false))
		and bool(hazard_probe.get("pushed", false))
		and bool(hazard_probe.get("player_clear", false)),
		"resonance_hazard"
	):
		return
	if not _endless_qa_require(RunState.collect_endless_resource("deep_alloy", 199) and int(RunState.cargo.get("deep_alloy", 0)) == 199, "resource_199"):
		return

	endless_world.restore_position(Vector2(endless_world.native_relic_position))
	endless_world._update_discoveries()
	if not _endless_qa_require(String(endless_world.current_context()) == "endless_relic:forge_heart", "relic_context"):
		return
	endless_world.perform_context()
	if not _endless_qa_require(bool(Dictionary(RunState.relic_status("forge_heart")).get("attached", false)), "relic_attach"):
		return
	var rope: = Dictionary(Dictionary(endless_world.debug_snapshot()).get("rope", {}))
	if not _endless_qa_require(bool(rope.get("attached", false)) and bool(rope.get("finite", false)) and int(rope.get("point_count", 0)) > 2, "rope_physics"):
		return
	if not _endless_qa_require(String(Dictionary(guide_director.goal_for_state()).get("kind", "")) == "endless_return", "haul_guide"):
		return
	_on_endless_depth_change_requested(0, "from_below")
	_on_endless_hub_exit_requested()
	var hauled: = Dictionary(RunState.relic_status("forge_heart"))
	if not _endless_qa_require(phase == "hub" and bool(hauled.get("carried", false)) and bool(hauled.get("attached", false)), "haul_to_hub"):
		return
	if not _endless_qa_require(String(Dictionary(guide_director.goal_for_state()).get("kind", "")) == "relic_place", "placement_guide"):
		return
	hub_world.restore_position(Vector2(hub_world.DEEP_ELEVATOR_POSITION))
	hub_world.perform_context()
	if not _endless_qa_require(phase == "hub", "carried_relic_blocks_descent"):
		return
	hub_world.restore_position(Vector2(hub_world.RELIC_PEDESTAL_POSITION))
	if not _endless_qa_require(String(hub_world.current_context()) == "relicPedestal", "relic_pedestal_context"):
		return
	if not _endless_qa_require(
		hub_world.qa_set_hub_relic_endpoint(
			Vector2(hub_world.RELIC_PEDESTAL_POSITION) + Vector2(180, -16)
		),
		"relic_endpoint_far_setup"
	):
		return
	hub_world.perform_context()
	if not _endless_qa_require(
		not bool(Dictionary(RunState.relic_status("forge_heart")).get("placed", false)),
		"relic_endpoint_gate"
	):
		return
	if not _endless_qa_require(
		hub_world.qa_set_hub_relic_endpoint(
			Vector2(hub_world.RELIC_PEDESTAL_POSITION) + Vector2(0, -16)
		),
		"relic_endpoint_near_setup"
	):
		return
	hub_world.perform_context()
	var placement: = Dictionary(RunState.relic_status("forge_heart"))
	if not _endless_qa_require(bool(placement.get("placed", false)) and bool(Dictionary(RunState.workshop_status("tool_forge")).get("blueprint_unlocked", false)), "place_and_blueprint"):
		return
	var partial: = Dictionary(RunState.deliver_workshop_material("tool_forge", "deep_alloy", 199))
	var early_build: = Dictionary(RunState.build_workshop("tool_forge"))
	if not _endless_qa_require(bool(partial.get("ok", false)) and int(partial.get("remaining", -1)) == 1 and not bool(early_build.get("ok", true)), "workshop_199_fails"):
		return

	_enter_endless(true, false)
	if not _endless_qa_require(
		int(Dictionary(endless_world.debug_snapshot()).get("resource_count", -1)) == 0
		and int(Dictionary(RunState.endless_descent_status()).get("resource_exhausted_through", 0)) >= 1,
		"exhausted_floor_does_not_respawn"
	):
		return
	if not _endless_qa_require(RunState.collect_endless_resource("deep_alloy", 1), "resource_200"):
		return
	_on_endless_depth_change_requested(0, "from_below")
	_on_endless_hub_exit_requested()
	hub_world.restore_position(Vector2(hub_world.WORKSHOP_POSITIONS.tool_forge))
	if not _endless_qa_require(String(hub_world.current_context()) == "workshop:tool_forge", "tool_forge_context"):
		return
	hub_world.perform_context()
	var ready_tool_forge: = Dictionary(RunState.workshop_status("tool_forge"))
	if not _endless_qa_require(
		bool(ready_tool_forge.get("ready_to_build", false))
		and not bool(ready_tool_forge.get("built", false))
		and int(ready_tool_forge.get("delivered", 0)) == 200,
		"workshop_200_delivered_not_built"
	):
		return
	hub_world.perform_context()
	if not _endless_qa_require(bool(Dictionary(RunState.workshop_status("tool_forge")).get("built", false)), "workshop_second_press_builds"):
		return


	_enter_endless(true, false)
	_on_endless_depth_change_requested(2, "from_above")
	_on_endless_depth_change_requested(1, "from_below")
	_on_endless_depth_change_requested(0, "from_below")
	_on_endless_hub_exit_requested()
	_enter_endless(true, false)
	if not _endless_qa_require(int(Dictionary(RunState.endless_descent_status()).get("current_depth", 0)) == 1, "lift_checkpoint_locked"):
		return
	if not _endless_qa_require(RunState.collect_endless_resource("waystone", 200), "waystone_200"):
		return
	for next_depth in range(2, 13):
		_on_endless_depth_change_requested(next_depth, "from_above")
	if not _endless_qa_require(RunState.discover_endless_relic("wayfinder_core", 12), "wayfinder_discover"):
		return
	if not _endless_qa_require(bool(Dictionary(RunState.collect_endless_relic("wayfinder_core", 12)).get("ok", false)) and RunState.attach_carried_relic("wayfinder_core"), "wayfinder_attach"):
		return
	for next_depth in range(11, -1, -1):
		_on_endless_depth_change_requested(next_depth, "from_below")
	_on_endless_hub_exit_requested()
	if not _endless_qa_require(bool(Dictionary(RunState.place_carried_relic()).get("ok", false)), "wayfinder_place"):
		return
	if not _endless_qa_require(bool(Dictionary(RunState.deliver_workshop_material("lift_workshop", "waystone", 200)).get("ok", false)), "lift_materials"):
		return
	if not _endless_qa_require(bool(Dictionary(RunState.build_workshop("lift_workshop")).get("ok", false)), "lift_build"):
		return
	_enter_endless(true, false)
	_on_endless_depth_change_requested(2, "from_above")
	_on_endless_depth_change_requested(3, "from_above")
	if not _endless_qa_require(int(Dictionary(RunState.endless_descent_status()).get("start_depth", 0)) == 3, "lift_checkpoint_saved"):
		return
	_on_endless_depth_change_requested(2, "from_below")
	_on_endless_depth_change_requested(1, "from_below")
	_on_endless_depth_change_requested(0, "from_below")
	_on_endless_hub_exit_requested()
	_enter_endless(true, false)
	if not _endless_qa_require(int(Dictionary(RunState.endless_descent_status()).get("current_depth", 0)) == 3, "lift_checkpoint_restored"):
		return

	RunState.set_location("endless", endless_world.player.global_position)
	var saved: = Dictionary(RunState.serialize())
	RunState.reset_run(false)
	if not _endless_qa_require(RunState.deserialize(saved), "save_reload"):
		return
	var restored: = Dictionary(RunState.endless_descent_status())
	if not _endless_qa_require(
		String(RunState.current_scene) == "endless"
		and bool(restored.get("active", false))
		and int(restored.get("current_depth", 0)) == 3
		and bool(Dictionary(RunState.workshop_status("tool_forge")).get("built", false))
		and bool(Dictionary(RunState.workshop_status("lift_workshop")).get("built", false)),
		"persistent_endless_run"
	):
		return
	phase = "surface"
	endless_world.set_active(false)
	_restore_saved_location()
	if not _endless_qa_require(phase == "endless" and int(endless_world.configured_depth()) == 3, "restore_scene"):
		return
	print("EVER_DEEPER_ENDLESS_OK legacy=true depth=3 deterministic=true hazards=telegraphed sites=active cache=one_claim rope=true relic=physical assets=20 blueprint=tool_forge materials=200 workshop=two_press lift_checkpoint=true persistence=true")
	get_tree().quit(0)


func _endless_premium_asset_contract() -> bool:
	var paths: Array[String] = [
		"res://assets/endless/node-lumen-shard-v1.png",
		"res://assets/endless/node-deep-alloy-v1.png",
		"res://assets/endless/node-memory-silk-v1.png",
		"res://assets/endless/node-echo-crystal-v1.png",
		"res://assets/endless/node-waystone-v1.png",
		"res://assets/endless/relic-forge-heart-v1.png",
		"res://assets/endless/relic-ancient-lens-v1.png",
		"res://assets/endless/relic-memory-loom-v1.png",
		"res://assets/endless/relic-echo-coffer-v1.png",
		"res://assets/endless/relic-wayfinder-core-v1.png",
		"res://assets/endless/ruin-survey-camp-v1.png",
		"res://assets/endless/ruin-archive-v1.png",
		"res://assets/endless/ruin-silent-machine-v1.png",
		"res://assets/endless/ruin-mineral-shrine-v1.png",
		"res://assets/endless/workshop-tool-forge-v1.png",
		"res://assets/endless/workshop-light-lab-v1.png",
		"res://assets/endless/workshop-wardrobe-v1.png",
		"res://assets/endless/workshop-lift-v1.png",
		"res://assets/endless/treasure-chamber-v1.png",
		"res://assets/endless/relic-pedestal-v1.png",
	]
	if paths.size() != 20:
		return false
	for path in paths:
		if not ResourceLoader.exists(path):
			return false
		var texture: Texture2D = load(path) as Texture2D
		if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0:
			return false
	return true


func _prepare_endless_qa_victory() -> bool:
	RunState.reset_run(false)
	RunState.unlock_world("starfall")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(3)
	RunState.current_scene = "starMine"
	RunState.current_depth = 2
	RunState.add_resource("singularity", 1, true)
	var recipe: = Dictionary(RunState.deep_elevator_recipe())
	for resource_id_value in recipe:
		var resource_id: = String(resource_id_value)
		var required: = int(recipe[resource_id])
		var carried: = int(RunState.cargo.get(resource_id, 0))
		if carried < required:
			RunState.add_resource(resource_id, required - carried, true)
		if not bool(Dictionary(RunState.deliver_deep_elevator_material(resource_id, required)).get("ok", false)):
			return false
	if not RunState.power_deep_elevator() or not RunState.begin_final_expedition():
		return false
	for seal_id_value in RunState.DEEPHEART_SEAL_IDS:
		if not RunState.open_deepheart_seal(String(seal_id_value)):
			return false
	return RunState.complete_final_expedition()


func _endless_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	print("EVER_DEEPER_ENDLESS_FAIL step=%s" % step)
	push_error("Endless QA failed: %s" % step)
	get_tree().quit(4)
	return false


func _run_crusher_impact_qa() -> void :
	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	mine_world.load_mine("mossMine")
	var tool: = Dictionary(mine_world._current_tool())
	if not _crusher_impact_qa_require(
		String(RunState.starforge_variant) == "crusher"
		and float(tool.get("cooldown", 0.0)) > float(RunState.current_pickaxe().get("cooldown", 0.0)) * 2.0,
		"slow_powerful_profile"
	):
		return

	var center: = Vector2i(20, 20)
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			mine_world.blocks[center + Vector2i(x_offset, y_offset)] = mine_world._make_block("stone", 999, 0, "terrain")
	mine_world._apply_crusher_shockwave(center, tool)
	var affected: = 0
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			var cell: = center + Vector2i(x_offset, y_offset)
			if cell != center and int(Dictionary(mine_world.blocks[cell]).get("hp", 999)) < 999:
				affected += 1
	if not _crusher_impact_qa_require(affected == 24, "full_5x5_footprint"):
		return


	if not _crusher_impact_qa_require(
		mine_world.drops.is_empty() and RunState.mine_loose_loot("mossMine", 1).is_empty(),
		"non_break_has_no_resource_bundles"
	):
		return




	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			mine_world.blocks[center + Vector2i(x_offset, y_offset)] = mine_world._make_block("stone", 1, 0, "terrain")
	var origin: Vector2 = mine_world._cell_center(center)
	var child_count_before: int = mine_world.get_child_count()
	mine_world._spawn_drop(center, "stone", 1, origin)
	mine_world._apply_crusher_shockwave(center, tool)
	var visual_total: = 0
	var visible_bundles: = 0
	var directions: = Vector4.ZERO
	var visual_by_id: Dictionary = {}
	for drop_value in mine_world.drops:
		var drop: Dictionary = Dictionary(drop_value)
		if not bool(drop.get("crusher_bundle", false)):
			continue
		if not bool(drop.get("visual_suppressed", false)):
			visible_bundles += 1
		var amount: = int(drop.get("amount", 0))
		var persistent_id: = String(drop.get("persistent_id", ""))
		visual_total += amount
		visual_by_id[persistent_id] = {"kind": String(drop.get("kind", "")), "amount": amount}
		var velocity: = Vector2(drop.get("velocity", Vector2.ZERO))
		directions.x += 1.0 if velocity.x < -0.01 else 0.0
		directions.y += 1.0 if velocity.x > 0.01 else 0.0
		directions.z += 1.0 if velocity.y < -0.01 else 0.0
		directions.w += 1.0 if velocity.y > 0.01 else 0.0
	var persistent_total: = 0
	var persistence_matches: = true
	for stored_value in RunState.mine_loose_loot("mossMine", 1):
		var stored: Dictionary = Dictionary(stored_value)
		var stored_id: = String(stored.get("id", ""))
		persistent_total += int(stored.get("amount", 0))
		persistence_matches = (
			persistence_matches
			and visual_by_id.has(stored_id)
			and String(Dictionary(visual_by_id[stored_id]).kind) == String(stored.get("kind", ""))
			and int(Dictionary(visual_by_id[stored_id]).amount) == int(stored.get("amount", 0))
		)
	if not _crusher_impact_qa_require(
		visual_total == 25
		and persistent_total == 25
		and persistence_matches
		and visible_bundles >= 4 and visible_bundles <= 12
		and directions.x > 0.0 and directions.y > 0.0 and directions.z > 0.0 and directions.w > 0.0
		and mine_world.get_child_count() == child_count_before,
		"real_radial_bundles_accounted"
	):
		return



	var sector_zero_index: = -1
	for index in mine_world.drops.size():
		if int(mine_world.drops[index].get("crusher_sector", -1)) == 0:
			sector_zero_index = index
			break
	if not _crusher_impact_qa_require(sector_zero_index >= 0, "radial_sector_zero"):
		return
	var merge_id: = String(mine_world.drops[sector_zero_index].persistent_id)
	var merge_amount: = int(mine_world.drops[sector_zero_index].amount)
	mine_world.drops[sector_zero_index].age = 0.149
	var count_before_merge: int = mine_world.drops.size()
	mine_world._spawn_drop(center + Vector2i(2, 0), "stone", 1, origin)
	if not _crusher_impact_qa_require(
		mine_world.drops.size() == count_before_merge
		and String(mine_world.drops[sector_zero_index].persistent_id) == merge_id
		and int(mine_world.drops[sector_zero_index].amount) == merge_amount + 1,
		"merge_at_0149"
	):
		return
	mine_world.drops[sector_zero_index].age = 0.151
	mine_world._spawn_drop(center + Vector2i(2, 0), "stone", 1, origin)
	if not _crusher_impact_qa_require(mine_world.drops.size() == count_before_merge + 1, "new_bundle_at_0151"):
		return

	var pickup_radii: Array[float] = []
	for drill_level in range(4):
		RunState.drill_level = drill_level
		pickup_radii.append(RunState.resource_pickup_radius(48.0))
	if not _crusher_impact_qa_require(
		pickup_radii == [48.0, 80.0, 112.0, 144.0]
		and is_equal_approx(RunState.resource_pickup_radius(48.0, "singularity"), 48.0)
		and is_equal_approx(RunState.resource_pickup_radius(52.0), 148.0),
		"drill_pickup_range"
	):
		return
	RunState.drill_level = 1
	var crusher_bundle_snapshot: Array[Dictionary] = mine_world.drops.duplicate(true)
	mine_world.drops.clear()
	var magnet_target: Vector2 = mine_world.player.global_position + Vector2(100.0, -24.0)
	mine_world.drops.append({
		"kind": "stone",
		"amount": 1,
		"position": magnet_target,
		"velocity": Vector2.ZERO,
		"age": 0.2,
		"pocket_reward_id": "",
		"persistent_id": "",
		"settled_persisted": true,
	})
	mine_world._update_drops(1.0 / 60.0)
	var basic_distance: float = Vector2(mine_world.drops[0].position).distance_to(
		mine_world.player.global_position + Vector2(0, -24)
	)
	RunState.drill_level = 2
	mine_world._update_drops(1.0 / 60.0)
	var drill_distance: float = Vector2(mine_world.drops[0].position).distance_to(
		mine_world.player.global_position + Vector2(0, -24)
	)
	if not _crusher_impact_qa_require(
		is_equal_approx(basic_distance, 100.0) and drill_distance < basic_distance,
		"drill_pickup_magnet"
	):
		return
	mine_world.drops.assign(crusher_bundle_snapshot)
	RunState.drill_level = 3
	var drill_tool: = Dictionary(mine_world._current_tool())
	var drill_impact: = {
		"style": mine_world._tool_impact_style(drill_tool),
		"broken": true,
	}
	mine_world._attach_crusher_debris(drill_impact, center)
	if not _crusher_impact_qa_require(
		bool(drill_tool.get("is_drill", false))
		and String(drill_impact.style) == "drill"
		and bool(drill_impact.get("crusher_force", false))
		and not drill_impact.has("crusher_chunks"),
		"crusher_attunes_drill_visual"
	):
		return



	var generated_total: = 27
	var stress_kinds: = ["stone", "copper", "gold"]
	for event_index in range(600):
		for drop_index in mine_world.drops.size():
			if bool(mine_world.drops[drop_index].get("crusher_bundle", false)):
				mine_world.drops[drop_index].age = maxf(0.151, float(mine_world.drops[drop_index].age))
		var sector: = event_index % 8
		var offset: = Vector2.from_angle(float(sector) * TAU / 8.0) * 96.0
		var spawn_cell: Vector2i = mine_world._world_to_cell(origin + offset)
		mine_world._spawn_drop(spawn_cell, String(stress_kinds[event_index % stress_kinds.size()]), 1, origin)
		generated_total += 1
		if not _crusher_impact_qa_require(
			mine_world._visible_crusher_bundle_count() <= 12
			and mine_world.get_child_count() == child_count_before,
			"super_drill_bundle_cap"
		):
			return
	for drop_index in mine_world.drops.size():
		if bool(mine_world.drops[drop_index].get("crusher_bundle", false)):
			mine_world.drops[drop_index].age = 1.0
			mine_world.drops[drop_index].crusher_flight_age = 1.0
	mine_world._spawn_drop(center + Vector2i(2, 0), "stone", 1, origin)
	generated_total += 1
	var relaunched_without_lifetime_reset: = false
	for drop in mine_world.drops:
		relaunched_without_lifetime_reset = (
			relaunched_without_lifetime_reset
			or (
				bool(drop.get("crusher_bundle", false))
				and float(drop.get("age", 0.0)) >= 1.0
				and is_zero_approx(float(drop.get("crusher_flight_age", -1.0)))
			)
		)
	if not _crusher_impact_qa_require(
		relaunched_without_lifetime_reset,
		"capped_merge_relaunches_before_magnet"
	):
		return
	visual_total = 0
	for drop in mine_world.drops:
		visual_total += int(drop.get("amount", 0))
	persistent_total = 0
	for stored in RunState.mine_loose_loot("mossMine", 1):
		persistent_total += int(Dictionary(stored).get("amount", 0))
	if not _crusher_impact_qa_require(
		visual_total == generated_total and persistent_total == generated_total,
		"super_drill_exact_accounting"
	):
		return



	mine_world._restore_persistent_loose_loot()
	var restored_total: = 0
	for restored_drop in mine_world.drops:
		restored_total += int(restored_drop.get("amount", 0))
	if not _crusher_impact_qa_require(restored_total == generated_total, "reload_preserves_total"):
		return
	mine_world.player.global_position = origin
	var collect_position: = origin + Vector2(0, -24)
	for drop_index in mine_world.drops.size():
		mine_world.drops[drop_index].position = collect_position
		mine_world.drops[drop_index].velocity = Vector2.ZERO
		mine_world.drops[drop_index].age = 1.0
		RunState.update_mine_loose_loot_position(
			"mossMine", 1, String(mine_world.drops[drop_index].persistent_id), collect_position
		)
	mine_world._update_drops(1.0 / 60.0)
	var cargo_total: = 0
	for resource_value in stress_kinds:
		cargo_total += int(RunState.cargo.get(String(resource_value), 0))
	if not _crusher_impact_qa_require(
		mine_world.drops.is_empty()
		and RunState.mine_loose_loot("mossMine", 1).is_empty()
		and cargo_total == generated_total,
		"magnet_collection_exact"
	):
		return

	mine_world.impacts.clear()
	mine_world.impacts.append({
		"position": mine_world._cell_center(center),
		"age": 0.0,
		"life": 0.3,
		"broken": true,
		"style": "crusher",
		"crusher_force": true,
	})
	mine_world._update_impacts(0.31)
	if not _crusher_impact_qa_require(
		mine_world.impacts.is_empty() and mine_world.drops.is_empty(),
		"short_force_cleanup"
	):
		return


	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	depth_world.load_depth("mossMine")
	depth_world.drops.clear()
	var depth_center: = Vector2i(24, 24)
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			var depth_cell: = depth_center + Vector2i(x_offset, y_offset)
			var depth_index: int = depth_world._cell_index(depth_cell)
			depth_world.dug_indices.erase(depth_index)
			depth_world.terrain_hp[depth_index] = 1
	depth_world._apply_depth_crusher_wave(depth_center, Dictionary(depth_world._current_tool()))
	var depth_visual_total: = 0
	var depth_visible_bundles: = 0
	var depth_kinds_valid: = true
	for depth_drop_value in depth_world.drops:
		var depth_drop: Dictionary = Dictionary(depth_drop_value)
		depth_visual_total += int(depth_drop.get("amount", 0))
		depth_kinds_valid = depth_kinds_valid and String(depth_drop.get("kind", "")) == "deepstone"
		if not bool(depth_drop.get("visual_suppressed", false)):
			depth_visible_bundles += 1
	var depth_persistent_total: = 0
	for depth_stored_value in RunState.mine_loose_loot("mossMine", 2):
		depth_persistent_total += int(Dictionary(depth_stored_value).get("amount", 0))
	if not _crusher_impact_qa_require(
		depth_visual_total == 24
		and depth_persistent_total == 24
		and depth_kinds_valid
		and depth_visible_bundles >= 4 and depth_visible_bundles <= 12,
		"depth_two_bundle_parity"
	):
		return
	print("EVER_DEEPER_CRUSHER_IMPACT_OK footprint=5x5 real_loot=true sectors=8 bundles_max=12 merge_window=0.15 arc=true drill_stress=600 accounting=exact depth2=true pickup=48/80/112/144 singularity=48 cleanup=0.30")
	get_tree().quit(0)


func _crusher_impact_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	push_error("EVER_DEEPER_CRUSHER_IMPACT_FAIL step=%s" % step)
	get_tree().quit(7)
	return false


func _run_workshop_overlap_qa() -> void :
	RunState.reset_run(false)
	_dev_seed_victory_state()
	if not _workshop_overlap_qa_require(_dev_grant_all_relics_state(), "relic_setup"):
		return
	var workshop_id: = "light_lab"
	var status: = Dictionary(RunState.workshop_status(workshop_id))
	var resource_id: = String(status.get("build_resource", ""))
	var remaining: = int(status.get("remaining", 0))
	RunState.add_resource(resource_id, remaining, false)
	var delivery: = Dictionary(RunState.deliver_workshop_material(workshop_id, resource_id, remaining))
	if not _workshop_overlap_qa_require(bool(delivery.get("ok", false)), "materials"):
		return
	game_started = true
	_enter_hub(false, false)
	var site: = Vector2(hub_world.WORKSHOP_POSITIONS[workshop_id])
	var overlap_position: = site + Vector2(0, 60)
	hub_world.restore_position(overlap_position)
	if not _workshop_overlap_qa_require(
		hub_world.player.global_position.is_equal_approx(overlap_position)
		and String(hub_world.current_context()) == "workshop:%s" % workshop_id,
		"overlap_setup"
	):
		return
	hub_world.perform_context()
	if not _workshop_overlap_qa_require(
		bool(Dictionary(RunState.workshop_status(workshop_id)).get("built", false)),
		"built"
	):
		return
	if not _workshop_overlap_qa_require(hub_world.player_position_clear(), "escaped"):
		return
	var safe_position: Vector2 = Vector2(hub_world.player.global_position)
	var resolved: = Vector2(hub_world._resolve_motion(safe_position, Vector2(0, 8)))
	if not _workshop_overlap_qa_require(
		resolved.distance_squared_to(safe_position) > 1.0,
		"movable"
	):
		return
	hub_world.restore_position(site)
	if not _workshop_overlap_qa_require(hub_world.player_position_clear(), "restore_recovery"):
		return
	var clear_restore: = site + Vector2(0, 104)
	hub_world.restore_position(clear_restore)
	if not _workshop_overlap_qa_require(
		hub_world.player.global_position.is_equal_approx(clear_restore),
		"safe_restore_exact"
	):
		return
	print("EVER_DEEPER_WORKSHOP_OVERLAP_OK workshop=light_lab built=true escaped=true movable=true restore=true")
	get_tree().quit(0)


func _workshop_overlap_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	push_error("EVER_DEEPER_WORKSHOP_OVERLAP_FAIL step=%s" % step)
	get_tree().quit(5)
	return false


func _run_commerce_integration_qa() -> void :
	RunState.reset_run(false)
	game_started = true
	phase = "surface"
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	surface_world.reset_for_new_run()
	surface_world.set_active(true)

	RunState.add_resource("stone", 4, false)
	RunState.add_resource("copper", 3, false)
	var expected_sale: = (
		4 * int(GameData.data.ROCK_TYPES.stone.value)
		+ 3 * int(GameData.data.ROCK_TYPES.copper.value)
	)
	assay_auto_armed = true
	surface_world.restore_position(surface_world.station_interaction_position("sell"))
	assert (surface_context == "sell" and assay_auto_armed)
	_start_assay_transaction()
	assert ( not assay_auto_armed and station_transaction_fx.busy and String(commerce_transaction.get("kind", "")) == "assay")
	assert (surface_world.player.control_enabled, "Assay presentation must never lock movement")
	var assay_state_id: = String(commerce_transaction.get("state_id", ""))
	_start_assay_transaction()
	assert (String(commerce_transaction.get("state_id", "")) == assay_state_id, "Standing in Assay must not create a duplicate sale")
	var assay_fx: Dictionary = Dictionary(station_transaction_fx.debug_snapshot())
	assert (int(assay_fx.get("visual_cap", 0)) <= 16 and not bool(assay_fx.get("per_visual_nodes", true)))
	station_transaction_fx.complete_immediately()
	assert (RunState.gold == expected_sale and int(RunState.cargo.stone) == 0 and int(RunState.cargo.copper) == 0)
	assert (commerce_transaction.is_empty() and commerce_presented_gold < 0)
	surface_world.restore_position(Vector2(240, 680))
	assert (assay_auto_armed, "Assay must re-arm only after the player leaves")

	var forge_cost: = int(RunState.next_pickaxe().cost)
	RunState.gold = forge_cost
	surface_world.restore_position(surface_world.station_interaction_position("forge"))
	_perform_context()
	assert (commerce_panel.is_open() and commerce_context == "forge")
	if developer_menu != null:
		assert (not bool(developer_menu.toggle_button.visible), "DEV toggle must be suppressed behind commerce")
	var mobile_css_size: = Vector2(844, 390)
	var mobile_scale_to_css: = mobile_css_size.y / 720.0
	var mobile_logical_size: = Vector2(720.0 * mobile_css_size.x / mobile_css_size.y, 720.0)
	var mobile_metrics: Dictionary = Dictionary(commerce_panel.apply_landscape_layout_for_test(mobile_logical_size))
	await get_tree().process_frame
	var mobile_panel_snapshot: Dictionary = Dictionary(commerce_panel.interaction_snapshot())
	assert (bool(mobile_metrics.get("fits_width", false)) and bool(mobile_metrics.get("fits_height", false)))
	assert (bool(mobile_panel_snapshot.get("touch_targets_valid", false)))
	assert (float(mobile_panel_snapshot.get("touch_target_rendered_minimum", 0.0)) * mobile_scale_to_css >= 44.0)
	assert (float(mobile_panel_snapshot.get("minimum_font_size", 0)) * mobile_scale_to_css >= 10.0)
	var pickaxe_before: = int(RunState.pickaxe_level)
	_on_commerce_action_confirmed("forge:pickaxe")
	assert ( not commerce_panel.is_open() and surface_world.player.control_enabled)
	if developer_menu != null:
		assert (bool(developer_menu.toggle_button.visible), "DEV toggle must return after commerce closes")
	assert (RunState.pickaxe_level == pickaxe_before, "Forge economy must commit after its presentation")
	assert (station_transaction_fx.busy and commerce_presented_gold == forge_cost)
	station_transaction_fx.complete_immediately()
	assert (RunState.pickaxe_level == pickaxe_before + 1 and RunState.gold == 0)
	assert (gold_label.text == "0 GOLD" and premium_hud.gold_value.text == "0")

	var wayfarer_cost: = int(RunState.movement_speed_upgrade_cost())
	RunState.gold = wayfarer_cost
	surface_world.restore_position(surface_world.station_interaction_position("speedShop"))
	_perform_context()
	assert (commerce_panel.is_open() and commerce_panel.selected_item_id() == "wayfarer:speed")
	_on_commerce_action_confirmed("wayfarer:speed")
	assert (RunState.movement_speed_level == 1 and commerce_presented_gold == wayfarer_cost)
	station_transaction_fx.complete_immediately()
	assert (RunState.gold == 0 and commerce_presented_gold < 0)
	assert (is_equal_approx(surface_world.player.movement_speed, float(GameData.data.PLAYER_SPEED) * 1.07))

	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.unlock_world("starfall")
	RunState.cargo.astralite = 200
	RunState.cargo.crownstone = 200
	surface_world.restore_position(surface_world.station_interaction_position("starforge"))
	_perform_context()
	var starforge_panel_snapshot: Dictionary = Dictionary(commerce_panel.interaction_snapshot())
	assert (bool(starforge_panel_snapshot.get("open", false)) and int(starforge_panel_snapshot.get("item_count", 0)) == 3)
	assert ( not starforge_panel.visible, "Legacy Starforge buttons must remain retired")
	_on_commerce_action_confirmed("starforge:crusher")
	assert (String(RunState.starforge_variant) == "crusher")
	assert (int(RunState.cargo.astralite) == 0 and int(RunState.cargo.crownstone) == 0)
	station_transaction_fx.complete_immediately()
	assert (commerce_transaction.is_empty() and surface_world.player.control_enabled)

	_dev_seed_victory_state()
	assert (_dev_build_all_workshops_state())
	var workshop_catalog_count: = 0
	for workshop_id_value in RunState.ENDLESS_WORKSHOP_IDS:
		var workshop_id: = String(workshop_id_value)
		var workshop_config: Dictionary = Dictionary(CommerceCatalogScript.workshop_config(
			workshop_id,
			Dictionary(RunState.workshop_status(workshop_id)),
			Dictionary(hub_world.workshop_selection_preview(workshop_id))
		))
		assert ( not Array(workshop_config.get("items", [])).is_empty(), "%s commerce catalog must contain an inspectable item" % workshop_id)
		workshop_catalog_count += 1
	assert (workshop_catalog_count == 5)

	print("EVER_DEEPER_COMMERCE_OK assay=auto_movable_once wallet=ticked forge=deferred wayfarer=menu starforge=3 workshops=5 mobile_css=844x390-956x440 touch>=44 cap=16")
	get_tree().quit(0)


func _run_workshop_panel_qa() -> void :
	RunState.reset_run(false)
	_dev_seed_victory_state()
	if not _workshop_panel_qa_require(_dev_grant_all_relics_state(), "relic_setup"):
		return
	var workshop_id: = "tool_forge"
	var initial: = Dictionary(RunState.workshop_status(workshop_id))
	var resource_id: = String(initial.get("build_resource", ""))
	var required: = int(initial.get("remaining", 0))
	RunState.add_resource(resource_id, required, false)
	game_started = true
	_enter_hub(false, false)
	hub_world.restore_position(Vector2(hub_world.WORKSHOP_POSITIONS[workshop_id]) + Vector2(0, 104))
	if not _workshop_panel_qa_require(String(hub_world.current_context()) == "workshop:%s" % workshop_id, "context"):
		return

	hub_world.perform_context()
	await get_tree().process_frame
	var delivery_visual: = Dictionary(hub_world.qa_workshop_presentation_snapshot())
	var delivery_current: = Dictionary(delivery_visual.get("current", {}))
	if not _workshop_panel_qa_require(
		String(delivery_current.get("kind", "")) == "delivery"
		and int(delivery_current.get("particle_count", 0)) >= 6
		and bool(Dictionary(RunState.workshop_status(workshop_id)).get("ready_to_build", false)),
		"delivery_presentation"
	):
		return

	hub_world.perform_context()
	await get_tree().process_frame
	var build_visual: = Dictionary(hub_world.qa_workshop_presentation_snapshot())
	if not _workshop_panel_qa_require(
		String(Dictionary(build_visual.get("current", {})).get("kind", "")) == "build"
		and int(build_visual.get("serial", 0)) > int(delivery_visual.get("serial", 0))
		and bool(Dictionary(RunState.workshop_status(workshop_id)).get("built", false)),
		"build_presentation"
	):
		return

	RunState.add_resource(resource_id, 100, false)
	var cancel_level_before: = int(Dictionary(RunState.workshop_status(workshop_id)).get("level", 0))
	var cancel_cargo_before: = int(RunState.cargo.get(resource_id, 0))
	hub_world.perform_context()
	await get_tree().process_frame
	var iphone_css_size: = Vector2(844, 390)
	var iphone_scale_to_css: = iphone_css_size.y / 720.0
	var iphone_logical_size: = Vector2(720.0 * iphone_css_size.x / iphone_css_size.y, 720.0)
	var iphone_panel_layout: = Dictionary(commerce_panel.apply_landscape_layout_for_test(iphone_logical_size))
	await get_tree().process_frame
	var panel_snapshot: = Dictionary(commerce_panel.interaction_snapshot())
	if not _workshop_panel_qa_require(
		bool(panel_snapshot.get("open", false))
		and bool(panel_snapshot.get("touch_targets_valid", false))
		and float(panel_snapshot.get("touch_target_rendered_minimum", 0.0)) * iphone_scale_to_css >= 44.0
		and float(panel_snapshot.get("minimum_font_size", 0)) * iphone_scale_to_css >= 10.0
		and bool(iphone_panel_layout.get("fits_width", false))
		and bool(iphone_panel_layout.get("fits_height", false))
		and not bool(hub_world.player.control_enabled)
		and int(Dictionary(RunState.workshop_status(workshop_id)).get("level", 0)) == cancel_level_before
		and int(RunState.cargo.get(resource_id, 0)) == cancel_cargo_before,
		"preview_first_no_transaction"
	):
		return
	commerce_panel.close_commerce()
	if not _workshop_panel_qa_require(
		int(Dictionary(RunState.workshop_status(workshop_id)).get("level", 0)) == cancel_level_before
		and int(RunState.cargo.get(resource_id, 0)) == cancel_cargo_before
		and bool(hub_world.player.control_enabled),
		"cancel_free"
	):
		return

	hub_world.perform_context()
	_on_commerce_action_confirmed("workshop:upgrade")
	await get_tree().process_frame
	var upgraded: = Dictionary(RunState.workshop_status(workshop_id))
	var upgrade_visual: = Dictionary(hub_world.qa_workshop_presentation_snapshot())
	if not _workshop_panel_qa_require(
		int(upgraded.get("level", 0)) == 2
		and int(RunState.cargo.get(resource_id, 0)) == 0
		and String(Dictionary(upgrade_visual.get("current", {})).get("kind", "")) == "upgrade",
		"explicit_upgrade"
	):
		return

	hub_world.perform_context()
	await get_tree().process_frame
	if not _workshop_panel_qa_require(commerce_panel.select_item("workshop:equip:crusher"), "equipment_preview"):
		return
	var loadout_before_cancel: = String(Dictionary(RunState.endless_loadout_status()).get("tool", ""))
	if not _workshop_panel_qa_require(
		loadout_before_cancel == "original"
		and String(Dictionary(Dictionary(hub_world.qa_workshop_presentation_snapshot()).get("panel_preview", {})).get("value", "")) == "crusher",
		"preview_does_not_equip"
	):
		return
	commerce_panel.close_commerce()
	if not _workshop_panel_qa_require(
		String(Dictionary(RunState.endless_loadout_status()).get("tool", "")) == "original"
		and Dictionary(Dictionary(hub_world.qa_workshop_presentation_snapshot()).get("panel_preview", {})).is_empty(),
		"preview_cancel_cleanup"
	):
		return

	hub_world.perform_context()
	await get_tree().process_frame
	if not _workshop_panel_qa_require(commerce_panel.select_item("workshop:equip:crusher"), "equipment_reselect"):
		return
	_on_commerce_action_confirmed("workshop:equip:crusher")
	await get_tree().process_frame
	if not _workshop_panel_qa_require(
		String(Dictionary(RunState.endless_loadout_status()).get("tool", "")) == "crusher"
		and String(Dictionary(Dictionary(hub_world.qa_workshop_presentation_snapshot()).get("current", {})).get("kind", "")) == "equip",
		"explicit_equip"
	):
		return
	hub_world.perform_context()
	await get_tree().process_frame
	if not _workshop_panel_qa_require(commerce_panel.select_item("workshop:style:riveted"), "style_preview"):
		return
	_on_commerce_action_confirmed("workshop:style:riveted")
	if not _workshop_panel_qa_require(String(Dictionary(RunState.workshop_status(workshop_id)).get("style", "")) == "riveted", "explicit_style"):
		return
	hub_world.set_active(false)
	var cleanup: = Dictionary(hub_world.qa_workshop_presentation_snapshot())
	if not _workshop_panel_qa_require(
		not bool(cleanup.get("active", true))
		and String(Dictionary(cleanup.get("last", {})).get("cleanup_reason", "")) == "inactive"
		and Array(cleanup.get("events", [])).size() >= 5,
		"presentation_cleanup"
	):
		return
	print("EVER_DEEPER_WORKSHOP_PANEL_OK preview_first=true cancel_free=true touch=52 delivery=physical build=staged upgrade=staged equip=explicit style=explicit cleanup=true")
	get_tree().quit(0)


func _workshop_panel_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	push_error("EVER_DEEPER_WORKSHOP_PANEL_FAIL step=%s" % step)
	get_tree().quit(6)
	return false


func _exit_mine() -> void :
	var exited_mine: = current_mine_id
	phase = "surface"
	mine_exit_context = false
	mine_depth_context = false
	depth_context = ""
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	surface_world.return_from_mine(exited_mine)
	surface_world.set_active(true)
	AudioDirector.set_environment("surface")
	AudioDirector.play_transition("ascend")
	objective_label.text = _surface_objective()
	_set_status("Back on the road · sell, forge, and continue deeper")
	_refresh_context_button()
	if persistence_active:
		RunState.set_location("surface", surface_world.player.global_position)


func _exit_depth() -> void :
	if phase != "depth":
		return
	phase = "mine"
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	mine_world.set_active(true, false)
	AudioDirector.set_environment("mine")
	AudioDirector.play_transition("ascend")
	mine_world.restore_position(Vector2(mine_world.depth_entrance) + Vector2(92, 0))
	objective_label.text = "%s · %s" % [String(GameData.mine(current_mine_id).name), String(GameData.mine(current_mine_id).finalGoal).to_upper()]
	_set_status("Back in %s Depth 1 · the shaft remains open" % _mine_name(current_mine_id).capitalize())
	_refresh_context_button()
	_refresh_hud()
	if persistence_active:
		RunState.set_location(current_mine_id, mine_world.player.global_position, 1)


func _on_final_resource_mined(resource_id: String) -> void :
	if resource_id != "singularity" or bool(RunState.singularity_secured):
		return
	AudioDirector.play_discovery(true)
	objective_label.text = "SINGULARITY EXPOSED · COLLECT THE CORE"
	_set_status("Singularity Core exposed · collect it to awaken the Starfall base lift")


func _enter_hub(entering: bool = true, persist_location: bool = true) -> void :
	if not RunState.is_hub_unlocked():
		AudioDirector.play_blocked()
		_set_status("The base lift is dormant")
		return
	if entering:
		RunState.begin_state_batch()
		surface_world.persist_ore_mountain_state()
		if not RunState.enter_hub(surface_world.player.global_position):
			RunState.end_state_batch()
			return
	phase = "hub"
	surface_context = ""
	hub_context = ""
	depth_context = ""
	mine_exit_context = false
	mine_depth_context = false
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	_sync_hub_runtime()
	hub_world.set_active(true, entering)
	AudioDirector.set_environment("hub")
	if entering:
		AudioDirector.play_transition("descend")
	hub_context = hub_world.current_context()
	objective_label.text = _hub_objective()
	if bool(RunState.victory):
		_set_status(_deep_hoard_status_text())
	elif RunState.hub_tutorial_pending():
		_set_status("Base Hub unlocked · store ore and return to Starfall whenever you choose")
		RunState.mark_hub_tutorial_seen()
	else:
		_set_status("Base Hub · your expedition remains intact")
	_refresh_context_button()
	_refresh_hud()
	if persistence_active and persist_location:
		RunState.set_location("hub", hub_world.player.global_position)
	if entering:
		RunState.end_state_batch()


func _exit_hub() -> void :
	if phase != "hub":
		return
	_commit_hub_runtime_snapshot()
	if not RunState.exit_hub():
		return
	phase = "surface"
	hub_context = ""
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	hub_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	surface_world.restore_position(Vector2(RunState.current_position))
	surface_world.set_active(true)
	AudioDirector.set_environment("surface")
	AudioDirector.play_transition("ascend")
	objective_label.text = _surface_objective()
	_set_status("Back on Starfall · the base lift remains open")
	_refresh_context_button()
	_refresh_hud()
	if persistence_active:
		RunState.set_location("surface", surface_world.player.global_position)


func _on_deep_elevator_enter_requested() -> void :
	if phase == "hub":
		if bool(RunState.victory):
			_enter_endless()
		else:
			_enter_deepheart()


func _enter_deepheart(entering: bool = true, persist_location: bool = true, allow_victory_restore: bool = false) -> void :
	if bool(RunState.victory) and not allow_victory_restore:
		AudioDirector.play_blocked()
		_set_status("The Deepheart is restored · use the Hub elevator to enter the Endless Descent")
		return
	var elevator_status: = Dictionary(RunState.deep_elevator_status())
	if not bool(elevator_status.get("powered", false)):
		AudioDirector.play_blocked()
		_set_status(_deep_elevator_status_text())
		return
	if phase == "deepheart" and bool(deepheart_world.active):
		return
	if phase == "hub":
		_commit_hub_runtime_snapshot()
		var elevator_position: = Vector2(hub_world.DEEP_ELEVATOR_POSITION)
		var exit_direction: Vector2 = hub_world.player.global_position - elevator_position
		if exit_direction.length_squared() < 1.0:
			exit_direction = Vector2.DOWN
		deepheart_hub_return_position = _safe_hub_return_position(elevator_position + exit_direction.normalized() * 166.0)
	phase = "deepheart"
	surface_context = ""
	mine_exit_context = false
	mine_depth_context = false
	depth_context = ""
	hub_context = ""
	deepheart_context = ""
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(true, entering)
	AudioDirector.set_environment("deepheart")
	if entering:
		AudioDirector.play_transition("depth")
	deepheart_context = String(deepheart_world.active_context)
	objective_label.text = _deepheart_objective()
	_set_status(_deepheart_progress_text())
	_refresh_context_button()
	_refresh_hud()
	if persistence_active and persist_location:
		RunState.set_location("deepheart", deepheart_world.player.global_position, 1)


func _exit_deepheart() -> void :
	if phase != "deepheart":
		return
	_dismiss_deepheart_conclusion(false)
	phase = "hub"
	deepheart_context = ""
	hub_context = ""
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	deepheart_world.set_active(false)
	endless_world.set_active(false)
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	_sync_hub_runtime()
	hub_world.set_active(true, false)
	hub_world.restore_position(_safe_hub_return_position(deepheart_hub_return_position))
	hub_context = hub_world.current_context()
	AudioDirector.set_environment("hub")
	AudioDirector.play_transition("ascend")
	objective_label.text = _hub_objective()
	_set_status(_deep_hoard_status_text() if bool(RunState.victory) else "Back in the Hub · the Deepheart lift remains ready")
	_refresh_context_button()
	_refresh_hud()
	if persistence_active:
		RunState.set_location("hub", hub_world.player.global_position, 1)


func _enter_endless(entering: bool = true, persist_location: bool = true, restoring_active_run: bool = false) -> void :
	if not bool(RunState.victory):
		AudioDirector.play_blocked()
		_set_status("The Endless Descent opens only after the Deepheart is restored")
		return
	if phase == "endless" and bool(endless_world.active):
		return
	if phase == "hub":
		_commit_hub_runtime_snapshot()
		var elevator_position: = Vector2(hub_world.DEEP_ELEVATOR_POSITION)
		var exit_direction: = Vector2(hub_world.player.global_position) - elevator_position
		if exit_direction.length_squared() < 1.0:
			exit_direction = Vector2.DOWN
		endless_hub_return_position = _safe_hub_return_position(elevator_position + exit_direction.normalized() * 166.0)
	var descent: = Dictionary(RunState.endless_descent_status())
	var target_depth: = int(descent.get("current_depth", 1))
	if restoring_active_run:
		if not bool(descent.get("active", false)):
			AudioDirector.play_blocked()
			_set_status("The saved descent is no longer active")
			return
	else:
		var started: = Dictionary(RunState.start_endless_descent())
		if not bool(started.get("ok", false)):
			AudioDirector.play_blocked()
			_set_status("Place the carried relic in the Museum before descending again" if String(started.get("reason", "")) == "carried_relic_must_be_placed" else "The Deep Elevator cannot begin this descent yet")
			return
		target_depth = int(started.get("depth", 1))
	phase = "endless"
	surface_context = ""
	mine_exit_context = false
	mine_depth_context = false
	depth_context = ""
	hub_context = ""
	deepheart_context = ""
	endless_context = ""
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	deepheart_world.set_active(false)
	endless_world.load_depth(target_depth, "from_above")
	endless_world.set_active(true, entering)
	AudioDirector.set_environment("depth")
	if entering:
		AudioDirector.play_transition("depth")
	endless_context = String(endless_world.current_context())
	objective_label.text = _endless_objective()
	_set_status(_endless_progress_text())
	_refresh_context_button()
	_refresh_hud()
	if persistence_active and persist_location:
		RunState.set_location("endless", endless_world.player.global_position)


func _on_endless_depth_change_requested(target_depth: int, arrival: String) -> void :
	if phase != "endless":
		return
	var status: = Dictionary(RunState.endless_descent_status())
	var previous_depth: = int(status.get("current_depth", -1))
	if int(status.get("current_depth", -1)) != target_depth and not RunState.reach_endless_depth(target_depth):
		AudioDirector.play_blocked()
		_set_status("Keep the relic attached and haul it upward · it cannot be taken deeper")
		return
	if not bool(endless_world.load_depth(target_depth, arrival)):
		AudioDirector.play_blocked()
		_set_status("That passage is not ready")
		return
	if target_depth > previous_depth and target_depth > 0 and bool(Dictionary(RunState.workshop_status("lift_workshop")).get("built", false)):
		RunState.checkpoint_endless_depth(target_depth)
	endless_context = String(endless_world.current_context())
	AudioDirector.play_transition("ascend" if arrival == "from_below" else "depth")
	objective_label.text = _endless_objective()
	_set_status(_endless_progress_text())
	_refresh_context_button()
	_refresh_hud()
	if persistence_active:
		RunState.set_location("endless", endless_world.player.global_position)


func _on_endless_hub_exit_requested() -> void :
	if phase != "endless":
		return
	var status: = Dictionary(RunState.endless_descent_status())
	var carried: = Dictionary(status.get("carried_relic", {}))
	if bool(status.get("active", false)):
		var result: = Dictionary(RunState.leave_endless_descent_to_hub())
		if not bool(result.get("ok", false)):
			AudioDirector.play_blocked()
			_set_status("Reach layer 0 with the relic still attached before returning to the Hub")
			return
	_return_from_endless_to_hub(String(carried.get("id", "")))


func _return_from_endless_to_hub(carried_relic_id: String = "") -> void :
	phase = "hub"
	endless_context = ""
	hub_context = ""
	button_move = Vector2.ZERO
	movement_pad.cancel()
	_apply_button_movement()
	endless_world.set_active(false)
	surface_world.set_active(false)
	mine_world.set_active(false)
	depth_world.set_active(false)
	deepheart_world.set_active(false)
	_sync_hub_runtime()
	hub_world.set_active(true, false)
	hub_world.restore_position(_safe_hub_return_position(endless_hub_return_position))
	hub_context = hub_world.current_context()
	AudioDirector.set_environment("hub")
	AudioDirector.play_transition("ascend")
	objective_label.text = _hub_objective()
	if carried_relic_id.is_empty():
		_set_status("Back in the Hub · the Endless Descent remains open")
	else:
		var relic: = Dictionary(RunState.relic_status(carried_relic_id))
		_set_status("%s hauled home · drag it to the Museum pedestal" % String(relic.get("display_name", "Relic")))
	_refresh_context_button()
	_refresh_hud()
	if persistence_active:
		RunState.set_location("hub", hub_world.player.global_position)
		RunState.flush_save()


func _on_endless_depth_changed(_depth: int) -> void :
	if phase != "endless":
		return
	objective_label.text = _endless_objective()
	_refresh_hud()


func _on_endless_resource_collected(kind: String, amount: int, depth: int) -> void :
	if phase != "endless" or amount <= 0:
		return
	AudioDirector.play_pickup(kind, amount)
	_set_status("Layer %d · +%d %s · workshop materials secured" % [depth, amount, String(ENDLESS_RESOURCE_NAMES.get(kind, kind.capitalize()))])
	_refresh_hud()


func _on_endless_discovery_found(_site_id: String, title: String, depth: int) -> void :
	if phase != "endless":
		return
	AudioDirector.play_discovery()
	_set_status("Layer %d discovery · %s" % [depth, title.capitalize()])


func _on_endless_relic_discovered(relic_id: String, depth: int) -> void :
	if phase != "endless":
		return
	var relic: = Dictionary(RunState.relic_status(relic_id))
	AudioDirector.play_discovery(true)
	_set_status("Layer %d · %s discovered · attach your rope" % [depth, String(relic.get("display_name", "Relic"))])
	_refresh_hud()


func _on_endless_relic_attached(relic_id: String, _depth: int) -> void :
	if phase != "endless":
		return
	var relic: = Dictionary(RunState.relic_status(relic_id))
	AudioDirector.play_ui("confirm")
	_set_status("%s attached · haul it upward to the Museum" % String(relic.get("display_name", "Relic")))
	_refresh_hud()


func _on_endless_relic_hauled_to_hub(relic_id: String, _discovery_depth: int) -> void :
	var relic: = Dictionary(RunState.relic_status(relic_id))
	_set_status("%s reached the Hub lift · return and place it in the Museum" % String(relic.get("display_name", "Relic")))


func _on_endless_rope_state_changed(attached: bool, relic_id: String) -> void :
	if phase != "endless" or relic_id.is_empty():
		return
	if not attached:
		_set_status("Rope released · reattach it before changing layers")
	_refresh_hud()


func _restore_deepheart_position(position: Vector2) -> void :
	if deepheart_world.has_method("restore_position"):
		deepheart_world.restore_position(position)
		return
	var walkable: = Rect2(deepheart_world.WALKABLE_RECT)
	var safe_position: = Vector2(
		clampf(position.x, walkable.position.x, walkable.end.x),
		clampf(position.y, walkable.position.y, walkable.end.y)
	)
	deepheart_world.player.global_position = safe_position
	deepheart_world.player.camera.reset_smoothing()
	deepheart_world._on_player_moved(safe_position)


func _safe_hub_return_position(preferred: Vector2) -> Vector2:
	var elevator: = Vector2(720, 142)
	var candidates: Array[Vector2] = [
		preferred,
		elevator + Vector2(0, 166),
		elevator + Vector2(-166, 120),
		elevator + Vector2(166, 120),
		Vector2(hub_world.entry_spawn()),
	]
	for candidate in candidates:
		var safe: = candidate.clamp(Vector2(52, 70), Vector2(hub_world.WORLD_SIZE) - Vector2(52, 58))
		if not hub_world._hub_wall_collision(safe):
			return safe
	return Vector2(hub_world.entry_spawn())


func _on_deepheart_finale_completed() -> void :
	objective_label.text = _deepheart_objective()
	_set_status("The Deepheart beats again · the gateway to the Endless Descent is open")
	_open_deepheart_conclusion()
	_refresh_context_button()
	_refresh_hud()
	if persistence_active:
		RunState.set_location("deepheart", deepheart_world.player.global_position, 1)
		RunState.flush_save()


func _open_deepheart_conclusion() -> void :
	if conclusion_overlay.visible:
		return
	_cancel_held_input()
	if is_instance_valid(deepheart_world.player):
		deepheart_world.player.control_enabled = false
	conclusion_stats.text = _deepheart_run_statistics()
	conclusion_overlay.visible = true
	guide_overlay.clear_target()
	AudioDirector.play_ui("confirm")
	conclusion_continue_button.call_deferred("grab_focus")


func _return_to_hub_from_conclusion() -> void :
	if not conclusion_overlay.visible:
		return
	AudioDirector.play_ui("confirm")
	RunState.mark_conclusion_seen()
	_dismiss_deepheart_conclusion(false)
	_exit_deepheart()


func _stay_in_deepheart_from_conclusion() -> void :
	if not conclusion_overlay.visible:
		return
	AudioDirector.play_ui("confirm")
	RunState.mark_conclusion_seen()
	_dismiss_deepheart_conclusion(true)
	_set_status("The Endless Descent awaits below your Hub · return whenever you are ready")
	_refresh_context_button()
	_refresh_hud()


func _dismiss_deepheart_conclusion(restore_control: bool) -> void :
	conclusion_overlay.visible = false
	if restore_control and phase == "deepheart" and is_instance_valid(deepheart_world.player):
		deepheart_world.player.control_enabled = true


func _deepheart_run_statistics() -> String:
	var ore_recovered: = 0
	for amount in RunState.mined.values():
		ore_recovered += int(amount)
	var final_tool: = String(RunState.current_pickaxe().get("name", "Pickaxe"))
	if int(RunState.drill_level) > 0:
		final_tool = String(RunState.current_drill().get("name", final_tool))
	return "ORE RECOVERED     %d\nPICKAXE SWINGS     %d\nGOLD EARNED        %d\nFINAL TOOL         %s" % [
		ore_recovered,
		int(RunState.total_swings),
		int(RunState.total_gold_earned),
		final_tool.to_upper(),
	]


func _deepheart_objective() -> String:
	if bool(RunState.victory):
		return "THE DEEPHEART IS THE GATEWAY · RETURN TO YOUR HUB"
	var seals: = Dictionary(RunState.deepheart_seal_status())
	var missing: = Array(seals.get("missing", []))
	if not missing.is_empty():
		return "OPEN THE %s RESONANCE · %d OF %d AWAKENED" % [
			String(missing[0]).to_upper(), int(seals.get("opened", 0)), int(seals.get("total", 4))
		]
	return "ALL RESONANCES OPEN · ATTUNE THE DEEPHEART CORE"


func _deepheart_progress_text() -> String:
	if bool(RunState.victory):
		return "The Deepheart is restored · the Endless Descent is open below the Hub"
	var seals: = Dictionary(RunState.deepheart_seal_status())
	var missing: = Array(seals.get("missing", []))
	if missing.is_empty():
		return "Four resonances sing together · approach the Deepheart Core"
	return "%s resonance is next · follow the guide and hold MINE" % String(missing[0]).capitalize()


func _hub_objective() -> String:
	if bool(RunState.victory):
		var goal: = Dictionary(guide_director.goal_for_state())
		return String(goal.get("title", "Enter the Endless Descent")).to_upper()
	var status: = Dictionary(RunState.deep_elevator_status())
	if bool(status.get("powered", false)):
		return "BEGIN THE FINAL DESCENT · ENTER THE DEEP ELEVATOR"
	if bool(status.get("repaired", false)):
		return "POWER THE DEEP ELEVATOR · INSTALL THE SINGULARITY CORE"
	return "REPAIR THE DEEP ELEVATOR · DELIVER CORE MATERIALS"


func _deep_hoard_status_text() -> String:
	var status: = Dictionary(RunState.deep_hoard_status())
	if not bool(status.get("unlocked", false)):
		return "Museum · restore the Deepheart to open the Endless Descent"
	return "Museum · %d / %d relics placed · deepest layer %d" % [
		int(status.get("placed_relic_count", 0)), int(status.get("total_relics", 5)),
		int(status.get("deepest_depth", 0)),
	]


func _endless_objective() -> String:
	var status: = Dictionary(RunState.endless_descent_status())
	var goal: = Dictionary(guide_director.goal_for_state())
	return "LAYER %d · %s" % [
		int(status.get("current_depth", 1)),
		String(goal.get("title", "Explore one layer deeper")).to_upper(),
	]


func _endless_progress_text() -> String:
	var status: = Dictionary(RunState.endless_descent_status())
	var carried: = Dictionary(status.get("carried_relic", {}))
	var relic_id: = String(carried.get("id", ""))
	if not relic_id.is_empty():
		var relic: = Dictionary(RunState.relic_status(relic_id))
		return "%s secured by rope · haul it upward one layer at a time" % String(relic.get("display_name", "Relic"))
	return "Layer %d · explore every branch or continue deeper when ready" % int(status.get("current_depth", 1))


func _workshop_status_text(workshop_id: String) -> String:
	var status: = Dictionary(RunState.workshop_status(workshop_id))
	if not bool(status.get("valid", false)):
		return "Fixed workshop site"
	var name: = String(status.get("display_name", workshop_id.capitalize()))
	if not bool(status.get("blueprint_unlocked", false)):
		return "%s · find and display its relic blueprint first" % name
	if bool(status.get("built", false)):
		var level: = int(status.get("level", 1))
		var selection: = Dictionary(hub_world.workshop_selection_preview(workshop_id))
		var equipped: = String(selection.get("current", ""))
		var next_upgrade: Dictionary = Dictionary(status.get("next_upgrade", {}))
		if not next_upgrade.is_empty():
			var resource_id: = String(next_upgrade.get("resource", ""))
			var resource_name: = String(ENDLESS_RESOURCE_NAMES.get(resource_id, resource_id.capitalize()))
			return "%s · L%d%s · next L%d costs %d %s" % [
				name,
				level,
				" · %s equipped" % equipped.replace("_", " ").capitalize() if not equipped.is_empty() else "",
				int(next_upgrade.get("level", level + 1)),
				int(next_upgrade.get("cost", 0)),
				resource_name,
			]
		return "%s · L%d%s · complete" % [
			name,
			level,
			" · %s equipped" % equipped.replace("_", " ").capitalize() if not equipped.is_empty() else "",
		]
	var resource_id: = String(status.get("build_resource", ""))
	var resource_name: = String(ENDLESS_RESOURCE_NAMES.get(resource_id, resource_id.capitalize()))
	if bool(status.get("ready_to_build", false)):
		return "%s · 200 / 200 %s · ready to build" % [name, resource_name]
	return "%s · %d / %d %s delivered" % [
		name, int(status.get("delivered", 0)), int(status.get("build_cost", 200)), resource_name,
	]


func _deep_elevator_status_text() -> String:
	var status: = Dictionary(RunState.deep_elevator_status())
	if bool(status.get("victory", false)):
		var endless: = Dictionary(RunState.endless_descent_status())
		return "Deep Elevator · Endless Descent ready · deepest layer %d" % int(endless.get("deepest_depth", 0))
	if bool(status.get("powered", false)):
		return "Deep Elevator · final descent ready"
	if bool(status.get("repaired", false)):
		return "Deep Elevator · the Singularity Core can awaken it"
	var missing: = Dictionary(status.get("missing", {}))
	var names: = {
		"ambercore": "Ambercore", "lunacore": "Lunacore",
		"furnaceheart": "Furnaceheart", "singularity": "Singularity Core",
	}
	var rows: Array[String] = []
	for resource_id_value in ["ambercore", "lunacore", "furnaceheart", "singularity"]:
		var resource_id: = String(resource_id_value)
		var amount: = int(missing.get(resource_id, 0))
		if amount > 0:
			rows.append("%d %s" % [amount, String(names[resource_id])])
	return "Deep Elevator · bring %s" % ", ".join(rows) if not rows.is_empty() else "Deep Elevator · awaiting repair"


func _sync_hub_runtime() -> void :
	var runtime: Dictionary = RunState.hub_runtime_snapshot()
	hub_world.load_runtime_state(
		Dictionary(runtime.hub),
		Dictionary(runtime.base),
		Dictionary(runtime.economy)
	)


func _commit_hub_runtime_snapshot() -> void :
	var runtime: Dictionary = hub_world.runtime_state_snapshot()
	RunState.commit_hub_runtime_state(
		Dictionary(runtime.hub),
		Dictionary(runtime.base),
		Dictionary(runtime.economy)
	)


func _on_hub_runtime_state_changed(next_hub: Dictionary, next_base: Dictionary, next_economy: Dictionary) -> void :
	RunState.commit_hub_runtime_state(next_hub, next_base, next_economy)
	_refresh_hud()


func _on_deep_elevator_checked() -> void :
	if phase != "hub":
		return
	_set_status(_deep_hoard_status_text() if bool(RunState.victory) else _deep_elevator_status_text())


func _on_hub_module_activated(module_id: String, kind: String) -> void :
	match kind:
		"sell":
			var earned: = RunState.sell_all()
			if earned > 0:
				AudioDirector.play_economy("sell")
			else:
				AudioDirector.play_blocked()
			_set_status("Assay complete · +%d gold" % earned if earned > 0 else "No sellable ore · progression materials remain protected")
		"forge":
			_use_forge()
		"storage":
			var moved: = RunState.auto_sort_resources(hub_world.player.global_position, "hub", 1)
			if moved > 0:
				AudioDirector.play_pickup("stone", moved)
				_set_status("Storage sorted · %d resources secured" % moved)
			else:
				var taken: = RunState.take_all_from_storage(module_id, hub_world.player.global_position, "hub", 1)
				if taken > 0:
					AudioDirector.play_pickup("gold", taken)
				else:
					AudioDirector.play_blocked()
				_set_status("Storage opened · %d resources returned to your pouch" % taken if taken > 0 else "Storage empty · upgrade materials remain in your pouch")
	_sync_hub_runtime()
	_refresh_hud()


func _checkpoint_location() -> void :
	RunState.begin_state_batch()
	if phase == "deepheart":
		RunState.set_location("deepheart", deepheart_world.player.global_position, 1)
	elif phase == "endless":
		RunState.set_location("endless", endless_world.player.global_position)
	elif phase == "depth":
		RunState.set_location(current_mine_id, depth_world.player.global_position, 2)
	elif phase == "mine":
		RunState.set_location(current_mine_id, mine_world.player.global_position)
	elif phase == "hub":
		_commit_hub_runtime_snapshot()
		RunState.set_location("hub", hub_world.player.global_position)
	else:
		surface_world.persist_ore_mountain_state()
		RunState.set_location("surface", surface_world.player.global_position)
	RunState.end_state_batch()


func _gate_status(world_id: String) -> String:
	var requirement: Dictionary = Dictionary(GATE_REQUIREMENTS[world_id])
	if int(requirement.pickaxe) > RunState.pickaxe_level:
		return "%s · %s required" % [String(requirement.title), String(GameData.data.PICKAXES[int(requirement.pickaxe)].name)]
	if int(requirement.mastery) > int(RunState.get("ember_mastery")):
		return "%s · Depth Mastery %d required" % [String(requirement.title), int(requirement.mastery)]
	if RunState.gold < int(requirement.gold):
		return "%s · %d gold" % [String(requirement.title), int(requirement.gold)]
	return "%s · ready to open" % String(requirement.title)


func _surface_chest_definition(chest_id: String) -> Dictionary:
	for chest_value in Array(GameData.data.CHEST_DEFINITIONS):
		var chest: Dictionary = Dictionary(chest_value)
		if String(chest.id) == chest_id:
			return chest.duplicate(true)
	return {}


func _surface_chest_reward_label(chest: Dictionary) -> String:
	var labels: Array[String] = []
	var rewards: Dictionary = Dictionary(chest.get("rewards", {}))
	for reward_id_value in rewards:
		var reward_id: = String(reward_id_value)
		var amount: = int(rewards.get(reward_id, 0))
		if reward_id == "coin":
			labels.append("%d gold" % amount)
		else:
			var rock: Dictionary = Dictionary(GameData.data.ROCK_TYPES.get(reward_id, {}))
			labels.append("%d %s" % [amount, String(rock.get("label", reward_id))])
	return " + ".join(labels)


func _surface_chest_status(chest_id: String) -> String:
	var chest: = _surface_chest_definition(chest_id)
	if chest.is_empty():
		return "Sealed cache"
	if RunState.is_surface_chest_opened(chest_id):
		return "%s · opened" % String(chest.name)
	var requirement: Dictionary = Dictionary(chest.get("requires", {}))
	var ready: = _surface_chest_is_ready(chest)
	if not ready:
		return "%s · requires %s" % [String(chest.name), String(requirement.get("label", "a stronger pickaxe"))]
	return "%s · %s · press OPEN" % [String(chest.name), _surface_chest_reward_label(chest)]


func _surface_chest_is_ready(chest: Dictionary) -> bool:
	var requirement: Dictionary = Dictionary(chest.get("requires", {}))
	if bool(requirement.get("starforge", false)):
		return not String(RunState.starforge_variant).is_empty()
	return int(RunState.pickaxe_level) >= int(requirement.get("pickaxeLevel", 1))


func _wayfarer_status() -> String:
	var current: = RunState.movement_speed_multiplier()
	var next: = RunState.movement_speed_multiplier(RunState.movement_speed_level + 1)
	return "Wayfarer · movement %.2fx → %.2fx · %d GOLD" % [current, next, RunState.movement_speed_upgrade_cost()]


func _surface_storage_status(module_id: String) -> String:
	var module: = RunState.base_module_by_id(module_id)
	if module.is_empty():
		return "Storage chest"
	var total: = 0
	for amount in Dictionary(module.get("items", {})).values():
		total += int(amount)
	return "Storage · %d/20 types · %d resources · press USE" % [RunState.storage_chest_type_count(module_id), total]


func _forge_status() -> String:
	var next: = RunState.next_pickaxe()
	if next.is_empty():
		var mastery: = RunState.next_ember_mastery()
		if mastery.is_empty():
			return "Forge · Depth Mastery complete"
		return "Forge · Mastery %d costs %d gold + %d Sunslag" % [int(mastery.rank), int(mastery.gold), int(mastery.sunslag)]
	if RunState.pickaxe_level == 4:
		return "Forge · %s costs %d gold + %d Emberstone" % [String(next.name), int(next.cost), int(GameData.data.EMBER_PICKAXE_ORE_REQUIRED)]
	return "Forge · %s costs %d gold" % [String(next.name), int(next.cost)]


func _assay_status() -> String:
	var protected: Dictionary = RunState.protected_progress_cargo()
	var sellable_pieces: = 0
	var sale_value: = 0
	for resource_id_value in RunState.cargo:
		var resource_id: = String(resource_id_value)
		var sellable: = maxi(0, int(RunState.cargo.get(resource_id, 0)) - int(protected.get(resource_id, 0)))
		var rock: Dictionary = Dictionary(GameData.data.ROCK_TYPES.get(resource_id, {}))
		sellable_pieces += sellable
		sale_value += sellable * int(rock.get("value", 0))
	if sellable_pieces > 0:
		return "Assay · %d sellable ore · %d gold ready" % [sellable_pieces, sale_value]
	if RunState.cargo_count() > 0:
		return "Assay · upgrade materials are protected"
	return "Assay · your ore pouch is empty"


func _starforge_status() -> String:
	if String(RunState.starforge_variant).is_empty():
		return "Starforge · forge a drill core attachment" if RunState.drill_level > 0 else "Starforge · choose your first final pickaxe form"
	var variant: Dictionary = Dictionary(GameData.data.STARFORGE_VARIANTS[String(RunState.starforge_variant)])
	if RunState.drill_level > 0:
		return "Starforge · %s core attached · forge or swap another core" % String(variant.name)
	return "Starforge · %s equipped · forge or swap another form" % String(variant.name)


func _drill_forge_status() -> String:
	var status: Dictionary = RunState.drill_upgrade_status()
	if bool(status.get("ready", false)):
		var recipe: Dictionary = Dictionary(status.recipe)
		return "Drill Forge · %s ready · press FORGE" % String(Dictionary(recipe.drill).name)
	match String(status.get("reason", "")):
		"starforge_required":
			return "Drill Forge · bring any forged Starforge pickaxe"
		"materials_required":
			var rows: Array[String] = []
			for missing_value in Array(status.get("missing", [])):
				var missing: Dictionary = Dictionary(missing_value)
				rows.append("%s %d/%d" % [String(missing.type).capitalize(), int(missing.owned), int(missing.amount)])
			return "Drill Forge · " + " · ".join(rows)
		"gold_required":
			return "Drill Forge · needs %d more gold" % int(status.get("missing_gold", 0))
		"maximum_level":
			return "Drill Forge · Deepcore Drill fully mastered"
	return "Drill Forge"


func _try_upgrade_drill() -> void :
	var next: Dictionary = RunState.next_drill()
	if RunState.upgrade_drill():
		AudioDirector.play_economy("upgrade")
		_set_status(
			"%s forged · faster mining · %d px resource magnet" % [
				String(next.name),
				roundi(RunState.resource_pickup_radius(48.0)),
			]
		)
		objective_label.text = _depth_objective()
		_refresh_hud()
		return
	AudioDirector.play_blocked()
	_set_status(_drill_forge_status())


func _depth_objective() -> String:
	var depth_title: = _depth_name(current_mine_id)
	if RunState.victory:
		return "ASCEND TO THE BASE HUB · ENTER THE ENDLESS DESCENT"
	if RunState.singularity_secured:
		return "SINGULARITY CORE SECURED · ASCEND TO THE STARFALL HUB"
	if not RunState.has_deep_tool():
		return "%s · STARFORGE REQUIRED" % depth_title
	var status: Dictionary = RunState.drill_upgrade_status()
	var recipe: Dictionary = Dictionary(status.get("recipe", {}))
	if recipe.is_empty():
		if current_mine_id == "starMine":
			return "MINE A SINGULARITY CORE · THE FINAL DISCOVERY"
		return "DEEPCORE DRILL MASTERED · THE FINAL DESCENT AWAITS"
	var drill: Dictionary = Dictionary(recipe.get("drill", RunState.next_drill()))
	var missing: Array = Array(status.get("missing", []))
	if not missing.is_empty():
		var requirement: Dictionary = Dictionary(missing[0])
		var rock: Dictionary = Dictionary(GameData.data.ROCK_TYPES.get(String(requirement.type), {}))
		var route: = _depth_name(String(requirement.get("scene", current_mine_id)))
		return "MINE %s FOR %s · %s" % [String(rock.get("label", requirement.type)).to_upper(), String(drill.name).to_upper(), route]
	var missing_gold: = int(status.get("missing_gold", 0))
	if missing_gold > 0:
		return "EARN GOLD FOR %s · NEED %d GOLD" % [String(drill.name).to_upper(), missing_gold]
	return "FORGE %s · DEPTH 2 DRILL FORGE" % String(drill.name).to_upper()


func _depth_hint() -> String:
	if RunState.victory:
		return "The Deep Elevator now leads into an endless world of discoveries"
	if RunState.singularity_secured:
		return "The final core is yours · repair the Deep Elevator in your Hub"
	if not RunState.has_deep_tool():
		return "%s stone resists normal pickaxes · return with Starforge" % _depth_name(current_mine_id).capitalize()
	var status: Dictionary = RunState.drill_upgrade_status()
	var recipe: Dictionary = Dictionary(status.get("recipe", {}))
	if recipe.is_empty():
		return "Deepcore Drill mastered · the deepest materials are now mineable"
	var drill: Dictionary = Dictionary(recipe.get("drill", RunState.next_drill()))
	var missing: Array = Array(status.get("missing", []))
	if not missing.is_empty():
		var requirement: Dictionary = Dictionary(missing[0])
		var rock: Dictionary = Dictionary(GameData.data.ROCK_TYPES.get(String(requirement.type), {}))
		return "Mine %d %s in %s for the %s" % [int(requirement.amount), String(rock.get("label", requirement.type)), _depth_name(String(requirement.get("scene", current_mine_id))).capitalize(), String(drill.name)]
	var missing_gold: = int(status.get("missing_gold", 0))
	if missing_gold > 0:
		return "Upgrade materials protected · earn %d more gold" % missing_gold
	return "%s ready · use any Depth 2 Drill Forge" % String(drill.name)


func _on_starforge_choice(variant_id: String) -> void :
	var status: Dictionary = RunState.starforge_crafting_status(variant_id)
	var variant: Dictionary = Dictionary(status.get("variant", {}))
	if bool(status.get("can_equip", false)):
		if RunState.equip_starforge_variant(variant_id):
			AudioDirector.play_economy("upgrade")
			_set_status(
				"%s drill core attached · its mining trait is active" % String(variant.name)
				if RunState.drill_level > 0
				else "%s equipped · Rootwound stone can now be mined" % String(variant.name)
			)
	elif bool(status.get("ready", false)):
		if RunState.forge_starforge_variant(variant_id):
			AudioDirector.play_economy("upgrade")
			_set_status(
				"%s core forged and attached · its drill trait is active" % String(variant.name)
				if RunState.drill_level > 0
				else "%s forged and equipped · the hidden depths are ready" % String(variant.name)
			)
	else:
		AudioDirector.play_blocked()
		match String(status.get("reason", "")):
			"materials_required":
				_set_status("%s needs 200 Astralite + 200 Crownstone" % String(variant.get("name", "Starforge")))
			_:
				_set_status("Reach Starfall and gather its final materials first")
	_refresh_hud()


func _refresh_starforge_panel() -> void :
	if not is_instance_valid(starforge_panel):
		return


	starforge_panel.visible = false


func _surface_objective() -> String:
	if RunState.victory:
		return "RETURN TO THE BASE HUB · ENTER THE ENDLESS DESCENT"
	if RunState.singularity_secured:
		return "ENTER THE BASE HUB · REPAIR THE DEEP ELEVATOR"
	if not RunState.area_unlocked:
		return "FORGE THE RUNED PICKAXE · OPEN THE MOONGLASS GATE"
	if not RunState.emberdeep_unlocked:
		return "EXPLORE MOONGLASS · FORGE THE MOONGLASS PICKAXE"
	if not RunState.fourth_unlocked:
		return "MASTER EMBERDEEP · OPEN THE STARFALL SEAL"
	if String(RunState.starforge_variant).is_empty():
		return "MINE STARFALL · FORGE A STARFORGE PICKAXE"
	if RunState.hub_tutorial_pending():
		return "ENTER THE UNDERGROUND HUB · AWAKEN YOUR BASE"
	if not RunState.is_depth_entrance_discovered("mossMine"):
		return "RETURN TO MOSSVEIN · FIND THE HIDDEN DESCENT"
	if RunState.drill_level <= 0:
		return "ENTER ROOTWOUND · BEGIN THE DRILL AGE"
	var drill_status: Dictionary = RunState.drill_upgrade_status()
	var missing: Array = Array(drill_status.get("missing", []))
	if not missing.is_empty():
		var route_mine: = String(Dictionary(missing[0]).get("scene", "mossMine"))
		return "DESCEND INTO %s · GATHER DRILL MATERIALS" % _depth_name(route_mine)
	if int(drill_status.get("missing_gold", 0)) > 0:
		return "SELL ORE · FUND THE NEXT DRILL"
	if bool(drill_status.get("ready", false)):
		return "RETURN TO A DRILL FORGE · COMPLETE THE UPGRADE"
	return "DESCEND INTO VOIDSTAR · FIND THE SINGULARITY CORE"


func _surface_hint() -> String:
	if RunState.victory:
		return "Relics unlock fixed workshop sites in your growing Hub"
	if RunState.singularity_secured:
		return "The Starfall base lift leads to the Deep Elevator"
	if not RunState.area_unlocked:
		return "Mine Mossvein · sell ore · forge the Runed Pickaxe"
	if not RunState.emberdeep_unlocked:
		return "The Moonglass road is open"
	if not RunState.fourth_unlocked:
		return "The Emberdeep road is open"
	if String(RunState.starforge_variant).is_empty():
		return "Mine Astralite and Crownstone · choose a Starforge form"
	if RunState.hub_tutorial_pending():
		return "The Starfall base lift is awake"
	if RunState.drill_level <= 0:
		return "Your Starforge can break Rootwound stone"
	return "Every hidden descent now leads to a different deep layer"


func _mine_is_unlocked(mine_id: String) -> bool:
	return RunState.is_world_unlocked(String(WORLD_BY_MINE.get(mine_id, "mossvein")))


func _refresh_context_button() -> void :
	var label: = ""
	var enabled: = true
	if phase == "deepheart":
		if deepheart_context == "deepheart_exit":
			label = "RETURN"
		elif deepheart_context == "deepheart_core" and not bool(RunState.victory):
			var seals: = Dictionary(RunState.deepheart_seal_status())
			enabled = bool(seals.get("all_open", false))
			label = "ATTUNE" if enabled else "SEALED"
	elif phase == "endless":
		if endless_context == "endless_up":
			label = "RETURN" if int(Dictionary(RunState.endless_descent_status()).get("current_depth", 0)) == 0 else "ASCEND"
		elif endless_context == "endless_down":
			label = "DEEPER"
		elif endless_context.begins_with("endless_site:"):
			label = "STABILIZE" if String(endless_context.get_slice(":", 2)) == "stabilize" else "OVERLOAD"
		elif endless_context.begins_with("endless_relic:"):
			label = "ATTACH ROPE"
	elif phase == "hub":
		if hub_context.begins_with("module:"):
			label = "USE"
		else:
			if hub_context == "deepElevator":
				var elevator_status: = Dictionary(RunState.deep_elevator_status())
				if bool(RunState.victory):
					label = "DESCEND"
				else:
					label = "DESCEND" if bool(elevator_status.get("powered", false)) else "POWER" if bool(elevator_status.get("repaired", false)) else "DELIVER"
			elif hub_context == "deepHoard":
				label = "INSPECT"
			elif hub_context == "relicPedestal":
				label = "PLACE"
			elif hub_context.begins_with("workshop:"):
				var workshop_id: = hub_context.trim_prefix("workshop:")
				var workshop: = Dictionary(RunState.workshop_status(workshop_id))
				if bool(workshop.get("built", false)):
					label = "OPEN"
				elif bool(workshop.get("ready_to_build", false)):
					label = "BUILD"
				elif bool(workshop.get("blueprint_unlocked", false)):
					label = "DELIVER"
			else:
				label = {"hubExit": "ASCEND"}.get(hub_context, "")
	elif phase == "depth":
		label = {"depthExit": "ASCEND", "depthSell": "SELL", "drillForge": "FORGE"}.get(depth_context, "")
	elif phase == "mine" and mine_depth_context:
		label = "DESCEND"
	elif phase == "mine" and mine_exit_context:
		label = "EXIT"
	elif phase == "surface":
		if surface_context.begins_with("chest:"):
			var chest: = _surface_chest_definition(surface_context.trim_prefix("chest:"))
			enabled = not chest.is_empty() and _surface_chest_is_ready(chest)
			label = "OPEN" if enabled else "LOCKED"
		elif surface_context.begins_with("storage:"):
			label = "USE"
		elif surface_context.begins_with("enter:"):
			label = "DESCEND"
		elif surface_context.begins_with("gate:"):
			label = "OPEN"
		elif surface_context == "hubEntrance":
			label = "DESCEND"
		else:
			label = {
				"sell": "SELL ORE" if automated_mode else "",
				"forge": "FORGE",
				"speedShop": "BROWSE",
				"starforge": "BROWSE",
			}.get(surface_context, "")
			if not commerce_transaction.is_empty():
				enabled = false
				match String(commerce_transaction.get("kind", "")):
					"assay": label = "ASSAYING"
					"forge": label = "FORGING"
					"wayfarer": label = "TUNING"
					"starforge": label = "ATTUNING"
	action_button.text = label


	action_button.visible = automated_mode and not label.is_empty()
	action_button.disabled = not enabled
	if premium_hud != null:
		premium_hud.set_context_action(label, enabled)
	mine_button.visible = phase in ["mine", "depth", "endless"] or (phase == "deepheart" and deepheart_context.begins_with("deepheart_seal:")) or (phase == "surface" and surface_context in ["ore_mountain", "moonglass_mountain", "emberdeep_mountain", "starfall_mountain", "moonglass_resource", "ember_resource", "starfall_resource"])
	_refresh_context_card()


func _refresh_context_card() -> void :
	var title: = ""
	var detail: = ""
	var hint: = ""
	if phase == "surface":
		if surface_context == "sell":
			title = "ASSAY STATION"
			detail = _assay_status().trim_prefix("Assay · ")
			hint = "WALK THROUGH · RESOURCES SELL AUTOMATICALLY"
		elif surface_context == "forge":
			title = "MOSSVEIN FORGE"
			detail = _forge_status().trim_prefix("Forge · ")
			hint = "OPEN FORGE · INSPECT FIRST, THEN CONFIRM"
		elif surface_context == "speedShop":
			title = "WAYFARER"
			detail = "Permanent movement tuning with no level cap"
			hint = "BROWSE · COMPARE THE NEXT SPEED LEVEL"
		elif surface_context == "starforge":
			title = "STARFORGE"
			detail = "Forge or equip a mining identity that remains active on drills"
			hint = "BROWSE · COMPARE ALL THREE CORES"
		elif surface_context.begins_with("enter:"):
			var mine_id: = surface_context.trim_prefix("enter:")
			title = String(GameData.mine(mine_id).name).to_upper()
			detail = "The lower road continues into the mine"
			hint = "PRESS E OR TAP DESCEND"
	elif phase == "mine" and mine_depth_context:
		title = "HIDDEN DESCENT"
		detail = "A deeper layer has been uncovered"
		hint = "PRESS E OR TAP DESCEND"
	elif phase == "hub":
		if hub_context == "relicPedestal":
			title = "MUSEUM PEDESTAL"
			detail = "Set the hauled relic permanently into your collection"
			hint = "PRESS E OR TAP PLACE"
		elif hub_context.begins_with("workshop:"):
			var workshop_id: = hub_context.trim_prefix("workshop:")
			var workshop: = Dictionary(RunState.workshop_status(workshop_id))
			title = String(workshop.get("display_name", "WORKSHOP")).to_upper()
			detail = _workshop_status_text(workshop_id)
			if bool(workshop.get("built", false)):
				hint = "OPEN · PREVIEW FIRST, THEN CONFIRM"
			else:
				hint = "DELIVER MATERIALS OR BUILD"
	elif phase == "deepheart":
		if deepheart_context == "deepheart_exit":
			title = "HUB LIFT"
			detail = "Your workshop and open worlds remain above"
			hint = "PRESS E OR TAP RETURN"
		elif deepheart_context.begins_with("deepheart_seal:"):
			var seal_id: = deepheart_context.trim_prefix("deepheart_seal:")
			title = "%s RESONANCE" % seal_id.to_upper()
			detail = "Hold your tool steady until the seal awakens"
			hint = "HOLD MINE"
		elif deepheart_context == "deepheart_core":
			var seals: = Dictionary(RunState.deepheart_seal_status())
			title = "DEEPHEART CORE"
			detail = "All four worlds are ready to resonate" if bool(seals.get("all_open", false)) else "%d of %d resonances awakened" % [int(seals.get("opened", 0)), int(seals.get("total", 4))]
			hint = "PRESS E OR TAP ATTUNE" if bool(seals.get("all_open", false)) else "OPEN EACH RESONANCE FIRST"
	elif phase == "endless":
		if endless_context == "endless_up":
			title = "UPPER PASSAGE"
			detail = "The route back toward your Hub"
			hint = "PRESS E OR TAP ASCEND"
		elif endless_context == "endless_down":
			title = "LOWER PASSAGE"
			detail = "A new cave layer waits below"
			hint = "PRESS E OR TAP DEEPER"
		elif endless_context.begins_with("endless_site:"):
			var choice: = String(endless_context.get_slice(":", 2))
			if choice == "stabilize":
				title = "CALM SEAL"
				detail = "Cross three lit floor seals to recover the cache and silence a nearby surge"
				hint = "PRESS E OR TAP STABILIZE"
			else:
				title = "POWER SEAL"
				detail = "Cross four lit floor seals for a double cache; the nearby surge grows stronger"
				hint = "PRESS E OR TAP OVERLOAD"
		elif endless_context.begins_with("endless_relic:"):
			var relic: = Dictionary(RunState.relic_status(endless_context.trim_prefix("endless_relic:")))
			title = String(relic.get("display_name", "RELIC")).to_upper()
			detail = "Attach your rope and physically haul it to the Museum"
			hint = "PRESS E OR TAP ATTACH ROPE"



	context_card.visible = false
	if not title.is_empty():
		context_card_title.text = title
		context_card_detail.text = detail
		context_card_hint.text = hint
		if premium_hud != null and premium_hud.context_button.visible:
			premium_hud.context_button.tooltip_text = " · ".join([title, detail, hint])


func _queue_hud_refresh() -> void :
	if hud_refresh_pending:
		return
	hud_refresh_pending = true
	call_deferred("_flush_hud_refresh")


func _flush_hud_refresh() -> void :
	hud_refresh_pending = false
	_refresh_hud()


func _refresh_hud() -> void :
	_update_presented_gold_labels()
	cargo_label.text = _cargo_summary()
	if phase == "depth":
		objective_label.text = _depth_objective()
	elif phase == "hub":
		objective_label.text = _hub_objective()
	elif phase == "deepheart":
		objective_label.text = _deepheart_objective()
	elif phase == "endless":
		objective_label.text = _endless_objective()
	elif phase == "surface":
		objective_label.text = _surface_objective()
	if RunState.drill_level > 0:
		tool_label.text = String(RunState.current_drill().name).to_upper()
	elif not String(RunState.starforge_variant).is_empty():
		tool_label.text = String(GameData.data.STARFORGE_VARIANTS[String(RunState.starforge_variant)].name).to_upper()
	else:
		tool_label.text = String(RunState.current_pickaxe().name).to_upper()
	_refresh_context_button()
	_refresh_starforge_panel()
	if premium_hud != null:
		premium_hud.refresh_from_state(
			phase,
			current_mine_id,
			action_button.text,
			not premium_hud.context_button.disabled,
			false
		)
		premium_hud.build_button.visible = false
		premium_hud.build_button.disabled = true
		_update_presented_gold_labels()
	if inventory_open and resource_inventory != null:
		resource_inventory.refresh_contents(
			Dictionary(RunState.cargo),
			Dictionary(RunState.protected_progress_cargo()),
			phase == "hub"
		)


func _cargo_summary() -> String:
	if phase == "endless":
		var status: = Dictionary(RunState.endless_descent_status())
		var carried: = Dictionary(status.get("carried_relic", {}))
		var relic_id: = String(carried.get("id", ""))
		if not relic_id.is_empty():
			return "LAYER %d  ·  RELIC ON ROPE  ·  POUCH %d" % [int(status.get("current_depth", 1)), RunState.cargo_count()]
		return "LAYER %d  ·  DEEPEST %d  ·  POUCH %d" % [
			int(status.get("current_depth", 1)), int(status.get("deepest_depth", 1)), RunState.cargo_count(),
		]
	if phase == "hub":
		var stored: = 0
		for module_value in RunState.all_base_modules():
			var module: Dictionary = Dictionary(module_value)
			if String(module.get("kind", "")) != "storage":
				continue
			for amount in Dictionary(module.get("items", {})).values():
				stored += int(amount)
		return "POUCH %d  ·  STORAGE %d  ·  GOLD %d" % [RunState.cargo_count(), stored, RunState.gold]
	if phase == "depth":
		var resources: = _depth_cargo_resources(current_mine_id)
		var labels: Array[String] = []
		for resource_id in resources:
			var rock: Dictionary = Dictionary(GameData.data.ROCK_TYPES.get(resource_id, {}))
			labels.append("%s %d" % [String(rock.get("label", resource_id)).to_upper(), int(RunState.cargo.get(resource_id, 0))])
		return "  ·  ".join(labels)
	var focus: = current_mine_id if phase == "mine" else "starMine" if RunState.fourth_unlocked else "emberMine" if RunState.emberdeep_unlocked else "moonMine" if RunState.area_unlocked else "mossMine"
	match focus:
		"moonMine":
			return "MOON %d  ·  STAR %d  ·  GOLD %d" % [int(RunState.cargo.moonglass), int(RunState.cargo.starshard), int(RunState.cargo.gold)]
		"emberMine":
			return "EMBER %d  ·  SUN %d  ·  GOLD %d" % [int(RunState.cargo.emberstone), int(RunState.cargo.sunslag), int(RunState.cargo.gold)]
		"starMine":
			return "ASTRAL %d  ·  CROWN %d  ·  GOLD %d" % [int(RunState.cargo.astralite), int(RunState.cargo.crownstone), int(RunState.cargo.gold)]
		_:
			return RunState.cargo_label()


func _mine_name(mine_id: String) -> String:
	return String(GameData.mine(mine_id).name)


func _depth_name(mine_id: String) -> String:
	return String(Dictionary(GameData.data.MINE_DEPTH_PROFILES[mine_id]).name)


func _depth_cargo_resources(mine_id: String) -> Array[String]:
	var profile: Dictionary = Dictionary(GameData.data.DEPTH2_RESOURCE_PROFILES[mine_id])
	var result: Array[String] = [String(profile.main), String(profile.rare)]
	for rock_value in Array(Dictionary(GameData.data.MINE_DEPTH_DISCOVERIES[mine_id]).rocks):
		var rock: Dictionary = Dictionary(rock_value)
		var resource_id: = String(rock.type)
		if int(rock.get("requiresDrillLevel", 0)) > 0 and resource_id not in result:
			result.append(resource_id)
			break
	if result.size() < 3:
		result.append(String(profile.secondary))
	return result


func _set_status(message: String) -> void :
	if message.ends_with("BROKEN · collect the ore") or message.ends_with(" COLLECTED"):
		return
	status_label.text = message
	if premium_hud != null:
		premium_hud.set_status(message)


func _on_resource_collected(resource_id: String, amount: int) -> void :
	if amount <= 0:
		return
	if resource_id == "singularity" and RunState.secure_singularity(resource_id):
		AudioDirector.play_discovery(true)
		objective_label.text = "ASCEND TO STARFALL · ENTER THE BASE HUB"
		_set_status("Singularity Core secured · repair the Deep Elevator in your Starfall Hub")
		_refresh_hud()
		if persistence_active:
			_checkpoint_location()
			RunState.flush_save()
	var active_world: Node = surface_world
	match phase:
		"mine":
			active_world = mine_world
		"depth":
			active_world = depth_world
		"hub":
			active_world = hub_world
		"deepheart":
			active_world = deepheart_world
		"endless":
			active_world = endless_world
	var active_player: Node = active_world.get("player") as Node
	if active_player == null:
		return
	var feedback: = active_player.get_node_or_null("ResourcePickupBurst")
	if feedback != null and feedback.has_method("show_pickup"):
		feedback.show_pickup(resource_id, amount)


func _on_achievement_unlocked(definition: Dictionary) -> void :
	if achievement_toast == null:
		return
	achievement_toast.show_achievement(definition)
	_update_achievement_toast_anchor()
	AudioDirector.play_discovery()


func _update_achievement_toast_anchor() -> void :
	if achievement_toast == null or not achievement_toast.is_presenting():
		return
	var active_player: Node2D = _active_player_node()
	if active_player == null or not is_instance_valid(active_player):
		return
	var player_screen_position: Vector2 = active_player.get_global_transform_with_canvas().origin
	achievement_toast.set_screen_anchor(player_screen_position + Vector2(0.0, -112.0))


func _active_player_node() -> Node2D:
	match phase:
		"mine":
			return mine_world.player as Node2D
		"depth":
			return depth_world.player as Node2D
		"hub":
			return hub_world.player as Node2D
		"deepheart":
			return deepheart_world.player as Node2D
		"endless":
			return endless_world.player as Node2D
	return surface_world.player as Node2D


func _on_achievement_toast_activated(achievement_id: String) -> void :
	achievement_toast.dismiss()
	if conclusion_overlay.visible or automated_mode:
		return
	if inventory_open:
		_close_inventory()
	if not menu_open:
		_open_start_menu()
	if menu_open and premium_menu != null:
		premium_menu.show_achievements(achievement_id)


func _has_any_arg(args: PackedStringArray, candidates: Array[String]) -> bool:
	for candidate in candidates:
		if candidate in args:
			return true
	return false


func _validate_release_version(args: PackedStringArray) -> bool:
	var release_version: = String(PremiumMenuScript.release_version())
	var displayed_label: = String(premium_menu.displayed_release_label())
	var required_label: = String(PremiumMenuScript.release_label())
	var expected_version: = ""
	for arg_value in args:
		var arg: = String(arg_value)
		if arg.begins_with("--expected-version="):
			expected_version = arg.trim_prefix("--expected-version=").strip_edges()
			break
	if release_version.is_empty() or displayed_label != required_label:
		push_error("Release version label mismatch: config=%s label=%s" % [release_version, displayed_label])
		get_tree().quit(2)
		return false
	if not expected_version.is_empty() and release_version != expected_version:
		push_error("Expected release %s but build reports %s" % [expected_version, release_version])
		get_tree().quit(2)
		return false
	if not expected_version.is_empty():
		print("EVER_DEEPER_VERSION_OK version=%s label=%s" % [release_version, displayed_label])
	return true


func _run_input_release_qa() -> void :
	phase = "surface"
	surface_context = "ore_mountain"
	_refresh_context_button()
	if not _qa_input_release_check(mine_button.visible, "Surface mining context must show the mining button"):
		return

	_on_mine_button_gui_input(_qa_input_touch(7, true))
	if not _qa_input_release_check(_qa_input_phase_is_held("surface"), "Touch press must hold only the active Surface world"):
		return
	surface_context = ""
	_refresh_context_button()
	if not _qa_input_release_check( not mine_button.visible, "Leaving mining context must hide the mining button"):
		return
	if not _qa_input_release_check(_qa_input_is_fully_released(), "Hiding the button without button_up must cancel every mining state"):
		return

	surface_context = "ore_mountain"
	_refresh_context_button()
	if not _qa_input_release_check(_qa_input_is_fully_released(), "Showing the button again must not resume mining"):
		return
	_on_mine_button_gui_input(_qa_input_touch(7, true))
	_input(_qa_input_touch(3, false))
	if not _qa_input_release_check(_qa_input_phase_is_held("surface") and mine_touch_index == 7, "An unrelated touch release must not cancel mining"):
		return
	_input(_qa_input_touch(7, false))
	if not _qa_input_release_check(_qa_input_is_fully_released(), "The matching root touch release must cancel mining"):
		return

	_on_mine_button_gui_input(_qa_input_touch(9, true))
	_input(_qa_input_touch(9, false, true))
	if not _qa_input_release_check(_qa_input_is_fully_released(), "A canceled matching touch must cancel mining"):
		return

	var touch_index: = 20
	for phase_value in ["surface", "mine", "depth", "deepheart", "endless"]:
		phase = String(phase_value)
		_on_mine_button_gui_input(_qa_input_touch(touch_index, true))
		if not _qa_input_release_check(_qa_input_phase_is_held(phase), "%s touch must hold only its active world" % phase):
			return
		_input(_qa_input_touch(touch_index, false))
		if not _qa_input_release_check(_qa_input_is_fully_released(), "%s touch release must clear every world" % phase):
			return
		touch_index += 1

	phase = "mine"
	_on_mine_button_gui_input(_qa_input_mouse_button(MOUSE_BUTTON_LEFT, true))
	if not _qa_input_release_check(mine_mouse_held and _qa_input_phase_is_held("mine"), "Mouse press must hold only the active Mine world"):
		return
	_input(_qa_input_mouse_button(MOUSE_BUTTON_RIGHT, false))
	if not _qa_input_release_check(mine_mouse_held and _qa_input_phase_is_held("mine"), "An unrelated mouse release must not cancel mining"):
		return
	_input(_qa_input_mouse_button(MOUSE_BUTTON_LEFT, false))
	if not _qa_input_release_check(_qa_input_is_fully_released(), "The matching root mouse release must cancel mining"):
		return

	phase = "surface"
	_on_mine_button_gui_input(_qa_input_touch(30, true))
	_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	if not _qa_input_release_check(_qa_input_is_fully_released(), "Application focus loss must cancel mining without persistence"):
		return
	_on_mine_button_gui_input(_qa_input_touch(31, true))
	_notification(NOTIFICATION_APPLICATION_PAUSED)
	if not _qa_input_release_check(_qa_input_is_fully_released(), "Application pause must cancel mining without persistence"):
		return

	print("EVER_DEEPER_INPUT_RELEASE_OK hide=true matching_touch=true canceled_touch=true unrelated_touch_ignored=true mouse=true worlds=5 focus_pause=true")
	get_tree().quit(0)


func _qa_input_touch(index: int, pressed: bool, canceled: bool = false) -> InputEventScreenTouch:
	var event: = InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.canceled = canceled
	return event


func _qa_input_mouse_button(button_index: MouseButton, pressed: bool) -> InputEventMouseButton:
	var event: = InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = pressed
	return event


func _qa_input_phase_is_held(expected_phase: String) -> bool:
	return (
		mine_held
		and surface_world.external_mine_held == (expected_phase == "surface")
		and mine_world.external_mine_held == (expected_phase == "mine")
		and depth_world.external_mine_held == (expected_phase == "depth")
		and deepheart_world.external_mine_held == (expected_phase == "deepheart")
		and endless_world.external_mine_held == (expected_phase == "endless")
	)


func _qa_input_is_fully_released() -> bool:
	return (
		not mine_held
		and mine_touch_index == -1
		and not mine_mouse_held
		and not surface_world.external_mine_held
		and not mine_world.external_mine_held
		and not depth_world.external_mine_held
		and not deepheart_world.external_mine_held
		and not endless_world.external_mine_held
	)


func _qa_input_release_check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("EVER_DEEPER_INPUT_RELEASE_FAILED: %s" % message)
	get_tree().quit(2)
	return false


func _run_landscape_qa() -> void :
	var viewport_size: = get_viewport().get_visible_rect().size
	var configured_size: = Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		float(ProjectSettings.get_setting("display/window/size/viewport_height")),
	)
	assert (configured_size.is_equal_approx(Vector2(1280, 720)))
	assert (int(ProjectSettings.get_setting("display/window/handheld/orientation")) == DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	assert (String(ProjectSettings.get_setting("display/window/stretch/aspect")) == "expand")
	assert (is_equal_approx(float(ProjectSettings.get_setting("display/window/stretch/scale")), 1.1))
	_sync_orientation_guard(Vector2(720, 1280), true)
	assert (orientation_guard_active and orientation_guard.visible)
	_sync_orientation_guard(Vector2(1280, 720), true)
	assert ( not orientation_guard_active and not orientation_guard.visible)
	assert (premium_hud.minimum_touch_targets_are_valid())
	assert (mine_button.keep_pressed_outside)
	assert (mine_button.icon != null and mine_button.icon.resource_path == "res://assets/ui/hud-mine-impact-v1.png")
	for sprite_button in [
		mine_button, premium_hud.menu_button, premium_hud.guide_button,
			premium_hud.bag_button,
	]:
		assert ((sprite_button as Button).text.is_empty())
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var stylebox: = (sprite_button as Button).get_theme_stylebox(state)
			assert (stylebox is StyleBoxEmpty, "%s.%s resolved to %s" % [sprite_button.name, state, stylebox.get_class()])


	assert (premium_hud.context_button.get_theme_stylebox("normal") is StyleBoxFlat)
	assert (premium_hud.context_button.get_theme_stylebox("focus") is StyleBoxEmpty)
	assert (resource_inventory.item_grid.columns == 4)
	assert (movement_pad._is_in_movement_zone(Vector2(220, 610)))
	assert ( not movement_pad._is_in_movement_zone(Vector2(1080, 610)))
	var landscape_menu_card: Control = premium_menu.main_view.get_child(0) as Control
	assert (landscape_menu_card != null and landscape_menu_card.size.is_equal_approx(Vector2(1040, 600)))
	surface_world.set_active(true)
	await get_tree().physics_frame
	var landscape_camera: CinematicCamera2D = surface_world.player.camera as CinematicCamera2D
	var surface_parallax: SurfaceParallax = surface_world.surface_parallax
	var surface_routes: Dictionary = surface_world.surface_route_snapshot()
	var moss_branch: Dictionary = Dictionary(surface_routes.branches.mossMine)
	var moon_branch: Dictionary = Dictionary(surface_routes.branches.moonMine)
	var moonglass_boundary: Dictionary = Dictionary(Array(surface_routes.boundaries)[0])
	var moss_gate_overlap: Rect2 = Rect2(moss_branch.entrance_visual_rect).intersection(Rect2(moonglass_boundary.gate_visual_rect))
	assert (moss_gate_overlap.get_area() <= 160.0, "The Moonglass seal must not cover the Mossvein entrance")
	assert ( not Rect2(moon_branch.entrance_visual_rect).intersects(Rect2(moonglass_boundary.gate_visual_rect)))
	assert ( not Rect2(moss_branch.entrance_visual_rect).intersects(Rect2(moonglass_boundary.generator_rect)))
	assert ( not Rect2(moon_branch.entrance_visual_rect).intersects(Rect2(moonglass_boundary.generator_rect)))
	assert ( not Rect2(moss_branch.entrance_visual_rect).intersects(Rect2(moonglass_boundary.seam_rect)))
	assert ( not Rect2(moon_branch.entrance_visual_rect).intersects(Rect2(moonglass_boundary.seam_rect)))
	assert (Vector2(moonglass_boundary.travel_axis) == Vector2.RIGHT)
	assert (
		Vector2(moonglass_boundary.station_position).distance_to(Vector2(moss_branch.entrance))
		> float(moonglass_boundary.station_radius) + float(moss_branch.interaction_radius)
	)
	var expected_portal_colors: = {
		"moonglass": PackedColorArray([Color("82ad62"), Color("69e8ff")]),
		"emberdeep": PackedColorArray([Color("69e8ff"), Color("ff6a2a")]),
		"starfall": PackedColorArray([Color("ff6a2a"), Color("a879ff")]),
	}
	var expected_gate_assets: = {
		"moonglass": "res://assets/surface/moonglass-gate.png",
		"emberdeep": "res://assets/surface/emberdeep-seal.png",
		"starfall": "res://assets/surface/starfall-seal.png",
	}
	var expected_mark_assets: = {
		"moonglass": "res://assets/surface/moonglass-open-threshold.png",
		"emberdeep": "res://assets/surface/emberdeep-seal-mark.png",
		"starfall": "res://assets/surface/starfall-seal-mark.png",
	}
	var boundary_rows: Dictionary = {}
	for boundary_value in Array(surface_routes.boundaries):
		var boundary: Dictionary = Dictionary(boundary_value)
		var boundary_id: = String(boundary.id)
		var anchor: = Vector2(boundary.anchor)
		var seam_rect: = Rect2(boundary.seam_rect)
		var generator_rect: = Rect2(boundary.generator_rect)
		var transition_debug: Dictionary = Dictionary(boundary.transition_debug)
		var transition: WorldTransitionVisual = surface_world.portal_transitions[boundary_id] as WorldTransitionVisual
		var generator: Dictionary = Dictionary(surface_world.portal_generator_nodes[boundary_id])
		var generator_sprite: Sprite2D = generator.sprite as Sprite2D
		assert (is_instance_valid(transition) and transition.position == anchor)
		assert (bool(boundary.seam_present) and seam_rect.size == Vector2(24, 184))
		assert (is_equal_approx(seam_rect.get_center().x, anchor.x))
		assert (bool(boundary.generator_visual_present) and generator_rect.size == Vector2(150, 150))
		assert (is_equal_approx(generator_rect.get_center().x, anchor.x))
		assert (is_equal_approx(generator_rect.end.y, anchor.y - surface_world.GATE_HALF_GAP))
		assert (generator_sprite.texture is AtlasTexture)
		assert ((generator_sprite.texture as AtlasTexture).region == Rect2(181, 25, 150, 150))
		assert (bool(transition_debug.seam_mode) and not bool(transition_debug.external_arch_mode))
		assert ( not bool(transition_debug.legacy_frame_visible) and not bool(boundary.legacy_arch_present))
		assert (Vector2(transition_debug.seam_back_size) == Vector2(24, 184))
		assert (Vector2(transition_debug.seam_front_size) == Vector2(8, 190))
		assert (int(transition_debug.seam_back_z) < surface_world.player.z_index)
		assert (int(transition_debug.seam_front_z) > surface_world.player.z_index)
		assert (is_equal_approx(float(transition_debug.crossing_pulse_duration), 0.42))
		assert (is_equal_approx(float(transition_debug.effective_transition_duration), 0.42))
		assert (int(transition_debug.particle_capacity) == 8)
		assert (String(transition_debug.gate_texture) == String(expected_gate_assets[boundary_id]))
		assert (String(transition_debug.threshold_texture) == String(expected_mark_assets[boundary_id]))
		assert (PackedColorArray(boundary.seam_palette) == PackedColorArray(expected_portal_colors[boundary_id]))
		assert ( not bool(boundary.player_occlusion_split) and Rect2(boundary.portal_arch_rect).size == Vector2.ZERO)
		assert (Vector2(boundary.travel_axis) == Vector2.RIGHT)
		boundary_rows[boundary_id] = boundary
	assert (boundary_rows.size() == 3)
	for boundary_id in ["moonglass", "emberdeep", "starfall"]:
		var transition: WorldTransitionVisual = surface_world.portal_transitions[boundary_id] as WorldTransitionVisual
		var anchor: = Vector2(Dictionary(boundary_rows[boundary_id]).anchor)
		transition.set_gate_open(false, false)
		assert (surface_world._surface_collides(anchor))
		assert (surface_world._surface_collides(anchor + Vector2(0, surface_world.GATE_HALF_GAP + surface_world.PLAYER_RADIUS + 1.0)))
	RunState.area_unlocked = true
	RunState.emberdeep_unlocked = true
	RunState.fourth_unlocked = true
	var player_position_before_portals: Vector2 = surface_world.player.global_position
	var player_control_before_portals: bool = surface_world.player.control_enabled
	for boundary_id in ["moonglass", "emberdeep", "starfall"]:
		var transition: WorldTransitionVisual = surface_world.portal_transitions[boundary_id] as WorldTransitionVisual
		var anchor: = Vector2(Dictionary(boundary_rows[boundary_id]).anchor)
		transition.set_gate_open(true, false)
		assert ( not surface_world._surface_collides(anchor))
		assert (surface_world._surface_collides(anchor + Vector2(0, surface_world.GATE_HALF_GAP + surface_world.PLAYER_RADIUS + 1.0)))
		transition.reset_actor_observation(anchor + Vector2(-60, 0))
		transition.observe_actor_position(anchor + Vector2(60, 0))
		assert (bool(transition.debug_snapshot().crossing))
		transition._process(0.21)
		assert (bool(transition.debug_snapshot().front_sweep_visible))
		transition._process(0.22)
		assert ( not bool(transition.debug_snapshot().crossing))
		transition.reset_actor_observation(anchor + Vector2(60, 0))
		transition.observe_actor_position(anchor + Vector2(-60, 0))
		assert (bool(transition.debug_snapshot().crossing))
		transition.cancel_crossing()
	assert (surface_world.player.global_position == player_position_before_portals)
	assert (surface_world.player.control_enabled == player_control_before_portals)
	assert (deepheart_world.EXIT_POSITION.x >= 400.0 and deepheart_world.EXIT_POSITION.x <= 500.0)
	assert (deepheart_world.PLAYER_SPAWN.distance_to(deepheart_world.EXIT_POSITION) > deepheart_world.EXIT_RADIUS)
	surface_parallax.force_update()
	var parallax_snapshot: Dictionary = surface_parallax.debug_snapshot()
	assert (int(parallax_snapshot.layer_count) == 4)
	assert (bool(parallax_snapshot.collision_neutral))
	assert (is_equal_approx(float(parallax_snapshot.reference_x), 640.0))
	var expected_effective_reference: = 640.0 + 0.5 * (float(parallax_snapshot.viewport_width_world) - 1280.0)
	assert (is_equal_approx(float(parallax_snapshot.effective_reference_x), expected_effective_reference))
	assert (is_equal_approx(surface_parallax._effective_reference_x(1563.4286), 781.7143))
	var parallax_layers: Dictionary = {}
	for layer_snapshot_value in Array(parallax_snapshot.layers):
		var layer_snapshot: Dictionary = Dictionary(layer_snapshot_value)
		parallax_layers[String(layer_snapshot.name)] = layer_snapshot
	assert (is_equal_approx(float(parallax_layers.FarSky.scroll_factor), 0.02))
	assert (is_equal_approx(float(parallax_layers.FarCanopy.scroll_factor), 0.05))
	assert (is_equal_approx(float(parallax_layers.MidForest.scroll_factor), 0.08))
	assert (is_equal_approx(float(parallax_layers.NearSilhouette.scroll_factor), 0.12))
	assert (int(parallax_layers.MidForest.visible_chunk_count) >= 1)
	assert (int(parallax_layers.NearSilhouette.visible_chunk_count) >= 1)
	var far_background_sprite: Sprite2D = surface_parallax.get_node("FarSky/MossMoonPanorama") as Sprite2D
	var midground_sprite: Sprite2D = surface_parallax.get_node("MidForest/MossveinMidground") as Sprite2D
	var foreground_sprite: Sprite2D = surface_parallax.get_node("NearSilhouette/MossveinCameraFrame") as Sprite2D
	var floor_frame_sprite: Sprite2D = surface_parallax.get_node("NearSilhouette/MossveinFloorFrame") as Sprite2D
	var continuous_floor: Sprite2D = surface_parallax.get_node("NearSilhouette/ContinuousForestFloor") as Sprite2D
	assert (midground_sprite.texture != null and midground_sprite.texture.get_size() == Vector2(1983, 793))
	for clipped_parallax_sprite in [far_background_sprite, midground_sprite]:
		var clip_material: ShaderMaterial = (clipped_parallax_sprite as Sprite2D).material as ShaderMaterial
		assert (clip_material != null and clip_material.shader != null)
		assert (clip_material.shader.resource_path == "res://shaders/surface_parallax_world_clip.gdshader")
		assert (is_equal_approx(float(clip_material.get_shader_parameter("world_right")), 2240.0))
	var expected_boundary_regions: = {
		"emberdeep": Rect2(192, 0, 297, 1024),
		"starfall": Rect2(186, 0, 318, 1024),
	}
	for boundary_id in ["emberdeep", "starfall"]:
		var boundary_sprite: Sprite2D = surface_world.boundary_backing_nodes[boundary_id] as Sprite2D
		assert (boundary_sprite.texture is AtlasTexture)
		var boundary_atlas: AtlasTexture = boundary_sprite.texture as AtlasTexture
		var expected_region: = Rect2(expected_boundary_regions[boundary_id])
		assert (boundary_atlas.region == expected_region)
		var source_scale: = Vector2(320.0 / 682.0, 1280.0 / 1024.0)
		var expected_rect: = Rect2(
			Vector2(float(Dictionary(boundary_rows[boundary_id]).anchor.x) - 160.0, 0.0) + expected_region.position * source_scale,
			expected_region.size * source_scale
		)
		assert (boundary_sprite.position.is_equal_approx(expected_rect.position))
		assert ((Vector2(boundary_atlas.get_size()) * boundary_sprite.scale.abs()).is_equal_approx(expected_rect.size))
	var surface_performance: Dictionary = surface_world.mobile_performance_snapshot()
	assert (is_equal_approx(float(surface_performance.dynamic_visual_hz), 30.0))
	assert (foreground_sprite.texture != null and foreground_sprite.texture.get_size() == Vector2(1672, 941))
	assert (foreground_sprite.region_enabled and foreground_sprite.region_rect == Rect2(0, 0, 1672, 430))
	assert (is_equal_approx(foreground_sprite.position.y, 215.0))
	var foreground_rect: = foreground_sprite.get_rect()
	var foreground_top: = minf(
		foreground_sprite.to_global(foreground_rect.position).y,
		foreground_sprite.to_global(foreground_rect.end).y
	)
	assert (is_equal_approx(foreground_top, 0.0), "The Mossvein canopy foreground must start at the world top without a horizontal mid-screen seam")
	assert (floor_frame_sprite.texture == foreground_sprite.texture)
	assert (floor_frame_sprite.region_enabled and floor_frame_sprite.region_rect == Rect2(0, 430, 1672, 511))
	assert (floor_frame_sprite.position.y >= 960.0, "The dense Mossvein foreground must stay anchored at the bottom of the landscape view")
	assert (continuous_floor.texture != null and continuous_floor.texture.get_size() == Vector2(2172, 724))
	var continuous_floor_image: Image = continuous_floor.texture.get_image()
	assert (continuous_floor_image != null)
	assert (continuous_floor_image.get_pixel(1086, 300).a <= 0.01, "The parallax floor background must be genuinely transparent")
	assert (continuous_floor_image.get_pixel(1086, 650).a >= 0.95, "The parallax floor artwork must remain opaque")
	assert (continuous_floor.material == null, "True-alpha parallax art must not depend on checkerboard keying")
	var floor_rect: Rect2 = continuous_floor.get_rect()
	var floor_top: Vector2 = continuous_floor.to_global(floor_rect.position)
	var floor_bottom: Vector2 = continuous_floor.to_global(floor_rect.end)
	assert (maxf(floor_top.y, floor_bottom.y) >= surface_world._world_size().y - 1.0)
	assert ((surface_parallax.get_node("NearSilhouette") as Node2D).z_index > surface_world.player.z_index)
	var chest_ids: Dictionary = {}
	var chest_positions: Dictionary = {}
	for chest_value in Array(GameData.data.CHEST_DEFINITIONS):
		var chest: Dictionary = Dictionary(chest_value)
		var chest_id: String = String(chest.id)
		var chest_position: Vector2 = surface_world.surface_chest_position(chest_id)
		assert ( not chest_ids.has(chest_id))
		assert ( not chest_positions.has(chest_position))
		chest_ids[chest_id] = true
		chest_positions[chest_position] = chest_id
	assert (chest_ids.size() == 8)
	assert (surface_world.surface_chest_position("moss_supply") == Vector2(750, 640))
	assert (surface_world.surface_chest_position("moss_ironbound") == Vector2(700, 720))
	for routed_chest in Array(surface_routes.chests):
		var routed_chest_row: = Dictionary(routed_chest)
		assert ( not surface_world._surface_collides(Vector2(routed_chest_row.position)), "Surface chest must remain on visible walkable terrain: %s at %s" % [String(routed_chest_row.id), Vector2(routed_chest_row.position)])
	assert ( not surface_world._surface_collides(Vector2(2860, 788)), "The Ember collision must follow the visible mine path")
	assert (surface_world._surface_collides(Vector2(2860, 700)), "Open Ember ground outside the path must not be invisibly walkable")
	assert ( not surface_world._surface_collides(Vector2(3890, 930)), "The Starfall collision must follow the visible mine path")
	assert (surface_world._surface_collides(Vector2(3890, 735)), "Open Starfall ground outside the path must not be invisibly walkable")
	for routed_mine_id in surface_world.MINE_IDS:
		assert ( not surface_world._surface_collides(surface_world._mine_entrance(String(routed_mine_id))), "Every mine entrance must meet its visible path: %s" % String(routed_mine_id))
	assert (surface_world._surface_collides(Vector2(300, 940)))
	assert (surface_world._surface_collides(Vector2(1285, 1110)))
	assert (surface_world._surface_collides(Vector2(600, 930)), "The annotated foliage below the road must not be walkable")
	var steering_contract: Dictionary = surface_world.route_steering_snapshot()
	assert (bool(steering_contract.enabled) and bool(steering_contract.projected_speed) and bool(steering_contract.tangent_fallback))
	assert (is_equal_approx(float(steering_contract.angle_step), 8.0))
	assert (is_equal_approx(float(steering_contract.maximum_angle), 72.0))
	assert (int(steering_contract.refine_steps) == 3)
	assert (bool(steering_contract.never_reverses_input) and bool(steering_contract.visible_solids_remain_blocking))
	var steering_cases: Array[Dictionary] = [
		{"label": "Moonglass", "route": Array(surface_world.LATER_MINE_BRANCH_ROUTES.moonMine), "segment": 2},
		{"label": "Emberdeep", "route": Array(surface_world.LATER_MINE_BRANCH_ROUTES.emberMine), "segment": 3},
		{"label": "Starfall", "route": Array(surface_world.LATER_MINE_BRANCH_ROUTES.starMine), "segment": 2},
	]
	var steering_events_before: int = int(surface_world.route_steering_snapshot().events)
	for steering_case_value in steering_cases:
		var steering_case: Dictionary = steering_case_value
		var steering_route: Array = steering_case.route
		var steering_segment: int = int(steering_case.segment)
		var steering_start: Vector2 = Vector2(steering_route[steering_segment])
		var steering_end: Vector2 = Vector2(steering_route[steering_segment + 1])
		var steering_tangent: Vector2 = (steering_end - steering_start).normalized()
		var steering_normal: Vector2 = Vector2( - steering_tangent.y, steering_tangent.x)
		var steering_position: Vector2 = (steering_start + steering_end) * 0.5 + steering_normal * (surface_world.LATER_BRANCH_ROUTE_HALF_WIDTH - 0.25)
		var steering_intent: Vector2 = (steering_tangent + steering_normal * 0.65).normalized() * 8.0
		assert ( not surface_world._surface_collides(steering_position), "%s soft-rail fixture must start on its visible road" % String(steering_case.label))
		assert (surface_world._surface_collides(steering_position + steering_intent), "%s fixture must press outward through the invisible route edge" % String(steering_case.label))
		surface_world._reset_surface_route_steering()
		surface_world.surface_last_motion_direction = steering_tangent
		for steering_step in range(6):
			var steered_position: Vector2 = surface_world._resolve_motion(steering_position, steering_intent)
			var steering_delta: Vector2 = steered_position - steering_position
			assert (steering_delta.length() >= 2.0, "%s soft rails must preserve visible progress" % String(steering_case.label))
			assert (steering_delta.dot(steering_intent) > 0.0 and steering_delta.dot(steering_tangent) > 0.0)
			assert (steering_delta.length() <= steering_intent.length() + 0.01, "Route steering must never boost movement speed")
			assert (surface_world._is_on_surface_route(steered_position) and not surface_world._surface_collides(steered_position))
			steering_position = steered_position
	assert (int(surface_world.route_steering_snapshot().events) >= steering_events_before + steering_cases.size())
	var ember_route: Array = surface_world.LATER_MINE_BRANCH_ROUTES.emberMine
	var ember_start: Vector2 = Vector2(ember_route[3])
	var ember_end: Vector2 = Vector2(ember_route[4])
	var ember_tangent: Vector2 = (ember_end - ember_start).normalized()
	var ember_normal: Vector2 = Vector2( - ember_tangent.y, ember_tangent.x)
	surface_world._reset_surface_route_steering()
	var outward_position: Vector2 = (ember_start + ember_end) * 0.5 + ember_normal * (surface_world.LATER_BRANCH_ROUTE_HALF_WIDTH - 0.25)
	var outward_result: Vector2 = surface_world._resolve_motion(outward_position, ember_normal * 8.0)
	var outward_delta: Vector2 = outward_result - outward_position
	assert (outward_delta.length() >= 2.0, "A pure outward press must glide along the road instead of hard-stopping")
	assert (outward_delta.dot(ember_normal) >= -0.01 and outward_delta.dot(ember_tangent) > 0.0)
	assert (outward_delta.length() <= 8.01 and not surface_world._surface_collides(outward_result))
	var moonglass_transition: WorldTransitionVisual = surface_world.portal_transitions.moonglass as WorldTransitionVisual
	RunState.area_unlocked = false
	moonglass_transition.set_gate_open(false, false)
	var locked_gate_position: Vector2 = surface_world._resolve_motion(Vector2(1038, 650), Vector2(160, 70))
	assert (locked_gate_position.x <= 1110.0 - (surface_world.BOUNDARY_HALF_WIDTH + surface_world.PLAYER_RADIUS) + 0.01)
	assert ( not surface_world._surface_collides(locked_gate_position), "Soft rails must never bypass a locked visible portal")
	RunState.area_unlocked = true
	moonglass_transition.set_gate_open(true, false)
	var camera_half_width: = viewport_size.x / (2.0 * maxf(absf(landscape_camera.zoom.x), 0.001))
	var camera_center_x: = landscape_camera.get_screen_center_position().x
	var camera_left: = camera_center_x - camera_half_width
	var camera_right: = camera_center_x + camera_half_width
	var coverage_sprites: Array[Sprite2D] = [far_background_sprite, midground_sprite, foreground_sprite]
	for coverage_sprite: Sprite2D in coverage_sprites:
		var coverage_rect: Rect2 = coverage_sprite.get_rect()
		var coverage_left: float = coverage_sprite.to_global(coverage_rect.position).x
		var coverage_right: float = coverage_sprite.to_global(coverage_rect.end).x
		assert (minf(coverage_left, coverage_right) <= camera_left + 1.0)
		assert (maxf(coverage_left, coverage_right) >= camera_right - 1.0)
	var expected_camera_y: = landscape_camera.framing_offset_for_viewport(viewport_size.y, landscape_camera.zoom.y)
	assert (is_equal_approx(landscape_camera.position.y, expected_camera_y))
	var design_camera_y: = landscape_camera.framing_offset_for_viewport(720.0)
	assert (is_equal_approx(design_camera_y, -129.6))
	var mine_lighting: Dictionary = mine_world.lighting_snapshot()
	var headlamp_snapshot: Dictionary = Dictionary(mine_lighting.headlamp)
	var cave_camera_snapshot: Dictionary = Dictionary(mine_lighting.camera)
	assert (bool(headlamp_snapshot.cone_only) and int(headlamp_snapshot.light_count) == 1)
	assert (Vector2i(headlamp_snapshot.texture_size) == Vector2i(256, 256))
	assert (float(headlamp_snapshot.border_alpha_max) <= 0.001)
	assert (is_equal_approx(float(headlamp_snapshot.beam_length), 600.0))
	assert (float(headlamp_snapshot.energy) >= 1.8)
	assert (bool(cave_camera_snapshot.enabled) and float(cave_camera_snapshot.maximum_forward_room) >= 460.0)
	var pickup_feedback: ResourcePickupBurst = surface_world.player.get_node("ResourcePickupBurst") as ResourcePickupBurst
	var pickup_contract: Dictionary = pickup_feedback.debug_snapshot()
	assert ( not pickup_feedback.is_processing(), "Idle pickup feedback must not consume an always-on frame callback")
	assert (bool(pickup_contract.transparent) and not bool(pickup_contract.has_panel) and not bool(pickup_contract.has_icon))
	assert (String(pickup_contract.presentation) == "color_coded_text" and bool(pickup_contract.color_coded))
	assert (int(pickup_contract.text_font_size) >= 28)
	assert (float(pickup_contract.hold_seconds) >= 2.6 and float(pickup_contract.fade_seconds) >= 0.7)
	pickup_feedback.show_pickup("stone", 1)
	assert (pickup_feedback.is_processing())
	pickup_feedback.show_pickup("stone", 2)
	var merged_pickup: Dictionary = pickup_feedback.debug_snapshot()
	assert (Array(merged_pickup.entries).size() == 1 and int(Dictionary(Array(merged_pickup.entries)[0]).amount) == 3)
	var stone_pickup: Dictionary = pickup_feedback.entries[0]
	var stone_label: Label = stone_pickup.label as Label
	assert (stone_label.text == "+3 STONE")
	assert (stone_label.get_theme_color("font_color") == Color("e6dfcf"))
	pickup_feedback.show_pickup("copper", 1)
	assert (Array(pickup_feedback.debug_snapshot().entries).size() == 2)
	var copper_pickup: Dictionary = pickup_feedback.entries[1]
	var copper_label: Label = copper_pickup.label as Label
	assert (copper_label.text == "+1 COPPER")
	assert (copper_label.get_theme_color("font_color") == Color("f0a35c"))
	assert (copper_label.get_theme_color("font_color") != stone_label.get_theme_color("font_color"))
	pickup_feedback._process(0.09)
	var pickup_root: Node2D = copper_pickup.root as Node2D
	assert (pickup_root.position.y <= -100.0 and pickup_root.modulate.a > 0.0 and pickup_root.modulate.a < 1.0)
	assert (pickup_root.scale.x >= 0.9 and pickup_root.scale.x <= 1.07)
	pickup_feedback._process(float(pickup_contract.hold_seconds) + float(pickup_contract.fade_seconds) + 0.1)
	assert (Array(pickup_feedback.debug_snapshot().entries).is_empty())
	assert ( not pickup_feedback.is_processing())
	print("EVER_DEEPER_LANDSCAPE_OK config=%dx%d canvas=%dx%d camera_y=%.1f/%.1f menu=%dx%d parallax=%d/%d" % [
		roundi(configured_size.x), roundi(configured_size.y),
		roundi(viewport_size.x), roundi(viewport_size.y), landscape_camera.position.y, design_camera_y,
		roundi(landscape_menu_card.size.x), roundi(landscape_menu_card.size.y),
		int(parallax_snapshot.visible_chunk_count), int(parallax_snapshot.chunk_count),
	])
	get_tree().quit(0)


func _run_onboarding_qa() -> void :
	RunState.reset_run(false)
	game_started = true
	menu_open = false
	inventory_open = false
	phase = "surface"
	surface_world.set_active(true)
	_update_minimap()
	var map_snapshot: Dictionary = minimap_overlay.debug_snapshot()
	assert (bool(map_snapshot.visible) and String(map_snapshot.phase) == "surface")
	assert (float(map_snapshot.redraw_hz) <= 10.0)
	assert (bool(map_snapshot.transparent) and bool(map_snapshot.organic_style) and bool(map_snapshot.overlap_fade))
	assert (Rect2(map_snapshot.map_rect).size.x >= 180.0)
	quick_tutorial.open(false)
	var pc_snapshot: Dictionary = quick_tutorial.debug_snapshot()
	assert (int(pc_snapshot.item_count) == 5 and not bool(pc_snapshot.has_background) and not bool(pc_snapshot.input_blocking))
	quick_tutorial.open(true)
	var mobile_snapshot: Dictionary = quick_tutorial.debug_snapshot()
	assert (int(mobile_snapshot.item_count) == 5 and not bool(mobile_snapshot.has_background) and not bool(mobile_snapshot.input_blocking))
	assert (is_equal_approx(float(depth_world.SHRINE_RESPAWN_SECONDS), 75.0))
	depth_world.shrine_cooldowns["qa-shrine"] = 1.0
	depth_world._update_shrine_cooldowns(1.1)
	assert ( not depth_world.shrine_cooldowns.has("qa-shrine"))
	print("EVER_DEEPER_ONBOARDING_OK minimap=transparent_organic_overlap_fade tutorial=nonblocking shrine_respawn=75")
	get_tree().quit(0)


func _run_iphone_layout_qa() -> void :
	var css_viewports: = [
		Vector2(844, 390), Vector2(852, 393), Vector2(874, 402),
		Vector2(912, 420), Vector2(932, 430), Vector2(956, 440),
	]
	for css_size_value in css_viewports:
		var css_size: Vector2 = css_size_value
		var scale_to_css: float = css_size.y / 720.0
		var logical_size: Vector2 = Vector2(720.0 * css_size.x / css_size.y, 720.0)
		premium_hud.set_context_action("OPEN", true)
		_apply_responsive_ui_layout(logical_size)
		var hud: Dictionary = premium_hud.apply_iphone_layout_for_test(logical_size)
		var menu: Dictionary = premium_menu.apply_iphone_layout_for_test(logical_size)
		var inventory: Dictionary = resource_inventory.apply_iphone_layout_for_test(logical_size)
		var main_metrics: Dictionary = _iphone_layout_metrics(logical_size)
		var icons: Dictionary = Dictionary(hud.icons)
		assert (bool(hud.iphone) and bool(menu.iphone) and bool(inventory.iphone))
		assert (Rect2(hud.menu).size.is_equal_approx(Vector2(96, 96)))
		assert (Rect2(hud.context).size.is_equal_approx(Vector2(206, 104)))
		assert (int(icons.menu_cap) == 96)
		assert (int(icons.guide_cap) == 84)
		assert (int(icons.bag_cap) == 104)
		assert (Vector2(icons.gold).is_equal_approx(Vector2(60, 60)))
		assert (String(menu.version_label) == premium_menu.release_label())
		assert (float(menu.version_font_size) * scale_to_css >= 9.0)
		var top_icon_extents: Array[float] = []
		for icon_name in ["menu", "guide"]:
			var visual_size: = Vector2(icons[icon_name]) * scale_to_css
			top_icon_extents.append(maxf(visual_size.x, visual_size.y))
		assert (top_icon_extents.min() >= 39.0)
		assert (top_icon_extents.max() - top_icon_extents.min() <= 3.0)
		var bag_visual_size: = Vector2(icons.bag) * scale_to_css
		var bag_extent: = maxf(bag_visual_size.x, bag_visual_size.y)
		assert (bag_extent >= 48.0)
		var context_variants: = {
			"OPEN": 108, "FORGE": 104, "DESCEND": 104, "SELL": 96,
			"BUILD": 104, "DELIVER": 104, "PLACE": 108, "ATTACH ROPE": 108,
		}
		var context_captions: = {"ATTACH ROPE": "ATTACH"}
		for context_label in context_variants:
			premium_hud.set_context_action(String(context_label), true)
			var variant_icons: Dictionary = premium_hud.icon_size_snapshot()
			assert (int(variant_icons.context_cap) == int(context_variants[context_label]))
			assert (premium_hud.context_button.text == String(context_captions.get(context_label, context_label)))
			var context_visual_size: = Vector2(variant_icons.context) * scale_to_css
			var context_extent: = maxf(context_visual_size.x, context_visual_size.y)
			assert (context_extent >= 48.0)
			assert (context_extent / bag_extent <= 1.12)
		premium_hud.set_context_action("OPEN", true)
		var mine_visual_size: Vector2 = premium_hud.button_icon_visual_size(mine_button) * scale_to_css
		assert (maxf(mine_visual_size.x, mine_visual_size.y) >= 67.0)
		for target_name in ["menu", "guide", "bag", "context"]:
			var target_rect: Rect2 = hud[target_name]
			assert (target_rect.size.x * scale_to_css >= 44.0)
			assert (target_rect.size.y * scale_to_css >= 44.0)
		for target_name in ["continue", "new_game", "achievements", "settings", "back", "confirm_cancel", "confirm_accept"]:
			var target_rect: Rect2 = menu[target_name]
			assert (target_rect.size.y * scale_to_css >= 44.0)
		assert (float(inventory.close_height) * scale_to_css >= 44.0)
		assert (float(inventory.auto_sort_height) * scale_to_css >= 44.0)
		assert (int(inventory.columns) == 4)
		assert (Rect2(menu.safe_rect).encloses(Rect2(menu.main)))
		assert (Rect2(menu.safe_rect).encloses(Rect2(menu.detail)))
		assert (Rect2(menu.safe_rect).encloses(Rect2(menu.confirm)))
		assert (Rect2(inventory.safe_rect).encloses(Rect2(inventory.card)))
		assert (Rect2(main_metrics.safe_rect).encloses(Rect2(main_metrics.mine)))
		assert (Rect2(hud.safe_rect).encloses(Rect2(hud.context)))
		assert (Rect2(hud.mine).is_equal_approx(Rect2(main_metrics.mine)))
		assert (movement_pad._is_in_movement_zone(Vector2(0.0, logical_size.y)))
		assert (movement_pad._is_in_movement_zone(Vector2(1.0, logical_size.y - 1.0)))
		movement_pad._begin(77, Vector2(0.0, logical_size.y - 1.0))
		movement_pad._update_knob(Vector2(48.0, logical_size.y - 1.0))
		assert (button_move.is_equal_approx(Vector2.RIGHT))
		movement_pad._end()
		assert (Rect2(main_metrics.safe_rect).encloses(Rect2(main_metrics.conclusion)))
		assert (Rect2(main_metrics.mine).size.y * scale_to_css >= 80.0)
		assert ( not Rect2(hud.objective).intersects(Rect2(hud.menu)))
		assert ( not Rect2(hud.objective).intersects(Rect2(hud.guide)))
		assert ( not Rect2(hud.objective).intersects(Rect2(hud.gold)))
		assert ( not Rect2(hud.objective).intersects(Rect2(hud.bag)))
		assert ( not Rect2(hud.context).intersects(Rect2(main_metrics.mine)))
		assert ( not Rect2(hud.context).intersects(Rect2(hud.bag)))
		assert ( not Rect2(hud.bag).intersects(Rect2(main_metrics.mine)))
		assert (is_equal_approx(Rect2(main_metrics.mine).position.x - Rect2(hud.bag).end.x, 18.0))
		assert (Rect2(hud.bag).position.y > logical_size.y * 0.5)
		var guide_safe: Rect2 = guide_overlay.safe_rect_for_viewport(logical_size)
		assert (guide_safe.position.x >= 110.0)
		assert (guide_safe.position.y >= Rect2(hud.menu).end.y + 36.0)
		assert (guide_safe.end.x <= Rect2(hud.bag).position.x - 30.0)
		assert (premium_hud.context_button.text == "OPEN")
		assert (($HUD / TouchControls / Mine / Caption as Label).text == "MINE")
		assert (premium_hud.objective_title.get_theme_font_size("font_size") * scale_to_css >= 10.5)
		assert (premium_hud.status_label.get_theme_font_size("font_size") * scale_to_css >= 10.5)
		assert (premium_menu.continue_button.get_theme_font_size("font_size") * scale_to_css >= 13.0)
		assert ((premium_menu.main_card.get_node("NewGame") as Button).get_theme_font_size("font_size") * scale_to_css >= 11.0)
		for variant_id in STARFORGE_VARIANT_IDS:
			var starforge_button: Button = starforge_buttons[variant_id]
			assert (starforge_button.size.y * scale_to_css >= 44.0)
			assert (Rect2(Vector2.ZERO, starforge_panel.size).encloses(Rect2(starforge_button.position, starforge_button.size)))
		assert (conclusion_continue_button.size.y * scale_to_css >= 44.0)
		assert (conclusion_hub_button.size.y * scale_to_css >= 44.0)
		assert ( not premium_hud.build_button.visible and premium_hud.build_button.disabled)
	print("EVER_DEEPER_IPHONE_LAYOUT_OK devices=844x390,852x393,874x402,912x420,932x430,956x440 touch=44css icons=optically-normalized safe=notch/home overlays=menu,bag,museum,starforge,conclusion")
	get_tree().quit(0)


func _run_portrait_qa() -> void :
	var portrait_logical: = Vector2(1280, 2770)
	_apply_responsive_ui_layout(portrait_logical)
	_sync_orientation_guard(portrait_logical, true)
	var card: Panel = orientation_guard.get_node("Card") as Panel
	var phone: Panel = card.get_node("Phone") as Panel
	assert (orientation_guard_active and orientation_guard.visible)
	assert (card.size.x >= 1000.0 and card.size.y >= 700.0)
	assert (phone.size.is_equal_approx(Vector2(100, 58)))
	assert (phone.scale.is_equal_approx(Vector2(3, 3)))
	var landscape_logical: = Vector2(1558, 720)
	_apply_responsive_ui_layout(landscape_logical)
	_sync_orientation_guard(landscape_logical, true)
	assert ( not orientation_guard_active and not orientation_guard.visible)
	print("EVER_DEEPER_PORTRAIT_GUARD_OK portrait=1280x2770 landscape=1558x720 card=%dx%d" % [roundi(card.size.x), roundi(card.size.y)])
	get_tree().quit(0)


func _run_surface_mountain_independence_smoke() -> void :
	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.unlock_world("starfall")
	phase = "surface"
	surface_world.reset_for_new_run()
	surface_world.set_active(true)
	var cases: Array[Dictionary] = [
		{
			"mountain_id": "moonglass_mountain", "vein_context": "moonglass_resource",
			"vein_position": Vector2(1820, 700), "mountain_position": Vector2(1580, 650),
			"snapshot_method": "moonglass_resource_snapshot", "mine_method": "_mine_moonglass_resource_once",
			"visual_method": "_update_moonglass_visual",
		},
		{
			"mountain_id": "emberdeep_mountain", "vein_context": "ember_resource",
			"vein_position": Vector2(3078, 1120), "mountain_position": Vector2(2899, 779),
			"snapshot_method": "ember_resource_snapshot", "mine_method": "_mine_timed_surface_resource_once",
			"mine_arg": "ember_fault", "visual_method": "_update_timed_surface_visual",
		},
		{
			"mountain_id": "starfall_mountain", "vein_context": "starfall_resource",
			"vein_position": Vector2(3970, 1130), "mountain_position": Vector2(4300, 770),
			"snapshot_method": "starfall_resource_snapshot", "mine_method": "_mine_timed_surface_resource_once",
			"mine_arg": "starfall_lattice", "visual_method": "_update_timed_surface_visual",
		},
	]
	for case_value in cases:
		var mountain_id: = String(case_value.mountain_id)
		var vein_context: = String(case_value.vein_context)
		var snapshot_method: = String(case_value.snapshot_method)
		surface_world.restore_position(Vector2(case_value.vein_position))
		assert (surface_context == vein_context, "%s must target its vein independently" % mountain_id)
		var mountain_before_vein: Dictionary = surface_world.surface_resource_mountain_snapshot(mountain_id)
		var vein_before: Dictionary = surface_world.call(snapshot_method)
		if case_value.has("mine_arg"):
			surface_world.call(String(case_value.mine_method), String(case_value.mine_arg))
			surface_world.call(String(case_value.visual_method), String(case_value.mine_arg))
		else:
			surface_world.call(String(case_value.mine_method))
			surface_world.call(String(case_value.visual_method))
		var mountain_after_vein: Dictionary = surface_world.surface_resource_mountain_snapshot(mountain_id)
		var vein_after: Dictionary = surface_world.call(snapshot_method)
		assert (Array(vein_after.nodes) != Array(vein_before.nodes), "%s vein hit must change a vein node" % mountain_id)
		assert (int(mountain_after_vein.hp) == int(mountain_before_vein.hp), "%s vein hit must not damage the mountain" % mountain_id)
		assert (int(mountain_after_vein.hit_count) == int(mountain_before_vein.hit_count), "%s vein hit must not trigger mountain effects" % mountain_id)
		assert (Vector2(mountain_after_vein.position).is_equal_approx(Vector2(mountain_before_vein.position)), "%s vein hit must not move the mountain" % mountain_id)
		assert (is_equal_approx(float(mountain_after_vein.rotation), float(mountain_before_vein.rotation)), "%s vein hit must not rotate the mountain" % mountain_id)

		surface_world.restore_position(Vector2(case_value.mountain_position))
		assert (surface_context == mountain_id, "%s must expose its own mining context" % mountain_id)
		assert (mine_button.visible, "%s must expose the touch mining control" % mountain_id)
		var vein_before_mountain: Dictionary = surface_world.call(snapshot_method)
		var mountain_before_hit: Dictionary = surface_world.surface_resource_mountain_snapshot(mountain_id)
		surface_world._mine_surface_resource_mountain_once(mountain_id)
		var mountain_after_hit: Dictionary = surface_world.surface_resource_mountain_snapshot(mountain_id)
		var vein_after_mountain: Dictionary = surface_world.call(snapshot_method)
		assert (int(mountain_after_hit.hp) < int(mountain_before_hit.hp), "%s hit must damage only its mountain" % mountain_id)
		assert (int(mountain_after_hit.hit_count) == int(mountain_before_hit.hit_count) + 1, "%s hit must own its reaction count" % mountain_id)
		assert (int(mountain_after_hit.impact_count) > int(mountain_before_hit.impact_count), "%s hit must spawn its authored material reaction" % mountain_id)
		assert (Array(vein_after_mountain.nodes) == Array(vein_before_mountain.nodes), "%s mountain hit must not alter vein nodes" % mountain_id)
		assert (String(vein_after_mountain.status) == String(vein_before_mountain.status), "%s mountain hit must not alter vein status" % mountain_id)

		surface_world._update_surface_resource_mountains(0.2)
		var normalized: Dictionary = surface_world.surface_resource_mountain_snapshot(mountain_id)
		var rendered_size: = Vector2(normalized.texture_size) * Vector2(normalized.sprite_scale).abs()
		var local_bottom_center: = Vector2(normalized.sprite_position) + Vector2(rendered_size.x * 0.5, rendered_size.y)
		assert (Vector2(normalized.display_size).is_equal_approx(Vector2(mountain_before_hit.display_size)), "%s damage frames must retain the authored display size" % mountain_id)
		assert (rendered_size.is_equal_approx(Vector2(normalized.display_size)), "%s damage texture must normalize to the authored frame" % mountain_id)
		assert (local_bottom_center.length() <= 0.01, "%s damage frame must retain its bottom-center anchor" % mountain_id)
		assert (Vector2(normalized.position).is_equal_approx(Vector2(normalized.base_position)), "%s must settle back onto its fixed world anchor" % mountain_id)
		assert (is_equal_approx(float(normalized.rotation), 0.0))
		assert (bool(normalized.fixed_bottom_center_anchor) and bool(normalized.independent_from_vein))
	surface_world.reset_for_new_run()


func _assert_depth_one_bedrock_contract() -> void :
	var catalog = WorldCatalogScript.new(GameData.data)
	var expected_surfaces: Dictionary = {
		"mossMine": {
			"world_id": "mossvein",
			"path": "res://assets/mossvein/bedrock-surface-v1.png",
		},
		"moonMine": {
			"world_id": "moonglass",
			"path": "res://assets/moonglass/bedrock-surface-v1.png",
		},
		"emberMine": {
			"world_id": "emberdeep",
			"path": "res://assets/emberdeep/bedrock-surface-v1.png",
		},
		"starMine": {
			"world_id": "starfall",
			"path": "res://assets/starfall/bedrock-surface-v1.png",
		},
	}
	var seen_paths: Dictionary = {}
	var previous_active_texture: Texture2D
	for mine_id_value in MINE_IDS:
		var mine_id: = String(mine_id_value)
		var expected: = Dictionary(expected_surfaces[mine_id])
		var world_contract: = Dictionary(catalog.world(String(expected.world_id)))
		var catalog_assets: = Dictionary(
			Dictionary(world_contract.mine_assets).get("depth1", {})
		)
		var expected_path: = String(expected.path)
		assert (
			String(catalog_assets.get("unbreakable_surface", "")) == expected_path,
			"%s must publish its own D1 bedrock surface" % mine_id
		)
		assert (
			catalog_assets.has("unbreakable_wall")
			and catalog_assets.has("unbreakable_corner"),
			"%s must retain legacy unbreakable asset keys" % mine_id
		)
		assert (ResourceLoader.exists(expected_path), "Missing D1 bedrock surface: %s" % expected_path)
		var authored_texture: = ResourceLoader.load(expected_path) as Texture2D
		assert (
			authored_texture != null
			and authored_texture.get_width() == 576
			and authored_texture.get_height() == 576,
			"%s bedrock surface must remain an authored 576x576 texture" % mine_id
		)
		assert (not seen_paths.has(expected_path), "Every D1 biome needs a distinct bedrock surface")
		seen_paths[expected_path] = true

		mine_world.load_mine(mine_id)
		var active_texture: = mine_world.get("bedrock_surface_texture") as Texture2D
		var renderer_assets: = Dictionary(mine_world.get("mine_assets"))
		assert (
			active_texture != null
			and active_texture.resource_path == expected_path
			and active_texture.get_width() == 576
			and active_texture.get_height() == 576,
			"%s must activate its own 576x576 bedrock surface" % mine_id
		)
		assert (
			renderer_assets.has("bedrock") and renderer_assets.has("bedrock_corner"),
			"%s renderer must retain its legacy bedrock keys" % mine_id
		)
		if previous_active_texture != null:
			assert (
				active_texture != previous_active_texture,
				"A biome switch must replace the active bedrock texture"
			)
		previous_active_texture = active_texture

	assert (seen_paths.size() == 4)
	assert (mine_world.has_method("_block_emits_mineable_edge"))
	assert (mine_world.has_method("_block_emits_mineable_corner"))
	assert (mine_world.has_method("_mineable_corner_uses_compact_join"))
	assert (mine_world.has_method("_mineable_edge_open_sides"))
	var all_open: Array[bool] = [true, true, true, true]
	var three_open: Array[bool] = [true, true, true, false]
	var bedrock_block: = Dictionary(mine_world.call("_make_block", "bedrock", 1, 99, "bedrock"))
	var terrain_block: = Dictionary(mine_world.call("_make_block", "stone", 8, 0, "terrain"))
	assert (not bool(mine_world.call("_block_emits_mineable_edge", bedrock_block)))
	assert (not bool(mine_world.call("_block_emits_mineable_corner", bedrock_block, all_open)))
	assert (bool(mine_world.call("_block_emits_mineable_edge", terrain_block)))
	assert (bool(mine_world.call("_block_emits_mineable_corner", terrain_block, three_open)))
	assert (bool(mine_world.call("_mineable_corner_uses_compact_join", three_open)))
	assert (bool(mine_world.call("_mineable_corner_uses_compact_join", all_open)))
	var adjacent_two_open: Array[Array] = [
		[true, true, false, false],
		[false, true, true, false],
		[false, false, true, true],
		[true, false, false, true],
	]
	for open_sides_value in adjacent_two_open:
		var open_sides: Array[bool] = []
		open_sides.assign(open_sides_value)
		assert (
			bool(mine_world.call("_block_emits_mineable_corner", terrain_block, open_sides)),
			"Every adjacent two-side turn must emit one local mineable corner join"
		)
		assert (
			bool(mine_world.call("_mineable_corner_uses_compact_join", open_sides)),
			"Every adjacent two-side turn must crop the authored corner to its local join"
		)
	for opposite_open_value in [
		[true, false, true, false],
		[false, true, false, true],
	]:
		var opposite_open: Array[bool] = []
		opposite_open.assign(opposite_open_value)
		assert (
			not bool(
				mine_world.call("_block_emits_mineable_corner", terrain_block, opposite_open)
			),
			"Opposite open faces are not a corner"
		)

	# Only an explicitly player-dug void may expose a mineable rim. Authored
	# openings and temporary resource depletion remain physically walkable but do
	# not manufacture cave edges.
	var original_blocks: Dictionary = mine_world.get("blocks")
	var original_mineable_edge_voids: Dictionary = mine_world.get(
		"mineable_edge_void_cells"
	)
	var provenance_origin: = Vector2i(6, 6)
	var player_dug_void: = provenance_origin + Vector2i.UP
	var authored_void: = provenance_origin + Vector2i.RIGHT
	var temporary_resource_void: = provenance_origin + Vector2i.DOWN
	var provenance_blocks: Dictionary = {
		provenance_origin: terrain_block.duplicate(true),
		provenance_origin + Vector2i.LEFT: terrain_block.duplicate(true),
	}
	var provenance_edge_voids: Dictionary = {player_dug_void: true}
	mine_world.set("blocks", provenance_blocks)
	mine_world.set("mineable_edge_void_cells", provenance_edge_voids)
	var provenance_sides: Array[bool] = mine_world.call(
		"_mineable_edge_open_sides", provenance_origin
	)
	assert (
		bool(provenance_sides[0]),
		"A player-dug neighbour must expose its mineable rim"
	)
	assert (
		not bool(provenance_sides[1]),
		"An untracked authored opening must not manufacture a mineable rim"
	)
	assert (
		not bool(provenance_sides[2]),
		"A temporarily depleted resource cell must not manufacture a mineable rim"
	)
	assert (not provenance_blocks.has(player_dug_void))
	assert (not provenance_blocks.has(authored_void))
	assert (not provenance_blocks.has(temporary_resource_void))
	mine_world.set("blocks", original_blocks)
	mine_world.set("mineable_edge_void_cells", original_mineable_edge_voids)
	mine_world.load_mine("mossMine")


func _run_smoke_test() -> void :
	RunState.reset_run(false)
	var drop_presentation: Dictionary = DropVisualsScript.debug_snapshot()
	assert (String(drop_presentation.presentation) == "sprite_only")
	assert (float(drop_presentation.normal_visible_extent) >= 80.0)
	assert (float(drop_presentation.rare_visible_extent) >= 92.0)
	movement_pad._begin(41, Vector2(90, 280))
	movement_pad._update_knob(Vector2(122, 280))
	assert (button_move.is_equal_approx(Vector2.RIGHT))
	assert (mine_world.player.external_movement.is_equal_approx(Vector2.RIGHT))
	movement_pad._end()
	assert (button_move.is_zero_approx())
	assert (int(GameData.manifest.parity_counts.assets) == 263)
	assert (int(GameData.data.BIOMES.size()) == 4)
	assert (int(GameData.data.MINE_DEFINITIONS.size()) == 4)
	_assert_depth_one_bedrock_contract()
	assert (Vector2(float(GameData.world().width), float(GameData.world().height)) == Vector2(4480, 1280))
	assert (surface_world.entrance_position == Vector2(930, 900))
	assert (surface_world.player.global_position == Vector2(240, 680))
	assert (surface_world._surface_collides(Vector2(1110, 650)))
	assert (surface_world._surface_collides(Vector2(600, 500)), "The ore mountain must be a physical surface landmark")
	surface_world.restore_position(Vector2(600, 650))
	assert (surface_context == "ore_mountain")
	assert (mine_button.visible)
	surface_world.reset_for_new_run()
	surface_world.restore_position(Vector2(600, 650))
	RunState.pickaxe_level = 4
	var surface_copper_before: = int(RunState.cargo.copper)
	var surface_mountain_hp_before: = int(surface_world.ore_mountain_hp)
	surface_world._mine_ore_mountain_once()
	assert (int(RunState.cargo.copper) == surface_copper_before, "Surface ore should exist visibly before pickup")
	assert (surface_world.ore_drops.size() == 1)
	assert (int(surface_world.ore_mountain_hp) < surface_mountain_hp_before)
	surface_world._update_ore_drops(0.7)
	assert (int(RunState.cargo.copper) == surface_copper_before, "Surface ore must wait on the ground until the player collects it")
	var landed_surface_drop: Sprite2D = surface_world.ore_drops[0].sprite
	surface_world.player.global_position = landed_surface_drop.global_position
	surface_world._update_ore_drops(0.01)
	surface_world._update_ore_drops(0.2)
	assert (int(RunState.cargo.copper) == surface_copper_before + 1)
	surface_world.restore_position(Vector2(600, 650))
	for drop in surface_world.ore_drops:
		var leftover_drop: Sprite2D = drop.sprite
		if is_instance_valid(leftover_drop):
			leftover_drop.queue_free()
	surface_world.ore_drops.clear()
	surface_world.reset_for_new_run()
	surface_world.restore_position(Vector2(600, 650))
	RunState.pickaxe_level = 4
	for _hit in range(18):
		surface_world._mine_ore_mountain_once()
	assert (bool(surface_world.ore_mountain_snapshot().depleted))
	assert (surface_world.ore_drops.size() == 25, "A full ridge should release 24 copper and one full-growth gold bonus regardless of tool speed")
	var clean_gold_drop: Sprite2D
	for raw_drop in surface_world.ore_drops:
		if String(Dictionary(raw_drop).kind) == "gold":
			clean_gold_drop = Dictionary(raw_drop).sprite as Sprite2D
			break
	assert (clean_gold_drop != null and clean_gold_drop.get_child_count() == 0, "Loose gold must render as the resource sprite without a glow circle")
	assert (clean_gold_drop.texture.resource_path == "res://assets/drops/gold-drop-clean-v2.png")
	var embedded_mountain_save_position: = Vector2(600, 500)
	assert (surface_world._surface_collides(embedded_mountain_save_position), "Copper Ridge collision must never shrink around a future regrowth area")
	surface_world.restore_position(embedded_mountain_save_position)
	assert ( not surface_world._surface_collides(surface_world.player.global_position), "Legacy saves inside Copper Ridge must migrate to a nearby safe position")
	var depleted_drop_count: int = surface_world.ore_drops.size()
	surface_world._mine_ore_mountain_once()
	assert (surface_world.ore_drops.size() == depleted_drop_count, "A bare ridge stays mineable but cannot release ore that has not regrown")
	surface_world._apply_ore_mountain_regrowth(75.0)
	assert (abs(int(surface_world.ore_mountain_snapshot().hp) - 180) <= 1, "The ridge should regrow continuously instead of popping back after a cooldown")
	assert ( not bool(surface_world.ore_mountain_snapshot().gold_ready), "Gold only returns after a complete regrowth cycle")
	surface_world._apply_ore_mountain_regrowth(75.0)
	assert (int(surface_world.ore_mountain_snapshot().hp) == int(surface_world.ore_mountain_snapshot().max_hp))
	assert (bool(surface_world.ore_mountain_snapshot().gold_ready))
	surface_world.ore_mountain_hp = 90
	surface_world.ore_mountain_growth_buffer = 0.5
	surface_world.ore_mountain_gold_ready = false
	surface_world.persist_ore_mountain_state()
	var living_mountain_save: Dictionary = RunState.serialize()
	RunState.reset_run(false)
	assert (RunState.deserialize(living_mountain_save))
	assert (is_equal_approx(float(RunState.surface_ore_reserve), 90.5 / 360.0))
	assert (int(RunState.surface_ore_ground_loot.copper) == 24 and int(RunState.surface_ore_ground_loot.gold) == 1, "Uncollected quarry loot must survive Continue")
	surface_world.restore_ore_mountain_state()
	assert (abs(int(surface_world.ore_mountain_snapshot().hp) - 90) <= 2)
	assert (surface_world.ore_drops.size() == 25)
	surface_world.reset_for_new_run()
	surface_world.restore_position(Vector2(240, 680))
	RunState.reset_run(false)
	RunState.pickaxe_level = 3
	RunState.gold = 120
	_try_unlock_gate("moonglass")
	assert (RunState.gold == 0)
	assert (RunState.area_unlocked)
	assert (surface_world._surface_collides(Vector2(1110, 650)))
	surface_world._process(2.5)
	assert ( not surface_world._surface_collides(Vector2(1110, 650)))
	_run_surface_mountain_independence_smoke()
	RunState.reset_run(false)
	mine_world.load_mine("mossMine")
	var snapshot: Dictionary = mine_world.smoke_snapshot()
	assert (Vector2(snapshot.world_size) == Vector2(1920, 5120))
	assert (Vector2(mine_world.depth_entrance) == Vector2(1752, 2808))
	var shaft_center_cell: Vector2i = mine_world._world_to_cell(Vector2(mine_world.depth_entrance))
	assert (mine_world.depth_entrance_cells.has(shaft_center_cell.y * mine_world.cols + shaft_center_cell.x))
	assert ( not mine_world._player_collides(Vector2(mine_world.depth_entrance) + Vector2(92, 0)), "Depth 1 return pad must be clear before the player ascends")
	assert (int(snapshot.blocks) > 3500)
	assert (int(Dictionary(snapshot.outer_barrier).requires_tool) == 1)
	assert (int(Dictionary(snapshot.iron_barrier).requires_tool) == 2)
	assert (int(snapshot.outer_barrier_rocks) == 3)
	assert (int(snapshot.iron_barrier_rocks) == 3)
	assert (mine_world._player_collides(Vector2(658, 505)))
	assert (mine_world._player_collides(Vector2(658, 775)))
	assert (mine_world._player_collides(Vector2(1263, 505)))
	assert (mine_world._player_collides(Vector2(1263, 775)))
	for row in range(3, 10):
		assert (mine_world.blocks.has(Vector2i(12, row)))
	for row in range(17, 24):
		assert (mine_world.blocks.has(Vector2i(12, row)))
	for row in range(3, 10):
		assert (mine_world.blocks.has(Vector2i(25, row)))
	for row in range(17, 24):
		assert (mine_world.blocks.has(Vector2i(25, row)))
	_enter_mossvein()
	assert (phase == "mine")
	assert (mine_world.player.global_position == Vector2(230, 640))
	assert (mine_world.player.camera.is_current())
	assert ( not surface_world.player.camera.enabled)
	var diagonal_aim_cases: = [
		{"cardinal": Vector2.RIGHT, "diagonal": Vector2(1, 1), "name": "right"},
		{"cardinal": Vector2.LEFT, "diagonal": Vector2(-1, -1), "name": "left"},
		{"cardinal": Vector2.UP, "diagonal": Vector2(1, -1), "name": "up"},
		{"cardinal": Vector2.DOWN, "diagonal": Vector2(-1, 1), "name": "down"},
	]
	for aim_case in diagonal_aim_cases:
		mine_world.player.set_facing(Vector2(aim_case.cardinal))
		mine_world.player.set_facing(Vector2(aim_case.diagonal))
		assert (mine_world.player.direction_name == String(aim_case.name))
		assert (mine_world.player.facing_vector == Vector2(aim_case.cardinal), "Diagonal intent must target where the pickaxe is visibly facing")
	var grounding: Dictionary = mine_world.player.visual.grounding_snapshot()
	for anchor_value in grounding.values():
		assert (is_equal_approx(float(anchor_value), float(grounding.walk)))
	var animation_target: = Vector2i(6, 13)
	var previous_animation_block: Variant = mine_world.blocks.get(animation_target)
	mine_world.blocks[animation_target] = mine_world._make_block("stone", 100, 0, "terrain")
	mine_world.current_target = animation_target
	mine_world.set_mine_held(true)
	mine_world.swing_active = false
	mine_world._update_mining(0.0)
	assert (mine_world.swing_active and mine_world.player.mining_visual_active)
	mine_world.swing_hit = true
	mine_world.swing_elapsed = mine_world.swing_duration
	mine_world._update_mining(0.0)
	assert (mine_world.swing_active and mine_world.player.mining_visual_active, "Held mining must not flash back to the walk asset between swings")
	mine_world.set_mine_held(false)
	mine_world.swing_active = false
	mine_world._update_mining(0.0)
	assert ( not mine_world.player.mining_visual_active)
	if previous_animation_block == null:
		mine_world.blocks.erase(animation_target)
	else:
		mine_world.blocks[animation_target] = previous_animation_block
	for target_row in range(10, 15):
		for target_col in range(7, 13):
			mine_world.blocks.erase(Vector2i(target_col, target_row))
	var bedrock_cell: = Vector2i(9, 12)
	var blocked_cell: = Vector2i(10, 12)
	mine_world.blocks[bedrock_cell] = mine_world._make_block("bedrock", 1, 99, "bedrock")
	mine_world.blocks[blocked_cell] = mine_world._make_block("stone", 8, 0, "terrain")
	mine_world.player.global_position = Vector2(400, 600)
	mine_world.player.set_facing(Vector2.RIGHT)
	assert (mine_world._find_mine_target() == Vector2i(-1, -1), "Bedrock must not be targetable or allow mining through it")
	mine_world.blocks[bedrock_cell] = mine_world._make_block("stone", 8, 0, "terrain")
	assert (mine_world._find_mine_target() == bedrock_cell, "A mineable rock in the same position must remain targetable")
	for target_row in range(10, 15):
		for target_col in range(7, 13):
			mine_world.blocks.erase(Vector2i(target_col, target_row))
	var corner_front_cell: = Vector2i(9, 13)
	var corner_back_cell: = Vector2i(9, 14)
	mine_world.blocks[corner_front_cell] = mine_world._make_block("stone", 8, 0, "terrain")
	mine_world.blocks[corner_back_cell] = mine_world._make_block("stone", 8, 0, "terrain")
	mine_world.player.global_position = Vector2(432, 602)
	mine_world.player.set_facing(Vector2.DOWN)
	assert (mine_world._find_mine_target() == corner_front_cell, "Mining at a tight corner must target the adjacent block before the block behind it")
	for target_row in range(10, 15):
		for target_col in range(7, 13):
			mine_world.blocks.erase(Vector2i(target_col, target_row))
	var lower_left_front_cell: = Vector2i(8, 13)
	var lower_left_back_cell: = Vector2i(8, 14)
	mine_world.blocks[lower_left_front_cell] = mine_world._make_block("stone", 8, 0, "terrain")
	mine_world.blocks[lower_left_back_cell] = mine_world._make_block("stone", 8, 0, "terrain")
	mine_world.player.global_position = Vector2(456, 602)
	mine_world.player.set_facing(Vector2.DOWN)
	assert (mine_world._find_mine_target() == lower_left_front_cell, "Downward mining at a lower-left corner must select the rock beside the player's feet")
	mine_world.load_mine("mossMine")
	mine_world.player.global_position = (Vector2(Vector2i(24, 12)) + Vector2(0.5, 0.5)) * 48.0
	mine_world.player.set_facing(Vector2.RIGHT)
	mine_world.current_target = mine_world._find_mine_target()
	assert (mine_world.current_target == Vector2i(26, 12), "Expected authored barrier rock (26, 12), got %s" % mine_world.current_target)
	var locked_hp: = int(Dictionary(mine_world.blocks[mine_world.current_target]).hp)
	mine_world._mine_once()
	assert (int(Dictionary(mine_world.blocks[mine_world.current_target]).hp) == locked_hp)
	RunState.gold = 30
	assert (RunState.upgrade_pickaxe())
	assert (RunState.pickaxe_level == 2)
	mine_world._mine_once()
	assert (int(Dictionary(mine_world.blocks[mine_world.current_target]).hp) == locked_hp - 7)
	for barrier_row in [12, 13, 14]:
		var barrier_cell: = Vector2i(26, barrier_row)
		var barrier_rock: Dictionary = Dictionary(mine_world.blocks[barrier_cell])
		barrier_rock.hp = 1
		mine_world.blocks[barrier_cell] = barrier_rock
		mine_world.current_target = barrier_cell
		mine_world._mine_once()
	assert (RunState.is_mine_barrier_cleared("iron_seam"))
	assert (int(mine_world.role_block_counts.iron_seam) == 0)
	assert ( not mine_world._player_collides(Vector2(1263, 640)))
	RunState.reset_run(false)
	for legacy_row in [12, 13, 14]:
		RunState.mark_terrain_dug("mossMine", legacy_row * 40 + 26, 1)
	mine_world.load_mine("mossMine")
	assert (RunState.is_mine_barrier_cleared("iron_seam"))
	assert (int(mine_world.role_block_counts.iron_seam) == 0)
	RunState.reset_run(false)
	mine_world.load_mine("mossMine")
	mine_world._on_player_moved(Vector2(230, 640))
	assert (phase == "mine")
	assert (mine_exit_context)
	_perform_context()
	assert (phase == "surface")
	assert (surface_world.player.camera.is_current())
	assert ( not mine_world.player.camera.enabled)
	var surface_mine_return: Vector2 = Vector2(surface_world.player.global_position)
	assert ( not surface_world._surface_collides(surface_mine_return), "Leaving Mossvein Mine must never return the player inside the locked portal boundary")
	assert (surface_world._resolve_motion(surface_mine_return, Vector2.LEFT * 8.0).x < surface_mine_return.x, "The player must be able to move immediately after leaving Mossvein Mine")
	mine_world.load_mine("mossMine")
	var terrain_no_respawn_cell: = Vector2i(6, 7)
	var terrain_no_respawn_index: int = (
		terrain_no_respawn_cell.y * int(mine_world.cols) + terrain_no_respawn_cell.x
	)
	mine_world.blocks[terrain_no_respawn_cell] = mine_world._make_block("stone", 1, 0, "terrain")
	mine_world.respawns.clear()
	mine_world.current_target = terrain_no_respawn_cell
	mine_world._mine_once()
	assert (not mine_world.blocks.has(terrain_no_respawn_cell))
	assert (mine_world.respawns.is_empty(), "Ordinary mined terrain must never enter the respawn queue")
	assert (
		mine_world.mineable_edge_void_cells.has(terrain_no_respawn_cell),
		"Newly mined terrain must expose the mineable rim immediately"
	)
	assert (
		RunState.dug_cells("mossMine", 1).has(terrain_no_respawn_index),
		"Ordinary mined terrain must persist as player-dug space"
	)
	mine_world._configure_mine("mossMine")
	assert (
		not mine_world.blocks.has(terrain_no_respawn_cell),
		"Ordinary terrain must stay dug after the mine is rebuilt"
	)
	assert (
		mine_world.mineable_edge_void_cells.has(terrain_no_respawn_cell),
		"Persisted player-dug terrain must restore its mineable rim provenance"
	)
	var respawn_cell: = Vector2i(5, 7)
	var resource_block: Dictionary = Dictionary(mine_world.blocks[respawn_cell])
	assert (String(resource_block.role) == "resource")
	resource_block.hp = 1
	mine_world.blocks[respawn_cell] = resource_block
	mine_world.current_target = respawn_cell
	mine_world._mine_once()
	assert ( not mine_world.blocks.has(respawn_cell) and mine_world.respawns.size() == 1)
	assert (
		not mine_world.mineable_edge_void_cells.has(respawn_cell),
		"A temporarily depleted resource node must not expose a terrain rim"
	)
	var expired_respawn: Dictionary = Dictionary(mine_world.respawns[0])
	expired_respawn.respawn_until_unix = Time.get_unix_time_from_system() - 1.0
	mine_world.respawns[0] = expired_respawn
	var respawn_scope: Dictionary = Dictionary(RunState.mine_resource_runtime["mossMine:1"])
	var respawn_depleted: Dictionary = Dictionary(respawn_scope.depleted)
	var respawn_node_id: String = String(mine_world._resource_node_id(respawn_cell))
	var respawn_record: Dictionary = Dictionary(respawn_depleted[respawn_node_id])
	respawn_record.respawn_until_unix = int(Time.get_unix_time_from_system()) - 1
	respawn_depleted[respawn_node_id] = respawn_record
	respawn_scope.depleted = respawn_depleted
	RunState.mine_resource_runtime["mossMine:1"] = respawn_scope
	mine_world._update_respawns(0.0)
	assert (mine_world.blocks.has(respawn_cell))
	assert (not mine_world.mineable_edge_void_cells.has(respawn_cell))
	mine_world.load_mine("moonMine")
	var moon_snapshot: Dictionary = mine_world.smoke_snapshot()
	assert (String(moon_snapshot.mine_id) == "moonMine")
	assert (Vector2(moon_snapshot.world_size) == Vector2(1680, 5760))



	assert (int(moon_snapshot.blocks) > 3500)
	mine_world.load_mine("mossMine")
	RunState.reset_run(false)
	_enter_mine("mossMine", true, false)
	assert ( not mine_world.depth_entrance_boundary.is_empty())
	var shaft_boundary_index: = int(mine_world.depth_entrance_boundary.keys()[0])
	var shaft_boundary_cell: = Vector2i(shaft_boundary_index % mine_world.cols, floori(float(shaft_boundary_index) / float(mine_world.cols)))
	assert (mine_world.blocks.has(shaft_boundary_cell))
	var shaft_boundary_block: Dictionary = Dictionary(mine_world.blocks[shaft_boundary_cell])
	shaft_boundary_block.hp = 1
	mine_world.blocks[shaft_boundary_cell] = shaft_boundary_block
	mine_world.current_target = shaft_boundary_cell
	mine_world._mine_once()
	assert (RunState.is_depth_entrance_discovered("mossMine"))
	mine_world.restore_position(Vector2(mine_world.depth_entrance) + Vector2(92, 0))
	assert (mine_depth_context)
	_perform_context()
	assert (phase == "depth" and RunState.is_depth_visited("mossMine"))
	assert (Vector2(depth_world.depth_entrance) == Vector2(1752, 2808))
	var station_contract: Dictionary = depth_world.contract_snapshot()
	var station_assets: Dictionary = Dictionary(station_contract.asset_contract)
	assert (String(station_assets.sell) == "res://assets/stations/ore-exchange-v1.png")
	assert (String(station_assets.forge) == "res://assets/stations/drill-forge-workshop-v1.png")
	var sell_position: Vector2 = Vector2(float(depth_world.station_positions.sell.x), float(depth_world.station_positions.sell.y))
	var forge_position: Vector2 = Vector2(float(depth_world.station_positions.forge.x), float(depth_world.station_positions.forge.y))
	assert (sell_position.distance_to(forge_position) >= 330.0, "Large stations need a player-wide central aisle")
	assert ( not depth_world.collision_at((sell_position + forge_position) * 0.5), "Player must fit between exchange and forge")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	var crusher_tool: Dictionary = mine_world._current_tool()
	assert (float(crusher_tool.cooldown) > float(RunState.current_pickaxe().cooldown) * 2.0)
	assert (is_equal_approx(mine_world._tool_strike_progress(), 0.66))
	var crusher_test_center: = Vector2i(20, 20)
	var crusher_previous_blocks: Dictionary = {}
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			var crusher_cell: = crusher_test_center + Vector2i(x_offset, y_offset)
			crusher_previous_blocks[crusher_cell] = mine_world.blocks.get(crusher_cell)
			mine_world.blocks[crusher_cell] = mine_world._make_block("stone", 999, 0, "terrain")
	mine_world._apply_crusher_shockwave(crusher_test_center, crusher_tool)
	var crusher_previous_impacts: Array[Dictionary] = mine_world.impacts.duplicate(true)
	var crusher_previous_drop_count: int = mine_world.drops.size()
	var crusher_force_impact: = {
		"position": mine_world._cell_center(crusher_test_center),
		"age": 0.0,
		"life": 0.3,
		"broken": true,
		"style": "crusher",
	}
	mine_world._attach_crusher_debris(crusher_force_impact, crusher_test_center)
	assert (bool(crusher_force_impact.get("crusher_force", false)), "Broken Crusher hits need a short dust-and-crack force cue")
	assert ( not crusher_force_impact.has("crusher_chunks"), "Crusher visuals must use the real resource drops, not decorative rock chunks")
	mine_world.impacts.clear()
	mine_world.impacts.append(crusher_force_impact)
	mine_world._update_impacts(0.31)
	assert (mine_world.impacts.is_empty(), "Crusher force dust must clean itself up quickly")
	assert (mine_world.drops.size() == crusher_previous_drop_count, "The dust cue must never create loot")
	mine_world.impacts.assign(crusher_previous_impacts)
	var shocked_cells: = 0
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			var crusher_cell: = crusher_test_center + Vector2i(x_offset, y_offset)
			if crusher_cell != crusher_test_center and int(Dictionary(mine_world.blocks[crusher_cell]).hp) < 999:
				shocked_cells += 1
	assert (shocked_cells == 24, "Astral Crusher must hit the full 5x5 footprint")
	for crusher_cell_value in crusher_previous_blocks:
		var crusher_cell: Vector2i = Vector2i(crusher_cell_value)
		var previous_crusher_block: Variant = crusher_previous_blocks[crusher_cell]
		if previous_crusher_block == null:
			mine_world.blocks.erase(crusher_cell)
		else:
			mine_world.blocks[crusher_cell] = previous_crusher_block
	RunState.set_starforge_variant("swift")
	assert (is_equal_approx(mine_world._tool_strike_progress(), 0.28))
	assert (float(mine_world._current_tool().cooldown) < float(RunState.current_pickaxe().cooldown))
	RunState.set_starforge_variant("prospector")
	assert (int(mine_world._current_tool().yield_multiplier) == 2, "Crownseeker must always double mined resources")
	RunState.set_starforge_variant("crusher")
	RunState.cargo.rootiron = 50
	RunState.cargo.ambercore = 5
	RunState.gold = 5000
	var drill_forge: Dictionary = Dictionary(depth_world.station_positions.forge)
	depth_world.restore_position(Vector2(float(drill_forge.x), float(drill_forge.y)))
	assert (depth_context == "drillForge")
	_perform_context()
	assert (RunState.drill_level == 1)
	depth_world.restore_position(Vector2(depth_world.depth_entrance))
	assert (depth_context == "depthExit")
	_perform_context()
	assert (phase == "mine")
	var depth_return_position: = Vector2(mine_world.depth_entrance) + Vector2(92, 0)
	assert (mine_world.player.global_position == depth_return_position)
	assert ( not mine_world._player_collides(mine_world.player.global_position), "Ascending from Depth 2 must never return the player inside rock")
	assert (mine_world._resolve_motion(mine_world.player.global_position, Vector2(-8, 0)).x < mine_world.player.global_position.x, "The player must be able to move immediately after ascending")


	RunState.reset_run(false)
	phase = "surface"
	current_mine_id = "mossMine"
	_apply_global_movement_speed()
	mine_world.set_active(false)
	depth_world.set_active(false)
	hub_world.set_active(false)
	surface_world.reset_for_new_run()
	surface_world.set_active(true)
	var moss_ironbound_position: Vector2 = surface_world.surface_chest_position("moss_ironbound")
	assert (moss_ironbound_position == Vector2(700, 720))
	assert ( not surface_world._surface_collides(moss_ironbound_position))
	assert (surface_world._surface_collides(Vector2(300, 940)))
	surface_world.restore_position(moss_ironbound_position)
	assert (surface_context == "chest:moss_ironbound")
	assert (action_button.text == "LOCKED" and action_button.disabled, "A tier-locked cache must explain itself without opening")
	RunState.gold = 150
	surface_world.restore_position(surface_world._station_position("speedShop"))
	assert (surface_context == "speedShop")
	_refresh_context_button()
	assert (action_button.text == "BROWSE" and not action_button.disabled)
	_perform_context()
	assert (commerce_panel.is_open() and commerce_context == "wayfarer")
	_on_commerce_action_confirmed("wayfarer:speed")
	station_transaction_fx.complete_immediately()
	assert (RunState.movement_speed_level == 1 and RunState.gold == 0)
	var upgraded_speed: = float(GameData.data.PLAYER_SPEED) * 1.07
	for upgraded_player in [surface_world.player, mine_world.player, depth_world.player, hub_world.player]:
		assert (is_equal_approx(upgraded_player.movement_speed, upgraded_speed), "Wayfarer speed must update every world immediately")
	RunState.reset_run(false)
	_apply_global_movement_speed()
	surface_world.reset_for_new_run()
	var moss_supply_position: Vector2 = surface_world.surface_chest_position("moss_supply")
	assert (moss_supply_position == Vector2(750, 640))
	assert ( not surface_world._surface_collides(moss_supply_position))
	assert (surface_world._surface_collides(Vector2(930, 350)))
	surface_world.restore_position(moss_supply_position)
	assert (surface_world.player.global_position == moss_supply_position)
	assert (surface_context == "chest:moss_supply" and action_button.text == "OPEN" and not action_button.disabled)
	_perform_context()
	assert (RunState.is_surface_chest_opened("moss_supply") and RunState.gold == 0)
	assert ( not RunState.is_surface_chest_opened("moss_ironbound"))
	assert (RunState.pending_chest_reward_loot("moss_supply") == {"coin": 25})
	assert (surface_world.chest_loot_drops.size() == 3, "Starter cache must spray three physical coin pieces")
	for chest_drop in surface_world.chest_loot_drops:
		assert ((Dictionary(chest_drop).sprite as Sprite2D).get_child_count() == 0, "Chest gold must use the resource sprite without a glow circle")
	for starter_drop in surface_world.chest_loot_drops:
		var starter_sprite: Sprite2D = Dictionary(starter_drop).sprite as Sprite2D
		starter_sprite.queue_free()
	surface_world.chest_loot_drops.clear()
	RunState.pending_chest_loot.clear()
	RunState.pickaxe_level = 3
	var moon_cache: Dictionary = _surface_chest_definition("moon_cache")
	var moon_plan: Dictionary = RunState.open_surface_chest("moon_cache")
	assert (bool(moon_plan.ok))
	surface_world._sync_pending_chest_loot_drops()
	assert ( not surface_world.chest_loot_drops.is_empty())
	var moon_drop: Dictionary = surface_world.chest_loot_drops[0]
	var moon_drop_sprite: Sprite2D = moon_drop.sprite as Sprite2D
	moon_drop.age = surface_world.ORE_DROP_FLIGHT_DURATION
	moon_drop.settled = true
	moon_drop_sprite.position = Vector2(moon_drop.landing_position)
	surface_world.chest_loot_drops[0] = moon_drop
	surface_world.player.global_position = moon_drop_sprite.global_position + Vector2(surface_world.CHEST_DROP_PICKUP_RADIUS - 8.0, 0.0)
	surface_world._update_chest_loot_drops(0.01)
	assert (bool(Dictionary(surface_world.chest_loot_drops[0]).collecting), "Moonglass chest gold must magnetize from the nearby path")
	surface_world._update_chest_loot_drops(surface_world.ORE_DROP_COLLECT_DURATION + 0.01)
	assert (RunState.gold > 0, "Moonglass chest gold must enter the wallet")
	RunState.cargo.stone = 5
	surface_world.restore_position(Vector2(335, 390))
	assert (surface_context == "storage:storage-1" and action_button.text == "USE")
	_perform_context()
	assert (int(Dictionary(RunState.base_module_by_id("storage-1").items).stone) == 5, "Starter storage must be functional on Surface")


	RunState.reset_run(false)
	surface_world.reset_for_new_run()
	RunState.add_resource("stone", 3)
	RunState.add_resource("copper", 2)
	surface_world.restore_position(surface_world.station_interaction_position("sell"))
	assert (surface_context == "sell" and action_button.text == "SELL ORE")
	assert ( not context_card.visible and premium_hud.context_button.visible and premium_hud.context_button.text == "SELL")
	assert (premium_hud.context_button.tooltip_text.contains("ASSAY STATION"))
	var expected_sale: = 3 * int(GameData.data.ROCK_TYPES.stone.value) + 2 * int(GameData.data.ROCK_TYPES.copper.value)
	_perform_context()
	assert (station_transaction_fx.busy and String(commerce_transaction.get("kind", "")) == "assay")
	station_transaction_fx.complete_immediately()
	assert (RunState.gold == expected_sale and int(RunState.cargo.stone) == 0 and int(RunState.cargo.copper) == 0, "Assay must sell ore through the shared context action")
	RunState.gold = int(RunState.next_pickaxe().cost)
	surface_world.restore_position(surface_world.station_interaction_position("forge"))
	assert (surface_context == "forge" and action_button.text == "FORGE")
	assert ( not context_card.visible and premium_hud.context_button.visible and premium_hud.context_button.text == "FORGE")
	assert (premium_hud.context_button.tooltip_text.contains("MOSSVEIN FORGE"))
	_perform_context()
	assert (commerce_panel.is_open() and commerce_context == "forge")
	_on_commerce_action_confirmed("forge:pickaxe")
	station_transaction_fx.complete_immediately()
	assert (RunState.pickaxe_level == 2, "Forge must buy the next pickaxe through the shared context action")
	surface_world.restore_position(surface_world._mine_entrance("mossMine"))
	assert (surface_context == "enter:mossMine" and action_button.text == "DESCEND" and action_button.visible)
	assert ( not context_card.visible and premium_hud.context_button.visible and premium_hud.context_button.text == "DESCEND")
	assert (InputMap.has_action("interact") and not InputMap.action_get_events("interact").is_empty(), "Keyboard interaction must remain bound for E/F")
	print("EVER_DEEPER_MOSS_ROOTWOUND_LOOP_OK source=", GameData.source_label(), " moss_blocks=", snapshot.blocks, " moon_blocks=", moon_snapshot.blocks, " portal=1752,2808 depth=Rootwound drill=Burrower persistence=true explicit_transitions=true")
	get_tree().quit(0)
