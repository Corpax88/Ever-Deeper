extends Node







const SAMPLE_RATE: = 22050
const VOICE_COUNT: = 10
const FEEDBACK_PRIORITY: = {
	"pickup_rare": 1, "mine_break": 1,
	"ui_confirm": 1, "ui_cancel": 1, "ui_open": 1, "blocked": 1,
	"sell": 2, "build": 2, "transition": 2,
	"upgrade": 3, "discovery": 3,
}
const SETTINGS_PATH: = "user://ever_deeper_audio_v1.json"
const MUSIC_CROSSFADE_SECONDS: = 3.0
const MUSIC_TRACKS: = [
	preload("res://assets/audio/ever-deeper-drift-loop.mp3"),
	preload("res://assets/audio/cozy-hub.mp3"),
	preload("res://assets/audio/cozy-hub-2.mp3"),
]



const MUSIC_TRACK_GAIN_DB: = [7.9, -8.0, -7.5]

const ENVIRONMENT_VOLUME_DB: = {
	"menu": -2.0,
	"surface": 0.0,
	"mine": 1.0,
	"depth": 2.0,
	"hub": 0.0,
	"deepheart": 2.5,
}

const RARE_RESOURCES: = [
	"gold", "starshard", "sunslag", "crownstone", "lunacore",
	"ambercore", "prismite", "phasecrystal", "voidglass", "singularity",
]
const CRYSTAL_RESOURCES: = [
	"moonglass", "starshard", "astralite", "crownstone", "lunacore",
	"prismite", "phasecrystal", "voidglass", "singularity",
]
const METAL_RESOURCES: = [
	"copper", "gold", "rootiron", "burrowsteel", "sunslag",
]

var muted: = false
var current_environment: = "menu"
var ambience_started: = false
var music_volume: = 0.78
var sfx_volume: = 0.86
var _headless: = false
var _voice_index: = 0
var _library: Dictionary = {}
var _last_played_ms: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _music_players: Array[AudioStreamPlayer] = []
var _active_music_slot: = 0
var _music_track_index: = 0
var _next_music_track_index: = 0
var _crossfade_progress: = -1.0
var _rng: = RandomNumberGenerator.new()


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless = DisplayServer.get_name() == "headless"
	_rng.seed = 243150318
	_load_settings()
	_build_library()
	if not _headless:
		_create_players()
	set_process_input(true)


func _input(event: InputEvent) -> void :
	if _headless or muted or ambience_started:
		return
	if (
		event is InputEventScreenTouch
		or event is InputEventMouseButton
		or event is InputEventKey
		or event is InputEventJoypadButton
	):
		_start_ambience()


func _process(delta: float) -> void :
	if _headless or muted or not ambience_started or _music_players.size() < 2:
		return
	var active: = _music_players[_active_music_slot]
	if _crossfade_progress < 0.0:
		active.volume_db = _music_track_db(_music_track_index)
		if not active.playing:
			_start_music_track(_active_music_slot, (_music_track_index + 1) % MUSIC_TRACKS.size(), false)
			return
		var remaining: = active.stream.get_length() - active.get_playback_position()
		if remaining <= MUSIC_CROSSFADE_SECONDS:
			_begin_music_crossfade()
		return
	_crossfade_progress = minf(1.0, _crossfade_progress + delta / MUSIC_CROSSFADE_SECONDS)
	_apply_music_crossfade()
	if _crossfade_progress >= 1.0:
		active.stop()
		_active_music_slot = 1 - _active_music_slot
		_music_track_index = _next_music_track_index
		_crossfade_progress = -1.0
		_music_players[_active_music_slot].volume_db = _music_track_db(_music_track_index)


func set_muted(value: bool) -> void :
	muted = value
	if _headless:
		return
	if muted:
		for player in _music_players:
			player.stop()
		ambience_started = false
		_crossfade_progress = -1.0
		for voice in _voices:
			voice.stop()
	else:
		_start_ambience()


func set_environment(next_environment: String) -> void :
	current_environment = next_environment if ENVIRONMENT_VOLUME_DB.has(next_environment) else "surface"
	_refresh_music_mix()


func set_music_volume(value: float, persist: bool = true) -> void :
	music_volume = clampf(value, 0.0, 1.0)
	if not _headless:
		_refresh_music_mix()
		if music_volume > 0.0 and not muted:
			_start_ambience()
	if persist:
		_save_settings()


func set_sfx_volume(value: float, persist: bool = true) -> void :
	sfx_volume = clampf(value, 0.0, 1.0)
	if persist:
		_save_settings()


func music_volume_percent() -> int:
	return roundi(music_volume * 100.0)


func sfx_volume_percent() -> int:
	return roundi(sfx_volume * 100.0)


func unlock_from_user_gesture() -> void :
	_start_ambience()


func play_mining(material: String = "stone", broken: bool = false, armored: bool = false) -> void :
	var group: = "mine_break" if broken else "mine_shell" if armored else "mine_hit"
	var pitch: = 1.0
	var volume_db: = -8.5
	if material in CRYSTAL_RESOURCES:
		pitch = 1.16
		volume_db = -10.0
	elif material in METAL_RESOURCES:
		pitch = 1.07
	elif material in ["deepstone", "stone", "bedrock"]:
		pitch = 0.94
	if broken:
		volume_db += 1.0
	_play(group, "mining", 92, volume_db, pitch, 0.035)
	if RunState.has_method("record_mining_swing"):
		RunState.record_mining_swing(true)
	if not _headless and (OS.has_feature("mobile") or OS.has_feature("web")):
		Input.vibrate_handheld(26 if broken else 14, 0.46 if broken else 0.24)


func play_pickup(resource_id: String = "stone", amount: int = 1) -> void :
	var rare: = resource_id in RARE_RESOURCES
	var pitch: = 1.0
	if resource_id in CRYSTAL_RESOURCES:
		pitch = 1.1
	elif resource_id in METAL_RESOURCES:
		pitch = 0.98
	if amount > 1:
		pitch += minf(0.1, float(amount - 1) * 0.025)
	# A common drop in the same collection batch must not swallow the rare cue.
	var group: = "pickup_rare" if rare else "pickup"
	_play(group, group, 62, -10.0 if rare else -12.0, pitch, 0.045)


func play_ui(kind: String = "confirm") -> void :
	match kind:
		"cancel":
			_play("ui_cancel", "ui", 70, -13.0, 1.0, 0.02)
		"open", "menu":
			_play("ui_open", "ui", 70, -13.5, 1.0, 0.02)
		_:
			_play("ui_confirm", "ui", 70, -12.5, 1.0, 0.025)


func play_economy(kind: String = "sell") -> void :
	if kind == "upgrade":
		_play("upgrade", "reward", 180, -8.5, 1.0, 0.01)
	elif kind == "build":
		_play("build", "build", 110, -10.0, 1.0, 0.025)
	else:
		_play("sell", "reward", 180, -10.0, 1.0, 0.025)


func play_transition(kind: String = "descend") -> void :
	var pitch: = 0.92 if kind in ["descend", "depth"] else 1.05 if kind in ["ascend", "return"] else 1.0
	_play("transition", "transition", 520, -9.5, pitch, 0.015)


func play_discovery(grand: bool = false) -> void :
	_play("discovery", "discovery", 420, -7.5 if grand else -9.5, 0.94 if grand else 1.0, 0.01)


func play_blocked() -> void :
	_play("blocked", "blocked", 210, -15.0, 1.0, 0.015)


func debug_catalog_snapshot() -> Dictionary:
	var variants: = 0
	for value in _library.values():
		variants += Array(value).size()
	return {
		"groups": _library.size(),
		"variants": variants,
		"sample_rate": SAMPLE_RATE,
		"voice_count": VOICE_COUNT,
		"headless": _headless,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"music_tracks": MUSIC_TRACKS.size(),
		"music_crossfade_seconds": MUSIC_CROSSFADE_SECONDS,
		"music_track_gain_db": MUSIC_TRACK_GAIN_DB.duplicate(),
	}


func _create_players() -> void :
	for _index in range(VOICE_COUNT):
		var voice: = AudioStreamPlayer.new()
		voice.process_mode = Node.PROCESS_MODE_ALWAYS
		voice.max_polyphony = 1

		voice.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		add_child(voice)
		_voices.append(voice)
	for _slot in range(2):
		var music_player: = AudioStreamPlayer.new()
		music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		music_player.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		music_player.volume_db = -80.0
		add_child(music_player)
		_music_players.append(music_player)


func _start_ambience() -> void :
	if _headless or muted or ambience_started or _music_players.size() < 2 or music_volume <= 0.0:
		return
	ambience_started = true
	_active_music_slot = 0
	_music_track_index = 0
	_crossfade_progress = -1.0
	_start_music_track(_active_music_slot, _music_track_index, false)


func _start_music_track(slot: int, track_index: int, fade_in: bool) -> void :
	var player: = _music_players[slot]
	var stream: AudioStream = MUSIC_TRACKS[track_index].duplicate()
	if stream is AudioStreamMP3:
		stream.loop = false
	player.stop()
	player.stream = stream
	player.volume_db = -80.0 if fade_in else _music_track_db(track_index)
	player.play()
	if slot == _active_music_slot:
		_music_track_index = track_index


func _begin_music_crossfade() -> void :
	if _crossfade_progress >= 0.0:
		return
	_next_music_track_index = (_music_track_index + 1) % MUSIC_TRACKS.size()
	_start_music_track(1 - _active_music_slot, _next_music_track_index, true)
	_crossfade_progress = 0.0
	_apply_music_crossfade()


func _apply_music_crossfade() -> void :
	if _music_players.size() < 2 or _crossfade_progress < 0.0:
		return
	var fade_out: = maxf(0.001, 1.0 - _crossfade_progress)
	var fade_in: = maxf(0.001, _crossfade_progress)
	_music_players[_active_music_slot].volume_db = _music_track_db(_music_track_index) + linear_to_db(fade_out)
	_music_players[1 - _active_music_slot].volume_db = _music_track_db(_next_music_track_index) + linear_to_db(fade_in)


func _refresh_music_mix() -> void :
	if _headless or _music_players.is_empty():
		return
	if _crossfade_progress >= 0.0:
		_apply_music_crossfade()
	elif ambience_started:
		_music_players[_active_music_slot].volume_db = _music_track_db(_music_track_index)


func _music_track_db(track_index: int) -> float:
	return _music_db() + float(MUSIC_TRACK_GAIN_DB[track_index])


func _play(
	group: String,
	cooldown_group: String,
	cooldown_ms: int,
	volume_db: float,
	pitch: float,
	pitch_variation: float
) -> void :
	if _headless or muted or sfx_volume <= 0.0 or _voices.is_empty() or not _library.has(group):
		return
	var now: = Time.get_ticks_msec()
	if now - int(_last_played_ms.get(cooldown_group, - cooldown_ms)) < cooldown_ms:
		return
	var variants: Array = _library[group]
	if variants.is_empty():
		return
	var priority: = int(FEEDBACK_PRIORITY.get(group, 0))
	var slot: = _feedback_voice_slot(priority)
	if slot < 0:
		return
	_last_played_ms[cooldown_group] = now
	_start_ambience()
	var voice: = _voices[slot]
	_voice_index = (slot + 1) % _voices.size()
	voice.stop()
	voice.stream = variants[_rng.randi_range(0, variants.size() - 1)]
	voice.volume_db = volume_db + linear_to_db(maxf(0.001, sfx_volume)) + _rng.randf_range(-0.7, 0.45)
	voice.pitch_scale = maxf(0.55, pitch + _rng.randf_range( - pitch_variation, pitch_variation))
	voice.set_meta("feedback_priority", priority)
	voice.set_meta("feedback_started_ms", now)
	voice.play()


func _feedback_voice_slot(priority: int) -> int:
	# Reuse completed sounds first. Blind rotation cuts long milestone cues even
	# while shorter mining and pickup voices elsewhere in this pool are idle.
	for offset in _voices.size():
		var slot: = (_voice_index + offset) % _voices.size()
		if not _voices[slot].playing:
			return slot
	var selected: = -1
	var lowest_priority: = priority
	var oldest_ms: = 0
	for offset in _voices.size():
		var slot: = (_voice_index + offset) % _voices.size()
		var voice: = _voices[slot]
		var voice_priority: = int(voice.get_meta("feedback_priority", 0))
		if voice_priority > priority:
			continue
		var started_ms: = int(voice.get_meta("feedback_started_ms", 0))
		if selected < 0 or voice_priority < lowest_priority or (voice_priority == lowest_priority and started_ms < oldest_ms):
			selected = slot
			lowest_priority = voice_priority
			oldest_ms = started_ms
	return selected


func _build_library() -> void :
	_library = {
		"mine_hit": [],
		"mine_shell": [],
		"mine_break": [],
		"pickup": [],
		"pickup_rare": [],
		"ui_confirm": [],
		"ui_cancel": [],
		"ui_open": [],
		"sell": [],
		"upgrade": [],
		"build": [],
		"transition": [],
		"discovery": [],
		"blocked": [],
	}
	for variant in range(4):
		_library.mine_hit.append(_make_mining_stream(variant, false, false))
	for variant in range(3):
		_library.mine_shell.append(_make_mining_stream(variant, false, true))
		_library.mine_break.append(_make_mining_stream(variant, true, false))
		_library.pickup.append(_make_pickup_stream(variant, false))
		_library.pickup_rare.append(_make_pickup_stream(variant, true))
	for variant in range(2):
		_library.ui_confirm.append(_make_ui_stream(variant, "confirm"))
		_library.ui_cancel.append(_make_ui_stream(variant, "cancel"))
		_library.ui_open.append(_make_ui_stream(variant, "open"))
	_library.sell.append(_make_reward_stream("sell"))
	_library.upgrade.append(_make_reward_stream("upgrade"))
	_library.build.append(_make_reward_stream("build"))
	_library.transition.append(_make_transition_stream())
	_library.discovery.append(_make_discovery_stream())
	_library.blocked.append(_make_blocked_stream())


func _make_mining_stream(variant: int, broken: bool, armored: bool) -> AudioStreamWAV:
	var duration: = 0.32 if broken else 0.19 + float(variant) * 0.012
	var seed: = 17 + variant * 23 + (91 if broken else 0) + (47 if armored else 0)
	return _make_stream(duration, func(t: float, progress: float, frame: int) -> float:
		var attack: = minf(1.0, t / 0.005)
		var decay: = pow(maxf(0.0, 1.0 - progress), 2.7 if not broken else 1.9)
		var grit: = _noise(frame, seed) * exp(-21.0 * t)
		var body_frequency: = (155.0 if broken else 205.0) + float(variant) * 13.0
		var body: = sin(TAU * body_frequency * t + t * t * 31.0) * exp(-13.0 * t)


		var ring_frequency: = (1320.0 if armored else 1040.0) + float(variant) * 53.0
		var ring: = sin(TAU * ring_frequency * t) * exp((-9.2 if armored else -12.5) * t)
		ring += sin(TAU * ring_frequency * 1.492 * t + 0.4) * exp(-16.0 * t) * 0.48
		ring += sin(TAU * ring_frequency * 2.087 * t + 1.1) * exp(-23.0 * t) * 0.24
		var crack: = 0.0
		if broken:
			for offset in [0.045, 0.083, 0.126]:
				var local_t: = t - float(offset)
				if local_t >= 0.0:
					crack += _noise(frame, seed + roundi(float(offset) * 1000.0)) * exp(-39.0 * local_t) * 0.19
		var mix: = grit * (0.42 if armored else 0.5) + body * 0.31 + ring * (0.4 if armored else 0.29) + crack
		return mix * attack * decay
	)


func _music_db() -> float:
	if muted or music_volume <= 0.0:
		return -80.0
	return float(ENVIRONMENT_VOLUME_DB[current_environment]) + linear_to_db(music_volume)


func _load_settings() -> void :
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file: = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		music_volume = clampf(float(parsed.get("music", music_volume)), 0.0, 1.0)
		sfx_volume = clampf(float(parsed.get("sfx", sfx_volume)), 0.0, 1.0)


func _save_settings() -> void :
	var file: = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"music": music_volume, "sfx": sfx_volume}))


func _make_pickup_stream(variant: int, rare: bool) -> AudioStreamWAV:
	var duration: = 0.34 if rare else 0.24
	var base: = (690.0 if rare else 520.0) + float(variant) * 38.0
	return _make_stream(duration, func(t: float, progress: float, _frame: int) -> float:
		var envelope: = minf(1.0, t / 0.008) * pow(maxf(0.0, 1.0 - progress), 2.0)
		var first: = sin(TAU * (base + t * 240.0) * t) * exp(-7.2 * t)
		var second_t: = maxf(0.0, t - 0.062)
		var second: = sin(TAU * base * (1.5 if rare else 1.34) * second_t) * exp(-9.0 * second_t) if t >= 0.062 else 0.0
		var shimmer: = sin(TAU * base * 2.03 * t) * exp(-12.0 * t)
		return (first * 0.42 + second * 0.34 + shimmer * 0.13) * envelope
	)


func _make_ui_stream(variant: int, kind: String) -> AudioStreamWAV:
	var duration: = 0.16 if kind == "open" else 0.11
	var frequency: = (410.0 if kind == "cancel" else 740.0 if kind == "confirm" else 545.0) + variant * 24.0
	return _make_stream(duration, func(t: float, progress: float, _frame: int) -> float:
		var sweep: = 1.0 + (0.18 * progress if kind == "open" else -0.1 * progress if kind == "cancel" else 0.07 * progress)
		var envelope: = minf(1.0, t / 0.004) * pow(maxf(0.0, 1.0 - progress), 2.4)
		return (sin(TAU * frequency * sweep * t) * 0.35 + sin(TAU * frequency * 2.0 * t) * 0.09) * envelope
	)


func _make_reward_stream(kind: String) -> AudioStreamWAV:
	var duration: = 0.62 if kind == "upgrade" else 0.44 if kind == "sell" else 0.27
	return _make_stream(duration, func(t: float, progress: float, frame: int) -> float:
		var mix: = 0.0
		if kind == "upgrade":
			var notes: = [392.0, 523.25, 659.25, 783.99]
			for index in notes.size():
				var local_t: = t - float(index) * 0.105
				if local_t >= 0.0:
					mix += sin(TAU * float(notes[index]) * local_t) * exp(-7.4 * local_t) * 0.25
					mix += sin(TAU * float(notes[index]) * 2.0 * local_t) * exp(-11.0 * local_t) * 0.055
		elif kind == "sell":
			for index in range(5):
				var local_t: = t - float(index) * 0.052
				if local_t >= 0.0:
					var coin_frequency: = 1320.0 + float(index) * 155.0
					mix += sin(TAU * coin_frequency * local_t) * exp(-25.0 * local_t) * 0.23
					mix += _noise(frame, 80 + index) * exp(-42.0 * local_t) * 0.035
		else:
			mix = sin(TAU * 145.0 * t) * exp(-12.0 * t) * 0.45
			mix += sin(TAU * 610.0 * t) * exp(-17.0 * t) * 0.16
			mix += _noise(frame, 211) * exp(-25.0 * t) * 0.13
		return mix * minf(1.0, t / 0.005) * pow(maxf(0.0, 1.0 - progress), 0.72)
	)


func _make_transition_stream() -> AudioStreamWAV:
	return _make_stream(0.82, func(t: float, progress: float, frame: int) -> float:
		var bell_envelope: = sin(PI * clampf(progress, 0.0, 1.0))
		var whoosh: = _noise(frame, 313) * sin(PI * progress) * 0.16
		var low: = sin(TAU * (92.0 + progress * 48.0) * t) * bell_envelope * 0.2
		var high: = sin(TAU * (365.0 + progress * 210.0) * t) * bell_envelope * 0.1
		return whoosh + low + high
	)


func _make_discovery_stream() -> AudioStreamWAV:
	return _make_stream(0.92, func(t: float, progress: float, _frame: int) -> float:
		var mix: = 0.0
		var notes: = [261.63, 392.0, 523.25, 659.25]
		for index in notes.size():
			var local_t: = t - float(index) * 0.115
			if local_t >= 0.0:
				mix += sin(TAU * float(notes[index]) * local_t) * exp(-4.3 * local_t) * 0.18
				mix += sin(TAU * float(notes[index]) * 2.01 * local_t) * exp(-7.0 * local_t) * 0.035
		return mix * minf(1.0, t / 0.012) * pow(maxf(0.0, 1.0 - progress), 0.55)
	)


func _make_blocked_stream() -> AudioStreamWAV:
	return _make_stream(0.15, func(t: float, progress: float, frame: int) -> float:
		var envelope: = minf(1.0, t / 0.004) * pow(maxf(0.0, 1.0 - progress), 2.8)
		return (sin(TAU * 132.0 * t) * 0.34 + _noise(frame, 404) * exp(-26.0 * t) * 0.15) * envelope
	)


func _make_stream(duration: float, sample_function: Callable) -> AudioStreamWAV:
	var frame_count: = maxi(1, roundi(duration * float(SAMPLE_RATE)))
	var bytes: = PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in range(frame_count):
		var t: = float(frame) / float(SAMPLE_RATE)
		var progress: = float(frame) / float(maxi(1, frame_count - 1))
		var sample: = clampf(float(sample_function.call(t, progress, frame)), -0.96, 0.96)
		bytes.encode_s16(frame * 2, roundi(sample * 32767.0))
	var stream: = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _noise(frame: int, seed: int) -> float:
	var value: = sin(float(frame * 41 + seed * 131) * 12.9898) * 43758.5453
	return fposmod(value, 2.0) - 1.0
