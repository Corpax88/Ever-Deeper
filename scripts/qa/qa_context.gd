extends RefCounted
## QA has explicit access to the live game; it owns no duplicated game state.
var main: Node
var session: Node

func _init(game: Node, launch_session: Node) -> void:
	main = game
	session = launch_session
