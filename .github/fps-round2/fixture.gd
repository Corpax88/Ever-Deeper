extends "res://scripts/qa/suites/round2_native_base.gd"
const Round2World = preload("res://scripts/qa/suites/round2_world_fixture.gd")
var round2_result: Dictionary = {}
var round2_clock: int = 0
var round2_bind_check: Dictionary = {}

func _command(data: Dictionary) -> void:
	var kind: String = data.kind
	if not kind.begins_with("r2_"):
		super._command(data)
		return
	command_id = int(data.id)
	var owner: Node = main._active_player_node().visual._native_worn
	var pet: Node = main.surface_world.get_node_or_null("MoleCompanion")
	match kind:
		"r2_modes":
			_round2_hero_modes(owner,bool(data.get("bind",false)),bool(data.get("contact",false)),bool(data.get("profile",true)))
			pet.qa_world_cache_enabled = bool(data.get("path",false))
			pet.qa_world_reset_counters()
		"r2_apply": owner.rig._apply(owner.rig.shown)
		"r2_contact": round2_result = _round2_hero_contact_benchmark(owner,1)
		"r2_world": round2_result = Round2World.new().run(main)
		"r2_walk_setup":
			main.surface_world.restore_position(Vector2(2820,650))
			main.surface_world.player.camera.reset_smoothing()
		"r2_bind_bench":
			var pose: Dictionary = owner.rig.shown.duplicate(true)
			var rows: Array = []
			for candidate in [false,true,true,false]:
				owner.rig.qa_round2_bind_cache=candidate
				owner.rig.qa_round2_hero_profile=false
				owner.rig._apply(pose)
				var start: int = Time.get_ticks_usec()
				for i in 1000: owner.rig._apply(pose)
				rows.append({"candidate":candidate,"calls":1000,"usec":Time.get_ticks_usec()-start})
			owner.rig.qa_round2_bind_cache=false
			round2_result={"parity":owner.rig.qa_round2_compare_bind_matrices(pose),"rows":rows,"scope":"Repeated identical CPU submission; no rendered-FPS claim"}

func _frame() -> void:
	super._frame()
	var now: int = Time.get_ticks_usec()
	if now-round2_clock<200000: return
	round2_clock=now
	var player: Node = main._active_player_node()
	var extra: Dictionary = {"id":command_id,"result":round2_result}
	if is_instance_valid(player) and is_instance_valid(player.visual._native_worn):
		var owner: Node=player.visual._native_worn
		if is_instance_valid(owner.rig) and owner.motion!=null:
			extra["hero"]=_round2_hero_stats(owner)
			extra["position"]=[player.global_position.x,player.global_position.y]
	var pet: Node=main.surface_world.get_node_or_null("MoleCompanion")
	if is_instance_valid(pet) and pet.has_method("qa_world_snapshot"): extra["world"]=pet.qa_world_snapshot()
	JavaScriptBridge.eval("window.ROUND2_STATE="+JSON.stringify(extra),true)
