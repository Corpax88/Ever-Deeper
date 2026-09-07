extends ScrollContainer
## Continuous, interruptible dragging with a critically damped snap at release.
signal settled(index: int)
var targets: Array[float] = []
var position_x: float = 0.0
var speed: float = 0.0
var target_x: float = 0.0
var target_index: int = 0
var held: bool = false
var moving: bool = false
var start_index: int = 0
var motion_samples: int = 0

func configure(points: Array[float], index: int) -> void:
	targets = points
	if not held and not moving: jump_to(index)

func jump_to(index: int) -> void:
	if targets.is_empty(): return
	target_index = clampi(index, 0, targets.size() - 1)
	target_x = targets[target_index]
	position_x = target_x
	speed = 0.0
	held = false
	moving = false
	_apply_position()

func press() -> void:
	held = true
	moving = false
	speed = 0.0
	start_index = nearest_index(position_x) if not targets.is_empty() else 0

func drag_by(distance: float) -> void:
	if targets.is_empty(): return
	position_x = clampf(position_x - distance, targets[0], targets[-1])
	_apply_position()

func release(velocity_x: float, canceled: bool) -> void:
	held = false
	if targets.is_empty(): return
	if canceled:
		scroll_to_index(start_index)
		return
	speed = clampf(-velocity_x, -2600.0, 2600.0)
	var projected: float = clampf(position_x + speed * 0.16, targets[0], targets[-1])
	target_index = nearest_index(projected)
	target_x = targets[target_index]
	moving = true

func nearest_index(value: float) -> int:
	var best: int = 0
	for index in range(targets.size()):
		if absf(targets[index] - value) < absf(targets[best] - value): best = index
	return best

func scroll_to_index(index: int) -> void:
	if targets.is_empty(): return
	target_index = clampi(index, 0, targets.size() - 1)
	target_x = targets[target_index]
	held = false
	moving = true
	speed = 0.0

func _apply_position() -> void:
	get_h_scroll_bar().value = position_x

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		moving = false
		held = false
		speed = 0.0
		return
	if held or not moving: return
	# Exact spring solution avoids frame-rate dependent lerping or an end jump.
	var dt: float = minf(delta, 0.05)
	var omega: float = 18.0
	var displacement: float = position_x - target_x
	var coefficient: float = speed + omega * displacement
	var decay: float = exp(-omega * dt)
	position_x = target_x + (displacement + coefficient * dt) * decay
	speed = (speed - omega * coefficient * dt) * decay
	position_x = clampf(position_x, targets[0], targets[-1])
	_apply_position()
	motion_samples += 1
	if absf(position_x - target_x) < 0.3 and absf(speed) < 3.0:
		position_x = target_x
		speed = 0.0
		moving = false
		_apply_position()
		settled.emit(target_index)

func _gui_input(event: InputEvent) -> void:
	# Wheel navigation uses the same animated path; touch/mouse drag is coordinated
	# by SwipePager, before child buttons receive a drag release.
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
			scroll_to_index(target_index + 1)
			accept_event()
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
			scroll_to_index(target_index - 1)
			accept_event()
