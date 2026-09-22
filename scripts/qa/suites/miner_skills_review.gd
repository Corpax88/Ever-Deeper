extends "res://scripts/qa/qa_context.gd"
const Skills = preload("res://scripts/progression/miner_skills.gd")
var checks: int = 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  push_error("SKILLS_CHECK_FAILED " + message)
  main.get_tree().quit(2)
 assert(ok, message)
func run() -> void:
 RunState.reset_run(false)
 var fresh: Dictionary = RunState.serialize()
 check(RunState.miner_skill_rows().size() == 4, "four real skills")
 check(RunState.stamina_value() == 100.0, "fresh stamina")
 for i in 25: RunState.record_mining_swing()
 check(RunState.miner_skill_level("mining") == 1, "mining earns level from actual swings")
 RunState.add_resource("copper", 10, false)
 check(RunState.miner_skill_level("prospecting") == 0 and RunState.miner_skills.prospecting == 0.0, "grants never earn ore XP")
 RunState.record_mined("copper", 10)
 check(RunState.miner_skills.prospecting == 10.0, "real mining earns prospecting once")
 var start: float = RunState.stamina_value()
 for i in 600: RunState.advance_miner_training(1.0 / 60.0, 4.0, false)
 check(RunState.stamina_value() < start and RunState.stamina_value() > 60, "mild continuous running drain")
 check(RunState.miner_skills.running > 0 and RunState.miner_skills.carrying > 0, "actual loaded travel trains")
 var running_xp: float = RunState.miner_skills.running
 RunState.advance_miner_training(0.016, 6000, false)
 check(RunState.miner_skills.running == running_xp, "teleports do not train")
 for i in 1800: RunState.advance_miner_training(1.0 / 60.0, 0.0, true)
 check(RunState.stamina_value() == 0.0, "mining drains but clamps")
 check(RunState.stamina_effort_multiplier() >= 0.75, "exhaustion never immobilizes")
 for i in 30: RunState.advance_miner_training(1.0 / 60.0, 0.0, false)
 check(RunState.stamina_value() == 0.0, "recovery delay")
 for i in 480: RunState.advance_miner_training(1.0 / 60.0, 0.0, false)
 check(RunState.stamina_value() == 100.0, "rest recovers fully")
 RunState.miner_skills.stamina = 42.0
 var saved: Dictionary = RunState.serialize()
 check(RunState.deserialize(saved), "round-trip save")
 check(RunState.stamina_value() == 42.0 and RunState.miner_skills.running == running_xp, "round-trip preserves training and stamina")
 var old: Dictionary = saved.duplicate(true)
 old.state.erase("miner_skills")
 check(RunState.deserialize(old), "old schema-three save still loads")
 check(RunState.miner_skills.mining == float(RunState.total_swings) * 4, "old recorded swings migrate")
 var clean: Dictionary = Skills.clean({"mining": INF, "running": -5, "stamina": NAN, "carrying": "999"})
 check(clean == Skills.defaults(), "malformed optional data is bounded")
 check(Skills.row("mining", Skills.MAX_XP).level == 100, "level 100 cap")
 RunState.deserialize(fresh)
 main.automated_mode = false
 main.game_started = true
 main._resume_current_phase()
 main._open_miner_skills()
 check(main.menu_open and main.miner_skills_panel.visible, "normal Skills route pauses world")
 var paused: Dictionary = RunState.miner_skills.duplicate(true)
 await main.get_tree().create_timer(0.3).timeout
 check(RunState.miner_skills == paused, "menu earns no XP and restores no stamina")
 check(not main._active_player_node().control_enabled, "player control stopped by modal")
 if DisplayServer.get_name() != "headless":
  await capture("fresh")
  RunState.miner_skills = {"mining": 21424.0, "running": 6280.0, "carrying": 10125.0, "prospecting": 3020.0, "stamina": 72.0}
  RunState.cargo.copper = 1240
  RunState.cargo.ambercore = 317
  RunState.cargo.lunacore = 86
  RunState.current_scene = "mossMine"
  RunState.current_depth = 2
  main.miner_skills_panel.refresh()
  await capture("skills")
  main.miner_skills_panel.map_requested.emit()
  check(main.miner_skills_panel._map_active, "Map routes to actual minimap")
  await capture("map")
  main.miner_skills_panel.show_skills()
 main._close_miner_skills()
 check(not main.menu_open and not main.miner_skills_panel.visible, "close resumes")
 check(main._active_player_node().control_enabled, "resume restores player control")
 main._open_miner_skills()
 main.miner_skills_panel.inventory_requested.emit()
 check(main.inventory_open and not main.menu_open, "Inventory routes to existing inventory")
 main._close_inventory()
 main._open_miner_skills()
 main.miner_skills_panel.settings_requested.emit()
 check(main.menu_open and main.premium_menu.visible and not main.miner_skills_panel.visible, "Settings route works")
 main._continue_from_menu()
 check(not main.menu_open, "settings resumes")
 print("MINER_SKILLS_COMPLETE ", checks)
 main.get_tree().quit(0)
func capture(name: String) -> void:
 await main.get_tree().process_frame
 await RenderingServer.frame_post_draw
 var directory: String = "user://skills-captures"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--skills-output="): directory = arg.substr(16)
 DirAccess.make_dir_recursive_absolute(directory)
 var image: Image = main.get_viewport().get_texture().get_image()
 check(image.save_png(directory.path_join(name + ".png")) == OK, "capture " + name)
 var file: FileAccess = FileAccess.open(directory.path_join(name + ".json"), FileAccess.WRITE)
 file.store_string(JSON.stringify(main.miner_skills_panel.debug_snapshot(), "\t"))
