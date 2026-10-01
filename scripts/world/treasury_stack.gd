extends RefCounted
## Fixed slots: row by row, then layer by layer. Counts are presentation, never currency.
const GOAL: int = 100000
const COLUMNS: int = 6
const ROWS: int = 5
const LAYERS: int = 6
const COUNT: int = COLUMNS * ROWS * LAYERS

static func filled(amount: int) -> int:
	var bounded: int = clampi(amount, 0, GOAL)
	@warning_ignore("integer_division")
	return 0 if bounded == 0 else ((bounded - 1) * COUNT / GOAL) + 1

static func boundary(slot: int) -> int:
	@warning_ignore("integer_division")
	return (clampi(slot + 1, 1, COUNT) * GOAL + COUNT - 1) / COUNT

static func next_slot(amount: int) -> int:
	var bounded: int = clampi(amount, 0, GOAL - 1)
	@warning_ignore("integer_division")
	return mini(COUNT - 1, bounded * COUNT / GOAL)

# Surface measured from alcove-v1: broad middle, narrow rear/front, no rim overlap.
# The 180 value boundaries stay unchanged; only their stable visual positions change.
static func footprint(slot: int, kind: String = "") -> Vector2:
	@warning_ignore("integer_division")
	var layer: int = slot / 30
	var local: int = slot % 30
	var radius: float = 0.0
	var angle: float = 0.0
	if local > 0 and local < 8:
		radius = 0.30
		angle = TAU * float(local - 1) / 7.0
	elif local < 18 and local >= 8:
		radius = 0.59
		angle = TAU * float(local - 8) / 10.0 + 0.23
	elif local >= 18:
		radius = 0.84
		angle = TAU * float(local - 18) / 12.0 + 0.11
	var seed_value: float = float(posmod(kind.hash(), 997)) * 0.017
	angle += float(layer) * 0.39 + seed_value * 0.12
	var taper: float = 1.0 - float(layer) * 0.10
	var jitter: Vector2 = Vector2(sin(float(slot)*8.31+seed_value)*2.0,cos(float(slot)*5.17+seed_value)*0.8)
	return Vector2(cos(angle)*76.0,sin(angle)*23.0)*radius*taper+jitter

static func offset(slot: int, kind: String = "") -> Vector2:
	@warning_ignore("integer_division")
	var layer: int = slot / 30
	return footprint(slot,kind) + Vector2(0,-49.0-float(layer)*9.0)

static func turn(slot: int, kind: String) -> float:
	return sin(float(slot)*6.73+float(posmod(kind.hash(),991))) * (0.055 if kind == "wallet_gold" else 0.18)

static var _orders: Dictionary = {}

static func draw_order(count: int, kind: String) -> Array[int]:
	if not _orders.has(kind):
		var all_slots: Array[int] = []
		for i in COUNT: all_slots.append(i)
		all_slots.sort_custom(func(a: int,b: int):
			@warning_ignore("integer_division")
			var la: int = a / 30
			@warning_ignore("integer_division")
			var lb: int = b / 30
			return la < lb if la != lb else footprint(a,kind).y < footprint(b,kind).y)
		_orders[kind] = all_slots
	var visible_slots: Array[int] = []
	for slot in _orders[kind]:
		if slot < count: visible_slots.append(slot)
	return visible_slots

static func extent(kind: String, slot: int, amount: int) -> Vector2:
	var lower: int = 0 if slot == 0 else boundary(slot - 1)
	var fraction: float = clampf(float(clampi(amount, 0, GOAL) - lower) / float(boundary(slot) - lower), 0.0, 1.0)
	# A small partial delivery visibly starts its slot; subsequent deliveries complete it.
	return (Vector2(39, 28) if kind == "wallet_gold" else Vector2(35, 31)) * lerpf(0.55, 1.0, fraction)
