extends RefCounted
## Saved, finite deposits for a tracked post-victory mod. No world/global RNG use.
const REVISION: int = 1
const FIRST_NODE: int = 24
const SLOT_COUNT: int = 3
const COLS: int = 40
const ROWS: int = 22
const GOAL: int = 100000
const MOD_BY_KIND: Dictionary = {
	"rootiron":"twin_auger", "burrowsteel":"bore_rush", "prismite":"laser",
	"phasecrystal":"ricochet", "singularity":"vortex",
	"deep_alloy":"corebreaker", "echo_crystal":"chainbreaker",
}

static func reserved_node(index: int) -> bool:
	return index >= FIRST_NODE and index < FIRST_NODE + SLOT_COUNT

static func whole_number(raw: Variant, minimum: int, maximum: int) -> bool:
	return (raw is int or raw is float) and is_finite(float(raw)) and float(raw) == floorf(float(raw)) and float(raw) >= float(minimum) and float(raw) <= float(maximum)

static func clean(raw: Variant) -> Dictionary:
	if not raw is Dictionary or not raw.get("kind", null) is String or not MOD_BY_KIND.has(raw.kind): return {}
	if not whole_number(raw.get("revision", null), REVISION, REVISION): return {}
	var cells: Variant = raw.get("cells", null)
	if not cells is Array or cells.size() != SLOT_COUNT: return {}
	var used: Dictionary = {}
	var result_cells: Array = []
	for value in cells:
		if not whole_number(value, -1, COLS * ROWS - 1): return {}
		var cell: int = int(value)
		if cell >= 0:
			# Deposits never occupy permanent side walls or a band boundary.
			if cell % COLS < 2 or cell % COLS >= COLS - 2 or cell < COLS or cell >= COLS * (ROWS - 1) or used.has(cell): return {}
			used[cell] = true
		result_cells.append(cell)
	return {"kind":String(raw.kind), "revision":REVISION, "cells":result_cells}

static func _seed(world_seed: int, depth: int, slot: int, revision: int, salt: int) -> int:
	return ((world_seed * 73856093) ^ (depth * 19349663) ^ ((slot + 1) * 83492791) ^ (revision * 1597463007) ^ salt) & 2147483647

static func generate(world_seed: int, depth: int, kind: String, candidates_by_slot: Array) -> Dictionary:
	if not MOD_BY_KIND.has(kind) or depth < 1 or candidates_by_slot.size() != SLOT_COUNT: return {}
	var cells: Array = []
	var used: Dictionary = {}
	for slot in SLOT_COUNT:
		if not candidates_by_slot[slot] is Array: return {}
		var candidates: Array = []
		for value in candidates_by_slot[slot]:
			if not whole_number(value, COLS, COLS * (ROWS - 1) - 1): continue
			var cell: int = int(value)
			if cell % COLS < 2 or cell % COLS >= COLS - 2 or used.has(cell) or cell in candidates: continue
			candidates.append(cell)
		candidates.sort()
		var chosen: int = -1
		if not candidates.is_empty():
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = _seed(world_seed, depth, slot, REVISION, 0x5345414d)
			chosen = int(candidates[rng.randi_range(0, candidates.size() - 1)])
			used[chosen] = true
		cells.append(chosen)
	return {"kind":kind, "revision":REVISION, "cells":cells}

static func deposit(raw: Variant, world_seed: int, depth: int, node_index: int) -> Dictionary:
	var seam: Dictionary = clean(raw)
	if seam.is_empty() or not reserved_node(node_index) or depth < 1: return {}
	var slot: int = node_index - FIRST_NODE
	var cell: int = int(seam.cells[slot])
	if cell < 0: return {}
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = _seed(world_seed, depth, slot, int(seam.revision), 0x5949454c)
	return {"kind":String(seam.kind), "cell":cell, "amount":rng.randi_range(350, 450), "node_index":node_index}

static func valid_amount(base: int, amount: int, with_prospecting: bool = false) -> bool:
	# Existing extraction permits Crown x2 and an unstable-seam event x2.
	# Prospecting can add one unit, once, when the physical drop is created.
	for multiplier in [1, 2, 4]:
		var difference: int = amount - base * multiplier
		if difference == 0 or (with_prospecting and difference == 1): return true
	return false

static func valid_drop(raw: Variant, seam: Variant, world_seed: int, depth: int, node_index: int) -> bool:
	if not raw is Dictionary: return false
	var entitled: Dictionary = deposit(seam, world_seed, depth, node_index)
	if entitled.is_empty() or raw.get("kind", null) != entitled.kind: return false
	if not whole_number(raw.get("cell", null), int(entitled.cell), int(entitled.cell)): return false
	if not whole_number(raw.get("amount", null), 1, 1801): return false
	return valid_amount(int(entitled.amount), int(raw.amount), true)
