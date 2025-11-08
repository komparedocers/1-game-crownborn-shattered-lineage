extends Node
# Global audio manager

# Audio bus indices
var MASTER_BUS = 0
var MUSIC_BUS = 1
var SFX_BUS = 2
var VO_BUS = 3

# Audio players
var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var vo_player: AudioStreamPlayer

# Audio paths (placeholders - replace with actual audio files)
var audio_library = {
	# Music
	"menu_theme": "res://audio/music/menu_theme.ogg",
	"combat_theme": "res://audio/music/combat_theme.ogg",
	"boss_theme": "res://audio/music/boss_theme.ogg",
	"victory_theme": "res://audio/music/victory.ogg",

	# SFX - Combat
	"sword_swing": "res://audio/sfx/sword_swing.ogg",
	"sword_hit": "res://audio/sfx/sword_hit.ogg",
	"arrow_fire": "res://audio/sfx/arrow_fire.ogg",
	"arrow_hit": "res://audio/sfx/arrow_hit.ogg",
	"knife_stab": "res://audio/sfx/knife_stab.ogg",

	# SFX - Player
	"footstep": "res://audio/sfx/footstep.ogg",
	"jump": "res://audio/sfx/jump.ogg",
	"land": "res://audio/sfx/land.ogg",
	"take_damage": "res://audio/sfx/player_hurt.ogg",
	"death": "res://audio/sfx/player_death.ogg",

	# SFX - Powers
	"blink_step": "res://audio/sfx/blink_step.ogg",
	"shadow_veil": "res://audio/sfx/shadow_veil.ogg",
	"time_slip": "res://audio/sfx/time_slip.ogg",

	# SFX - Enemy
	"enemy_alert": "res://audio/sfx/enemy_alert.ogg",
	"enemy_death": "res://audio/sfx/enemy_death.ogg",

	# SFX - Boss
	"boss_roar": "res://audio/sfx/boss_roar.ogg",
	"boss_phase_change": "res://audio/sfx/boss_phase.ogg",

	# SFX - UI
	"button_click": "res://audio/sfx/ui_click.ogg",
	"purchase": "res://audio/sfx/purchase.ogg",
	"level_complete": "res://audio/sfx/level_complete.ogg",
	"rescue": "res://audio/sfx/rescue.ogg",
	"power_unlock": "res://audio/sfx/power_unlock.ogg",

	# Voice - Shaman
	"shaman_appears": "res://audio/vo/shaman_appears.ogg",
	"shaman_wisdom_1": "res://audio/vo/shaman_wisdom_1.ogg",
}

func _ready():
	# Setup audio buses
	setup_audio_buses()

	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	# Create SFX pool
	for i in range(10):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		sfx_players.append(player)
		add_child(player)

	# Create VO player
	vo_player = AudioStreamPlayer.new()
	vo_player.bus = "VO"
	add_child(vo_player)

func setup_audio_buses():
	# Ensure buses exist
	if AudioServer.get_bus_count() < 4:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "Music")

		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, "SFX")

		AudioServer.add_bus(3)
		AudioServer.set_bus_name(3, "VO")

func play_music(track_name: String, fade_in: float = 1.0):
	"""Play background music with optional fade in"""
	if not audio_library.has(track_name):
		print("Music track not found: ", track_name)
		return

	# Fade out current music
	if music_player.playing:
		stop_music(fade_in)
		await get_tree().create_timer(fade_in).timeout

	# Load and play new track
	var audio_path = audio_library[track_name]
	if FileAccess.file_exists(audio_path):
		var stream = load(audio_path)
		music_player.stream = stream
		music_player.volume_db = -80 if fade_in > 0 else 0
		music_player.play()

		# Fade in
		if fade_in > 0:
			var tween = create_tween()
			tween.tween_property(music_player, "volume_db", 0, fade_in)
	else:
		print("Audio file not found: ", audio_path)

func stop_music(fade_out: float = 1.0):
	"""Stop music with optional fade out"""
	if fade_out > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_out)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

func play_sfx(sfx_name: String, volume_db: float = 0.0):
	"""Play sound effect"""
	if not audio_library.has(sfx_name):
		print("SFX not found: ", sfx_name)
		return

	# Find available player
	var player = get_available_sfx_player()
	if not player:
		return

	var audio_path = audio_library[sfx_name]
	if FileAccess.file_exists(audio_path):
		var stream = load(audio_path)
		player.stream = stream
		player.volume_db = volume_db
		player.play()
	else:
		print("Audio file not found: ", audio_path)

func play_sfx_3d(sfx_name: String, position: Vector3, volume_db: float = 0.0):
	"""Play 3D positioned sound effect"""
	# Would create AudioStreamPlayer3D for spatial audio
	play_sfx(sfx_name, volume_db)

func play_vo(vo_name: String):
	"""Play voice line"""
	if not audio_library.has(vo_name):
		print("VO not found: ", vo_name)
		return

	# Stop current VO
	if vo_player.playing:
		vo_player.stop()

	var audio_path = audio_library[vo_name]
	if FileAccess.file_exists(audio_path):
		var stream = load(audio_path)
		vo_player.stream = stream
		vo_player.play()

func get_available_sfx_player() -> AudioStreamPlayer:
	"""Get available SFX player from pool"""
	for player in sfx_players:
		if not player.playing:
			return player
	return null

func set_master_volume(volume: float):
	"""Set master volume (0.0 to 1.0)"""
	AudioServer.set_bus_volume_db(MASTER_BUS, linear_to_db(volume))

func set_music_volume(volume: float):
	"""Set music volume (0.0 to 1.0)"""
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear_to_db(volume))

func set_sfx_volume(volume: float):
	"""Set SFX volume (0.0 to 1.0)"""
	AudioServer.set_bus_volume_db(SFX_BUS, linear_to_db(volume))

func set_vo_volume(volume: float):
	"""Set voice volume (0.0 to 1.0)"""
	AudioServer.set_bus_volume_db(VO_BUS, linear_to_db(volume))

func linear_to_db(volume: float) -> float:
	"""Convert linear volume to decibels"""
	if volume <= 0:
		return -80
	return 20 * log(volume) / log(10)
