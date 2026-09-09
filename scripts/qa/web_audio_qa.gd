extends Node
## Opt-in browser audit. Calls the real AudioDirector without replacing its backend.
var _callback: JavaScriptObject
var _audio: Node

func run(_main: Node) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web") or not OS.has_feature("ever_deeper_dev"):
		push_error("WEB_AUDIO_QA requires an actual DEV web export")
		get_tree().quit(2)
		return
	var state: Node = get_node("/root/RunState")
	state.initialize_persistence("user://one-point-zero-web-audio-qa.json")
	_audio = get_node("/root/AudioDirector")
	_audio.set_muted(true)
	_audio.set_music_volume(0.0, false)
	_audio.set_sfx_volume(1.0, false)
	_audio.set_muted(false)
	# Freeze gameplay, while AudioDirector and its real players keep ALWAYS mode.
	get_tree().paused = true
	_callback = JavaScriptBridge.create_callback(_command)
	var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	window.everDeeperAudioReviewCommand = _callback
	_snapshot("ready")
	print("WEB_AUDIO_QA_READY")

func _command(arguments: Array) -> void:
	if arguments.is_empty():
		return
	var operation: String = str(arguments[0])
	match operation:
		"reset":
			for voice in _audio.get("_voices"):
				voice.stop()
			_audio.get("_last_played_ms").clear()
			_audio.set("_voice_index", 0)
			_audio.set_muted(false)
		"cluster":
			_audio.play_pickup("stone")
			_audio.play_pickup("singularity")
			for index in 20:
				_audio.play_pickup("singularity")
		"discovery": _audio.play_discovery(true)
		"mining": _audio.play_mining("copper")
		"pickup": _audio.play_pickup("stone")
		"upgrade": _audio.play_economy("upgrade")
		"mute", "finish": _audio.set_muted(true)
		"unmute": _audio.set_muted(false)
		"snapshot": pass
		_:
			push_error("WEB_AUDIO_QA unknown operation: " + operation)
	_snapshot(operation)

func _snapshot(operation: String) -> void:
	var voices: Array = _audio.get("_voices")
	var library: Dictionary = _audio.get("_library")
	var playing: Array[Dictionary] = []
	var sample_backend := true
	for slot in voices.size():
		var voice: AudioStreamPlayer = voices[slot]
		sample_backend = sample_backend and voice.playback_type == AudioServer.PLAYBACK_TYPE_SAMPLE
		if not voice.playing:
			continue
		var group := "unknown"
		for key in library:
			if voice.stream in library[key]:
				group = str(key)
				break
		playing.append({"slot": slot, "group": group, "position": voice.get_playback_position()})
	var snapshot := {"operation": operation, "playing": playing, "voices": voices.size(), "sample_backend": sample_backend, "headless": _audio.get("_headless"), "muted": _audio.muted, "driver": AudioServer.get_driver_name(), "version": PremiumMenu.release_version()}
	JavaScriptBridge.eval("window.everDeeperAudioReviewState=" + JSON.stringify(snapshot), true)
