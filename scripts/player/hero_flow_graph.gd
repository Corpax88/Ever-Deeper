extends RefCounted
## Finite reversible routes. The original gameplay clock owns every impact.
const CONTACT := 0.42
const LAST_PRECONTACT := 0.40
const EDGE_STEPS := 18.0
var mode := "legacy"
var shown := 0.0
var edge := "idle"
var edge_position := 0.0
var walk_phase := 0.0
var walk_target := 0.0
var was_mining := false
var previous_progress := 0.0
var progress_rate := 1.0 / 0.68
var restart_source := -1.0
var restart_progress := 0.0
var selected: Dictionary = {}
var packet_mining := false
var start_pending := false
var exit_steps := 12.0
var exit_duration := 0.18
var exit_distance := 61.2
var exit_source := 0
var exit_position := 0.0
var exit_direction := 1.0

func configure(info: Dictionary) -> void:
	if not info.has("exit_profile"): return
	var profile: Dictionary = info.exit_profile
	exit_steps = float(profile.steps)
	exit_duration = float(profile.duration)
	exit_distance = float(profile.distance_pixels)

func note_state(active: bool) -> void:
	if active and not packet_mining:
		start_pending = true
	packet_mining = active

func reset() -> void:
	mode = "legacy"
	shown = 0.0
	was_mining = false
	restart_source = -1.0
	selected = {}
	packet_mining = false
	start_pending = false

func flow_progress(progress: float, hit: float) -> float:
	if progress <= hit:
		return progress / hit * CONTACT
	return CONTACT + (progress - hit) / (1.0 - hit) * (1.0 - CONTACT)

func _distance_to_walk_node() -> float:
	return fposmod(walk_target - walk_phase + 0.5, 1.0) - 0.5

func _select_flow(impact: bool = false) -> Dictionary:
	var cell := 21 if impact else clampi(roundi(shown * 50.0), 0, 49)
	selected = {"bank":"flow", "cell":cell, "impact":impact, "mode":mode, "shown":shown}
	return selected

func _select_edge() -> Dictionary:
	selected = {"bank":"edges", "edge":edge, "cell":clampi(roundi(edge_position), 0, 18), "impact":false, "mode":mode}
	return selected

func step(delta: float, active: bool, walking: bool, progress: float, hit: float, impact: bool,
		_legacy_walk_phase: float, last_state: String, last_cell: int, motion_distance: float = 0.0) -> Dictionary:
	hit = clampf(hit, 0.01, 0.99)
	if delta <= 0.0:
		return selected
	if active and was_mining and progress > previous_progress:
		progress_rate = maxf(0.01, (progress - previous_progress) / delta)
	elif active and not was_mining and progress > 0.0:
		progress_rate = maxf(0.01, progress / delta)
	var started := active and (start_pending or not was_mining)
	start_pending = false
	if mode == "legacy":
		if walking:
			was_mining = active
			previous_progress = progress
			return {}
		if last_state == "walk":
			walk_phase = float(last_cell) / 48.0
			walk_target = roundf(walk_phase * 2.0) * 0.5
			edge = "walk0" if posmod(roundi(walk_target * 48.0), 48) == 0 else "walk24"
			mode = "settle"
		else:
			edge = "idle"
			edge_position = 0.0
			mode = "edge"
	if started and mode == "flow":
		restart_source = shown
		restart_progress = progress
	was_mining = active
	previous_progress = progress
	# A slow draw must still show the native contact that produced damage.
	if impact and not walking:
		mode = "flow"
		shown = CONTACT
		restart_source = -1.0
		return _select_flow(true)
	var remaining_time := maxf(delta, (hit - progress) / progress_rate)
	if mode == "flow" and walking:
		exit_source = clampi(int(selected.get("cell", roundi(shown * 50.0))), 0, 49)
		exit_position = 0.0
		exit_direction = 1.0
		mode = "exit"
	if mode == "exit":
		var next_direction := 1.0 if walking else -1.0
		if next_direction != exit_direction:
			# The displayed integer cell, not an invisible interpolated pose,
			# owns an interrupted edge's reversal.
			exit_position = float(selected.get("cell", roundi(exit_position)))
			exit_direction = next_direction
		var advance := motion_distance / maxf(1.0, exit_distance) * exit_steps
		if not walking:
			advance = delta * exit_steps / exit_duration
			if active and progress < hit:
				advance = maxf(advance, delta * exit_position / maxf(delta, remaining_time * 0.55))
		exit_position = clampf(exit_position + next_direction * advance, 0.0, exit_steps)
		selected = {"bank":"exits", "edge":"exit%02d" % exit_source, "cell":roundi(exit_position),
			"impact":false, "mode":"exit", "source_cell":exit_source}
		if exit_position >= exit_steps:
			mode = "legacy"
			selected["resume_walk_phase"] = 0.25
		elif exit_position <= 0.0:
			mode = "flow"
			shown = float(exit_source) / 50.0
			restart_source = shown if active else -1.0
			restart_progress = progress
		return selected
	if mode == "settle":
		if walking:
			reset()
			return {}
		var distance := _distance_to_walk_node()
		var rate := 3.0
		if active and progress < hit:
			rate = maxf(rate, absf(distance) / maxf(delta, remaining_time * 0.25))
		walk_phase += clampf(distance, -delta * rate, delta * rate)
		if absf(_distance_to_walk_node()) < 0.00001:
			mode = "edge"
			edge_position = 0.0
		selected = {"bank":"legacy_walk", "cell":posmod(roundi(walk_phase * 48.0), 48), "impact":false, "mode":"settle"}
		return selected
	if mode == "edge":
		var goal := 0.0 if walking else EDGE_STEPS
		var rate := EDGE_STEPS / 0.30
		if active and progress < hit and not walking:
			rate = maxf(rate, (EDGE_STEPS - edge_position) / maxf(delta, remaining_time * 0.55))
		edge_position = move_toward(edge_position, goal, delta * rate)
		var result := _select_edge()
		if edge_position >= EDGE_STEPS:
			mode = "flow"
			shown = 0.0
			restart_source = 0.0
			restart_progress = progress if active else 0.0
		elif edge_position <= 0.0 and walking:
			mode = "legacy"
			result["resume_walk_phase"] = 0.5 if edge == "walk24" else 0.0
		return result
	if active and not walking:
		var requested := flow_progress(progress, hit)
		if restart_source >= 0.0:
			var end := maxf(restart_progress + 0.001, hit * 0.88)
			var weight := smoothstep(restart_progress, end, progress)
			var destination := requested + (1.0 if restart_source >= CONTACT and progress < hit else 0.0)
			shown = fposmod(lerpf(restart_source, destination, weight), 1.0)
			if weight >= 1.0:
				restart_source = -1.0
		else:
			shown = requested
		if progress < hit and shown < CONTACT:
			shown = minf(shown, LAST_PRECONTACT)
	else:
		restart_source = -1.0
		var goal := 0.0 if shown < CONTACT else 1.0
		shown = move_toward(shown, goal, delta / 0.36)
		if is_equal_approx(shown, goal):
			shown = 0.0
	return _select_flow()

func snapshot() -> Dictionary:
	return {"mode":mode, "shown":shown, "edge":edge, "edge_position":edge_position,
		"walk_phase":walk_phase, "progress_rate":progress_rate, "selection":selected.duplicate(),
		"exit_source":exit_source, "exit_position":exit_position}
