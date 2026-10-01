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

static func offset(slot: int) -> Vector2:
	@warning_ignore("integer_division")
	var layer: int = slot / (COLUMNS * ROWS)
	var local: int = slot % (COLUMNS * ROWS)
	@warning_ignore("integer_division")
	var row: int = local / COLUMNS
	var column: int = local % COLUMNS
	return Vector2((column - row) * 19.0 - 9.5, (column + row) * 9.0 - 73.5 - layer * 13.0)

static func extent(kind: String, slot: int, amount: int) -> Vector2:
	var lower: int = 0 if slot == 0 else boundary(slot - 1)
	var fraction: float = clampf(float(clampi(amount, 0, GOAL) - lower) / float(boundary(slot) - lower), 0.0, 1.0)
	# A small partial delivery visibly starts its slot; subsequent deliveries complete it.
	return (Vector2(39, 28) if kind == "wallet_gold" else Vector2(35, 31)) * lerpf(0.55, 1.0, fraction)
