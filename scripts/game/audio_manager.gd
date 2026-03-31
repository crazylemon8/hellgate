extends Node
class_name AudioManager

const STARTUP_STREAM := preload("res://assets/audio/jingles/jingles_STEEL00.ogg")
const GAME_OVER_STREAM := preload("res://assets/audio/jingles/jingles_STEEL08.ogg")
const TUTORIAL_STREAM := preload("res://assets/audio/jingles/jingles_PIZZI00.ogg")
const SUCCESS_STREAM := preload("res://assets/audio/jingles/jingles_PIZZI06.ogg")
const MISTAKE_STREAM := preload("res://assets/audio/jingles/jingles_HIT00.ogg")

var _startup_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _success_player: AudioStreamPlayer
var _negative_player: AudioStreamPlayer


func _ready() -> void:
	_startup_player = _create_player("StartupPlayer", -10.0)
	_ui_player = _create_player("UiPlayer", -12.0)
	_success_player = _create_player("SuccessPlayer", -11.0)
	_negative_player = _create_player("NegativePlayer", -10.0)


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
