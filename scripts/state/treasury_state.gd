class_name TreasuryState
extends RefCounted
## Optional additive save section. Currency is distinct from mined gold ore.
const WALLET: String = "wallet_gold"
const MAX_TOTAL: int = 9000000000000000000

static func keys() -> Array:
	var result: Array = RunState.RESOURCE_IDS.duplicate()
	result.append(WALLET)
	return result

static func clean(raw: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not raw is Dictionary: return result
	for key in keys():
		var value: Variant = raw.get(key, 0)
		if value is int and value > 0:
			result[key] = mini(value, MAX_TOTAL)
	return result

static func available(kind: String) -> int:
	return maxi(0, int(RunState.gold if kind == WALLET else RunState.cargo.get(kind, 0)))

static func stage(amount: int) -> int:
	if amount <= 0: return 0
	@warning_ignore("integer_division")
	return amount / 1000 + 1

static func land(kind: String, requested: int) -> int:
	if kind not in keys() or requested <= 0: return 0
	var stored: int = int(RunState.treasury_totals.get(kind, 0))
	var amount: int = mini(mini(requested, available(kind)), maxi(0, preload("res://scripts/world/treasury_stack.gd").GOAL - stored))
	if amount <= 0: return 0
	# Debit and credit occur in one synchronous operation before save notification.
	if kind == WALLET: RunState.gold -= amount
	else: RunState.cargo[kind] = available(kind) - amount
	RunState.treasury_totals[kind] = stored + amount
	RunState._state_changed()
	return amount
