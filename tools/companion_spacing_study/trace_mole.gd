extends "res://tools/companion_spacing_study/pilot_mole.gd"
## Optional bounded diagnostic wrapper; no motion or task changes.
var trace_calls := 0
var prior_trace := ""

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if world.name != "MossveinMine" or not visible or trace_calls >= 240:
		return
	trace_calls += 1
	var state := mode + "/" + action + "/" + str(_mining_held())
	if state != prior_trace or trace_calls % 20 == 0:
		print("MOLE_TRACE ", JSON.stringify({"tick": trace_calls, "state": state, "position": [global_position.x, global_position.y],
			"hero": [hero.global_position.x, hero.global_position.y], "destination": [destination.x, destination.y],
			"think_clock": think_clock, "action_clock": action_clock, "dug": dug_total, "shake_cooldown": shake_cooldown}))
		prior_trace = state
