extends Node2D
class_name GameController

signal score_changed(red_sorted: int, green_sorted: int, mistakes_remaining: int)
signal pause_changed(is_paused: bool)
signal game_over(final_state: Dictionary)

enum RoundState {
	BRIEFING,
	RUNNING,
	PAUSED,
	GAME_OVER,
}

@export var game_balance: GameBalanceConfig
@export var player_config: PlayerConfig
@export var skeleton_config: SkeletonConfig
@export var wave_config: WaveConfig
@export var skeleton_scene: PackedScene

@onready var player: PlayerController = $World/Entities/Player
@onready var enemies: Node2D = $World/Entities/Enemies
@onready var spawner: Marker2D = $World/Spawner
@onready var left_exit: Marker2D = $World/ExitMarkers/LeftExit
@onready var right_exit: Marker2D = $World/ExitMarkers/RightExit
@onready var wave_director: WaveDirector = $WaveDirector

var _desktop_input := PlayerInputState.new()
var _round_state: RoundState = RoundState.BRIEFING
var _red_sorted: int = 0
var _green_sorted: int = 0
var _mistakes_remaining: int = 0
var _resolved_count: int = 0


func _ready() -> void:
	assert(game_balance != null, "Game balance config is required.")
	assert(player_config != null, "Player config is required.")
	assert(skeleton_config != null, "Skeleton config is required.")
	assert(wave_config != null, "Wave config is required.")
	assert(skeleton_scene != null, "Skeleton scene is required.")

	player.setup(player_config)
	player.speed_meter_changed.connect(_on_player_speed_meter_changed)
	wave_director.spawn_skeleton.connect(_on_spawn_skeleton_requested)
	wave_director.configure(wave_config)
	restart_round()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		match _round_state:
			RoundState.RUNNING:
				set_paused(true)
			RoundState.PAUSED:
				set_paused(false)
			RoundState.GAME_OVER:
				restart_round()


func _physics_process(_delta: float) -> void:
	if _round_state != RoundState.RUNNING:
		player.apply_input(PlayerInputState.new())
		return

	player.apply_input(_build_desktop_input())


func restart_round() -> void:
	for enemy in enemies.get_children():
		enemy.queue_free()

	_red_sorted = 0
	_green_sorted = 0
	_resolved_count = 0
	_mistakes_remaining = game_balance.allowed_mistakes
	_round_state = RoundState.RUNNING

	player.reset_for_round()
	player.global_position = Vector2(360, 640)
	wave_director.start_round()

	score_changed.emit(_red_sorted, _green_sorted, _mistakes_remaining)
	pause_changed.emit(false)


func set_paused(should_pause: bool) -> void:
	if should_pause and _round_state == RoundState.RUNNING:
		_round_state = RoundState.PAUSED
		pause_changed.emit(true)
		return

	if not should_pause and _round_state == RoundState.PAUSED:
		_round_state = RoundState.RUNNING
		pause_changed.emit(false)


func resolve_mobile_input(input_state: PlayerInputState) -> void:
	_desktop_input = input_state.duplicate()


func _build_desktop_input() -> PlayerInputState:
	var state := _desktop_input.duplicate()
	state.move_x = Input.get_axis("move_left", "move_right")
	state.jump_pressed = Input.is_action_just_pressed("jump")
	state.sprint_held = Input.is_action_pressed("sprint")
	state.pause_pressed = Input.is_action_just_pressed("pause")
	return state


func _on_spawn_skeleton_requested(color_name: String, spawn_position: Vector2) -> void:
	var skeleton := skeleton_scene.instantiate() as SortingSkeletonController
	enemies.add_child(skeleton)
	skeleton.global_position = spawn_position
	skeleton.setup(skeleton_config, color_name, _resolved_count)
	skeleton.set_exit_bounds(left_exit.global_position.x, right_exit.global_position.x)
	skeleton.exited.connect(_on_skeleton_exited)
	skeleton.resolved.connect(_on_skeleton_resolved)


func _on_skeleton_exited(side: String, color_name: String) -> void:
	var was_correct := (color_name == "red" and side == "left") or (color_name == "green" and side == "right")
	if was_correct:
		if color_name == "red":
			_red_sorted += 1
		else:
			_green_sorted += 1
	else:
		_mistakes_remaining -= 1

	score_changed.emit(_red_sorted, _green_sorted, _mistakes_remaining)
	if _mistakes_remaining <= 0:
		_round_state = RoundState.GAME_OVER
		wave_director.stop_round()
		game_over.emit(
			{
				"red_sorted": _red_sorted,
				"green_sorted": _green_sorted,
				"resolved_count": _resolved_count,
			}
		)


func _on_skeleton_resolved() -> void:
	_resolved_count += 1
	wave_director.on_skeleton_resolved(_resolved_count)


func _on_player_speed_meter_changed(_current_ratio: float) -> void:
	pass
