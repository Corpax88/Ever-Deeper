extends Node
## Own horizontal gestures before the child scroll containers see them.
## Vertical gestures and stationary taps keep their normal GUI behavior.
signal tapped(start: Vector2, end: Vector2)
signal contact_ended
signal contact_started
signal drag_started
signal dragged(distance: float)
signal released(velocity_x: float, canceled: bool)
var region: Control
var enabled: bool = false
var horizontal_enabled: bool = true
const TAP_SLOP: float = 16.0
var finger: int = -1
var origin: Vector2
var latest: Vector2
var axis: int = 0 # 0 undecided, 1 horizontal, 2 vertical
var suppress_until: int = 0
var release_speed: float = 0.0
var last_motion_usec: int = 0
var drag_previous: Vector2
var web_cancel_callback: JavaScriptObject

func _ready() -> void:
	region.visibility_changed.connect(_cancel)
	if OS.has_feature("web"):
		web_cancel_callback = JavaScriptBridge.create_callback(func(_args: Array): _cancel())
		JavaScriptBridge.get_interface("window").addEventListener("touchcancel", web_cancel_callback, true)

func _exit_tree() -> void:
	if web_cancel_callback != null:
		JavaScriptBridge.get_interface("window").removeEventListener("touchcancel", web_cancel_callback, true)

func _local(point: Vector2) -> Vector2:
	return region.get_global_transform_with_canvas().affine_inverse() * point

func _begin(point: Vector2, index: int) -> void:
	if finger != -1 or not Rect2(Vector2.ZERO, region.size).has_point(_local(point)): return
	finger = index
	origin = _local(point)
	latest = origin
	axis = 0
	release_speed = 0.0
	last_motion_usec = Time.get_ticks_usec()
	drag_previous = origin
	contact_started.emit()

func _clear_child_scrolls(node: Node) -> void:
	if node is TouchScrollContainer: node._cancel()
	for child in node.get_children(): _clear_child_scrolls(child)

func _motion(point: Vector2) -> void:
	latest = _local(point)
	var distance: Vector2 = latest - origin
	if axis == 0 and distance.length() >= TAP_SLOP:
		axis = 1 if horizontal_enabled and absf(distance.x) > absf(distance.y) * 1.25 else 2
		if axis == 1:
			_clear_child_scrolls(region)
			region.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
			drag_started.emit()
	if axis == 1:
		var now: int = Time.get_ticks_usec()
		var elapsed: float = maxf(float(now - last_motion_usec) / 1000000.0, 0.008)
		var dx: float = latest.x - drag_previous.x
		release_speed = lerpf(release_speed, dx / elapsed, 0.55)
		drag_previous = latest
		last_motion_usec = now
		dragged.emit(dx)
		get_viewport().set_input_as_handled()

func _finish(canceled: bool) -> void:
	var velocity_x: float = 0.0
	if axis == 1:
		get_viewport().set_input_as_handled()
		suppress_until = Time.get_ticks_msec() + 180
		region.propagate_notification(Control.NOTIFICATION_SCROLL_END)
		if absf(latest.x - origin.x) >= 24.0 and Time.get_ticks_usec() - last_motion_usec < 90000:
			velocity_x = release_speed
	var completed_axis: int = axis
	finger = -1
	axis = 0
	if completed_axis == 1:
		released.emit(velocity_x, canceled)
	else:
		contact_ended.emit()
		if completed_axis == 0 and not canceled and origin.distance_to(latest) < TAP_SLOP:
			tapped.emit(region.get_global_transform_with_canvas() * origin, region.get_global_transform_with_canvas() * latest)

func _cancel() -> void:
	if finger != -1:
		# Cancel any pressed child even if the finger has not started moving.
		region.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
		axis = 1
		_finish(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree(): _cancel()

func _input(event: InputEvent) -> void:
	if not enabled or not region.is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		if event.pressed:
			if finger != -1 and event.index != finger:
				_cancel()
				return
			_begin(event.position, event.index)
		elif event.index == finger:
			latest = _local(event.position)
			_finish(event.canceled)
	elif event is InputEventScreenDrag and event.index == finger:
		_motion(event.position)
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		if axis == 1 and finger >= 0 or Time.get_ticks_msec() < suppress_until:
			get_viewport().set_input_as_handled()
			return
		# Godot synthesizes mouse events for touch. Never start a second gesture.
		if event.device == InputEvent.DEVICE_ID_EMULATION or finger >= 0: return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed: _begin(event.position, -2)
			elif finger == -2: _finish(false)
		elif event is InputEventMouseMotion and finger == -2:
			_motion(event.position)
