extends RefCounted
## Persisted, activity-earned skills. Never owns world timing or animation poses.
const IDS = ["mining", "running", "carrying", "prospecting"]
const MAX_LEVEL = 100
const MAX_XP = 257500.0

static func defaults() -> Dictionary:
	return {"mining": 0.0, "running": 0.0, "carrying": 0.0, "prospecting": 0.0, "stamina": 100.0}

static func clean(raw: Variant) -> Dictionary:
	var result: Dictionary = defaults()
	if not raw is Dictionary: return result
	for id in result:
		var value: Variant = raw.get(id, result[id])
		if (value is float or value is int) and is_finite(float(value)):
			result[id] = clampf(float(value), 0.0, 100.0 if id == "stamina" else MAX_XP)
	return result

static func row(id: String, total: float) -> Dictionary:
	var remaining: float = clampf(total, 0.0, MAX_XP)
	var level: int = 0
	while level < MAX_LEVEL and remaining >= 100.0 + 50.0 * level:
		remaining -= 100.0 + 50.0 * level
		level += 1
	var required: int = 100 + 50 * level
	return {"id": id, "name": id.capitalize(), "level": level,
		"xp": floori(remaining) if level < MAX_LEVEL else required,
		"next": required, "maxed": level == MAX_LEVEL,
		"ratio": remaining / required if level < MAX_LEVEL else 1.0}

static func level(id: String, state: Dictionary) -> int:
	return int(row(id, float(state.get(id, 0.0))).level)
