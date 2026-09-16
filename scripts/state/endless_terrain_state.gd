class_name EndlessTerrainState
extends RefCounted
## Compact save journal: 880 permanent excavation bits and two claim masks/band.
## Only changed bands are stored; generated geometry is never serialized.

const CELL_COUNT: int = 880
const HEX_COUNT: int = CELL_COUNT / 4
const HEX: String = "0123456789abcdef"


static func empty_chunk() -> Dictionary:
	return {"dug": "", "nodes": 0, "sites": 0, "seen": 0}


static func cells(mask: String) -> Array:
	var result: Array = []
	for digit_index in mini(mask.length(), HEX_COUNT):
		var value: int = HEX.find(mask[digit_index])
		if value < 0:
			continue
		for bit in 4:
			if value & (1 << bit):
				result.append(digit_index * 4 + bit)
	return result


static func contains(mask: String, cell: int) -> bool:
	if cell < 0 or cell >= CELL_COUNT or cell / 4 >= mask.length():
		return false
	var value: int = HEX.find(mask[cell / 4])
	return value >= 0 and (value & (1 << (cell % 4))) != 0


static func mark(mask: String, cell: int) -> String:
	if cell < 0 or cell >= CELL_COUNT:
		return mask
	var padded: String = mask.rpad(HEX_COUNT, "0")
	var digit: int = cell / 4
	var value: int = maxi(0, HEX.find(padded[digit])) | (1 << (cell % 4))
	return padded.substr(0, digit) + HEX[value] + padded.substr(digit + 1)


static func sanitize(raw: Variant, max_depth: int) -> Dictionary:
	var result: Dictionary = {}
	if not raw is Dictionary:
		return result
	for key in raw:
		if not key is String:
			continue
		var id: String = key
		if not id.is_valid_int() or int(id) < 1 or int(id) > max_depth or not raw[key] is Dictionary:
			continue
		var source: Dictionary = raw[key]
		var raw_mask: Variant = source.get("dug", "")
		var mask: String = raw_mask.to_lower().substr(0, HEX_COUNT) if raw_mask is String else ""
		var valid: bool = true
		for digit in mask:
			if HEX.find(digit) < 0:
				valid = false
				break
		result[str(int(id))] = {
			"dug": mask if valid else "",
			"nodes": _bounded_mask(source.get("nodes", 0), 2147483647),
			"sites": _bounded_mask(source.get("sites", 0), 255),
			"seen": _bounded_mask(source.get("seen", 0), 15),
		}
	return result


static func _bounded_mask(raw: Variant, maximum: int) -> int:
	if (raw is int or raw is float) and is_finite(float(raw)):
		return int(clampf(float(raw), 0.0, float(maximum)))
	return 0
