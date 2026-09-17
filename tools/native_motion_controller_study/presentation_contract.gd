extends RefCounted
## Offline presentation-boundary study. Never owns or advances gameplay.
## Recorded draw acknowledgments must be verified against original captures by the caller.
const INTENTS := ["idle", "walk", "mine"]
const DIRECTIONS := ["down", "left", "right", "up"]
const EVENT_LIMIT := 4096
var _bank: Dictionary = {}
var _bank_sha := ""
var _presented: Dictionary = {}
var _presented_id := ""
var _request: Dictionary = {}
var _events: Array[Dictionary] = []
var _last_request := -1
var _last_event := -1


func configure(bytes: PackedByteArray, expected_sha: String) -> bool:
	if not _bank.is_empty() or bytes.get_string_from_utf8().sha256_text() != expected_sha:
		return false
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not parsed is Dictionary or not _integer(parsed.get("schema_version")) or int(parsed.schema_version) != 2:
		return false
	if not parsed.get("states") is Dictionary or not parsed.get("directions") is Dictionary:
		return false
	for name in parsed.states:
		if not parsed.states[name] is Dictionary: return false
		var state: Dictionary = parsed.states[name]
		if not state.get("phases") is Array or not _integer(state.get("count")) or int(state.count) <= 0 or int(state.count) != state.phases.size():
			return false
		if not _integer(state.get("offset")) or int(state.offset) < 0 or not _integer(state.get("page")) or int(state.page) < 0: return false
		for phase in state.phases:
			if not _number(phase) or float(phase) < 0.0 or float(phase) > 1.0: return false
	for view in parsed.directions:
		if not view in DIRECTIONS or not parsed.directions[view] is Dictionary: return false
		if not parsed.directions[view].get("transitions") is Dictionary: return false
	_bank = parsed.duplicate(true)
	_bank_sha = expected_sha
	return true


func accept_recorded_draw(sample: Dictionary, proof: Dictionary) -> String:
	if _bank.is_empty() or proof.get("bank_sha256") != _bank_sha:
		return ""
	if proof.get("kind") != "verified_original_capture" or not _sha(String(proof.get("image_sha256", ""))):
		return ""
	if not bool(sample.get("actually_presented", false)):
		return ""
	for field in ["drawn_frame", "local_frame", "atlas_frame", "page"]:
		if not _integer(sample.get(field)): return ""
	if not _integer(proof.get("drawn_frame")) or not _number(sample.get("sample_phase")): return ""
	var draw: int = int(sample.get("drawn_frame", -1))
	if draw <= int(_presented.get("drawn_frame", -1)) or draw != int(proof.get("drawn_frame", -2)):
		return ""
	var direction := String(sample.get("direction", ""))
	var state := String(sample.get("state", ""))
	if not _bank.directions.has(direction) or not _bank.states.has(state):
		return ""
	var info: Dictionary = _bank.states[state]
	var index := int(sample.get("local_frame", -1))
	if index < 0 or index >= int(info.count): return ""
	# This is the displayed sample index, never a nearest source-phase lookup.
	if float(sample.get("sample_phase", -1.0)) != float(info.phases[index]): return ""
	if int(sample.get("atlas_frame", -1)) != int(info.offset) + index: return ""
	if int(sample.get("page", -1)) != int(info.page): return ""
	var offset: Variant = sample.get("retained_offset")
	if not offset is Array or offset.size() != 2: return ""
	if not _number(offset[0]) or not _number(offset[1]): return ""
	var is_bridge := not state in INTENTS
	if bool(sample.get("is_bridge", not is_bridge)) != is_bridge: return ""
	if is_bridge and not _bank.directions[direction].transitions.has(state): return ""
	_presented = sample.duplicate(true)
	# All recorded context, including bridge interior and retained offset, is bound.
	_presented_id = JSON.stringify({"bank": _bank_sha, "sample": _presented, "proof": proof}).sha256_text()
	return _presented_id


func submit_request(packet: Dictionary, physical_events: Array = []) -> bool:
	if _bank.is_empty() or not _integer(packet.get("request_id")) or int(packet.request_id) <= _last_request: return false
	if not String(packet.get("state", "")) in INTENTS or not String(packet.get("direction", "")) in DIRECTIONS:
		return false
	if _events.size() + physical_events.size() > EVENT_LIMIT: return false
	var event_cursor := _last_event
	for event in physical_events:
		if not event is Dictionary or not _integer(event.get("sequence")) or int(event.sequence) <= event_cursor: return false
		event_cursor = int(event.sequence)
	# Validate the complete batch before mutating any ledger state.
	for event in physical_events: _events.append(event.duplicate(true))
	_last_event = event_cursor
	_last_request = int(packet.request_id)
	_request = packet.duplicate(true)
	return true


func resolve(expected_presented_id: String) -> Dictionary:
	var result := {"covered": false, "scope": "state_heading_route_only", "source_id": _presented_id,
		"request": _request.duplicate(true), "physical_events": _events.duplicate(true),
		"world_clock_owned": false, "gameplay_mutated": false}
	if _presented_id.is_empty() or expected_presented_id != _presented_id:
		result.reason = "missing_or_changed_draw_source"
		return result
	if _request.is_empty():
		result.reason = "no_request"
		return result
	if _request.get("bank_sha256") != _bank_sha or _request.get("gear") != _bank.get("gear"):
		result.reason = "bank_or_equipment_change_uncovered"
		return result
	if String(_request.direction) != String(_presented.direction):
		result.reason = "turn_or_combined_change_uncovered"
		return result
	var source := String(_presented.state)
	var wanted := String(_request.state)
	if not source in INTENTS:
		# Even an unchanged goal still requires the future timing/lifecycle policy.
		result.reason = "bridge_interior_policy_uncovered"
		return result
	if source == wanted:
		result.covered = true
		result.reason = "same_state_heading_only_not_cycle_or_lifecycle_acceptance"
		return result
	var matches: Array = []
	var bank: Dictionary = _bank.directions[_presented.direction].transitions
	for name in bank:
		var edge: Dictionary = bank[name]
		if String(edge.source_state) == source and String(edge.target_state) == wanted and float(edge.source_phase) == float(_presented.sample_phase):
			matches.append(name)
	if matches.size() != 1:
		result.reason = "missing_exact_edge" if matches.is_empty() else "ambiguous_exact_edge"
		return result
	result.covered = true
	result.reason = "exact_declared_edge_timing_not_yet_validated"
	result.edge = matches[0]
	result.metadata = bank[matches[0]].duplicate(true)
	return result


func events_snapshot() -> Array[Dictionary]:
	return _events.duplicate(true)


func source_id() -> String:
	return _presented_id


func _number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))


func _integer(value: Variant) -> bool:
	return _number(value) and float(value) == floor(float(value))


func _sha(value: String) -> bool:
	if value.length() != 64: return false
	for character in value:
		if not character in "0123456789abcdef": return false
	return true
