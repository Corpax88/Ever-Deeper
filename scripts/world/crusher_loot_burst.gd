class_name CrusherLootBurst
extends RefCounted




const MERGE_WINDOW_SECONDS: = 0.15
const ARC_SECONDS: = 0.36
const MAGNET_DELAY_SECONDS: = 0.44
const LAUNCH_SPEED: = 244.0
const ARC_LIFT: = 58.0
const SECTOR_COUNT: = 8
const MAX_VISIBLE_BUNDLES: = 12


static func sector_for(origin: Vector2, position: Vector2, seed_value: int = 0) -> int:
	var offset: = position - origin
	if offset.length_squared() <= 0.01:
		return posmod(seed_value, SECTOR_COUNT)
	var slice: = TAU / float(SECTOR_COUNT)
	return posmod(floori((offset.angle() + slice * 0.5) / slice), SECTOR_COUNT)


static func direction_for_sector(sector: int) -> Vector2:
	return Vector2.from_angle(float(posmod(sector, SECTOR_COUNT)) * TAU / float(SECTOR_COUNT))


static func visible_bundle_count(drops: Array[Dictionary]) -> int:
	var count: = 0
	for drop in drops:
		if bool(drop.get("crusher_bundle", false)) and not bool(drop.get("visual_suppressed", false)):
			count += 1
	return count


static func merge_target_index(drops: Array[Dictionary], kind: String, sector: int) -> int:
	var same_sector_fallback: = -1
	var same_kind_fallback: = -1
	for index in drops.size():
		var drop: Dictionary = drops[index]
		if not bool(drop.get("crusher_bundle", false)):
			continue
		if not String(drop.get("pocket_reward_id", "")).is_empty():
			continue
		if String(drop.get("kind", "")) != kind:
			continue
		if same_kind_fallback < 0 and not bool(drop.get("visual_suppressed", false)):
			same_kind_fallback = index
		if int(drop.get("crusher_sector", -1)) != sector:
			continue
		if same_sector_fallback < 0 and not bool(drop.get("visual_suppressed", false)):
			same_sector_fallback = index


		if float(drop.get("age", 0.0)) < MERGE_WINDOW_SECONDS:
			return index
	if visible_bundle_count(drops) < MAX_VISIBLE_BUNDLES:
		return -1
	if same_sector_fallback >= 0:
		return same_sector_fallback
	return same_kind_fallback


static func draw_position(drop: Dictionary) -> Vector2:
	var position: = Vector2(drop.get("position", Vector2.ZERO))
	if not bool(drop.get("crusher_bundle", false)):
		return position
	var progress: = clampf(
		float(drop.get("crusher_flight_age", drop.get("age", 0.0))) / ARC_SECONDS,
		0.0,
		1.0
	)
	var lift: = float(drop.get("crusher_lift", ARC_LIFT))
	return position - Vector2(0.0, sin(progress * PI) * lift)


static func magnet_delay(drop: Dictionary, default_delay: float) -> float:
	return MAGNET_DELAY_SECONDS if bool(drop.get("crusher_bundle", false)) else default_delay


static func magnet_age(drop: Dictionary) -> float:
	if bool(drop.get("crusher_bundle", false)):
		return float(drop.get("crusher_flight_age", drop.get("age", 0.0)))
	return float(drop.get("age", 0.0))


static func needs_animation(drop: Dictionary) -> bool:
	if Vector2(drop.get("velocity", Vector2.ZERO)).length_squared() > 1.0:
		return true
	if (
		bool(drop.get("crusher_bundle", false))
		and float(drop.get("crusher_flight_age", drop.get("age", 0.0))) < ARC_SECONDS
	):
		return true
	return bool(drop.get("magnet_active", false))
