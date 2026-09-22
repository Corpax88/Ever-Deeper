extends SceneTree
## Synthetic contact/cancel geometry regression; final graphical gameplay is separate.
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	assert(ProjectSettings.load_resource_pack(args[0]))
	var Rig = load("res://scripts/player/native_worn/native_rig.gd")
	var Motion = load(args[1] if args.size()>1 else "res://scripts/player/native_worn/runtime_motion.gd")
	var rig = Rig.new()
	assert(rig.configure("res://assets/native-worn",true))
	var equipment: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/native-pickaxes/runtime-manifest.json"))
	var checks: int = 0
	for gear in ["worn","comet","crusher","crown"]:
		for delta in [1.0/60.0,1.0/30.0,.025,.05]:
			for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
				for stop in range(2,31):
					var motion = Motion.new()
					assert(motion.configure(rig,"res://assets/native-worn/tasks.json","res://assets/native-worn/motion.json"))
					if gear != "worn":
						motion.cap_local=rig._vector(equipment.tools[gear].tool_cap_local)
						motion.reference_cap=motion.bank.mine[21].bones.tool*motion.cap_local
					var elapsed: float = 0.0
					var impact: int = 0
					var last_impact_swing: int = -1
					var cycle: float = .0872146606001222 if gear=="comet" else .68
					for tick in range(stop+12):
						var mining: bool = tick>0 and tick<stop
						if mining: elapsed += delta
						var serial: int = int(elapsed/cycle)
						var progress: float = fposmod(elapsed/cycle,1.0)
						if mining and elapsed>=float(impact)*cycle+cycle*.28:
							impact+=1
							last_impact_swing=serial
						var packet := {"world_position":Vector2.ZERO,"travelled_distance":0.0,"physics_tick":tick,"moving":false,"mining":mining,"mining_timing_valid":true,"bearing":direction,"swing_serial":serial,"swing_continuation":serial>0,"target_position":direction*64.0,"progress":progress,"hit_phase":.28,"cycle_duration":cycle,"impact_serial":impact,"impact_swing_serial":last_impact_swing,"impact_target_valid":true,"impact_target_position":direction*64.0}
						if not motion.advance(delta,packet):
							print("FAST_TOOL_REPRO_FAILURE ",JSON.stringify({"gear":gear,"delta":delta,"direction":str(direction),"stop":stop,"tick":tick,"mining":mining,"errors":motion.errors,"snapshot":motion.snapshot()}))
							rig.free();quit(2);return
					checks+=1
	print("FAST_TOOL_REPRO_COMPLETE ",checks)
	rig.free();quit(0)
