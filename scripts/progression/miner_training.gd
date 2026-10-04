extends Node
## Samples only the active player's physics travel counter: no teleport XP,
## no background-world training. Menus allow rest, but never movement/mining XP.
var main: Node
var _player: Node
var _travel: float = 0.0

func _ready() -> void:
	process_physics_priority = 100

func _physics_process(delta: float) -> void:
	if not is_instance_valid(main): return
	var player: Node = main._active_player_node()
	var ready: bool = main.game_started and not main.orientation_guard_active \
		and not main.deepheart_presentation and not main.tunnel_home_in_progress \
		and not main.conclusion_overlay.visible
	if player != _player:
		_player = player
		_travel = float(player.animation_travelled_distance) if is_instance_valid(player) else 0.0
	if not is_instance_valid(player): return
	var travelled: float = float(player.animation_travelled_distance)
	var distance: float = maxf(0.0, travelled - _travel)
	_travel = travelled
	if not ready: return
	if main.menu_open or main.inventory_open or main._shop_panel_is_open() or main._companion_panel_is_open():
		RunState.advance_miner_training(delta, 0.0, false)
		return
	var mining: bool = bool(player.mining_visual_active)
	if main.phase == "endless" and is_instance_valid(main.endless_world.drill_modes):
		mining = mining or main.endless_world.drill_modes.is_mining_work_active()
	RunState.advance_miner_training(delta, distance, mining)
