extends Node

## AudioManager - Universal SpongeBob Nautical Sound System & Music Conductor
## Manages seamless looping BGM, polyphonic SFX pooling, footstep squeaks, and fanfares.

signal bgm_changed(track_name: String)

var bgm_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var footstep_player: AudioStreamPlayer

const SFX_POOL_SIZE: int = 16
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_pool_idx: int = 0

var current_bgm_track: String = ""
var bgm_fade_tween: Tween = null

var bgm_streams: Dictionary = {}
var sfx_streams: Dictionary = {}

var is_audio_initialized: bool = false
var footstep_cooldown: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_nodes()
	_load_all_audio_streams()
	_sync_volumes()
	is_audio_initialized = true

func _setup_audio_nodes() -> void:
	# 1. Background Music Player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# 2. Voice & Fanfare Player
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.bus = "Master"
	add_child(voice_player)
	
	# 3. SpongeBob Footstep Squeaker Player
	footstep_player = AudioStreamPlayer.new()
	footstep_player.name = "FootstepPlayer"
	footstep_player.bus = "Master"
	add_child(footstep_player)
	
	# 4. Polyphonic SFX Pool (16 players)
	sfx_pool.clear()
	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)

func _load_all_audio_streams() -> void:
	var bgm_files = {
		"main_menu": "res://assets/audio/bgm/bgm_main_menu.wav",
		"lobby": "res://assets/audio/bgm/bgm_lobby.wav",
		"zone1_outskirts": "res://assets/audio/bgm/bgm_zone1_outskirts.wav",
		"zone2_krusty": "res://assets/audio/bgm/bgm_zone2_krusty.wav",
		"zone3_squidward": "res://assets/audio/bgm/bgm_zone3_squidward.wav",
		"infinity": "res://assets/audio/bgm/bgm_infinity.wav",
		"victory": "res://assets/audio/bgm/bgm_victory.wav",
		"defeat": "res://assets/audio/bgm/bgm_defeat.wav"
	}
	
	for track_id in bgm_files.keys():
		var path: String = bgm_files[track_id]
		var is_looping = (track_id != "victory" and track_id != "defeat")
		var stream = load_wav_file(path, is_looping)
		if stream:
			bgm_streams[track_id] = stream
			
	var sfx_files = {
		"footstep_squeak": "res://assets/audio/sfx/sfx_footstep_squeak.wav",
		"jump": "res://assets/audio/sfx/sfx_jump.wav",
		"teleport": "res://assets/audio/sfx/sfx_teleport.wav",
		"tower_place": "res://assets/audio/sfx/sfx_tower_place.wav",
		"tower_upgrade": "res://assets/audio/sfx/sfx_tower_upgrade.wav",
		"tower_sell": "res://assets/audio/sfx/sfx_tower_sell.wav",
		"bubble_shoot": "res://assets/audio/sfx/sfx_bubble_shoot.wav",
		"bubble_pop": "res://assets/audio/sfx/sfx_bubble_pop.wav",
		"boulder_throw": "res://assets/audio/sfx/sfx_boulder_throw.wav",
		"boulder_impact": "res://assets/audio/sfx/sfx_boulder_impact.wav",
		"clarinet_blast": "res://assets/audio/sfx/sfx_clarinet_blast.wav",
		"spatula_hit": "res://assets/audio/sfx/sfx_spatula_hit.wav",
		"karate_chop": "res://assets/audio/sfx/sfx_karate_chop.wav",
		"money_fountain": "res://assets/audio/sfx/sfx_money_fountain.wav",
		"meow": "res://assets/audio/sfx/sfx_meow.wav",
		"plankton_laser": "res://assets/audio/sfx/sfx_plankton_laser.wav",
		"enemy_spawn": "res://assets/audio/sfx/sfx_enemy_spawn.wav",
		"enemy_hit": "res://assets/audio/sfx/sfx_enemy_hit.wav",
		"enemy_death": "res://assets/audio/sfx/sfx_enemy_death.wav",
		"boss_alert": "res://assets/audio/sfx/sfx_boss_alert.wav",
		"base_damage": "res://assets/audio/sfx/sfx_base_damage.wav",
		"ui_click": "res://assets/audio/sfx/sfx_ui_click.wav",
		"ui_open": "res://assets/audio/sfx/sfx_ui_open.wav",
		"ui_close": "res://assets/audio/sfx/sfx_ui_close.wav",
		"coins": "res://assets/audio/sfx/sfx_coins.wav",
		"gems": "res://assets/audio/sfx/sfx_gems.wav",
		"summon_pull": "res://assets/audio/sfx/sfx_summon_pull.wav",
		"trait_reroll": "res://assets/audio/sfx/sfx_trait_reroll.wav",
		"stage_enter": "res://assets/audio/sfx/sfx_stage_enter.wav"
	}
	
	for sfx_id in sfx_files.keys():
		var path: String = sfx_files[sfx_id]
		var stream = load_wav_file(path, false)
		if stream:
			sfx_streams[sfx_id] = stream

func load_wav_file(path: String, loop: bool = false) -> AudioStreamWAV:
	# 1. Direct binary WAV byte reading FIRST (guarantees freshly synthesized audio from disk is loaded immediately, never stale cache!)
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var bytes: PackedByteArray = file.get_buffer(file.get_length())
			file.close()
			if bytes.size() >= 44:
				var data_pos: int = 44
				for i in range(12, bytes.size() - 8):
					if bytes[i] == 100 and bytes[i+1] == 97 and bytes[i+2] == 116 and bytes[i+3] == 97: # 'data'
						data_pos = i + 8
						break
				var raw_samples: PackedByteArray = bytes.slice(data_pos)
				var stream = AudioStreamWAV.new()
				stream.format = AudioStreamWAV.FORMAT_16_BITS
				stream.mix_rate = 44100
				stream.stereo = false
				stream.data = raw_samples
				if loop:
					stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
					stream.loop_begin = 0
					stream.loop_end = raw_samples.size() / 2
				else:
					stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
				return stream
				
	# 2. ResourceLoader fallback
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStreamWAV:
			if loop:
				res.loop_mode = AudioStreamWAV.LOOP_FORWARD
				res.loop_begin = 0
				res.loop_end = res.data.size() / 2
			else:
				res.loop_mode = AudioStreamWAV.LOOP_DISABLED
			return res
			
	return null

func _sync_volumes() -> void:
	set_music_volume(PlayerData.music_volume if "music_volume" in PlayerData else 0.8)
	set_sfx_volume(PlayerData.sfx_volume if "sfx_volume" in PlayerData else 1.0)

func set_music_volume(linear: float) -> void:
	var clamped = clampf(linear, 0.0, 1.0)
	if clamped <= 0.001:
		bgm_player.volume_db = -80.0
	else:
		bgm_player.volume_db = linear_to_db(clamped)

func set_sfx_volume(linear: float) -> void:
	var clamped = clampf(linear, 0.0, 1.0)
	var db = -80.0 if clamped <= 0.001 else linear_to_db(clamped)
	for p in sfx_pool:
		p.volume_db = db
	if footstep_player:
		footstep_player.volume_db = db - 7.0 # Gentle subtle SpongeBob rubber squeak
	if voice_player:
		voice_player.volume_db = db + 1.5

# -------------------------------------------------------------
# Background Music API
# -------------------------------------------------------------

func play_bgm(track_name: String, fade_duration: float = 0.45) -> void:
	if current_bgm_track == track_name and bgm_player.playing:
		return
		
	var stream: AudioStreamWAV = bgm_streams.get(track_name, null)
	if not stream:
		return
		
	current_bgm_track = track_name
	emit_signal("bgm_changed", track_name)
	
	var target_db = -80.0 if PlayerData.music_volume <= 0.001 else linear_to_db(clampf(PlayerData.music_volume, 0.001, 1.0))
	
	if bgm_fade_tween and bgm_fade_tween.is_valid():
		bgm_fade_tween.kill()
		
	if bgm_player.playing and fade_duration > 0.05:
		bgm_fade_tween = create_tween()
		bgm_fade_tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration * 0.5)
		bgm_fade_tween.tween_callback(func():
			bgm_player.stream = stream
			bgm_player.play()
		)
		bgm_fade_tween.tween_property(bgm_player, "volume_db", target_db, fade_duration * 0.5)
	else:
		bgm_player.stream = stream
		bgm_player.volume_db = target_db
		bgm_player.play()

func stop_bgm(fade_duration: float = 0.4) -> void:
	current_bgm_track = ""
	if not bgm_player.playing:
		return
	if bgm_fade_tween and bgm_fade_tween.is_valid():
		bgm_fade_tween.kill()
	if fade_duration > 0.05:
		bgm_fade_tween = create_tween()
		bgm_fade_tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration)
		bgm_fade_tween.tween_callback(bgm_player.stop)
	else:
		bgm_player.stop()

func get_current_bgm() -> String:
	return current_bgm_track

# -------------------------------------------------------------
# Sound Effects API (Polyphonic Pool)
# -------------------------------------------------------------

func play_sfx(sfx_name: String, pitch_range: float = 0.05, volume_offset_db: float = 0.0) -> void:
	var stream: AudioStreamWAV = sfx_streams.get(sfx_name, null)
	if not stream:
		return
		
	var player = sfx_pool[sfx_pool_idx]
	sfx_pool_idx = (sfx_pool_idx + 1) % SFX_POOL_SIZE
	
	player.stream = stream
	player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	var base_db = -80.0 if PlayerData.sfx_volume <= 0.001 else linear_to_db(clampf(PlayerData.sfx_volume, 0.001, 1.0))
	player.volume_db = base_db + volume_offset_db
	player.play()

func play_footstep() -> void:
	if footstep_cooldown > 0.0:
		return
	footstep_cooldown = 0.22
	var stream: AudioStreamWAV = sfx_streams.get("footstep_squeak", null)
	if not stream or not footstep_player:
		return
	footstep_player.stream = stream
	footstep_player.pitch_scale = randf_range(0.96, 1.04)
	var base_db = -80.0 if PlayerData.sfx_volume <= 0.001 else linear_to_db(clampf(PlayerData.sfx_volume, 0.001, 1.0))
	footstep_player.volume_db = base_db - 7.0
	footstep_player.play()

func play_fanfare(fanfare_name: String) -> void:
	var stream: AudioStreamWAV = bgm_streams.get(fanfare_name, null)
	if not stream:
		stream = sfx_streams.get(fanfare_name, null)
	if not stream:
		return
	voice_player.stream = stream
	var base_db = -80.0 if PlayerData.sfx_volume <= 0.001 else linear_to_db(clampf(PlayerData.sfx_volume, 0.001, 1.0))
	voice_player.volume_db = base_db + 2.0
	voice_player.play()

func _process(delta: float) -> void:
	if footstep_cooldown > 0.0:
		footstep_cooldown -= delta
