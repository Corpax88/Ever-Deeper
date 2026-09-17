extends "res://scripts/companion/mole_companion.gd"
## Opt-in fixture replacement. The shipped companion is unchanged.
const Separation = preload("res://tools/companion_spacing_study/follow_separation.gd")
var separation := Separation.new()
var observed_hero := Vector2(INF, INF)
var hero_before_step := Vector2.ZERO
var observed_velocity := Vector2.ZERO
var observation_active := false
var follow_step_ran := false
var separation_ticks := 0
var trapped_ticks := 0


func _physics_process(delta: float) -> void:
	follow_step_ran = false
	var may_supplement := action not in ["pickup", "shake", "tunnel"]
	var active_now: bool = is_instance_valid(hero) and world.is_visible_in_tree() and bool(hero.get("control_enabled")) and action != "tunnel" and (world.has_method("_surface_collides") or bool(world.get("active")))
	if is_instance_valid(hero):
		var now: Vector2 = hero.global_position
		var continuous: bool = observation_active and is_finite(observed_hero.x) and observed_hero.distance_to(now) <= maxf(32.0, delta * 1000.0)
		hero_before_step = observed_hero if active_now and continuous else now
		observed_velocity = (now - hero_before_step) / delta if delta > 0.0 else Vector2.ZERO
		observed_hero = now
	observation_active = active_now
	if not active_now:
		separation.reset()
	super._physics_process(delta)
	# The base owner deliberately skips _move inside its 50 px stop radius.
	# Yielding must still run there, after its normal task-selection priority.
	if active_now and may_supplement and mode == "follow" and action in ["idle", "walk"] and not follow_step_ran:
		moving = false
		_move(delta)
		action = "walk" if moving else "idle"
		_draw_pose()


func _spawn_beside_hero() -> void:
	super._spawn_beside_hero()
	observed_hero = hero.global_position
	hero_before_step = observed_hero
	observed_velocity = Vector2.ZERO
	separation.reset()


func rebase_world(offset: Vector2) -> void:
	super.rebase_world(offset)
	if is_finite(observed_hero.x):
		observed_hero += offset
	hero_before_step += offset


func _move(delta: float) -> void:
	if mode != "follow":
		super._move(delta)
		return
	follow_step_ran = true
	separation_ticks += 1
	destination = hero.global_position
	var distance_to_hero := global_position.distance_to(hero.global_position)
	var next: Vector2 = destination
	var have_route := distance_to_hero > Separation.COMFORT
	if have_route and not _segment_clear(global_position, destination):
		if route.is_empty() or route_goal.distance_to(destination) > 30.0:
			if path_cooldown <= 0.0:
				path_cooldown = 0.9
				route = _path_to(destination)
				route_goal = destination
			else:
				have_route = false
		while not route.is_empty() and global_position.distance_to(route[0]) < 0.5:
			route.pop_front()
		if route.is_empty():
			have_route = false
		else:
			next = route[0]
	else:
		route.clear()
	var speed: float = 280.0 * (1.60 if Skills.has_skill("trailrunner") else 1.0)
	if distance_to_hero > 240.0:
		speed = maxf(speed, 580.0)
	var preferred := Vector2.ZERO
	if have_route:
		preferred = (next - global_position).limit_length(speed * delta)
		if next.is_equal_approx(destination):
			preferred = preferred.limit_length(maxf(0.0, distance_to_hero - Separation.COMFORT))
	var step: Vector2 = separation.choose(global_position, hero_before_step, hero.global_position,
		observed_velocity, preferred, speed, delta, _segment_clear)
	if separation.trapped:
		trapped_ticks += 1
	if step.length_squared() > 0.01:
		global_position += step
		facing = step.normalized()
		moving = true
		if world.has_method("actor_draw_depth"):
			z_index = world.actor_draw_depth(position)
