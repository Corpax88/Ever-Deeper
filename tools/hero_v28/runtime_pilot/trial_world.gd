extends "res://scripts/world/endless_descent_world.gd"
## The isolated Worn trial exposes ore contacts that its native pose can reach.
## Ordinary world selection and all gameplay builds keep the original owner.
var trial_contact_allowed: Callable

func _nearest_resource_index() -> int:
	var index := super._nearest_resource_index()
	if index < 0 or not trial_contact_allowed.is_valid(): return index
	return index if trial_contact_allowed.call(resources[index]) else -1

func _nearest_diggable_wall() -> Vector2i:
	return Vector2i(-1,-1)

func _update_stream_depth() -> void:
	# This trial retains its original three-band room and fixture identities.
	# The ordinary game's deeper descent and rebasing remain unchanged.
	pass
