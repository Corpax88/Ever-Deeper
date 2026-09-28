extends RefCounted

func run() -> Dictionary:
	if AudioDirector._music_players.size() != 2:
		return {"exact":false,"error":"Expected both production music players"}
	var saved_environment: String = AudioDirector.current_environment
	var saved_volume: float = AudioDirector.music_volume
	var saved_slot: int = AudioDirector._active_music_slot
	var saved_index: int = AudioDirector._music_track_index
	var saved_next: int = AudioDirector._next_music_track_index
	var saved_fade: float = AudioDirector._crossfade_progress
	var saved_requests: Dictionary = AudioDirector._music_gain_requests.duplicate(true)
	var saved_gains: Array = []
	for player in AudioDirector._music_players: saved_gains.append(player.volume_db)
	var rows: Array = []
	var exact: bool = true
	var reference: AudioStreamPlayer = AudioStreamPlayer.new()
	for environment in ["surface","mine","depth","hub","deepheart","menu"]:
		for volume in [0.0,0.37,0.78,1.0]:
			AudioDirector.current_environment = environment
			AudioDirector.music_volume = volume
			for track in 3:
				var value: float = AudioDirector._music_track_db(track)
				reference.volume_db = value
				for slot in 2:
					var player: AudioStreamPlayer = AudioDirector._music_players[slot]
					AudioDirector._set_music_gain(player,value)
					AudioDirector._set_music_gain(player,value)
					var equal: bool = player.volume_db == reference.volume_db
					# A direct external property write must not be hidden by the cache.
					player.volume_db = -50.0
					AudioDirector._set_music_gain(player,value)
					equal = equal and player.volume_db == reference.volume_db
					exact = exact and equal
					rows.append({"environment":environment,"volume":volume,"track":track,"slot":slot,"exact":equal})
	AudioDirector._music_track_index = 0
	AudioDirector._next_music_track_index = 1
	AudioDirector.music_volume = 0.78
	for active_slot in 2:
		AudioDirector._active_music_slot = active_slot
		for fade in [0.0,0.2,0.5,0.8,1.0]:
			AudioDirector._crossfade_progress = fade
			AudioDirector._apply_music_crossfade()
			var fade_out: float = maxf(0.001,1.0-fade)
			var fade_in: float = maxf(0.001,fade)
			for slot in 2:
				var outgoing: bool = slot == active_slot
				reference.volume_db = AudioDirector._music_track_db(0 if outgoing else 1)+linear_to_db(fade_out if outgoing else fade_in)
				var equal: bool = AudioDirector._music_players[slot].volume_db == reference.volume_db
				exact = exact and equal
				rows.append({"fade":fade,"slot":slot,"active_slot":active_slot,"exact":equal})
	AudioDirector.current_environment = saved_environment
	AudioDirector.music_volume = saved_volume
	AudioDirector._active_music_slot = saved_slot
	AudioDirector._music_track_index = saved_index
	AudioDirector._next_music_track_index = saved_next
	AudioDirector._crossfade_progress = saved_fade
	for slot in saved_gains.size(): AudioDirector._set_music_gain(AudioDirector._music_players[slot],saved_gains[slot])
	AudioDirector._music_gain_requests = saved_requests
	var restored: bool = AudioDirector._music_gain_requests == saved_requests
	for slot in saved_gains.size(): restored = restored and AudioDirector._music_players[slot].volume_db == saved_gains[slot]
	exact = exact and restored
	reference.free()
	return {"exact":exact,"restored":restored,"rows":rows,"scope":"Exact stored music gains in both slots, direct-edit invalidation and crossfade endpoints with either active slot; bus-change/playback lifecycle is outside this helper fixture; no SFX or saved settings edited"}
