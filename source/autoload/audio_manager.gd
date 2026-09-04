extends Node

signal compressor_started(count: int)
signal sfx_played(sfx_id: StringName)

const COMPRESSOR_INTERVAL := 12.0

var _sfx: Dictionary = {}
var _music: Dictionary = {}
var _ambience_weights: Dictionary = {}
var _compressor_count: int = 0
var _compressor_timer: Timer
var _ambience_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer


func _ready() -> void:
	_ensure_audio_buses()
	_ambience_player = _make_player("AmbiencePlayer", &"Ambience")
	_ambience_player.stream = _create_compressor_hum()
	_ambience_player.volume_db = -20.0
	_ambience_player.play()
	_music_player = _make_player("MusicPlayer", &"Music")
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
	player.stream = _sfx.get(sfx_id, _create_tone(_tone_for_id(sfx_id), 0.12, 0.18))
	player.finished.connect(player.queue_free)
	player.play()


func play_music(music_id: StringName, fade_seconds: float = 0.4) -> void:
	var stream: AudioStream = _music.get(music_id)
	if stream == null:
		return
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -30.0, maxf(fade_seconds, 0.0))
	await tween.finished
	_music_player.stream = stream
	_music_player.play()
	create_tween().tween_property(_music_player, "volume_db", 0.0, maxf(fade_seconds, 0.0))


func set_ambience_layer(layer_id: StringName, weight: float) -> void:
	_ambience_weights[layer_id] = clampf(weight, 0.0, 1.0)
	if layer_id == &"compressor" and is_instance_valid(_ambience_player):
		_ambience_player.volume_db = lerpf(-40.0, -16.0, _ambience_weights[layer_id])


func get_ambience_weight(layer_id: StringName) -> float:
	return float(_ambience_weights.get(layer_id, 0.0))


func get_compressor_count() -> int:
	return _compressor_count


func stop_all() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()


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
	if is_instance_valid(_compressor_timer):
		_compressor_timer.start()
	call_deferred("_on_compressor_cycle")


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
	match sfx_id:
		&"compressor_start": return 58.0
		&"pickup": return 660.0
		&"interact_short": return 440.0
		&"interact_hold": return 330.0
		&"sticky_enter": return 120.0
		&"sticky_exit": return 180.0
		&"frost_touch": return 880.0
		&"barrier_break": return 240.0
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
