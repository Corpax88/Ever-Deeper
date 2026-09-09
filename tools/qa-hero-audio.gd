extends SceneTree
## Bounded playback regressions; isolated save/output supplied by the caller.
var output_dir := ""
var failures: Array[String] = []
var results: Dictionary = {}
var audio: Node

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, key: String) -> void:
	results[key] = ok
	if not ok:
		failures.append(key)

func reset_voices() -> void:
	for voice in audio.get("_voices"):
		voice.stop()
	audio.get("_last_played_ms").clear()
	audio.set("_voice_index", 0)

func playing_group(group: String) -> Array[AudioStreamPlayer]:
	var found: Array[AudioStreamPlayer] = []
	var streams: Array = audio.get("_library")[group]
	for voice in audio.get("_voices"):
		if voice.playing and voice.stream in streams:
			found.append(voice)
	return found

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output_dir = arg.get_slice("=", 1)
	if output_dir.is_empty():
		push_error("HERO_AUDIO_QA requires --output=<isolated directory>")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output_dir.path_join("isolated-save.json"))
	audio = root.get_node("AudioDirector")
	# Use real AudioStreamPlayer lifecycles even with the headless Dummy backend.
	# This proves scheduling and interruption, not the physical device's sound.
	if audio.get("_voices").is_empty():
		audio.call("_create_players")
	# Native Dummy cannot mix Web Audio's SAMPLE backend. STREAM drives the
	# same players to natural completion; the shipped web backend is unchanged.
	if DisplayServer.get_name() == "headless":
		for voice in audio.get("_voices"):
			voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	audio.set("_headless", false)
	audio.set("music_volume", 0.0)
	audio.set("sfx_volume", 1.0)
	audio.set("muted", false)
	audio.set_process(false)
	reset_voices()
	audio.play_pickup("stone")
	audio.play_pickup("singularity")
	check(playing_group("pickup").size() == 1, "common_pickup_started")
	check(playing_group("pickup_rare").size() == 1, "same_cluster_rare_pickup_audible")
	for index in 20:
		audio.play_pickup("singularity")
	check(playing_group("pickup_rare").size() <= 1, "rare_pickup_burst_is_throttled")
	reset_voices()
	audio.play_discovery(true)
	var discoveries := playing_group("discovery")
	check(discoveries.size() == 1, "discovery_started")
	if not discoveries.is_empty():
		var discovery: AudioStreamPlayer = discoveries[0]
		var discovery_stream: AudioStream = discovery.stream
		var start_ms := Time.get_ticks_msec()
		for index in 12:
			if index % 2 == 0:
				audio.play_mining("copper")
			else:
				audio.play_pickup("stone")
			await create_timer(0.06).timeout
		results["overlap_elapsed_ms"] = Time.get_ticks_msec() - start_ms
		results["discovery_playback_seconds"] = discovery.get_playback_position()
		check(discovery.playing and discovery.stream == discovery_stream, "discovery_survives_mining_pickup_overlap")
		check(discovery.get_playback_position() > 0.4, "real_audio_playback_advances")
		await create_timer(0.4).timeout
		check(not discovery.playing, "discovery_completes_without_leaking_voice")
	reset_voices()
	# Saturate the existing ten slots with milestone cues, then try low-priority
	# mining. A new upgrade may replace an equal-priority oldest cue.
	for index in 10:
		audio.get("_last_played_ms").clear()
		audio.play_discovery(true)
	check(playing_group("discovery").size() == 10, "milestone_voice_saturation_fixture")
	audio.play_mining("stone")
	check(playing_group("discovery").size() == 10, "mining_cannot_cut_saturated_milestones")
	audio.play_economy("upgrade")
	check(playing_group("upgrade").size() == 1, "new_upgrade_is_not_silenced")
	check(audio.get("_voices").size() == 10, "voice_pool_remains_bounded")
	audio.set_muted(true)
	var active := 0
	for voice in audio.get("_voices"):
		if voice.playing:
			active += 1
	check(active == 0, "mute_stops_active_feedback")
	results["passed"] = failures.is_empty()
	results["failures"] = failures
	results["engine"] = Engine.get_version_info().string
	results["audio_driver"] = AudioServer.get_driver_name()
	results["physical_iphone_sound_verified"] = false
	FileAccess.open(output_dir.path_join("hero-audio.json"), FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	print("HERO_AUDIO_QA " + JSON.stringify(results))
	# Let the audio mixer release stopped playback objects before tree teardown.
	await create_timer(0.1).timeout
	quit(0 if failures.is_empty() else 1)
