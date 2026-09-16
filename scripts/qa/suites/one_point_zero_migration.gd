extends "res://scripts/qa/suites/one_point_zero.gd"
## Historical launch flag retained for CI. Schema 3 deliberately rejects old
## saves; this suite now verifies the current journal and durable generations.

const SaveCodec = preload("res://scripts/state/run_save_codec.gd")
const DISK_PATH: String = "user://schema-three-review.sav"


func run() -> void:
	_test_rejected_imports()
	_test_journal_bounds()
	_test_binary_envelope()
	_test_file_generations()
	if _new_player_to_deep():
		_test_current_progression()
	_finish("migration")


func _test_rejected_imports() -> void:
	RunState.reset_run(false)
	RunState.gold = 17
	RunState.add_resource("copper", 9)
	var sale: Dictionary = RunState.begin_assay_sale()
	_check(bool(sale.get("ok", false)), "Rejection fixture has a real pending sale")
	var preserved: Dictionary = RunState.serialize().state
	var current: Dictionary = RunState.serialize()
	var obsolete: Dictionary = current.duplicate(true)
	obsolete.version = 2
	var future: Dictionary = current.duplicate(true)
	future.version = 4
	var wrong_schema: Dictionary = current.duplicate(true)
	wrong_schema.schema = "unrelated_game"
	var incomplete: Dictionary = current.duplicate(true)
	incomplete.state.erase("overhaul")
	var wrong_type: Dictionary = current.duplicate(true)
	wrong_type.state.cargo = []
	var nonfinite: Dictionary = current.duplicate(true)
	nonfinite.state.gold = INF
	var invalid_documents: Array = [null, [], {}, current.state, obsolete, future, wrong_schema, incomplete, wrong_type, nonfinite]
	for index in invalid_documents.size():
		_check(not RunState.deserialize(invalid_documents[index]), "Unsupported or malformed import rejected %d" % index)
		_check(RunState.serialize().state == preserved, "Rejected import leaves every live field unchanged %d" % index)
	var expected_gold: int = int(RunState.assay_sale_snapshot().gold_after)
	var transaction_id: String = String(sale.get("transaction_id", ""))
	_check(bool(RunState.commit_assay_sale(transaction_id).get("ok", false)), "Rejected import does not cancel a pending sale")
	_check(RunState.gold == expected_gold and int(RunState.cargo.copper) == 0, "Pending sale still commits exact inventory and gold")
	RunState.commit_assay_sale(transaction_id)
	_check(RunState.gold == expected_gold, "Pending sale replay cannot duplicate payment")


func _test_journal_bounds() -> void:
	var terrain: Script = preload("res://scripts/state/endless_terrain_state.gd")
	var clean: Dictionary = terrain.sanitize({
		"-1": {}, "0": {}, "2147483648": {}, "invalid": {},
		"1": {"dug": "z", "nodes": INF, "sites": [], "seen": -12},
		"2": {"dug": "F".repeat(230), "nodes": 1.0e30, "sites": 1000, "seen": 32},
	}, RunState.ENDLESS_MAX_SAVED_DEPTH)
	_check(clean.size() == 2, "Journal rejects invalid and out-of-range band keys")
	_check(clean["1"] == {"dug": "", "nodes": 0, "sites": 0, "seen": 0}, "Malformed journal leaves sanitize without conversion errors")
	_check(String(clean["2"].dug).length() == 220 and String(clean["2"].dug) == "f".repeat(220), "Excavation journal is bounded to the real 880-cell band")
	_check(int(clean["2"].nodes) == 2147483647 and int(clean["2"].sites) == 255 and int(clean["2"].seen) == 15, "Claim masks remain within their defined bits even for huge numbers")


func _test_binary_envelope() -> void:
	var document: Dictionary = RunState.serialize()
	var encoded: PackedByteArray = SaveCodec.encode(document)
	_check(not encoded.is_empty() and SaveCodec.decode(encoded) == document, "Binary codec preserves the complete typed dictionary")
	var typed: Dictionary = document.duplicate(true)
	typed.state.gold = 9007199254740993
	typed.state.surface_ore.reserve = 0.731239847
	var round_trip: Dictionary = SaveCodec.decode(SaveCodec.encode(typed))
	_check(round_trip.state.gold is int and round_trip.state.gold == typed.state.gold, "Binary codec preserves integer precision beyond the JSON floating-point range")
	_check(round_trip.state.surface_ore.reserve is float and round_trip.state.surface_ore.reserve == typed.state.surface_ore.reserve, "Binary codec preserves exact floating-point values")
	_check(RunState.deserialize(round_trip) and RunState.gold == typed.state.gold, "Canonical import retains the exact large integer without a float conversion")
	_check(RunState.deserialize(document), "Precision fixture restores the previous canonical state")
	var short_header: PackedByteArray = encoded.slice(0, SaveCodec.HEADER_BYTES - 1)
	_check(SaveCodec.decode(short_header) == null, "Truncated binary header is rejected")
	_check(SaveCodec.decode(encoded.slice(0, encoded.size() - 1)) == null, "Truncated payload is rejected before decoding")
	var oversized: PackedByteArray = encoded.duplicate()
	oversized.encode_u32(8, SaveCodec.MAX_PAYLOAD_BYTES + 1)
	_check(SaveCodec.decode(oversized) == null, "Oversized payload declaration is rejected before allocating or decoding it")
	var tailed: PackedByteArray = encoded.duplicate()
	tailed.append(0)
	_check(SaveCodec.decode(tailed) == null, "Trailing file bytes cannot be silently accepted")
	var wrong_magic: PackedByteArray = encoded.duplicate()
	wrong_magic.encode_u32(0, 0)
	_check(not RunState.deserialize(SaveCodec.decode(wrong_magic)), "Unknown binary magic is not imported")
	var future: PackedByteArray = encoded.duplicate()
	future.encode_u32(4, RunState.SAVE_SCHEMA_VERSION + 1)
	_check(not RunState.deserialize(SaveCodec.decode(future)), "Unknown binary schema is not imported")
	var bad_types: Dictionary = document.duplicate(true)
	bad_types.state.cargo = []
	var preserved: Dictionary = RunState.serialize().state
	_check(not RunState.deserialize(SaveCodec.decode(SaveCodec.encode(bad_types))) and RunState.serialize().state == preserved, "Well-formed typed payload with invalid current field types is rejected without state loss")
	_check(not RunState.deserialize(SaveCodec.decode(JSON.stringify(document).to_utf8_buffer())), "Unreleased JSON envelope has no parallel import path")


func _test_file_generations() -> void:
	_clear_disk_files()
	RunState.reset_run(false)
	RunState.gold = 101
	RunState.set_surface_ore_state(0.731, 0.237, false, 1234, {"copper": 2, "gold": 1})
	_check(RunState.save_game(DISK_PATH), "First complete generation commits")
	_check(not FileAccess.file_exists(DISK_PATH + ".tmp"), "Successful commit removes temporary generation")
	RunState.gold = 0
	_check(RunState.load_game(DISK_PATH) and RunState.gold == 101, "Primary file reloads with its integrity digest")
	_check(is_equal_approx(RunState.surface_ore_reserve, 0.731) and is_equal_approx(RunState.surface_ore_yield_buffer, 0.237), "Fractional surface state survives typed binary storage")
	RunState.gold = 202
	_check(RunState.save_game(DISK_PATH), "Second complete generation commits")
	_check(FileAccess.file_exists(DISK_PATH + ".bak"), "Successful save retains the prior good generation")
	_check(RunState.load_game(DISK_PATH) and RunState.gold == 202 and RunState.last_load_status == "loaded", "Newest complete generation wins")
	_write_text(DISK_PATH, "{truncated")
	_check(RunState.load_game(DISK_PATH) and RunState.gold == 101 and RunState.last_load_status == "recovered_backup", "Truncated primary recovers the preceding generation")
	RunState.gold = 303
	_check(RunState.save_game(DISK_PATH), "Recovered session can save normally")
	var damaged: PackedByteArray = FileAccess.get_file_as_bytes(DISK_PATH)
	damaged[damaged.size() - 1] ^= 1
	_write_bytes(DISK_PATH, damaged)
	_check(RunState.load_game(DISK_PATH) and RunState.gold == 101, "Changed payload bytes fail integrity before decoding and preserve the good backup")
	RunState.gold = 401
	_check(RunState.save_game(DISK_PATH), "Next healthy generation repairs a damaged primary")
	_write_text(DISK_PATH + ".tmp", "unfinished newer write")
	_check(RunState.load_game(DISK_PATH) and RunState.gold == 401, "Crash before rotation ignores incomplete temporary data")
	_remove_file(DISK_PATH + ".bak")
	_check(DirAccess.rename_absolute(ProjectSettings.globalize_path(DISK_PATH), ProjectSettings.globalize_path(DISK_PATH + ".bak")) == OK, "Fixture models crash between rotation and commit")
	_check(RunState.load_game(DISK_PATH) and RunState.gold == 401 and RunState.last_load_status == "recovered_backup", "Crash after primary rotation recovers committed backup")
	_check(RunState.save_game(DISK_PATH), "Recovered missing primary can be replaced")
	var committed_bytes: PackedByteArray = FileAccess.get_file_as_bytes(DISK_PATH)
	_remove_file(DISK_PATH + ".tmp")
	_check(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(DISK_PATH + ".tmp")) == OK, "Fixture blocks the temporary file path")
	RunState.gold = 502
	_check(not RunState.save_game(DISK_PATH) and RunState.last_save_error != OK, "Write failure is reported instead of claiming success")
	_check(FileAccess.get_file_as_bytes(DISK_PATH) == committed_bytes, "Write failure leaves the committed generation byte-identical")
	_check(FileAccess.file_exists(DISK_PATH + ".bak"), "Write failure preserves recovery generation")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DISK_PATH + ".tmp"))
	_check(RunState.load_game(DISK_PATH) and RunState.gold == 401, "Committed state remains loadable after write failure")
	var old: Dictionary = RunState.serialize()
	old.version = 2
	_remove_file(DISK_PATH + ".bak")
	var old_bytes: PackedByteArray = SaveCodec.encode(old)
	old_bytes.encode_u32(4, 2)
	_write_bytes(DISK_PATH, old_bytes)
	_check(not RunState.load_game(DISK_PATH) and RunState.last_load_status == "incompatible", "Old version on disk is explicitly invalidated")
	_check(RunState.gold == 0 and RunState.pickaxe_level == 1 and RunState.world_seed > 0, "Invalidated save starts one clean seeded run")
	_write_text(DISK_PATH, "broken primary")
	_write_text(DISK_PATH + ".bak", "broken backup")
	_check(not RunState.load_game(DISK_PATH) and RunState.last_load_status == "corrupt", "Two broken generations report corruption")
	_check(RunState.gold == 0 and RunState.world_seed > 0, "Unrecoverable corruption produces a clean playable state")
	_clear_disk_files()


func _test_current_progression() -> void:
	_check(bool(RunState.start_endless_descent().get("ok", false)), "Canonical journal starts a real descent")
	_check(bool(RunState.claim_endless_rock_cell(1, 253, "deep_alloy", 5).get("ok", false)), "Rock claim enters canonical journal")
	_check(bool(RunState.claim_endless_resource_node(1, 4, "deep_alloy", 9).get("ok", false)), "Resource claim enters canonical journal")
	RunState.mark_endless_site_discovered(1, 1)
	_check(bool(RunState.claim_endless_site_cache(1, 1, "overload", "deep_alloy", 8).get("ok", false)), "Resolved site enters canonical journal")
	_check(RunState.discover_endless_relic("forge_heart", 1), "Relic is discovered through state authority")
	_check(bool(RunState.collect_endless_relic("forge_heart", 1).get("ok", false)) and RunState.attach_carried_relic(), "Relic transport starts attached")
	_check(bool(RunState.tunnel_home_endless_descent().get("ok", false)), "Attached relic returns through Tunnel Home")
	RunState.set_location("hub", Vector2(520, 670))
	_check(bool(RunState.place_carried_relic().get("ok", false)), "Real relic placement funds construction")
	_check(bool(RunState.build_workshop("tool_forge").get("ok", false)), "Relic-funded workshop builds")
	var upgrade: Dictionary = RunState.workshop_status("tool_forge").next_upgrade
	_fund_resource(String(upgrade.resource), int(upgrade.cost))
	_check(bool(RunState.upgrade_workshop("tool_forge").get("ok", false)), "Workshop upgrade spends its real price")
	_check(RunState.set_endless_tool_style("crusher"), "Paid workshop unlocks saved appearance")
	_check(bool(RunState.start_endless_descent().get("ok", false)), "Returning descent retains prior journal")
	_check(RunState.reach_endless_depth(2) and RunState.reach_endless_depth(3), "Canonical journal crosses bands")
	RunState.claim_endless_rock_cell(3, 294, "lumenstone", 2)
	RunState.claim_endless_rock_cell(3, 335, "lumenstone", 3)
	_check(RunState.discover_endless_relic("ancient_lens", 3), "Second relic is discovered at its band")
	_check(bool(RunState.collect_endless_relic("ancient_lens", 3).get("ok", false)) and RunState.attach_carried_relic(), "Second relic remains attached for the save")
	RunState.save_endless_stream_anchor(2, Vector2(960, 1820), Vector2(894, 1802))
	RunState.set_location("endless", Vector2(960, 1820))
	RunState.set_surface_moonglass_state([{"hp": 17, "respawn": 0.0}, {"hp": 0, "respawn": 12.5}, {"hp": 42, "respawn": 0.0}], "active", 9.25, 7, 12345, {"moonglass": 3, "starshard": 2})
	RunState.overhaul_progress.skills = {"lantern": 1, "fetch": 1, "trailrunner": 1}
	RunState.overhaul_progress.companion_xp = 237
	RunState.strike_barrier("moonMine:d2:test")
	var saved: Dictionary = RunState.serialize()
	var expected: Dictionary = saved.state.duplicate(true)
	_check(int(saved.version) == 3 and not saved.state.has("surface_moonglass"), "Schema 3 stores each surface vein once")
	for key in ["active_floor_depth", "active_floor_mined_mask", "active_floor_site_mask", "resource_exhausted_through", "stream_version"]:
		_check(not saved.state.endless_descent.has(key), "No obsolete Deep save field " + key)
	_check(not saved.state.overhaul.has("dug"), "Excavation has one compact canonical owner")
	RunState.reset_run(false)
	_check(RunState.deserialize(saved), "Current progression document round trips")
	_check_same_state(RunState.serialize().state, expected, "Every canonical field survives current document round trip")
	_check(RunState.endless_dug_cells(1).has(253) and RunState.endless_dug_cells(3).has(294) and RunState.endless_dug_cells(3).has(335), "Excavation persists across multiple bands")
	_check(int(RunState.endless_floor_resource_state(1).mined_mask) == 16, "Resource depletion is retained in its chunk")
	var site: Dictionary = RunState.endless_floor_site_state(1, 1)
	_check(bool(site.resolved) and bool(site.discovered) and String(site.choice) == "overload", "Site choice and discovery survive reload")
	_check(RunState.surface_moonglass_nodes == saved.state.surface_veins.moonglass_bloom.nodes and RunState.surface_moonglass_completions == 7, "Surface read API uses canonical vein data")
	var detached_nodes: Array = RunState.surface_moonglass_nodes
	detached_nodes[0].hp = 0
	_check(int(RunState.surface_moonglass_nodes[0].hp) == 17, "Surface snapshot cannot mutate the persisted vein")
	_check(RunState.surface_moonglass_ground_loot == {"moonglass": 3, "starshard": 2}, "Pending surface resource drops persist")
	_check(MoleSkills.has_skill("trailrunner") and MoleSkills.bond() == 237, "Paid companion progress survives schema round trip")
	_check(bool(RunState.relic_status("ancient_lens").attached) and bool(RunState.relic_status("forge_heart").placed), "Attached and placed relic states remain distinct")
	_check(int(RunState.workshop_status("tool_forge").level) == 2 and RunState.endless_tool_style == "crusher", "Paid workshop level and equipped appearance persist")
	_check(RunState.save_game(DISK_PATH), "Mature canonical state commits to disk")
	RunState.reset_run(false)
	_check(RunState.load_game(DISK_PATH), "Mature canonical file passes integrity and reloads")
	_check_same_state(RunState.serialize().state, expected, "Disk round trip preserves all canonical values")
	main._restore_saved_location()
	_check(main.phase == "endless" and int(RunState.endless_current_depth) == 3, "Current save restores the actual continuous world at its native depth")
	_check(not main.endless_world.collision_at(main.endless_world.player.global_position), "Restored native stream anchor is walkable")
	_check(RunState.reach_endless_depth(4), "Attached relic can move deeper after loading")
	RunState.save_endless_stream_anchor(3, Vector2(970, 1850), Vector2(900, 1800))
	RunState.set_location("endless", Vector2(970, 1850))
	saved = RunState.serialize()
	_check(RunState.deserialize(saved) and int(RunState.relic_status("ancient_lens").current_depth) == 4, "Transport depth never snaps back to the relic discovery band")
	RunState.detach_carried_relic()
	var cargo_before: Dictionary = RunState.cargo.duplicate(true)
	_check(not bool(RunState.tunnel_home_endless_descent().get("ok", true)), "Detached relic blocks Tunnel Home after reload")
	_check(RunState.cargo == cargo_before and int(RunState.endless_current_depth) == 4, "Rejected travel preserves inventory and depth")
	RunState.attach_carried_relic()
	RunState.reach_endless_depth(3)
	var before_replay: Dictionary = RunState.cargo.duplicate(true)
	_check(not bool(RunState.claim_endless_rock_cell(3, 294, "lumenstone", 2).get("ok", true)), "Reloaded rock claim cannot be repeated")
	RunState.reach_endless_depth(2)
	RunState.reach_endless_depth(1)
	_check(not bool(RunState.claim_endless_resource_node(1, 4, "deep_alloy", 9).get("ok", true)), "Reloaded resource claim cannot be repeated")
	_check(not bool(RunState.claim_endless_site_cache(1, 1, "overload", "deep_alloy", 8).get("ok", true)), "Reloaded site reward cannot be repeated")
	_check(RunState.cargo == before_replay, "All rejected replays leave resource totals unchanged")
	main.endless_world.set_active(false)
	main.phase = "surface"
	_test_mature_appearances()
	_clear_disk_files()


func _test_mature_appearances() -> void:
	var saved: Dictionary = RunState.serialize()
	var state: Dictionary = saved.state
	for index in RunState.ENDLESS_RELIC_IDS.size():
		state.endless_descent.relics[RunState.ENDLESS_RELIC_IDS[index]] = {"discovered": true, "collected": true, "placed": true, "found_depth": [1, 3, 5, 8, 12][index]}
		var id: String = RunState.ENDLESS_WORKSHOP_IDS[index]
		state.endless_descent.workshops[id] = {"built": true, "level": 1 if id in ["treasure_chamber", "lift_workshop"] else 5, "style": "original", "delivered": 200}
	state.endless_descent.carried_relic = {"id": "", "origin_depth": 0, "current_depth": 0, "attached": false}
	state.endless_descent.active = false
	state.endless_descent.current_depth = 0
	state.endless_descent.deepest_depth = 12
	state.endless_descent.start_depth_checkpoint = 12
	state.endless_descent.stream_anchor = {}
	state.endless_descent.outfit = "deepheart"
	state.location.scene = "hub"
	_check(RunState.deserialize(saved), "Current mature workshop fixture loads")
	_check(RunState.endless_descent_status().placed_relic_count == 5 and RunState.endless_descent_status().built_workshop_count == 5, "All five canonical relic/building pairs persist")
	_check(RunState.endless_outfit == "deepheart" and not bool(RunState.endless_descent_status().exploration_complete), "Mature wardrobe persists while exploration remains open")
	var gear: Script = load("res://scripts/player/hero_gear.gd")
	var appearances: Dictionary = {"crusher": "crusher", "comet": "comet", "crownseeker": "crown", "deepheart": "ember"}
	for level in range(1, 4):
		RunState.drill_level = level
		var drill_before: Dictionary = RunState.current_drill().duplicate(true)
		var power_before: float = RunState.endless_tool_power_multiplier()
		var speed_before: float = RunState.endless_tool_speed_multiplier()
		var range_before: float = RunState.endless_tool_range_multiplier()
		for style in appearances:
			_check(RunState.set_endless_tool_style(style), "Unlocked appearance equips " + style)
			_check(gear.resolve_tool(RunState.pickaxe_level, level, RunState.starforge_variant, String(RunState.endless_loadout_status().tool)) == appearances[style], "Saved appearance overrides owned drill model " + style)
			_check(RunState.current_drill() == drill_before and RunState.endless_tool_power_multiplier() == power_before and RunState.endless_tool_speed_multiplier() == speed_before and RunState.endless_tool_range_multiplier() == range_before, "Appearance preserves every mining statistic " + style)
		_check(RunState.set_endless_tool_style("original"), "Original appearance can be restored")
		_check(gear.resolve_tool(RunState.pickaxe_level, level, RunState.starforge_variant, "original") == ["burrower", "pulse", "deepcore"][level - 1], "Original retains the actual drill tier")


func _write_text(path: String, contents: String) -> void:
	_write_bytes(path, contents.to_utf8_buffer())


func _write_bytes(path: String, contents: PackedByteArray) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not _check(file != null, "Disk fixture opens " + path):
		return
	file.store_buffer(contents)
	file.flush()


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _clear_disk_files() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		_remove_file(DISK_PATH + suffix)


func _check_same_state(actual: Dictionary, expected: Dictionary, label: String) -> void:
	if not _check(actual == expected, label):
		for key in expected:
			if actual.get(key) != expected[key]:
				print("SAVE_FIELD_DIFF %s expected=%s actual=%s" % [key, JSON.stringify(expected[key]), JSON.stringify(actual.get(key))])
