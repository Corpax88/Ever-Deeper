class_name TouchScrollContainer
extends ScrollContainer
## One-finger scrolling over labels, cards and buttons, including mobile Web.
## A drag cancels the pending button press; a stationary tap retains normal GUI input.
var web_cancel_callback: JavaScriptObject
var finger: int = -1
var origin: Vector2
var previous: Vector2
var dragging: bool = false
var velocity: Vector2 = Vector2.ZERO
var last_motion: int = 0
var suppress_mouse_until: int = 0

func _ready() -> void:
	scroll_deadzone = 6
	visibility_changed.connect(_cancel)
	if OS.has_feature("web"):
		web_cancel_callback = JavaScriptBridge.create_callback(func(_args: Array): _cancel())
		JavaScriptBridge.get_interface("window").addEventListener("touchcancel", web_cancel_callback, true)

func _exit_tree() -> void:
	if web_cancel_callback != null:
		JavaScriptBridge.get_interface("window").removeEventListener("touchcancel", web_cancel_callback, true)

func _local(point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * point

func _on_bar(point: Vector2) -> bool:
	for bar in [get_h_scroll_bar(), get_v_scroll_bar()]:
		if bar.is_visible_in_tree() and Rect2(Vector2.ZERO, bar.size).has_point(bar.get_global_transform_with_canvas().affine_inverse() * point): return true
	return false

func _notify_content(what: int) -> void:
	for child in get_children():
		if child != get_h_scroll_bar() and child != get_v_scroll_bar(): child.propagate_notification(what)

func _begin_drag() -> void:
	dragging = true
	_notify_content(Control.NOTIFICATION_SCROLL_BEGIN)
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused): focused.release_focus()
	scroll_started.emit()

func _cancel() -> void:
	if finger >= 0:
		if not dragging: _begin_drag()
		suppress_mouse_until = Time.get_ticks_msec() + 150
	_finish(false)

func _finish(coast: bool) -> void:
	if dragging:
		_notify_content(Control.NOTIFICATION_SCROLL_END)
		scroll_ended.emit()
	finger = -1
	dragging = false
	if not coast: velocity = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		if dragging or Time.get_ticks_msec() < suppress_mouse_until:
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if finger >= 0 or not Rect2(Vector2.ZERO, size).has_point(_local(event.position)) or _on_bar(event.position): return
			finger = event.index
			origin = _local(event.position)
			previous = origin
			velocity = Vector2.ZERO
			last_motion = Time.get_ticks_msec()
			suppress_mouse_until = 0
		elif event.index == finger:
			if event.canceled and not dragging: _begin_drag()
			if dragging:
				get_viewport().set_input_as_handled()
				suppress_mouse_until = Time.get_ticks_msec() + 150
			_finish(not event.canceled and Time.get_ticks_msec() - last_motion < 120)
	elif event is InputEventScreenDrag and event.index == finger:
		var point: Vector2 = _local(event.position)
		var distance: Vector2 = point - origin
		if not dragging and distance.length() < 6.0: return
		if not dragging: _begin_drag()
		var movement: Vector2 = previous - point
		var now: int = Time.get_ticks_msec()
		velocity = movement / maxf(float(now - last_motion) / 1000.0, 0.016)
		velocity = velocity.limit_length(2200.0)
		_move(movement)
		previous = point
		last_motion = now
		get_viewport().set_input_as_handled()

func _move(amount: Vector2) -> void:
	if horizontal_scroll_mode != SCROLL_MODE_DISABLED:
		get_h_scroll_bar().value += amount.x
	if vertical_scroll_mode != SCROLL_MODE_DISABLED:
		get_v_scroll_bar().value += amount.y

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		velocity = Vector2.ZERO
		return
	if finger >= 0 or velocity.length() < 5.0: return
	_move(velocity * minf(delta, 0.05))
	velocity = velocity.move_toward(Vector2.ZERO, 2600.0 * delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree(): _cancel()
