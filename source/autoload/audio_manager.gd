extends Node

signal compressor_started(count: int)
signal sfx_played(sfx_id: StringName)

const COMPRESSOR_INTERVAL := 12.0
const AUDIO_ROOT := "res://assets/audio/"
const BACKGROUND_ROOT := "res://assets/audio/background/"

var _sfx: Dictionary = {}
var _sfx_variants: Dictionary = {}
var _music: Dictionary = {}
var _background_tracks: Dictionary = {}
var _ambience_weights: Dictionary = {}
var _compressor_count: int = 0
var _compressor_timer: Timer
var _ambience_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _background_current_layer := -1
var _background_pending_layer := 0
var _background_intro_active := false
var _ending_music_active := false
var _music_request_id := 0
var _opening_generation := 0


func _ready() -> void:
	_ensure_audio_buses()
	_load_runtime_audio()
	_ambience_player = _make_player("AmbiencePlayer", &"Ambience")
	_ambience_player.stream = _load_audio_file(&"ambience", &"amb_fridge_compressor_loop.ogg")
	if _ambience_player.stream == null:
		_ambience_player.stream = _create_compressor_hum()
	_ambience_player.volume_db = -20.0
	_ambience_player.play()
	_music_player = _make_player("MusicPlayer", &"Music")
	_music_player.finished.connect(_on_music_finished)
	_compressor_timer = Timer.new()
	_compressor_timer.name = "CompressorTimer"
	_compressor_timer.wait_time = COMPRESSOR_INTERVAL
	_compressor_timer.one_shot = false
	_compressor_timer.autostart = true
	_compressor_timer.timeout.connect(_on_compressor_cycle)
	add_child(_compressor_timer)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.run_reset.connect(_on_run_reset)


func register_sfx(sfx_id: StringName, stream: AudioStream) -> void:
	_sfx[sfx_id] = stream


func register_music(music_id: StringName, stream: AudioStream) -> void:
	_music[music_id] = stream


func play_sfx(sfx_id: StringName) -> void:
	sfx_played.emit(sfx_id)
	var player := _make_player("SFX_%s" % sfx_id, &"SFX")
	var stream := _resolve_sfx(sfx_id)
	player.stream = stream if stream != null else _create_tone(_tone_for_id(sfx_id), 0.12, 0.18)
	player.finished.connect(player.queue_free)
	player.play()


func play_music(music_id: StringName, fade_seconds: float = 0.4) -> void:
	var stream := _resolve_music(music_id)
	if stream == null:
		return
	_music_request_id += 1
	var request_id := _music_request_id
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -30.0, maxf(fade_seconds, 0.0))
	await tween.finished
	if request_id != _music_request_id or not is_instance_valid(_music_player):
		return
	_music_player.stream = stream
	_music_player.play()
	create_tween().tween_property(_music_player, "volume_db", 0.0, maxf(fade_seconds, 0.0))


func set_background_layer(layer_index: int) -> void:
	if _ending_music_active:
		return
	var clamped_layer := clampi(layer_index, 0, 6)
	_background_pending_layer = clamped_layer
	if _background_intro_active or _background_current_layer == clamped_layer:
		return
	_apply_background_layer(clamped_layer)


func get_background_layer() -> int:
	return _background_current_layer


func set_ambience_layer(layer_id: StringName, weight: float) -> void:
	_ambience_weights[layer_id] = clampf(weight, 0.0, 1.0)
	if layer_id == &"compressor" and is_instance_valid(_ambience_player):
		_ambience_player.volume_db = lerpf(-40.0, -16.0, _ambience_weights[layer_id])


func get_ambience_weight(layer_id: StringName) -> float:
	return float(_ambience_weights.get(layer_id, 0.0))


func get_compressor_count() -> int:
	return _compressor_count


func stop_all() -> void:
	_music_request_id += 1
	_opening_generation += 1
	_background_current_layer = -1
	_background_intro_active = false
	for child in get_children():
		if child is AudioStreamPlayer:
			if child == _ambience_player or child == _music_player:
				child.stop()
			else:
				child.queue_free()


func play_ending_music(category: String) -> void:
	_opening_generation += 1
	_ending_music_active = true
	_background_intro_active = false
	_background_current_layer = -1
	var music_id := &"music_ending_solemn_sting"
	match category:
		"eldritch": music_id = &"music_ending_eldritch"
		"comedy": music_id = &"music_ending_nailong"
		"warm", "crown": music_id = &"music_ending_balcony_warm"
		"symbiosis": music_id = &"music_symbiosis_layer_03"
		"corporate", "harvest": music_id = &"music_ending_comic_8bit"
		"frost": music_id = &"music_ending_solemn_sting"
		"root": music_id = &"music_root_pulse_loop"
		"landfill": music_id = &"music_credits_loop"
	play_music(music_id, 0.25)


func _on_compressor_cycle() -> void:
	_compressor_count += 1
	compressor_started.emit(_compressor_count)
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.increment_counter(&"compressor_start_count")
	play_sfx(&"compressor_start")
	if is_instance_valid(_ambience_player):
		_ambience_player.volume_db = -10.0
		create_tween().tween_property(_ambience_player, "volume_db", -20.0, 1.2)


func _on_run_reset(_run_number: int) -> void:
	_compressor_count = 0
	_opening_generation += 1
	_ending_music_active = false
	_background_current_layer = -1
	_background_pending_layer = 0
	if is_instance_valid(_ambience_player) and not _ambience_player.playing:
		_ambience_player.play()
	if is_instance_valid(_compressor_timer):
		_compressor_timer.start()
	call_deferred("_on_compressor_cycle")
	_start_opening_music()


func _load_runtime_audio() -> void:
	_load_audio_folder(&"sfx", _sfx, true)
	_load_audio_folder(&"music", _music, false)
	_load_background_audio()


func _load_background_audio() -> void:
	_background_tracks.clear()
	var directory := DirAccess.open(BACKGROUND_ROOT)
	if directory == null:
		return
	for file_name in directory.get_files():
		if not (file_name.ends_with(".wav") or file_name.ends_with(".ogg")):
			continue
		var prefix := file_name.substr(0, 2)
		if not prefix.is_valid_int():
			continue
		var stream := load(BACKGROUND_ROOT + file_name) as AudioStream
		if stream != null:
			_background_tracks[int(prefix)] = stream


func _start_opening_music() -> void:
	var generation := _opening_generation
	var intro := _resolve_music(&"music_mythic_ambience_loop")
	if intro == null:
		_background_intro_active = false
		_apply_background_layer(_background_pending_layer)
		return
	_background_intro_active = true
	play_music(&"music_mythic_ambience_loop", 0.35)
	var intro_length := maxf(intro.get_length(), 0.0)
	if intro_length <= 0.05:
		_background_intro_active = false
		_apply_background_layer(_background_pending_layer)
		return
	var timer := get_tree().create_timer(intro_length + 0.35, true)
	timer.timeout.connect(_finish_opening_music.bind(generation), CONNECT_ONE_SHOT)


func _finish_opening_music(generation: int) -> void:
	if _ending_music_active or generation != _opening_generation:
		return
	_background_intro_active = false
	_apply_background_layer(_background_pending_layer)


func _apply_background_layer(layer_index: int) -> void:
	if _ending_music_active:
		return
	var stream := _background_tracks.get(layer_index) as AudioStream
	if stream == null:
		return
	_background_current_layer = layer_index
	_music_request_id += 1
	var request_id := _music_request_id
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -30.0, 0.35)
	await tween.finished
	if request_id != _music_request_id or not is_instance_valid(_music_player):
		return
	_music_player.stream = stream
	_music_player.play()
	create_tween().tween_property(_music_player, "volume_db", 0.0, 0.35)


func _on_music_finished() -> void:
	if _ending_music_active or _background_intro_active or _background_current_layer < 0:
		return
	if is_instance_valid(_music_player):
		_music_player.play()


func _load_audio_folder(folder: StringName, target: Dictionary, strip_prefix: bool) -> void:
	var directory := DirAccess.open("%s%s" % [AUDIO_ROOT, str(folder)])
	if directory == null:
		return
	for file_name in directory.get_files():
		if not (file_name.ends_with(".wav") or file_name.ends_with(".ogg")):
			continue
		var stream := load("%s%s/%s" % [AUDIO_ROOT, str(folder), file_name]) as AudioStream
		if stream == null:
			continue
		var stem := file_name.get_basename()
		var id := stem
		if strip_prefix and id.begins_with("sfx_"):
			id = id.trim_prefix("sfx_")
		elif not strip_prefix and id.begins_with("music_"):
			id = id.trim_prefix("music_")
		target[StringName(id)] = stream
		if strip_prefix and id.length() > 3 and id.substr(id.length() - 3, 1) == "_" and id.substr(id.length() - 2).is_valid_int():
			var base := id.substr(0, id.length() - 3)
			if not _sfx_variants.has(base):
				_sfx_variants[base] = []
			if stream not in _sfx_variants[base]:
				_sfx_variants[base].append(stream)


func _load_audio_file(folder: StringName, file_name: StringName) -> AudioStream:
	return load("%s%s/%s" % [AUDIO_ROOT, str(folder), str(file_name)]) as AudioStream


func _resolve_sfx(sfx_id: StringName) -> AudioStream:
	var key := str(sfx_id)
	if _sfx.has(sfx_id):
		return _sfx[sfx_id] as AudioStream
	if _sfx_variants.has(key):
		var variants: Array = _sfx_variants[key]
		if not variants.is_empty():
			return variants[Time.get_ticks_msec() % variants.size()] as AudioStream
	var alias := key
	if alias.begins_with("sfx_"):
		alias = alias.trim_prefix("sfx_")
	if _sfx.has(alias):
		return _sfx[StringName(alias)] as AudioStream
	if _sfx_variants.has(alias):
		var alias_variants: Array = _sfx_variants[alias]
		if not alias_variants.is_empty():
			return alias_variants[Time.get_ticks_msec() % alias_variants.size()] as AudioStream
	# Gameplay ids historically used an unpadded index (ritual_step_1),
	# while delivered files follow the artist-friendly _01 convention.
	if alias.length() > 2 and alias.substr(alias.length() - 2, 1) == "_":
		var digit := alias.substr(alias.length() - 1)
		if digit.is_valid_int():
			var padded := "%s_0%s" % [alias.substr(0, alias.length() - 2), digit]
			if _sfx.has(StringName(padded)):
				return _sfx[StringName(padded)] as AudioStream
	match sfx_id:
		&"pickup", &"interact_hold": return _sfx.get(&"item_absorb") as AudioStream
		&"interact_short": return _sfx.get(&"item_discover") as AudioStream
		&"barrier_break": return _sfx.get(&"plastic_film_break_01") as AudioStream
		&"hard_hit": return _sfx.get(&"glass_impact_01") as AudioStream
		&"effect_warning": return _sfx.get(&"electric_node_error") as AudioStream
		&"effect_unlock": return _sfx.get(&"eldritch_eye_open_01") as AudioStream
		&"sprint": return _sfx.get(&"sprout_move_stop") as AudioStream
	return null


func _resolve_music(music_id: StringName) -> AudioStream:
	if _music.has(music_id):
		return _music[music_id] as AudioStream
	var key := str(music_id)
	if key.begins_with("music_"):
		key = key.trim_prefix("music_")
	if _music.has(key):
		return _music[StringName(key)] as AudioStream
	return null


func _make_player(player_name: String, bus_name: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	add_child(player)
	return player


func _ensure_audio_buses() -> void:
	for bus_name in [&"Music", &"Ambience", &"SFX", &"UI"]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _tone_for_id(sfx_id: StringName) -> float:
	if str(sfx_id).begins_with("ritual_step_"):
		return 420.0 + float(str(sfx_id).get_slice("_", 2).to_int()) * 90.0
	match sfx_id:
		&"compressor_start": return 58.0
		&"pickup": return 660.0
		&"interact_short": return 440.0
		&"interact_hold": return 330.0
		&"sticky_enter": return 120.0
		&"sticky_exit": return 180.0
		&"frost_touch": return 880.0
		&"sprint": return 180.0
		&"effect_unlock": return 740.0
		&"effect_warning": return 90.0
		&"barrier_break": return 240.0
		&"milk_do": return 261.63
		&"milk_re": return 293.66
		&"milk_mi": return 329.63
		_: return 520.0


func _create_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var frame_count := maxi(roundi(duration * sample_rate), 1)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in range(frame_count):
		var fade := 1.0 - float(frame) / float(frame_count)
		var value := sin(TAU * frequency * float(frame) / float(sample_rate)) * volume * fade
		var sample := clampi(roundi(value * 32767.0), -32768, 32767)
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream


func _create_compressor_hum() -> AudioStreamWAV:
	var stream := _create_tone(58.0, 2.0, 0.11)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	return stream
