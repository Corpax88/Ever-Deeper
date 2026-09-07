class_name BeltNetwork
extends RefCounted







const STATE_VERSION: = 1
const DEFAULT_COLS: = 22
const DEFAULT_ROWS: = 10
const DEFAULT_SEGMENT_CAPACITY: = 4
const DEFAULT_ENDPOINT_CAPACITY: = 64
const MAX_SEGMENTS: = DEFAULT_COLS * DEFAULT_ROWS
const MAX_ENDPOINTS: = 32
const MAX_PACKETS: = 512
const MAX_PACKET_AMOUNT: = 1000000
const DIRECTIONS: = {
	"up": Vector2i.UP,
	"right": Vector2i.RIGHT,
	"down": Vector2i.DOWN,
	"left": Vector2i.LEFT,
}

var cols: = DEFAULT_COLS
var rows: = DEFAULT_ROWS


func _init(grid_cols: int = DEFAULT_COLS, grid_rows: int = DEFAULT_ROWS) -> void :
	cols = maxi(1, grid_cols)
	rows = maxi(1, grid_rows)


func default_state() -> Dictionary:
	return {
		"version": STATE_VERSION,
		"tick": 0,
		"next_packet_id": 1,
		"segments": [],
		"endpoints": [],
		"packets": [],
		"delivered": {},
	}


func sanitize_state(raw: Variant) -> Dictionary:
	var source: Dictionary = raw if raw is Dictionary else {}
	var clean: = default_state()
	clean["tick"] = _nonnegative_int(source.get("tick", 0), 0)

	var occupied_segments: = {}
	var raw_segments: Variant = source.get("segments", [])
	if raw_segments is Array:
		for value in Array(raw_segments):
			if not value is Dictionary or Array(clean.segments).size() >= MAX_SEGMENTS:
				continue
			var segment: = _sanitize_segment(Dictionary(value))
			if segment.is_empty():
				continue
			var key: = _cell_key(int(segment.col), int(segment.row))
			if occupied_segments.has(key):
				continue
			occupied_segments[key] = true
			clean.segments.append(segment)

	var sink_capacities: = {}
	var occupied_endpoints: = {}
	var raw_endpoints: Variant = source.get("endpoints", [])
	if raw_endpoints is Array:
		for value in Array(raw_endpoints):
			if not value is Dictionary or Array(clean.endpoints).size() >= MAX_ENDPOINTS:
				continue
			var endpoint: = _sanitize_endpoint(Dictionary(value))
			if endpoint.is_empty():
				continue
			var endpoint_id: = String(endpoint.id)
			var cell_key: = _cell_key(int(endpoint.col), int(endpoint.row))
			if (
				_endpoint_id_exists(clean, endpoint_id)
				or occupied_endpoints.has(cell_key)
				or occupied_segments.has(cell_key)
			):
				continue
			if String(endpoint.kind) == "sink":
				sink_capacities[endpoint_id] = int(endpoint.capacity)
			occupied_endpoints[cell_key] = true
			clean.endpoints.append(endpoint)

	var seen_packet_ids: = {}
	var maximum_packet_id: = 0
	var raw_packets: Variant = source.get("packets", [])
	if raw_packets is Array:
		for value in Array(raw_packets):
			if not value is Dictionary or Array(clean.packets).size() >= MAX_PACKETS:
				continue
			var packet: = _sanitize_packet(Dictionary(value))
			if packet.is_empty() or not _packet_cell_is_valid(packet, clean):
				continue
			var packet_id: = int(packet.id)
			if seen_packet_ids.has(packet_id):
				continue
			seen_packet_ids[packet_id] = true
			maximum_packet_id = maxi(maximum_packet_id, packet_id)
			clean.packets.append(packet)

	var requested_next: = _nonnegative_int(source.get("next_packet_id", 1), 1)
	clean["next_packet_id"] = maxi(1, maxi(requested_next, maximum_packet_id + 1))
	clean["delivered"] = _sanitize_delivered(
		source.get("delivered", {}), sink_capacities
	)
	_sort_state(clean)
	return clean


func set_segment(
	state: Dictionary,
	col: int,
	row: int,
	direction: String,
	capacity: int = DEFAULT_SEGMENT_CAPACITY
) -> Dictionary:
	var clean: = sanitize_state(state)
	if not _cell_in_bounds(col, row) or not DIRECTIONS.has(direction):
		return {"ok": false, "reason": "invalid_segment", "state": clean}
	if _endpoint_at_cell(clean, col, row).size() > 0:
		return {"ok": false, "reason": "endpoint_cell_occupied", "state": clean}
	var segment: = {
		"col": col,
		"row": row,
		"direction": direction,
		"capacity": clampi(capacity, 1, MAX_PACKET_AMOUNT),
	}
	var replaced: = false
	for index in Array(clean.segments).size():
		var existing: Dictionary = Dictionary(clean.segments[index])
		if int(existing.col) == col and int(existing.row) == row:
			clean.segments[index] = segment
			replaced = true
			break
	if not replaced:
		if Array(clean.segments).size() >= MAX_SEGMENTS:
			return {"ok": false, "reason": "segment_limit", "state": clean}
		clean.segments.append(segment)
	_sort_state(clean)
	_replace_state(state, clean)
	return {"ok": true, "reason": "replaced" if replaced else "placed", "state": clean}


func remove_segment(state: Dictionary, col: int, row: int) -> Dictionary:
	var clean: = sanitize_state(state)
	for packet_value in Array(clean.packets):
		var packet: Dictionary = Dictionary(packet_value)
		if int(packet.col) == col and int(packet.row) == row:
			return {"ok": false, "reason": "segment_occupied", "state": clean}
	for index in Array(clean.segments).size():
		var segment: Dictionary = Dictionary(clean.segments[index])
		if int(segment.col) == col and int(segment.row) == row:
			clean.segments.remove_at(index)
			_replace_state(state, clean)
			return {"ok": true, "reason": "removed", "state": clean}
	return {"ok": false, "reason": "segment_missing", "state": clean}


func set_endpoint(
	state: Dictionary,
	endpoint_id: String,
	kind: String,
	col: int,
	row: int,
	direction: String = "right",
	accepts: Array = [],
	capacity: int = DEFAULT_ENDPOINT_CAPACITY
) -> Dictionary:
	var clean: = sanitize_state(state)
	var endpoint: = _sanitize_endpoint({
		"id": endpoint_id,
		"kind": kind,
		"col": col,
		"row": row,
		"direction": direction,
		"accepts": accepts,
		"capacity": capacity,
	})
	if endpoint.is_empty():
		return {"ok": false, "reason": "invalid_endpoint", "state": clean}
	var normalized_endpoint_id: = String(endpoint.id)
	if _segment_at_cell(clean, col, row).size() > 0:
		return {"ok": false, "reason": "segment_cell_occupied", "state": clean}
	var previous: = _endpoint_by_id(clean, normalized_endpoint_id)
	if (
		not previous.is_empty()
		and String(previous.kind) == "sink"
		and kind != "sink"
		and not Dictionary(Dictionary(clean.delivered).get(normalized_endpoint_id, {})).is_empty()
	):
		return {"ok": false, "reason": "endpoint_occupied", "state": clean}
	if not previous.is_empty() and (
		int(previous.col) != col
		or int(previous.row) != row
		or String(previous.kind) != kind
	):
		if _packet_amount_at(clean, int(previous.col), int(previous.row)) > 0:
			return {"ok": false, "reason": "endpoint_occupied", "state": clean}
	for existing_value in Array(clean.endpoints):
		var existing: Dictionary = Dictionary(existing_value)
		if (
			String(existing.id) != normalized_endpoint_id
			and int(existing.col) == col
			and int(existing.row) == row
		):
			return {"ok": false, "reason": "endpoint_cell_occupied", "state": clean}
	var replaced: = false
	for index in Array(clean.endpoints).size():
		if String(Dictionary(clean.endpoints[index]).id) == normalized_endpoint_id:
			clean.endpoints[index] = endpoint
			replaced = true
			break
	if not replaced:
		if Array(clean.endpoints).size() >= MAX_ENDPOINTS:
			return {"ok": false, "reason": "endpoint_limit", "state": clean}
		clean.endpoints.append(endpoint)
	_sort_state(clean)
	_replace_state(state, clean)
	return {"ok": true, "reason": "replaced" if replaced else "placed", "state": clean}


func remove_endpoint(state: Dictionary, endpoint_id: String) -> Dictionary:
	var clean: = sanitize_state(state)
	var normalized_endpoint_id: = _resource_id(endpoint_id)
	var endpoint: = _endpoint_by_id(clean, normalized_endpoint_id)
	if endpoint.is_empty():
		return {"ok": false, "reason": "endpoint_missing", "state": clean}
	if _packet_amount_at(clean, int(endpoint.col), int(endpoint.row)) > 0:
		return {"ok": false, "reason": "endpoint_occupied", "state": clean}
	if not Dictionary(Dictionary(clean.delivered).get(normalized_endpoint_id, {})).is_empty():
		return {"ok": false, "reason": "endpoint_occupied", "state": clean}
	for index in Array(clean.endpoints).size():
		if String(Dictionary(clean.endpoints[index]).id) == normalized_endpoint_id:
			clean.endpoints.remove_at(index)
			_replace_state(state, clean)
			return {"ok": true, "reason": "removed", "state": clean}
	return {"ok": false, "reason": "endpoint_missing", "state": clean}


func enqueue(state: Dictionary, source_id: String, resource_id: String, amount: int) -> Dictionary:
	var clean: = sanitize_state(state)
	var source: = _endpoint_by_id(clean, _resource_id(source_id))
	if source.is_empty() or String(source.kind) != "source":
		return {"ok": false, "reason": "source_missing", "accepted": 0, "state": clean}
	var normalized_resource: = _resource_id(resource_id)
	if normalized_resource.is_empty() or amount <= 0:
		return {"ok": false, "reason": "invalid_resource", "accepted": 0, "state": clean}
	var occupied: = _packet_amount_at(clean, int(source.col), int(source.row))
	var available: = maxi(0, int(source.capacity) - occupied)
	var accepted: = mini(clampi(amount, 0, MAX_PACKET_AMOUNT), available)
	if accepted <= 0 or Array(clean.packets).size() >= MAX_PACKETS:
		return {"ok": false, "reason": "source_full", "accepted": 0, "state": clean}
	var packet: = {
		"id": int(clean.next_packet_id),
		"resource": normalized_resource,
		"amount": accepted,
		"col": int(source.col),
		"row": int(source.row),
	}
	clean["next_packet_id"] = int(clean.next_packet_id) + 1
	clean.packets.append(packet)
	_sort_state(clean)
	_replace_state(state, clean)
	return {
		"ok": true,
		"reason": "queued" if accepted == amount else "partially_queued",
		"accepted": accepted,
		"rejected": maxi(0, amount - accepted),
		"packet_id": int(packet.id),
		"state": clean,
	}


func tick(state: Dictionary, steps: int = 1) -> Dictionary:
	var clean: = sanitize_state(state)
	var moved: = 0
	var delivered_amount: = 0
	var bounded_steps: = clampi(steps, 0, 10000)
	for _step in bounded_steps:
		var result: = _tick_once(clean)
		moved += int(result.moved)
		delivered_amount += int(result.delivered)
	clean["tick"] = int(clean.tick) + bounded_steps
	_sort_state(clean)
	_replace_state(state, clean)
	return {
		"ok": true,
		"steps": bounded_steps,
		"moved": moved,
		"delivered": delivered_amount,
		"state": clean,
	}


func delivered_snapshot(state: Dictionary, sink_id: String = "") -> Dictionary:
	var clean: = sanitize_state(state)
	if sink_id.is_empty():
		return Dictionary(clean.delivered).duplicate(true)
	return Dictionary(
		Dictionary(clean.delivered).get(_resource_id(sink_id), {})
	).duplicate(true)


func take_delivered(
	state: Dictionary,
	sink_id: String,
	resource_id: String,
	amount: int
) -> int:
	if amount <= 0:
		return 0
	var clean: = sanitize_state(state)
	var normalized_sink_id: = _resource_id(sink_id)
	var delivered: Dictionary = Dictionary(clean.delivered)
	var sink: Dictionary = Dictionary(delivered.get(normalized_sink_id, {}))
	var available: = int(sink.get(resource_id, 0))
	var taken: = mini(available, amount)
	if taken <= 0:
		return 0
	sink[resource_id] = available - taken
	if int(sink[resource_id]) <= 0:
		sink.erase(resource_id)
	if sink.is_empty():
		delivered.erase(normalized_sink_id)
	else:
		delivered[normalized_sink_id] = sink
	clean["delivered"] = delivered
	_replace_state(state, clean)
	return taken


func conservation_snapshot(state: Dictionary) -> Dictionary:
	var clean: = sanitize_state(state)
	var packets: = {}
	for value in Array(clean.packets):
		var packet: Dictionary = Dictionary(value)
		var resource_id: = String(packet.resource)
		packets[resource_id] = int(packets.get(resource_id, 0)) + int(packet.amount)
	var delivered: = {}
	for sink_value in Dictionary(clean.delivered).values():
		for resource_value in Dictionary(sink_value):
			var resource_id: = String(resource_value)
			delivered[resource_id] = int(delivered.get(resource_id, 0)) + int(Dictionary(sink_value)[resource_id])
	var total: = packets.duplicate(true)
	for resource_id in delivered:
		total[resource_id] = int(total.get(resource_id, 0)) + int(delivered[resource_id])
	return {"packets": packets, "delivered": delivered, "total": total}


func _tick_once(state: Dictionary) -> Dictionary:
	var segment_by_cell: = {}
	for value in Array(state.segments):
		var segment: Dictionary = Dictionary(value)
		segment_by_cell[_cell_key(int(segment.col), int(segment.row))] = segment
	var endpoint_by_cell: = {}
	for value in Array(state.endpoints):
		var endpoint: Dictionary = Dictionary(value)
		endpoint_by_cell[_cell_key(int(endpoint.col), int(endpoint.row))] = endpoint
	var available_by_cell: = {}
	for key_value in segment_by_cell:
		var key: = String(key_value)
		var segment: Dictionary = Dictionary(segment_by_cell[key])
		var parts: = key.split(":")
		var occupied: = _packet_amount_at(state, int(parts[0]), int(parts[1]))
		available_by_cell[key] = maxi(0, int(segment.capacity) - occupied)

	var next_packets: Array = []
	var delivered: Dictionary = Dictionary(state.delivered).duplicate(true)
	var moved: = 0
	var delivered_amount: = 0
	var packet_values: Array = Array(state.packets)
	for packet_index in packet_values.size():
		var value: Variant = packet_values[packet_index]
		var packet: Dictionary = Dictionary(value).duplicate(true)
		var origin_key: = _cell_key(int(packet.col), int(packet.row))
		var direction: = ""
		if segment_by_cell.has(origin_key):
			direction = String(Dictionary(segment_by_cell[origin_key]).direction)
		elif endpoint_by_cell.has(origin_key):
			var origin_endpoint: Dictionary = Dictionary(endpoint_by_cell[origin_key])
			if String(origin_endpoint.kind) == "source":
				direction = String(origin_endpoint.direction)
		if not DIRECTIONS.has(direction):
			next_packets.append(packet)
			continue
		var destination: = Vector2i(int(packet.col), int(packet.row)) + Vector2i(DIRECTIONS[direction])
		if not _cell_in_bounds(destination.x, destination.y):
			next_packets.append(packet)
			continue
		var destination_key: = _cell_key(destination.x, destination.y)
		if endpoint_by_cell.has(destination_key):
			var endpoint: Dictionary = Dictionary(endpoint_by_cell[destination_key])
			if String(endpoint.kind) == "sink" and _endpoint_accepts(endpoint, String(packet.resource)):
				var sink_store: Dictionary = Dictionary(delivered.get(String(endpoint.id), {}))
				var stored_total: = 0
				for stored_amount in sink_store.values():
					stored_total += int(stored_amount)
				var sink_available: = maxi(0, int(endpoint.capacity) - stored_total)
				var accepted: = mini(int(packet.amount), sink_available)
				if accepted > 0:
					sink_store[String(packet.resource)] = int(sink_store.get(String(packet.resource), 0)) + accepted
					delivered[String(endpoint.id)] = sink_store
					delivered_amount += accepted
					moved += accepted
					packet.amount = int(packet.amount) - accepted
				if int(packet.amount) > 0:
					next_packets.append(packet)
				continue
		if not segment_by_cell.has(destination_key):
			next_packets.append(packet)
			continue
		var available: = int(available_by_cell.get(destination_key, 0))
		var accepted: = mini(int(packet.amount), available)
		if accepted <= 0:
			next_packets.append(packet)
			continue



		var remaining_unprocessed: = packet_values.size() - packet_index - 1
		var projected_packet_count: = next_packets.size() + 2 + remaining_unprocessed
		if accepted < int(packet.amount) and projected_packet_count > MAX_PACKETS:
			next_packets.append(packet)
			continue
		available_by_cell[destination_key] = available - accepted
		var moved_packet: = packet.duplicate(true)
		moved_packet.col = destination.x
		moved_packet.row = destination.y
		moved_packet.amount = accepted
		if accepted < int(packet.amount):
			moved_packet.id = int(state.next_packet_id)
			state["next_packet_id"] = int(state.next_packet_id) + 1
			packet.amount = int(packet.amount) - accepted
			next_packets.append(packet)
		next_packets.append(moved_packet)
		moved += accepted
	state["packets"] = next_packets
	state["delivered"] = delivered
	return {"moved": moved, "delivered": delivered_amount}


func _sanitize_segment(source: Dictionary) -> Dictionary:
	var col: = _integer(source.get("col", -1), -1)
	var row: = _integer(source.get("row", -1), -1)
	var direction: = String(source.get("direction", ""))
	if not _cell_in_bounds(col, row) or not DIRECTIONS.has(direction):
		return {}
	return {
		"col": col,
		"row": row,
		"direction": direction,
		"capacity": clampi(_integer(source.get("capacity", DEFAULT_SEGMENT_CAPACITY), DEFAULT_SEGMENT_CAPACITY), 1, MAX_PACKET_AMOUNT),
	}


func _sanitize_endpoint(source: Dictionary) -> Dictionary:
	var endpoint_id: = _resource_id(String(source.get("id", "")))
	var kind: = String(source.get("kind", ""))
	var col: = _integer(source.get("col", -1), -1)
	var row: = _integer(source.get("row", -1), -1)
	var direction: = String(source.get("direction", "right"))
	if (
		endpoint_id.is_empty()
		or kind not in ["source", "sink"]
		or not _cell_in_bounds(col, row)
		or not DIRECTIONS.has(direction)
	):
		return {}
	var accepts: Array[String] = []
	var seen: = {}
	var raw_accepts: Variant = source.get("accepts", [])
	if raw_accepts is Array:
		for value in Array(raw_accepts):
			var resource_id: = _resource_id(String(value))
			if resource_id.is_empty() or seen.has(resource_id):
				continue
			seen[resource_id] = true
			accepts.append(resource_id)
	accepts.sort()
	return {
		"id": endpoint_id,
		"kind": kind,
		"col": col,
		"row": row,
		"direction": direction,
		"accepts": accepts,
		"capacity": clampi(_integer(source.get("capacity", DEFAULT_ENDPOINT_CAPACITY), DEFAULT_ENDPOINT_CAPACITY), 1, MAX_PACKET_AMOUNT),
	}


func _sanitize_packet(source: Dictionary) -> Dictionary:
	var packet_id: = _integer(source.get("id", 0), 0)
	var resource_id: = _resource_id(String(source.get("resource", "")))
	var amount: = clampi(_integer(source.get("amount", 0), 0), 0, MAX_PACKET_AMOUNT)
	var col: = _integer(source.get("col", -1), -1)
	var row: = _integer(source.get("row", -1), -1)
	if packet_id <= 0 or resource_id.is_empty() or amount <= 0 or not _cell_in_bounds(col, row):
		return {}
	return {"id": packet_id, "resource": resource_id, "amount": amount, "col": col, "row": row}


func _sanitize_delivered(raw: Variant, sink_capacities: Dictionary) -> Dictionary:
	var result: = {}
	if not raw is Dictionary:
		return result
	for sink_id_value in Dictionary(raw):
		var sink_id: = String(sink_id_value)
		if not sink_capacities.has(sink_id) or not Dictionary(raw)[sink_id_value] is Dictionary:
			continue
		var clean_sink: = {}
		var remaining: = int(sink_capacities[sink_id])
		var resource_ids: Array = Dictionary(Dictionary(raw)[sink_id_value]).keys()
		resource_ids.sort()
		for resource_value in resource_ids:
			var resource_id: = _resource_id(String(resource_value))
			var amount: = mini(
				remaining,
				clampi(
					_integer(Dictionary(Dictionary(raw)[sink_id_value]).get(resource_value, 0), 0),
					0,
					MAX_PACKET_AMOUNT
				)
			)
			if not resource_id.is_empty() and amount > 0:
				clean_sink[resource_id] = amount
				remaining -= amount
			if remaining <= 0:
				break
		if not clean_sink.is_empty():
			result[sink_id] = clean_sink
	return result


func _packet_cell_is_valid(packet: Dictionary, state: Dictionary) -> bool:
	var key: = _cell_key(int(packet.col), int(packet.row))
	for value in Array(state.segments):
		var segment: Dictionary = Dictionary(value)
		if _cell_key(int(segment.col), int(segment.row)) == key:
			return true
	for value in Array(state.endpoints):
		var endpoint: Dictionary = Dictionary(value)
		if _cell_key(int(endpoint.col), int(endpoint.row)) == key and String(endpoint.kind) == "source":
			return true
	return false


func _endpoint_accepts(endpoint: Dictionary, resource_id: String) -> bool:
	var accepts: Array = Array(endpoint.get("accepts", []))
	return accepts.is_empty() or resource_id in accepts


func _endpoint_by_id(state: Dictionary, endpoint_id: String) -> Dictionary:
	for value in Array(state.endpoints):
		var endpoint: Dictionary = Dictionary(value)
		if String(endpoint.id) == endpoint_id:
			return endpoint
	return {}


func _endpoint_id_exists(state: Dictionary, endpoint_id: String) -> bool:
	return not _endpoint_by_id(state, endpoint_id).is_empty()


func _endpoint_at_cell(state: Dictionary, col: int, row: int) -> Dictionary:
	for value in Array(state.endpoints):
		var endpoint: Dictionary = Dictionary(value)
		if int(endpoint.col) == col and int(endpoint.row) == row:
			return endpoint
	return {}


func _segment_at_cell(state: Dictionary, col: int, row: int) -> Dictionary:
	for value in Array(state.segments):
		var segment: Dictionary = Dictionary(value)
		if int(segment.col) == col and int(segment.row) == row:
			return segment
	return {}


func _packet_amount_at(state: Dictionary, col: int, row: int) -> int:
	var result: = 0
	for value in Array(state.packets):
		var packet: Dictionary = Dictionary(value)
		if int(packet.col) == col and int(packet.row) == row:
			result += int(packet.amount)
	return result


func _sort_state(state: Dictionary) -> void :
	var segments: Array = Array(state.segments)
	segments.sort_custom( func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.row) < int(right.row) or (int(left.row) == int(right.row) and int(left.col) < int(right.col))
	)
	state["segments"] = segments
	var endpoints: Array = Array(state.endpoints)
	endpoints.sort_custom( func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.id) < String(right.id)
	)
	state["endpoints"] = endpoints
	var packets: Array = Array(state.packets)
	packets.sort_custom( func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.id) < int(right.id)
	)
	state["packets"] = packets


func _replace_state(target: Dictionary, source: Dictionary) -> void :
	target.clear()
	for key in source:
		target[key] = source[key]


func _cell_in_bounds(col: int, row: int) -> bool:
	return col >= 0 and row >= 0 and col < cols and row < rows


func _cell_key(col: int, row: int) -> String:
	return "%d:%d" % [col, row]


func _resource_id(value: String) -> String:
	var normalized: = value.strip_edges().to_lower()
	if normalized.is_empty() or normalized.length() > 64:
		return ""
	for character in normalized:
		var text: = String(character)
		if not (text >= "a" and text <= "z") and not (text >= "0" and text <= "9") and text != "_" and text != "-":
			return ""
	return normalized


func _integer(value: Variant, fallback: int) -> int:
	if value is int:
		return int(value)
	if value is float and is_finite(float(value)):
		return int(value)
	return fallback


func _nonnegative_int(value: Variant, fallback: int) -> int:
	return maxi(0, _integer(value, fallback))
