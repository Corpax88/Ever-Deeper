extends RefCounted
## Activity-earned skills. Balance revision changes preserve old level and bar progress.
const IDS = ["mining", "running", "carrying", "prospecting"]
const MAX_LEVEL = 100
const MAX_XP = 47600.0
const BALANCE_REVISION = 2
const RECOVERY_DELAY = 0.4
const RECOVERY_PER_SECOND = 25.0
const BASE_XP = {"mining": 80.0, "running": 80.0, "carrying": 80.0, "prospecting": 10.0}

static func requirement(id: String, at_level: int) -> float:
	return float(BASE_XP.get(id, 80.0)) * (1.0 + 0.1 * clampi(at_level, 0, MAX_LEVEL))

static func threshold(id: String, at_level: int) -> float:
	var n: float = clampi(at_level, 0, MAX_LEVEL)
	return float(BASE_XP.get(id, 80.0)) * (n + 0.05 * n * (n - 1.0))

static func max_xp(id: String) -> float:
	return threshold(id, MAX_LEVEL)

static func defaults() -> Dictionary:
	return {"mining": 0.0, "running": 0.0, "carrying": 0.0, "prospecting": 0.0, "stamina": 100.0}

static func clean(raw: Variant) -> Dictionary:
	var result: Dictionary = defaults()
	if not raw is Dictionary: return result
	for id in result:
		var value: Variant = raw.get(id, result[id])
		if (value is float or value is int) and is_finite(float(value)):
			result[id] = clampf(float(value), 0.0, 100.0 if id == "stamina" else max_xp(id))
	return result

static func restore(raw: Variant, revision: Variant) -> Dictionary:
	if revision is int and revision >= BALANCE_REVISION: return clean(raw)
	var migrated: Dictionary = defaults()
	if not raw is Dictionary: return migrated
	for id in IDS:
		var value: Variant = raw.get(id, 0.0)
		if not (value is float or value is int) or not is_finite(float(value)): continue
		var remaining: float = clampf(float(value), 0.0, 257500.0)
		var old_level: int = 0
		while old_level < MAX_LEVEL and remaining >= 100.0 + 50.0 * old_level:
			remaining -= 100.0 + 50.0 * old_level
			old_level += 1
		var progress: float = remaining / (100.0 + 50.0 * old_level)
		migrated[id] = threshold(id, old_level) + requirement(id, old_level) * progress if old_level < MAX_LEVEL else max_xp(id)
	migrated.stamina = clean(raw).stamina
	return clean(migrated)

static func row(id: String, total: float) -> Dictionary:
	var bounded: float = clampf(total, 0.0, max_xp(id)) if is_finite(total) else 0.0
	var at_level: int = 0
	while at_level < MAX_LEVEL and bounded >= threshold(id, at_level + 1):
		at_level += 1
	var remaining: float = bounded - threshold(id, at_level)
	var required: int = roundi(requirement(id, at_level))
	return {"id": id, "name": id.capitalize(), "level": at_level,
		"xp": floori(remaining) if at_level < MAX_LEVEL else required,
		"next": required, "maxed": at_level == MAX_LEVEL,
		"ratio": remaining / required if at_level < MAX_LEVEL else 1.0}

static func level(id: String, state: Dictionary) -> int:
	return int(row(id, float(state.get(id, 0.0))).level)

## One additional ore unit, after equipment multipliers. No recursive bonus rolls.
static func prospecting_chance(at_level: int) -> float:
	return float(clampi(at_level, 0, MAX_LEVEL)) * 0.005

static func prospecting_bonus(at_level: int, sample: float) -> int:
	return 1 if is_finite(sample) and sample >= 0.0 and sample < prospecting_chance(at_level) else 0
