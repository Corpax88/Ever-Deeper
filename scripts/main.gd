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
const QaLauncher = preload("res://scripts/qa/qa_launcher.gd")
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
const MINE_IDS: = WorldCatalog.MINE_ORDER
const WORLD_BY_MINE = WorldCatalog.WORLD_BY_MINE
const GATE_REQUIREMENTS: = {
	"moonglass": {"pickaxe": 3, "gold": 120, "mastery": 0, "title": "Moonglass Gate"},
	"emberdeep": {"pickaxe": 4, "gold": 360, "mastery": 0, "title": "Emberdeep Seal"},
	"starfall": {"pickaxe": WorldCatalog.ENTRY_GATES.starfall.min_pickaxe_level, "gold": 0, "mastery": WorldCatalog.ENTRY_GATES.starfall.min_ember_mastery, "title": "Starfall Master Seal"}
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
var tunnel_home_in_progress: = false
var deepheart_hub_return_position: = Vector2(720, 300)
var endless_hub_return_position: = Vector2(720, 300)
var button_move: = Vector2.ZERO
var persistence_active: = false
var checkpoint_elapsed: = 0.0
var menu_open: = false
var game_started: = false
var save_available: = false
var automated_mode: = false
var qa_launcher: Node
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
	call_deferred("_install_mining_companion")
	var args: = OS.get_cmdline_user_args()
	var dev_qa_active: = "--qa-dev-tools" in args
	# Visual capture is a QA mode, not a build flavor. Production captures must
	# exercise the production HUD and save namespace without a developer menu.
	dev_build_active = OS.has_feature(DEV_BUILD_FEATURE) or dev_qa_active
	if OS.has_feature("web"):
		web_storage_uncertain = not OS.is_userfs_persistent()
	automated_mode = QaLauncher.is_automated(args)
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
	_connect_optional_signal(endless_world, "world_rebased", "_on_endless_world_rebased")
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
	qa_launcher = QaLauncher.new(self) if automated_mode else null
	if qa_launcher != null:
		add_child(qa_launcher)
		qa_launcher.start(args)
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
	if qa_launcher != null and qa_launcher.advance_performance(delta):
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
			message = "THE DEEP READY · DEPTH 1"
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
			message = "JUMPED TO THE DEEP · DEPTH 1"
		"jump_endless_12":
			ok = _dev_jump_endless(12)
			message = "JUMPED TO THE DEEP · DEPTH 12"
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
	_set_status("DEV · The Deep · Depth %d" % target_depth)
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
		if resource_id.is_empty():
			return false
		if remaining > 0:
			RunState.add_resource(resource_id, remaining, false)
			var delivered: = Dictionary(RunState.deliver_workshop_material(workshop_id, resource_id, remaining))
			if not bool(delivered.get("ok", false)):
				return false
		if not bool(Dictionary(RunState.build_workshop(workshop_id)).get("ok", false)):
			return false
	return true


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
	return _workshop_panel_is_open() or _commerce_panel_is_open() or _companion_panel_is_open()


func _companion_panel_is_open() -> bool:
	var interface=get_node_or_null("CompanionInterface")
	return interface!=null and interface.journal!=null and interface.journal.is_open()


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
	if tunnel_home_in_progress or automated_mode or menu_open or inventory_open or conclusion_overlay.visible or _shop_panel_is_open() or not commerce_transaction.is_empty() or not game_started:
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


func _progression_goal() -> Dictionary:
	var discovery: Dictionary = {}
	if phase == "endless" and is_instance_valid(endless_world):
		discovery = endless_world.discovery_goal()
	return guide_director.goal_for_state(discovery)


func _update_visual_guide() -> void :
	if guide_overlay == null or menu_open or inventory_open or not game_started:
		return
	guide_route_update_count += 1
	var goal: Dictionary = _progression_goal()
	if goal.is_empty():
		guide_director.reset()
		guide_overlay.clear_target()
		if premium_hud != null:
			premium_hud.set_progression_goal({})
		return
	if premium_hud != null:
		premium_hud.set_progression_goal(goal)
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
			if goal.has("discovery_target"):
				proposal.waypoint_id = String(goal.objective_id)
				proposal.candidates = [_guide_candidate(proposal.waypoint_id, Vector2(goal.discovery_target), 0.0)]
				return proposal
			var target_kind: = ""
			if kind == "endless_return":
				# The mole's home command is always available; no uphill waypoint.
				return {}
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
	if tunnel_home_in_progress or automated_mode or menu_open or conclusion_overlay.visible or _shop_panel_is_open() or not commerce_transaction.is_empty():
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
		return "THE DEEP · DEPTH %d" % int(Dictionary(RunState.endless_descent_status()).get("current_depth", 1))
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
	tunnel_home_in_progress = false
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
			location_name = "THE DEEP · %d m" % endless_world.depth_metres()
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
	if tunnel_home_in_progress:
		_cancel_mine_hold()
		return
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
	if tunnel_home_in_progress or _shop_panel_is_open():
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
		"depthSell":
			if phase=="depth" and not _shop_panel_is_open():
				var before: int=RunState.gold
				depth_world.perform_context()
				if RunState.gold>before: AudioDirector.play_economy("sell")
				_refresh_hud()
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
		"wardrobe": "Preview and unlock clothing colors",
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
		tunnel_home_in_progress
		or commerce_panel == null
		or _shop_panel_is_open()
		or (station_transaction_fx != null and station_transaction_fx.busy)
		or config.is_empty()
	):
		return
	commerce_context = context_id
	var current_world: Node = get(String(phase)+"_world")
	if is_instance_valid(current_world):
		current_world.player.control_enabled=false
		current_world.set_process(false)
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
	if context_id=="companion":
		get_node("CompanionInterface").journal.open_journal()
	else:
		commerce_panel.open_commerce(config)


func _on_commerce_closed() -> void :
	var current_world: Node=get(String(phase)+"_world")
	if is_instance_valid(current_world):
		current_world.set_process(true)
		current_world.player.control_enabled=true
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
	if item_id == "depth:drill" and commerce_context == "depth_forge":
		_try_upgrade_drill()
		commerce_panel.refresh(CommerceCatalogScript.depth_forge_config(current_mine_id))
	elif item_id == "wayfarer:speed" and commerce_context == "depth_wayfarer":
		var result: Dictionary=RunState.buy_movement_speed()
		if bool(result.get("ok",false)): AudioDirector.play_economy("upgrade")
		else: AudioDirector.play_blocked()
		commerce_panel.refresh(CommerceCatalogScript.wayfarer_config())
	elif item_id.begins_with("forge:"):
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
	if workshop_id not in ["wardrobe", "light_lab"]:
		_close_commerce_for_action()
	var transaction: = Dictionary(hub_world.confirm_workshop_action(workshop_id, action, value))
	if workshop_id in ["wardrobe", "light_lab"]:
		commerce_panel.refresh_commerce(CommerceCatalogScript.workshop_config(workshop_id, RunState.workshop_status(workshop_id), hub_world.workshop_selection_preview(workshop_id)))
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
	if not _shop_panel_is_open() and not tunnel_home_in_progress:
		return
	var active_player: Node2D = _active_player_node()
	if is_instance_valid(active_player):
		active_player.set("control_enabled", false)


func _settle_commerce_before_world_change() -> void :
	if _companion_panel_is_open(): get_node("CompanionInterface").journal.close_journal()
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
		_set_status("Upper passage · haul discoveries toward the Hub" if int(Dictionary(RunState.endless_descent_status()).get("current_depth", 0)) > 0 else "Tunnel Home · return with everything you found")
	elif context == "endless_down":
		_set_status("Keep digging · The Deep continues")
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
	if tunnel_home_in_progress or menu_open or inventory_open or orientation_guard_active or _companion_panel_is_open() or conclusion_overlay.visible or _shop_panel_is_open() or not commerce_transaction.is_empty():
		return
	if phase == "deepheart":
		deepheart_world.interact()
		return
	if phase == "endless":
		if endless_context.is_empty():
			request_tunnel_home()
		else:
			endless_world.perform_context()
		return
	if phase == "hub":
		hub_world.perform_context()
		objective_label.text = _hub_objective()
		_refresh_hud()
		return
	if phase == "depth":
		if depth_context == "drillForge":
			_open_commerce(CommerceCatalogScript.depth_forge_config(current_mine_id),"depth_forge")
		elif depth_context == "depthWayfarer":
			_open_commerce(CommerceCatalogScript.wayfarer_config(),"depth_wayfarer")
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
	var requirement: Dictionary = _gate_requirements(world_id)
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
	var first_visit: = RunState.hub_tutorial_pending()
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
	elif first_visit:
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
		_set_status("The Deepheart is restored · enter The Deep from your Hub")
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
	_set_status(_deep_hoard_status_text() if bool(RunState.victory) else "Back in the Hub · the Deepheart passage remains ready")
	_refresh_context_button()
	_refresh_hud()
	if persistence_active:
		RunState.set_location("hub", hub_world.player.global_position, 1)


func _enter_endless(entering: bool = true, persist_location: bool = true, restoring_active_run: bool = false) -> void :
	if not bool(RunState.victory):
		AudioDirector.play_blocked()
		_set_status("The Deep opens when the Deepheart is restored")
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
			_set_status("Place the carried relic in the Museum before descending again" if String(started.get("reason", "")) == "carried_relic_must_be_placed" else "The tunnel is not ready yet")
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
			_set_status("Use Tunnel Home with your relic attached")
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
		_set_status("Home again · your tunnel waits where you left it")
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
	guide_update_elapsed = GUIDE_UPDATE_INTERVAL


func _on_endless_world_rebased(offset: Vector2) -> void:
	var mole: Node = endless_world.get_node_or_null("MoleCompanion")
	if mole != null:
		mole.rebase_world(offset)
	guide_director.reset()
	guide_update_elapsed = GUIDE_UPDATE_INTERVAL
	minimap_update_elapsed = MINIMAP_UPDATE_INTERVAL


func request_tunnel_home() -> bool:
	if phase != "endless" or tunnel_home_in_progress or menu_open or inventory_open or orientation_guard_active or _shop_panel_is_open():
		return false
	if not bool(RunState.victory) or not bool(endless_world.active):
		return false
	var mole: Node = endless_world.get_node_or_null("MoleCompanion")
	if mole == null:
		return false
	tunnel_home_in_progress = true
	_cancel_held_input()
	endless_world.player.control_enabled = false
	endless_world.set_process(false)
	endless_world.set_physics_process(false)
	mole.begin_tunnel_home()
	AudioDirector.play_mining("stone", true, false)
	_refresh_context_button()
	_complete_tunnel_home()
	return true


func _complete_tunnel_home() -> void:
	# Use the existing authored digging frames before returning player and rope.
	await get_tree().create_timer(RunState.tunnel_home_duration()).timeout
	endless_world.set_process(true)
	endless_world.set_physics_process(true)
	if not tunnel_home_in_progress:
		return
	tunnel_home_in_progress = false
	if phase != "endless":
		return
	var result: Dictionary = endless_world.prepare_tunnel_home()
	if not bool(result.get("ok", false)):
		var mole: Node = endless_world.get_node_or_null("MoleCompanion")
		if mole != null:
			mole.recall()
		endless_world.player.control_enabled = not orientation_guard_active and not menu_open and not inventory_open
		AudioDirector.play_blocked()
		_set_status("Attach your relic's rope before tunneling home" if String(result.get("reason", "")) == "relic_rope_required" else "Tunnel paused · ready when you are")
		return
	_return_from_endless_to_hub(String(result.get("carried_relic_id", "")))
	if menu_open or inventory_open or orientation_guard_active:
		_pause_all_worlds_for_orientation()


func _on_endless_resource_collected(kind: String, amount: int, depth: int) -> void :
	if phase != "endless" or amount <= 0:
		return
	AudioDirector.play_pickup(kind, amount)
	_refresh_hud()


func _on_endless_discovery_found(_site_id: String, title: String, depth: int) -> void :
	if phase != "endless":
		return
	AudioDirector.play_discovery()
	_set_status("%s discovered" % title.capitalize())


func _on_endless_relic_discovered(relic_id: String, depth: int) -> void :
	if phase != "endless":
		return
	var relic: = Dictionary(RunState.relic_status(relic_id))
	AudioDirector.play_discovery(true)
	_set_status("%s · attach your rope" % String(relic.get("display_name", "Relic")))
	_refresh_hud()


func _on_endless_relic_attached(relic_id: String, _depth: int) -> void :
	if phase != "endless":
		return
	var relic: = Dictionary(RunState.relic_status(relic_id))
	AudioDirector.play_ui("confirm")
	_set_status("%s attached · ask your mole for Tunnel Home" % String(relic.get("display_name", "Relic")))
	_refresh_hud()


func _on_endless_relic_hauled_to_hub(relic_id: String, _discovery_depth: int) -> void :
	var relic: = Dictionary(RunState.relic_status(relic_id))
	_set_status("%s hauled home · drag it to the Museum pedestal" % String(relic.get("display_name", "Relic")))


func _on_endless_rope_state_changed(attached: bool, relic_id: String) -> void :
	if phase != "endless" or relic_id.is_empty():
		return
	if not attached:
		_set_status("Rope released · reattach it before Tunnel Home")
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
	_set_status("The Deepheart beats again · The Deep is open")
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
	_set_status("The Deep awaits below your Hub · your mole can tunnel home")
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
		return "The Deepheart is restored · The Deep is open below the Hub"
	var seals: = Dictionary(RunState.deepheart_seal_status())
	var missing: = Array(seals.get("missing", []))
	if missing.is_empty():
		return "Four resonances sing together · approach the Deepheart Core"
	return "%s resonance is next · follow the guide and hold MINE" % String(missing[0]).capitalize()


func _hub_objective() -> String:
	if bool(RunState.victory):
		var goal: = Dictionary(guide_director.goal_for_state())
		return String(goal.get("title", "Explore The Deep")).to_upper()
	var status: = Dictionary(RunState.deep_elevator_status())
	if bool(status.get("powered", false)):
		return "ENTER THE DEEPHEART PASSAGE"
	if bool(status.get("repaired", false)):
		return "AWAKEN THE PASSAGE · INSTALL THE SINGULARITY CORE"
	return "RESTORE THE PASSAGE · DELIVER CORE MATERIALS"


func _deep_hoard_status_text() -> String:
	var status: = Dictionary(RunState.deep_hoard_status())
	if not bool(status.get("unlocked", false)):
		return "Museum · restore the Deepheart to open The Deep"
	return "Museum · %d / %d relics placed · deepest %d m" % [
		int(status.get("placed_relic_count", 0)), int(status.get("total_relics", 5)),
		int(status.get("deepest_metres", 0)),
	]


func _endless_objective() -> String:
	var status: = Dictionary(RunState.endless_descent_status())
	var goal: = _progression_goal()
	return "%d m · %s" % [
		endless_world.depth_metres(),
		String(goal.get("title", "Keep digging deeper")).to_upper(),
	]


func _endless_progress_text() -> String:
	var status: = Dictionary(RunState.endless_descent_status())
	var carried: = Dictionary(status.get("carried_relic", {}))
	var relic_id: = String(carried.get("id", ""))
	if not relic_id.is_empty():
		var relic: = Dictionary(RunState.relic_status(relic_id))
		return "%s secured · Tunnel Home brings it back with you" % String(relic.get("display_name", "Relic"))
	return "Dig your own way deeper · your mole can tunnel home"


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
		return "The Deep · tunnel ready · deepest %d" % int(endless.get("deepest_depth", 0))
	if bool(status.get("powered", false)):
		return "Deepheart passage · ready"
	if bool(status.get("repaired", false)):
		return "Deepheart passage · install the Singularity Core"
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
	return "Deepheart passage · bring %s" % ", ".join(rows) if not rows.is_empty() else "Deepheart passage · awaiting repair"


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
		endless_world.save_stream_position()
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
	var requirement: Dictionary = _gate_requirements(world_id)
	if int(requirement.pickaxe) > RunState.pickaxe_level:
		return "%s · %s required" % [String(requirement.title), String(GameData.data.PICKAXES[int(requirement.pickaxe)].name)]
	if int(requirement.mastery) > int(RunState.get("ember_mastery")):
		return "%s · Depth Mastery %d required" % [String(requirement.title), int(requirement.mastery)]
	if RunState.gold < int(requirement.gold):
		return "%s · %d gold" % [String(requirement.title), int(requirement.gold)]
	return "%s · ready to open" % String(requirement.title)


func _gate_requirements(world_id: String) -> Dictionary:
	var requirement: Dictionary = Dictionary(GATE_REQUIREMENTS.get(world_id, {})).duplicate()
	if world_id == "moonglass":
		requirement["gold"] = int(GameData.data.GATE_COST)
	elif world_id == "emberdeep":
		requirement["gold"] = int(GameData.data.EMBER_GATE_COST)
	return requirement


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
		return "ASCEND TO THE BASE HUB · EXPLORE THE DEEP"
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
		return "RETURN TO THE BASE HUB · EXPLORE THE DEEP"
	if RunState.singularity_secured:
		return "ENTER THE BASE HUB · RESTORE THE DEEPHEART PASSAGE"
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
		else:
			label = "TUNNEL HOME"
		enabled = enabled and not tunnel_home_in_progress
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
		label = {"depthExit": "ASCEND", "depthSell": "SELL", "drillForge": "FORGE", "depthWayfarer":"BOOTS"}.get(depth_context, "")
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
				hint = "PRESS E OR TAP STEADY"
			else:
				title = "POWER SEAL"
				detail = "Cross four lit floor seals for a double cache; the nearby surge grows stronger"
				hint = "PRESS E OR TAP BOOST"
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
			return "%d m  ·  RELIC ON ROPE  ·  POUCH %d" % [endless_world.depth_metres(), RunState.cargo_count()]
		return "%d m  ·  BEST %d m  ·  POUCH %d" % [
			endless_world.depth_metres(), endless_world.deepest_metres(), RunState.cargo_count(),
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
		_set_status("Singularity Core secured · restore the passage in your Starfall Hub")
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


func _validate_release_version(args: PackedStringArray) -> bool:
	var release_version: = String(PremiumMenuScript.release_version())
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.everDeeperVersion=" + JSON.stringify(release_version) + ";var badge=document.getElementById('ed-build-label');if(badge)badge.textContent='v'+window.everDeeperVersion;", true)
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
	assert (mine_world.has_method("_resource_node_uses_transparent_surround"))
	assert (mine_world.has_method("_target_uses_filled_highlight"))
	assert (mine_world.has_method("_mineable_corner_uses_compact_join"))
	assert (mine_world.has_method("_mineable_edge_open_sides"))
	var all_open: Array[bool] = [true, true, true, true]
	var none_open: Array[bool] = [false, false, false, false]
	var three_open: Array[bool] = [true, true, true, false]
	var bedrock_block: = Dictionary(mine_world.call("_make_block", "bedrock", 1, 99, "bedrock"))
	var terrain_block: = Dictionary(mine_world.call("_make_block", "stone", 8, 0, "terrain"))
	var copper_resource_block: = Dictionary(
		mine_world.call("_make_block", "copper", 8, 0, "resource")
	)
	assert (not bool(mine_world.call("_block_emits_mineable_edge", bedrock_block)))
	assert (not bool(mine_world.call("_block_emits_mineable_corner", bedrock_block, all_open)))
	assert (
		not bool(mine_world.call("_block_emits_mineable_edge", copper_resource_block)),
		"Authored copper nodes must remain visible instead of receiving a pale cave rim"
	)
	assert (
		not bool(
			mine_world.call(
				"_block_emits_mineable_corner", copper_resource_block, all_open
			)
		),
		"Exposed resource nodes must not be buried under ordinary cave corner art"
	)
	assert (
		bool(
			mine_world.call(
				"_resource_node_uses_transparent_surround", copper_resource_block, all_open
			)
		),
		"Exposed resource sprites must show the continuous cave floor through their alpha"
	)
	assert (
		not bool(
			mine_world.call(
				"_resource_node_uses_transparent_surround", copper_resource_block, none_open
			)
		),
		"Fully buried resources must retain their concealing terrain undercoat"
	)
	assert (
		not bool(
			mine_world.call(
				"_resource_node_uses_transparent_surround", terrain_block, all_open
			)
		),
		"Ordinary terrain must retain its authored opaque undercoat"
	)
	assert (
		not bool(mine_world.call("_target_uses_filled_highlight", copper_resource_block)),
		"Selected resource sprites must not receive a square highlight fill"
	)
	assert (
		bool(mine_world.call("_target_uses_filled_highlight", terrain_block)),
		"Selected ordinary terrain must retain its filled target feedback"
	)
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


func _install_mining_companion() -> void:
	var script: Script=load("res://scripts/companion/mole_companion.gd")
	for world in [surface_world,mine_world,depth_world,hub_world,deepheart_world,endless_world]:
		var companion: Node2D=script.new()
		companion.name="MoleCompanion"
		world.add_child(companion)
	var interface: CanvasLayer=load("res://scripts/companion/companion_interface.gd").new()
	interface.name="CompanionInterface"
	add_child(interface)
