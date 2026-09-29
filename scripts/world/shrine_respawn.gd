extends RefCounted
## Stored inside the existing saved progress dictionary; old one-use shrines revive.
const SECONDS: float = 120.0
static func remaining(id: String) -> float:
	var timers: Dictionary=Dictionary(RunState.overhaul_progress.get("shrine_respawn",{}))
	return clampf(float(timers.get(id,0.0))-Time.get_unix_time_from_system(),0.0,SECONDS)

static func claim(id: String) -> void:
	var timers: Dictionary=Dictionary(RunState.overhaul_progress.get("shrine_respawn",{}))
	timers[id]=Time.get_unix_time_from_system()+SECONDS
	RunState.overhaul_progress["shrine_respawn"]=timers
	RunState._state_changed()
