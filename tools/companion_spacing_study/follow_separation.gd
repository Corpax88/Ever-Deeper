extends RefCounted
## Isolated follow-only local steering. No player, terrain or task mutations.
const EXCLUSION := 50.0
const COMFORT := 64.0
const LOOKAHEAD := 0.22
const ESCAPE_SPEED := 580.0
var yield_axis := Vector2.ZERO
var avoidance_active := false
var trapped := false
var attempts := 0
var choice := ""


func reset() -> void:
	yield_axis = Vector2.ZERO
	avoidance_active = false
	trapped = false
	attempts = 0
	choice = ""


static func segment_distance(a: Vector2, b: Vector2) -> float:
	var span := b - a
	var fraction := clampf(-a.dot(span) / span.length_squared(), 0.0, 1.0) if span.length_squared() > 0.000001 else 0.0
	return (a + span * fraction).length()


func choose(origin: Vector2, hero_before: Vector2, hero_now: Vector2, hero_velocity: Vector2,
		preferred_step: Vector2, follow_speed: float, delta: float, terrain_clear: Callable) -> Vector2:
	trapped = false
	attempts = 0
	choice = ""
	if delta <= 0.0:
		return Vector2.ZERO
	var distance := origin.distance_to(hero_now)
	var away := (origin - hero_now).normalized()
	if away.is_zero_approx():
		away = -hero_velocity.normalized() if not hero_velocity.is_zero_approx() else Vector2.LEFT
	var preferred_future_gap := segment_distance(origin - hero_now,
		origin + preferred_step / delta * LOOKAHEAD - hero_now - hero_velocity * LOOKAHEAD)
	# The normal route keeps ownership outside the danger area. While the hero
	# recedes, a close follower can hold its position rather than chase a new anchor.
	var receding := hero_velocity.dot(away) < -1.0
	var heading := hero_velocity.normalized()
	var relative := origin - hero_now
	var passed_or_stopped := heading.is_zero_approx() or relative.dot(heading) <= 0.0
	# Once safely beside an approaching hero, wait for it to pass. Immediately
	# seeking the hero again would zigzag between following and yielding.
	if avoidance_active and not passed_or_stopped and absf(relative.cross(heading)) >= COMFORT + 8.0:
		if _safe(origin, hero_before, hero_now, hero_velocity, Vector2.ZERO, delta, terrain_clear):
			choice = "give_way"
			return Vector2.ZERO
	if (not avoidance_active or passed_or_stopped) and (distance >= COMFORT - 0.1 or receding) and preferred_future_gap >= EXCLUSION:
		if _safe(origin, hero_before, hero_now, hero_velocity, preferred_step, delta, terrain_clear):
			choice = "route"
			if passed_or_stopped:
				yield_axis = Vector2.ZERO
				avoidance_active = false
			return preferred_step
	var recovery := minf(240.0, maxf(0.0, COMFORT - distance) * 6.0)
	if hero_velocity.length_squared() < 1.0:
		var restore := away * minf(follow_speed * delta, maxf(0.0, COMFORT - distance))
		if _safe(origin, hero_before, hero_now, hero_velocity, restore, delta, terrain_clear):
			choice = "restore"
			return restore
	var lateral := Vector2(-hero_velocity.y, hero_velocity.x).normalized()
	if lateral.is_zero_approx():
		lateral = Vector2(-away.y, away.x)
	if not yield_axis.is_zero_approx():
		if lateral.dot(yield_axis) < 0.0:
			lateral = -lateral
	elif lateral.dot(away) < 0.0:
		lateral = -lateral
	for side in [lateral, -lateral]:
		var velocity: Vector2 = (hero_velocity + side * follow_speed + away * recovery).limit_length(ESCAPE_SPEED)
		var step := velocity * delta
		# Do not begin a sideways escape into a narrow passage that immediately
		# forces the opposite choice. This bounded terrain probe is only paid
		# while choosing a yield, never on ordinary following frames.
		if not bool(terrain_clear.call(origin, origin + velocity * maxf(delta, 0.12))):
			continue
		if _safe(origin, hero_before, hero_now, hero_velocity, step, delta, terrain_clear):
			yield_axis = side
			avoidance_active = true
			choice = "yield"
			return step
	# A narrow passage may only permit retreat along the passage. The same
	# existing catch-up ceiling can outrun the hero's resolved approach.
	var retreat_speed := minf(ESCAPE_SPEED, maxf(follow_speed, hero_velocity.dot(away) + recovery))
	var retreat := away * retreat_speed * delta
	if _safe(origin, hero_before, hero_now, hero_velocity, retreat, delta, terrain_clear):
		choice = "retreat"
		avoidance_active = true
		return retreat
	# Prefer a safe hold while an approaching hero passes. Rejoining between
	# retreat steps creates a one-frame reversal at a wall. If holding is unsafe,
	# retain the normal fallback escape and its full terrain/sweep checks.
	var wait_before_follow := avoidance_active and not passed_or_stopped
	if wait_before_follow and _safe(origin, hero_before, hero_now, hero_velocity, Vector2.ZERO, delta, terrain_clear):
		choice = "wait"
		return Vector2.ZERO
	if _safe(origin, hero_before, hero_now, hero_velocity, preferred_step, delta, terrain_clear):
		choice = "route_fallback"
		return preferred_step
	if not wait_before_follow and _safe(origin, hero_before, hero_now, hero_velocity, Vector2.ZERO, delta, terrain_clear):
		choice = "wait"
		return Vector2.ZERO
	# An approaching player can trap the follower against solid terrain. Never
	# resolve this impossibility by teleporting, entering terrain or moving the hero.
	trapped = true
	choice = "trapped"
	return Vector2.ZERO


func _safe(origin: Vector2, hero_before: Vector2, hero_now: Vector2, hero_velocity: Vector2,
		step: Vector2, delta: float, terrain_clear: Callable) -> bool:
	attempts += 1
	var prior := origin - hero_before
	var actual := origin + step - hero_now
	var required := minf(EXCLUSION, prior.length())
	if segment_distance(prior, actual) < required - 0.001:
		return false
	if prior.length() < EXCLUSION and actual.length() < prior.length() - 0.001:
		return false
	var future := actual + (step / delta - hero_velocity) * maxf(0.0, LOOKAHEAD - delta)
	if segment_distance(actual, future) < minf(EXCLUSION, actual.length()) - 0.001:
		return false
	return bool(terrain_clear.call(origin, origin + step))
