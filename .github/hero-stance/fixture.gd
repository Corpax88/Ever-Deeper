func _command(data: Dictionary) -> void:
	if String(data.kind) == "stance_setup":
		_original_command({"kind":"setup","id":data.id,"mine":"starMine","durable":true,"cached":true})
		_require(_place_moss(_direction(String(data.direction))), "No direction target")
		var w: Node = main.mine_world
		var cell: Vector2i = w._find_mine_target()
		w.blocks[cell].hp = 100000
		w.blocks[cell].max_hp = 100000
		return
	if String(data.kind) == "stance_pose":
		command_id = int(data.id)
		var owner: Node = main.mine_world.player.visual._native_worn
		var m: RefCounted = owner.motion
		m.bank.mine = m.original_mining_poses if bool(data.reference) else m.aligned_mining_poses
		var pose: Dictionary = m._world(m.aimed(float(data.phase)))
		_require(m._rigid(pose), "Pose disconnected")
		owner.rig.shown = pose.bones
		owner.rig._apply(pose.bones)
		owner.equipment.apply_pose()
		return
	_original_command(data)

func _stance_location() -> void:
	var player: Node2D = main._active_player_node()
	if player == null: return
	var p: Vector2 = player.get_global_transform_with_canvas().origin
	var v: Vector2 = player.get_viewport_rect().size
	JavaScriptBridge.eval("window.STANCE_SCREEN="+JSON.stringify([p.x,p.y,v.x,v.y]),true)
