extends RefCounted
static var enabled: bool = false
static var stats: Dictionary = {}
static var events: Array = []
static func reset() -> void:
	stats.clear()
	events.clear()
static func record(label: String, usec: int) -> void:
	if not stats.has(label): stats[label] = {"calls":0,"usec":0,"max_usec":0}
	var row: Dictionary = stats[label]
	row.calls += 1
	row.usec += usec
	row.max_usec = maxi(row.max_usec, usec)
	if usec >= 5000 and events.size() < 2000:
		events.append({"label":label,"usec":usec,"frame":Engine.get_process_frames(),"at":Time.get_ticks_usec()})
