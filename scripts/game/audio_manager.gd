extends Node
class_name AudioManager

const GAMEPLAY_MUSIC_STREAM := preload("res://assets/audio/music/dungeon002.ogg")
const STARTUP_STREAM := preload("res://assets/audio/jingles/jingles_STEEL00.ogg")
const GAME_OVER_STREAM := preload("res://assets/audio/jingles/jingles_STEEL08.ogg")
const TUTORIAL_STREAM := preload("res://assets/audio/jingles/jingles_PIZZI00.ogg")
const SUCCESS_STREAM := preload("res://assets/audio/jingles/jingles_PIZZI06.ogg")
const MISTAKE_STREAM := preload("res://assets/audio/sfx/impactSoft_medium_002.ogg")
const UI_CLICK_STREAM := preload("res://assets/audio/ui/click3.ogg")
const UI_TOGGLE_STREAM := preload("res://assets/audio/ui/switch11.ogg")
const JUMP_STREAM := preload("res://assets/audio/sfx/jumpland.wav")
const LAND_STREAM := preload("res://assets/audio/sfx/slime_04.ogg")
const RESPAWN_STREAM := preload("res://assets/audio/sfx/slime_11.ogg")
const REDIRECT_STREAM := preload("res://assets/audio/sfx/impactPunch_medium_001.ogg")
const SPRINT_STREAM := preload("res://assets/audio/sfx/swish-5.wav")

var _music_player: AudioStreamPlayer
var _startup_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _success_player: AudioStreamPlayer
var _negative_player: AudioStreamPlayer
var _movement_player: AudioStreamPlayer
var _impact_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = _create_player("MusicPlayer", -18.0)
	_startup_player = _create_player("StartupPlayer", -18.0)
	_ui_player = _create_player("UiPlayer", -12.0)
	_success_player = _create_player("SuccessPlayer", -11.0)
	_negative_player = _create_player("NegativePlayer", -10.0)
	_movement_player = _create_player("MovementPlayer", -9.5)
	_impact_player = _create_player("ImpactPlayer", -9.0)
	_music_player.stream = GAMEPLAY_MUSIC_STREAM
	_music_player.stream_paused = true
	_music_player.autoplay = false


func play_startup() -> void:
	_play_stream(_startup_player, STARTUP_STREAM)


func play_tutorial_complete() -> void:
	_play_stream(_ui_player, TUTORIAL_STREAM)


func play_success() -> void:
	_play_stream(_success_player, SUCCESS_STREAM)


func play_mistake() -> void:
	_play_stream(_negative_player, MISTAKE_STREAM)


func play_game_over() -> void:
	_play_stream(_negative_player, GAME_OVER_STREAM)


func play_ui_click() -> void:
	_play_stream(_ui_player, UI_CLICK_STREAM)


func play_ui_toggle() -> void:
	_play_stream(_ui_player, UI_TOGGLE_STREAM)


func play_jump() -> void:
	_play_stream(_movement_player, JUMP_STREAM)


func play_land() -> void:
	_play_stream(_movement_player, LAND_STREAM)


func play_respawn() -> void:
	_play_stream(_movement_player, RESPAWN_STREAM)


func play_redirect() -> void:
	_play_stream(_impact_player, REDIRECT_STREAM)


func play_sprint() -> void:
	_play_stream(_movement_player, SPRINT_STREAM)


func play_music() -> void:
	if _music_player == null or GAMEPLAY_MUSIC_STREAM == null:
		return
	if _music_player.playing:
		return
	_music_player.stream = GAMEPLAY_MUSIC_STREAM
	_music_player.play()


func stop_music() -> void:
	if _music_player == null:
		return
	_music_player.stop()


func _create_player(name: String, volume_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = name
	player.bus = "Master"
	player.volume_db = volume_db
	add_child(player)
	return player


func _play_stream(player: AudioStreamPlayer, stream: AudioStream) -> void:
	if player == null or stream == null:
		return

	player.stop()
	player.stream = stream
	player.play()
